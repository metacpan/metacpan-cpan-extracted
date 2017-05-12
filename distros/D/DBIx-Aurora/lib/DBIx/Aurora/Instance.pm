package DBIx::Aurora::Instance;
use strict;
use warnings;
use DBIx::Handler;
use Time::HiRes;

sub new {
    my ($class, $connect_info, $opts) = @_;
    $opts ||= {};

    my $self = bless {
        handler        => undef,
        is_readonly    => undef,
        is_unreachable => undef,
        maybe_reader   => 1,
        connected_at   => 0,
    }, $class;

    my $on_connection_event = sub {
        my ($mode, $dbh, $additional) = @_;
        if (my $orig = $opts->{$mode}) {
            if (not ref $orig) {
                $dbh->do($orig);
            } elsif (ref $orig eq 'CODE') {
                $orig->($dbh);
            } elsif (ref $orig eq 'ARRAY') {
                $dbh->do($_) for @$orig;
            } else {
                Carp::croak "Invalid $mode: " . ref $orig;
            }
        }
        $additional->($mode, $dbh);
    };

    $self->{handler} = DBIx::Handler->new(
        $connect_info->[0],
        $connect_info->[1],
        $connect_info->[2],
        {

            AutoCommit            => 0,
            mysql_connect_timeout => 1,
            mysql_write_timeout   => 1,
            mysql_read_timeout    => 1,
            %{$connect_info->[3]},
            RaiseError => 1,
        },
        {
            on_connect_do => sub {
                my $dbh = shift;
                $on_connection_event->(on_connect_do => $dbh, sub {
                    my ($mode, $dbh) = @_;
                    my $is_readonly = do {
                        my $sql = 'SELECT @@global.innodb_read_only AS readonly';
                        my $row = $dbh->selectrow_hashref($sql);
                        $row->{readonly};
                    };
                    $self->{is_readonly}  = $is_readonly;
                    $self->{maybe_reader} = $is_readonly;
                    $self->{connected_at} = Time::HiRes::time;
                });
            },
            on_disconnect_do => sub {
                my $dbh = shift;
                $on_connection_event->(on_disconnect_do => $dbh, sub {
                    my ($mode, $dbh) = @_;
                    $self->{is_readonly}  = undef;
                    $self->{connected_at} = 0;
                    # DO NOT `undef $self->{maybe_reader}`;
                });
            },
        }
    );

    $self;
}

sub handler {
    my $self = shift;

    eval { $self->{handler}->dbh };
    if (my $e = $@) {
        if ($e =~ /DBI connect\(.+\) failed:/) {
            if ($e =~ /Can't connect to MySQL server on '[^']*' \(111\)/) { # failover
                Carp::croak(DBIx::Aurora::Instance::Exception::Connectivity::Failover->new($e));
            } elsif ($e =~ /Lost connection to MySQL server at/) {
                Carp::croak(DBIx::Aurora::Instance::Exception::Connectivity::LostConnection->new($e));
            } elsif ( # unexpected connection errors
                $e =~ /Unknown MySQL server host '[^']*' \(0\)/
             or $e =~ /Can't connect to MySQL server on/
            ) {
                # FIXME $self->{is_unreachable} = 1;
                Carp::croak(DBIx::Aurora::Instance::Exception::Connectivity::Unreachable->new($e));
            } else {
                Carp::croak(DBIx::Aurora::Instance::Exception::Connectivity->new($e));
            }
        } else {
            Carp::croak($e);
        }
    }

    return $self->{handler};
}

sub disconnect {
    my $self = shift;
    $self->{is_readonly} = undef;
    # DO NOT `undef $self->{maybe_reader}`;
    $self->{handler} && $self->{handler}->disconnect;
}

sub maybe_writer   { !shift->{maybe_reader}   }
sub maybe_reader   {  shift->{maybe_reader}   }
sub is_writer      { !shift->{is_readonly}    }
sub is_reader      {  shift->{is_readonly}    }
sub is_unreachable {  shift->{is_unreachable} }
sub connected_at   {  shift->{connected_at}   }

sub DESTROY { $_[0]->disconnect }

package
    DBIx::Aurora::Instance::Exception::Connectivity;
use overload '""' => sub { shift->{msg} };

sub new {
    my ($class, $msg) = @_;
    bless { msg => $msg }, $class;
}

package
    DBIx::Aurora::Instance::Exception::Connectivity::Failover;
use parent -norequire, 'DBIx::Aurora::Instance::Exception::Connectivity';

package
    DBIx::Aurora::Instance::Exception::Connectivity::LostConnection;
use parent -norequire, 'DBIx::Aurora::Instance::Exception::Connectivity';

package
    DBIx::Aurora::Instance::Exception::Connectivity::Unreachable;
use parent -norequire, 'DBIx::Aurora::Instance::Exception::Connectivity';

1;
__END__
