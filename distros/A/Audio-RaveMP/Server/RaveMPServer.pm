package Audio::RaveMPServer;

use strict;

use RPC::PlServer ();
use Audio::RaveMP ();

if ($0 eq '-e') {
    package main;
    use subs 'start';
    *start = \&Audio::RaveMPDaemon::start;
}

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->{rmp} = Audio::RaveMP->new;
    unless ($self->{rmp}->permitted) {
	die $!;
    }
    unless ($self->{rmp}->is_ready) {
	die "device is not ready";
    }
    $self;
}

sub contents {
    my $self = shift;
    my $contents = $self->{rmp}->contents;
    my $c = [];
    for my $slot (@$contents) {
	push @$c, bless {
		   number => $slot->number,
		   type => $slot->type,
		   filename => $slot->filename,
		  }, 'Audio::RaveMPSlotRemote';
    }
    bless $c, 'Audio::RaveMPSlotsRemote';
}

sub filename {
    my($self, $slot) = @_;
    $self->{rmp}->filename($slot);
}

sub upload {
    my($self, $fname, $dest_name) = @_;
    $self->{rmp}->upload($fname, $dest_name);
}

sub download {
    my($self, $fname, $dest_name) = @_;
    $self->{rmp}->download($fname, $dest_name);
}

sub remove {
    my($self, $number) = @_;
    $self->{rmp}->remove($number);
}

sub is_ready {
    shift->{rmp}->is_ready;
}

sub permitted {
    shift->{rmp}->permitted;
}

package Audio::RaveMPDaemon;

my $PORT = 9886; #XXX config?

{
    no strict;
    $VERSION = '0.01';
    @ISA = qw(RPC::PlServer);
}

#access control
my @allow = (
{
 'mask' => '^127\.0\.0\.1$',
 'accept' => 1,
},
);

sub allow {
    my $self = shift;
    push @allow, @_;
}

sub new {
    my $class = shift;
    $class->SUPER::new({'pidfile' => 'none',
			'clients' => \@allow,
			'mode' => 'single', #non-forking mode
			'logfile' => 'STDERR', #XXX
			'localport' => $PORT}, []);
}

sub start {
    my $server = Audio::RaveMPDaemon->new;

    $server->Bind();
}

1;

__END__
