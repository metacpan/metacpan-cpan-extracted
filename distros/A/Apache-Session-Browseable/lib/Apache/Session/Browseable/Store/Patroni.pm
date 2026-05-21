package Apache::Session::Browseable::Store::Patroni;

use strict;

use DBI;
use Apache::Session::Store::Postgres;

our @ISA     = qw(Apache::Session::Store::Postgres);
our $VERSION = '1.3.19';

# Cache structure per DataSource:
# {
#   leader => { host => '...', port => '...', time => ... },
#   lastFailure => timestamp,
# }
our %patroniCache;

sub connection {
    my $self    = shift;
    my $session = shift;

    return if ( defined $self->{dbh} );

    $self->{'table_name'} =
      $session->{args}->{TableName} || $Apache::Session::Store::DBI::TableName;

    if ( exists $session->{args}->{Handle} ) {
        $self->{dbh}    = $session->{args}->{Handle};
        $self->{commit} = $session->{args}->{Commit};
        return;
    }

    # Store original DataSource as cache key
    my $originalDataSource = $session->{args}->{DataSource};
    $self->{_originalDataSource} = $originalDataSource;

    # Use cached leader if available and not expired
    my $cache    = $patroniCache{$originalDataSource}  || {};
    my $cacheTTL = $session->{args}->{PatroniCacheTTL} || 60;

    if (    $cache->{leader}
        and $cache->{leader}->{time}
        and ( time() - $cache->{leader}->{time} ) < $cacheTTL )
    {
        $session->{args}->{DataSource} =
          _buildDataSource( $originalDataSource, $cache->{leader} );
    }

    foreach ( 0 .. 1 ) {
        (
            $self->checkMaster( $session->{args} )
              or warn "Patroni check failed"
        ) if $self->{failure};
        eval {
            $self->{dbh} = DBI->connect(
                $session->{args}->{DataSource},
                $session->{args}->{UserName},
                $session->{args}->{Password},
                { RaiseError => 1, AutoCommit => 0 }
            ) || die $DBI::errstr;
        };
        if ( $@ and !$_ ) {
            $self->{failure} = 1;
        }
        else {
            last;
        }
    }
    die $@ if $@;

    #If we open the connection, we close the connection
    $self->{disconnect} = 1;

    #the programmer has to tell us what commit policy to use
    $self->{commit} = $session->{args}->{Commit} // 1;
}

sub _try {
    my $self = shift;
    my $sub  = shift;
    my $res;

    foreach ( 0 .. 1 ) {
        $res =
          eval { Apache::Session::Store::Postgres->can($sub)->( $self, @_ ) };
        if ( $@ and $@ !~ /Object does not exist/ and !$_ ) {
            $self->{failure} = 1;
            $self->DESTROY;
            delete $self->{"${sub}_sth"};
            delete $self->{dbh};
        }
        else {
            last;
        }
    }
    die $@ if $@;
    return $res;
}

sub insert {
    my $self = shift;
    return $self->_try( 'insert', @_ );
}

sub update {
    my $self = shift;
    return $self->_try( 'update', @_ );
}

sub materialize {
    my $self = shift;
    return $self->_try( 'materialize', @_ );
}

sub remove {
    my $self = shift;
    return $self->_try( 'remove', @_ );
}

