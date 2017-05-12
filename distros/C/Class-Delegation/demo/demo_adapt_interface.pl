package DogTag;

sub new { bless {}, $_[0] };

sub get_name   { return $_[0]->{name} }
sub set_name   { $_[0]->{name} = $_[1] }

sub get_rank   { return $_[0]->{rank} }
sub set_rank   { $_[0]->{rank} = $_[1] }

sub get_serial { return $_[0]->{serial} }
sub set_serial { $_[0]->{serial} = $_[1] }


package DogTag::SingleAccess;

use Class::Delegation
	send => -ALL,
	  to => 'dogtag',
	  as => sub {
			my ($invocant, $method, @args) = @_;
			return @args ? "set_$method" : "get_$method"
		    },
	;
	
sub new { bless { dogtag => DogTag->new(@_[1..$#_]) }, $_[0] }


package main;

my $obj = DogTag::SingleAccess->new();

$obj->name("Damian");
$obj->rank("Private");

print $obj->name(), "\n";
print $obj->rank(), "\n";


