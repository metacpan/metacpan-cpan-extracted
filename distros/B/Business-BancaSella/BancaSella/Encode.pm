package Business::BancaSella::Encode;

$VERSION = "0.11";
sub Version { $VERSION; }

require 5.004;
use strict;
use Carp;

use Business::BancaSella::Encode::Gestpay;
use Business::BancaSella::Encode::Gateway;

my %fields 	=
    (
     type		=>		'gestpay',
     );
     
my @fields_req	= qw/type/;
     
sub new
{   
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self,$class;
    $self->init(@_);
    return $self;
}							

sub init {
	my $self = shift;
	my (%options) = @_;
	# Assign default options
	while (my ($key,$value) = each(%fields)) {
		$self->{$key} = $self->{$key} || $value;
    }
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
	}												
	if ($self->type eq 'gestpay') {
		no strict 'vars';
		unshift @ISA,'Business::BancaSella::Encode::Gestpay';
	} elsif ($self->type eq 'gateway') {
		no strict 'vars';
		unshift @ISA,'Business::BancaSella::Encode::Gateway';
	} else {
		die "Unsupported type " . $self->type . "in " . ref($self) . "::new";
	}
	$self->SUPER::init(@_);
}


sub type { my $s=shift; return @_ ? ($s->{type}=shift) : $s->{type} }

# Preloaded methods go here.

1;
__END__
