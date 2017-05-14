package Data::TDMA::Constants;

require Exporter;

use warnings;
use strict;

use vars qw{ 
	@ISA %EXPORT_TAGS @EXPORT_OK 
		$EPOCHS_PER_DAY    $FRAMES_PER_EPOCH
		$SLOTS_PER_FRAME   $FRAMES_PER_DAY
		$SLOTS_PER_DAY     $SECONDS_PER_EPOCH
		$SECONDS_PER_DAY   $SECONDS_PER_SLOT
		$SECONDS_PER_FRAME $TDMA_DEBUG
	};
use Carp qw{ confess };

@ISA = qw{ Exporter };

@EXPORT_OK = qw{
		$EPOCHS_PER_DAY    $FRAMES_PER_EPOCH
		$SLOTS_PER_FRAME   $FRAMES_PER_DAY
		$SLOTS_PER_DAY     $SECONDS_PER_EPOCH
		$SECONDS_PER_DAY   $SECONDS_PER_SLOT
		$SECONDS_PER_FRAME $TDMA_DEBUG
};

%EXPORT_TAGS = (
	all => [ @EXPORT_OK ],
);

sub _init {
	$EPOCHS_PER_DAY    = 113; # this is really 112.5
	$FRAMES_PER_EPOCH  = 64; 
	$SLOTS_PER_FRAME   = 1536;
	
	$FRAMES_PER_DAY    = $EPOCHS_PER_DAY * $FRAMES_PER_EPOCH;
	$SLOTS_PER_DAY     = $FRAMES_PER_DAY * $SLOTS_PER_FRAME;
	
	$SECONDS_PER_SLOT  = 1/128; # there are 12 seconds in a frame
	$SECONDS_PER_EPOCH = $FRAMES_PER_EPOCH * $SLOTS_PER_FRAME * $SECONDS_PER_SLOT;
	$SECONDS_PER_DAY   = $SECONDS_PER_EPOCH * $EPOCHS_PER_DAY; # this should be CLOSE to 86400
	$SECONDS_PER_FRAME = $SLOTS_PER_FRAME * $SECONDS_PER_SLOT;

	# Squawk if we failed to init properly
	if (
		defined $EPOCHS_PER_DAY and 
		defined $FRAMES_PER_EPOCH and 
		defined $SLOTS_PER_FRAME and 
		defined $FRAMES_PER_DAY and 
		defined $SLOTS_PER_DAY and 
		defined $SECONDS_PER_SLOT and 
		defined $SECONDS_PER_EPOCH and 
		defined $SECONDS_PER_DAY and 
		defined $SECONDS_PER_FRAME      # XXX: thar be dragons here 
	) { return  0 } else {
		confess "Failure to initialize"
	}
}

sub new { 
	confess "there is no constructor in this package."
}

1;

=pod

=head1 NAME

Data::TDMA::Constants

=head1 ABSTRACT

TDMA::Constants provides basic data structures and functions which
may then be used by other pieces of the TDMA structure.

=head1 USAGE

	use Data::TDMA::Constants;
	
	Data::TDMA::Constants->frame_configure(
		{
			add_methods => {
				method_name => \&method_name,
				method_name => sub { }
			},
			
			serialize  => sub { }, 
			# or ...
			serialize  => \&serialize,
		}
	);
	
	# a practical example
	
	Data::TDMA::Constants::slot_configure(
		add_data   => {
			jitter      => 0,  # a default
			propagation => 0,  # a default
			payload     => "secrets"
		},
		serialize => sub {
			my $self = $_[0];
			$self->{jitter}       = CRYPTO::get_jitter();
			$self->{propagation}  = CRYPTO::get_propagation();
			$self->{payload}      = CRYPTO::supercrypt($self->{payload}) 
		},
	);
	
This means when we go to create a new set of slots (eg with frame->new()),
they will all know how to have jitter set, when they are serialized,
they will have jitter set, default values are set, and the payload is created.

Instead of adding a jitter function, we could have added frequency-hopping,
or payload introspection capabilities ("is what I've got what it says 
it is?"), like checksums and friends.

You can have TDMA with no data, but it's not very interesting. So, going
through and creating configurations for your objects, by using the methods

	slot_configure()
	frame_configure()
	epoch_configure()
	day_configure()

all of which have the exact syntax, you may define the I<type> of data
you wish to pass over your TDMA network. I<Then> go start creating objects
and putting them on the wire. If the first thing you do is create a new
TDMA Day, you'll have an object full of thousands of empty objects.

And that would be silly.

=head2 SERIALIZATION

This will depend on how you intend to put things on the wire. You may 
want to look into f<pack> and f<vec> and some of the compression modules
available to perl. Be aware that every cycle you spend processing your
payload for serialization is a cycle you don't spend putting it on the
wire. It is very easy to take an application which would normally be I/O
bound (say, by a gigabit interface), and turn it into one that is CPU-bound
by increasing the complexity of the algorithm. So let me be very clear
about the serialization argument: you want it to be short, sweet, and
really, I<really> fast. If you're running crypto, consider running
crypto on the line rather than in the software, or using one of the 
SSL acceleration cards.

=head3 THE BAD NEWS

You need to have a serialize function. It must be a subroutine. There are
two syntaxes for it, the latter will be a demonstration:

	serialize => \&serialize,
	# or ...
	serialize => sub {
		my $self = $_[0];
		$self->{jitter}       = CRYPTO::get_jitter();
		$self->{propagation}  = CRYPTO::get_propagation();
		$self->{payload}      = CRYPTO::supercrypt(
			$self->{payload},
			$self->{jitter},
			$self->{propagation},
		); 
	},

The object being serialized is going to be getting passed in to you
as your first argument. So treat it, programmatically, as you would
OOP in any other perl application.

The important notion here is that you are making an object fit to put
on the wire. If this means you need to encrypt it, or you need to strip
high bits off it, do that here. You will have access to all the data
structures that you provided with the add_data argument to the
xxxx_configure( ) procedure. So if you have a jitter value you want
to store, store it in the object, or get it at run time; it doesn't matter.
There is more than one way to serialize your object. At any rate, when
you are done serializing, you are either going to explicitly return() 
the serialized data, or you are going to have your last element returned.
When whatever wire-access object you have wants to put stuff on the wire
it's going to say:

	$wire->put($slot->serialize())

Note that no arguments are given. All data you need can be divined from
the objects methods themselves, and from the data structures you provided.
Bear in mind also that TDMA is time sensitive, and if it takes longer than 
your slice to serialize what you're putting on the wire, it's only useless
as "documentation" to the receiver – not current information.

=head1 BUGS

This stuff should be in the Data::TDMA module.

=head1 AUTHOR

	Jane A. Avriette
  jane@cpan.org
