package Apache::Session::Browseable::Store::Patroni;

use strict;

use DBI;
use Apache::Session::Store::Postgres;

our @ISA     = qw(Apache::Session::Store::Postgres);
our $VERSION = '1.3.17';

our %knownMappings;

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

    # Use last known Patroni response if available
    $session->{args}->{DataSource} =
      $knownMappings{ $session->{args}->{DataSource} }
      if $session->{args}->{DataSource}
      and $knownMappings{ $session->{args}->{DataSource} };

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
    require JSON;
    require LWP::UserAgent;
    require IO::Socket::SSL;
    my $ua = LWP::UserAgent->new(
        env_proxy => 1,
        ssl_opts  => {
            verify_hostname => 0,
            SSL_verify_mode => &IO::Socket::SSL::SSL_VERIFY_NONE,
        },
        timeout => 3,
    );
    my $res;

    foreach my $patroniUrl ( split /[,\s]\s*/,
        ( $args->{PatroniUrl} || $args->{patroniUrl} ) )
    {
        my $resp = $ua->get($patroniUrl);
        if ( $resp->is_success ) {
            my $c = eval { JSON::from_json( $resp->decoded_content ) };
            if ( $@ or !$c->{members} or ref( $c->{members} ) ne 'ARRAY' ) {
                print STDERR "Bad response from $patroniUrl\n"
                  . $resp->decoded_content;
                next;
            }
            my ($leader) = grep { $_->{role} eq 'leader' } @{ $c->{members} };
            unless ($leader) {
                print STDERR "No leader found from $patroniUrl\n"
                  . $resp->decoded_content;
                next;
            }
            my $old = $args->{DataSource};
            $args->{DataSource} =~ s/(?:port|host)=[^;]+;*//g;
            $args->{DataSource} =~ s/;$//;
            $args->{DataSource} .= ( $args->{DataSource} =~ /:$/ ? '' : ';' )
              . "host=$leader->{host};port=$leader->{port}";
            $knownMappings{$old} = $args->{DataSource};
            $res = 1;
            last;
        }
    }
    return $res;
}

1;
