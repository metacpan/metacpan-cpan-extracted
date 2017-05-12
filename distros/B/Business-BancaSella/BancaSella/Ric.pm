package Business::BancaSella::Ric;

$VERSION = "0.11";
sub Version { $VERSION; }

require 5.004;
use strict;
use warnings;
use Carp;

use Business::BancaSella::Ric::File;
use Business::BancaSella::Ris::FileFast;
use Business::BancaSella::Ric::Mysql;

my %fields 	=
    (
     type		=>		'file',
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
	if ($self->type eq 'file') {
		no strict 'vars';
		unshift @ISA,'Business::BancaSella::Ric::File';
	} elsif ($self->type eq 'mysql') {
		no strict 'vars';
		unshift @ISA,'Business::BancaSella::Ric::Mysql';
	} elsif ($self->type eq 'filefast') {
		no strict 'vars';
		unshift @ISA,'Business::BancaSella::Ric::FileFast';
	} else {
		die "Unsupported type " . $self->type . "in " . ref($self) . "::new";
	}
	$self->SUPER::init(@_);
}

sub type { my $s=shift; return @_ ? ($s->{type}=shift) : $s->{type} }

1;
__END__
