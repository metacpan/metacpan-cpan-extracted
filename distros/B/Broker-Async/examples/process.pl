#!/usr/bin/env perl
package main;
use Broker::Async;
use Future;

my @numbers   = @ARGV;
my @processes = map MyProcess->new, 1 .. 5;
my @workers   = map { my $proc = $_; sub { $proc->request(@_) } } @processes;
my $broker    = Broker::Async->new(workers => \@workers);

my @results;
for my $num (@numbers) {
    push @results, $broker->do($num)->on_ready(sub{
        my $result = $_[0]->get;
        warn "> got result: $num**2 = $result\n";
    });
}
Future->wait_all(@results)->get;
warn "> finished getting all results\n";

package MyProcess;
use AE;
use AnyEvent::Future;
use IO::Handle;

sub request {
    my ($self, $num) = @_;
    $self->{child}{w}->printflush($num, "\n");

    my $f = AnyEvent::Future->new;
    my $w; $w = AE::io $self->{parent}{r}, 0, sub {
        chomp(my $res = $self->{parent}{r}->getline);
        $f->done($res);
        undef $w;
    };

    return $f;
}

sub serve {
    my ($self) = @_;
    while (my $req = $self->{child}{r}->getline) {
        chomp $req;
        $self->{parent}{w}->printflush($req**2, "\n");
    }
}

sub new {
    my ($class) = @_;
    my $self = bless {
        parent => {},
        child  => {},
    }, $class;

    pipe( $self->{parent}{r}, $self->{parent}{w} );
    pipe( $self->{child}{r},  $self->{child}{w}  );

    if (my $pid = fork) {
        close $self->{parent}{w};
        close $self->{child}{r};
        return $self;
    } else {
        close $self->{parent}{r};
        close $self->{child}{w};
        $self->serve;
        exit 0;
    }
}
