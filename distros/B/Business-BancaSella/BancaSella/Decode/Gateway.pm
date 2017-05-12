package Business::BancaSella::Decode::Gateway;

push @ISA,'Business::BancaSella::Gateway';
use Business::BancaSella::Gateway;
use URI;
use Carp;


$VERSION = "0.11";
sub Version { $VERSION; }
require 5.004;
use strict;
use warnings;

my %fields 	=
    (
     query_string		=>		undef
     );
     
my @fields_req	= qw/query_string/;
     
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
    	$self->{$key} = $value;
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
	}
	$self->_split_uri;
}

sub _split_uri {
	my $self = shift;
	my $qs	= '?' . $self->query_string;
	my %qs = URI->new($qs)->query_form;
	die "Malformed uri definition: " . $self->{uri} 
							if (!(exists $qs{a} && exists $qs{b}));
	$self->{result} = $qs{a};
	$self->{id}		= $qs{b};
	$self->{otp}	= $qs{c};
	if ($self->{result} ne 'KO') {
		$self->{authcode} = $qs{a};
	}
	
}

sub result {
	my $self = shift;
	if (@_) { $self->SUPER::result(shift) };
	return $self->SUPER::result ne 'KO';
}

sub query_string { my $s=shift; return @_ ? ($s->{query_string}=shift) : $s->{query_string} }

# Preloaded methods go here.

1;
__END__
