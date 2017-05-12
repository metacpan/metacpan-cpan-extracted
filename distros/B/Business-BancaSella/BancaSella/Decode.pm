package Business::BancaSella::Decode;

$VERSION = "0.11";
sub Version { $VERSION; }

require 5.004;
use Carp;
use strict;
use warnings;

use Business::BancaSella::Decode::Gestpay;
use Business::BancaSella::Decode::Gateway;

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
		unshift @ISA,'Business::BancaSella::Decode::Gestpay';
	} elsif ($self->type eq 'gateway') {
		no strict 'vars';
		unshift @ISA,'Business::BancaSella::Decode::Gateway';
	} else {
		croak "Unsupported type " . $self->type . "in " . ref($self) . "::new";
	}
	$self->SUPER::init(@_);
}

sub type { my $s=shift; return @_ ? ($s->{type}=shift) : $s->{type} }

# Preloaded methods go here.

1;
__END__