sub checkMaster {
    my ( $self, $args ) = @_;
    delete $self->{failure};

    my $originalDataSource =
      $self->{_originalDataSource} || $args->{DataSource};
    my $cache = $patroniCache{$originalDataSource} ||= {};

    # Circuit breaker: avoid hammering Patroni API if it's failing
    my $circuitBreakerDelay = $args->{PatroniCircuitBreakerDelay} || 30;
    if ( $cache->{lastFailure}
        and ( time() - $cache->{lastFailure} ) < $circuitBreakerDelay )
    {
        # Circuit breaker active, try cached leader as fallback
        return $self->_useCachedLeader( $args, $originalDataSource,
            "Circuit breaker active" );
    }

    require JSON;
    require LWP::UserAgent;
    require IO::Socket::SSL;

    # SSL verification: secure by default, can be disabled with PatroniVerifySSL => 0
    my $verify_ssl = $args->{PatroniVerifySSL} // 1;
    my %ssl_opts;
    if ($verify_ssl) {
        %ssl_opts = (
            verify_hostname => 1,
            SSL_verify_mode => &IO::Socket::SSL::SSL_VERIFY_PEER,
            ( $args->{PatroniSSLCAFile} ? ( SSL_ca_file => $args->{PatroniSSLCAFile} ) : () ),
            ( $args->{PatroniSSLCAPath} ? ( SSL_ca_path => $args->{PatroniSSLCAPath} ) : () ),
        );
    }
    else {
        %ssl_opts = (
            verify_hostname => 0,
            SSL_verify_mode => &IO::Socket::SSL::SSL_VERIFY_NONE,
        );
    }

    my $ua = LWP::UserAgent->new(
        env_proxy => 1,
        ssl_opts  => \%ssl_opts,
        timeout   => $args->{PatroniTimeout} || 3,
    );
    my $res;

    foreach my $patroniUrl ( split /[,\s]\s*/,
        ( $args->{PatroniUrl} || $args->{patroniUrl} ) )
    {
        my $resp = $ua->get($patroniUrl);
        if ( $resp->is_success ) {
            my $c = eval { JSON::from_json( $resp->decoded_content ) };
            if ( $@ or !$c->{members} or ref( $c->{members} ) ne 'ARRAY' ) {
                print STDERR "Bad response from $patroniUrl: "
                  . $resp->decoded_content . "\n";
                next;
            }

            my @leaders = grep { $_->{role} eq 'leader' } @{ $c->{members} };

            # Check for split-brain scenario
            if ( @leaders > 1 ) {
                my $leadersList =
                  join( ', ', map { "$_->{host}:$_->{port}" } @leaders );
                print STDERR
                  "Multiple leaders detected (split-brain) from $patroniUrl"
                  . " - Leaders: $leadersList\n";
                next;
            }

            my ($leader) = @leaders;
            unless ($leader) {
                print STDERR "No leader found from $patroniUrl: "
                  . $resp->decoded_content . "\n";
                next;
            }

            # Validate leader has required fields
            unless ( defined $leader->{host} && defined $leader->{port} ) {
                print STDERR "Leader missing host or port from $patroniUrl: "
                  . $resp->decoded_content . "\n";
                next;
            }

            # Check leader health state
            if ( $leader->{state} && $leader->{state} ne 'running' ) {
                print STDERR
                  "Leader not in running state (state=$leader->{state})"
                  . " from $patroniUrl\n";
                next;
            }

            # Cache the leader info
            $cache->{leader} = {
                host => $leader->{host},
                port => $leader->{port},
                time => time()
            };

            # Reset circuit breaker on success
            delete $cache->{lastFailure};

            $args->{DataSource} =
              _buildDataSource( $originalDataSource, $leader );
            $res = 1;
            last;
        }
    }

    # If API failed, record for circuit breaker and try cached leader
    unless ($res) {
        $cache->{lastFailure} = time();
        $res = $self->_useCachedLeader( $args, $originalDataSource,
            "Patroni API unavailable" );
    }

    return $res;
}

# Use cached leader as fallback
sub _useCachedLeader {
    my ( $self, $args, $originalDataSource, $reason ) = @_;

    my $cache    = $patroniCache{$originalDataSource} || {};
    my $cacheTTL = $args->{PatroniCacheTTL}           || 60;

    if (    $cache->{leader}
        and $cache->{leader}->{time}
        and ( time() - $cache->{leader}->{time} ) < $cacheTTL )
    {
        my $age = time() - $cache->{leader}->{time};
        print STDERR "$reason, using cached leader (${age}s old)\n";
        $args->{DataSource} =
          _buildDataSource( $originalDataSource, $cache->{leader} );
        return 1;
    }
    return 0;
}

# Build DataSource string with new host/port
sub _buildDataSource {
    my ( $originalDataSource, $leader ) = @_;

    my $chain = $originalDataSource;

    # Remove existing host/port parameters
    $chain =~ s/;\s*host=[^;]+//gi;
    $chain =~ s/;\s*port=[^;]+//gi;
    $chain =~ s/\s+host=[^\s;]+//gi;
    $chain =~ s/\s+port=[^\s;]+//gi;

    # Clean up trailing semicolons
    $chain =~ s/;+$//;

    # Add new host and port
    my $separator = ( $chain =~ /:$/ ) ? '' : ';';
    return "${chain}${separator}host=$leader->{host};port=$leader->{port}";
}

1;
