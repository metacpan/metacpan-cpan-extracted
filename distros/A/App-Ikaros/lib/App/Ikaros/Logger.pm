package App::Ikaros::Logger;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle;
use POSIX;

sub new {
    my ($class) = @_;
    my $self = {
        hosts => +{}
    };
    return bless $self, $class;
}

sub add {
    my ($self, $name, $stdout, $stderr) = @_;
    $self->{hosts}->{$name} = {
        name   => $name,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub logging {
    my ($self, $name, $pid) = @_;
    my $handler_container = $self->{hosts}->{$name} or return;
    my $cv = AnyEvent->condvar;
    my $handles = [];
    my $building = 0;
    for my $handle_name (qw/stdout stderr/) {
        my $handler = $handler_container->{$handle_name};
        $cv->begin;
        my $handle; $handle = AnyEvent::Handle->new(
            fh => $handler,
            on_read => sub {
                $handle->push_read(line => sub {
                    my $line = $_[1];
                    print STDERR sprintf "[%s] %s\n", $name, $line if ($handle_name eq 'stdout');
                    #print STDERR sprintf "[%s] <<< %s >>>\n", $name, $line if ($handle_name eq 'stderr');
                    if ($line =~ /^IKAROS:BUILD_START/) {
                        $building = 1;
                    } elsif ($line =~ /^IKAROS:BUILD_END/) {
                        $building = 0;
                        $cv->end;
                        kill(9, $pid);
                    }
                });
            },
            on_eof => sub {
                $cv->end unless ($building);
            },
            on_error => sub {
                my $msg = $_[2];
                print STDERR sprintf "[%s] %s\n", $name, $msg
                    unless $! == POSIX::EPIPE;
                if ($msg =~ /^IKAROS:/) {
                    print STDERR "ERROR";
                    kill(9, $pid);
                }
                $cv->end;
            },
        );
        push @$handles, $handle;
    }
    $cv->recv;
    $_->destroy foreach (@$handles);
}

1;
