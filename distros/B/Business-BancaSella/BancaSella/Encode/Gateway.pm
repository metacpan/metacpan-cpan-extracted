package Business::BancaSella::Encode::Gateway;

push @ISA,'Business::BancaSella::Gateway';
use Business::BancaSella::Gateway;
use URI::Escape;
use HTML::Entities;

$VERSION = "0.11";

sub Version { $VERSION; }
require 5.004;
use strict;
use Carp;

my %fields 	=
    (
				base_url		=> 'https://ecomm.sella.it/gestpay/pagam.asp'
     );
     
my @fields_req	= qw/shopping amount id otp tid/;
     
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
	$self->SUPER::init(@_);
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
}


sub uri {
	my $self 	= shift;
	my $uri 	= 'a=' . uri_escape($self->shopping) . '&b=' . 
					uri_escape($self->getB) . '&c=' . uri_escape($self->otp) . 
					'&d=' . uri_escape($self->id);
	return  	$self->base_url . '?' . $uri;
}

sub form {
	my $self	= shift;
	my $frmName = shift || '';
	my $ret 	= '<FORM NAME="' . $frmName . '" METHOD="POST" ACTION="' . 
					$self->base_url . '">' . "\n";
	$ret		.= '<input type="hidden" name="a" value="' . 
					encode_entities($self->shopping) .
					'">' . "\n";
	$ret		.= '<input type="hidden" name="b" value="' . 
					encode_entities($self->getB) .	'">' . "\n";
	$ret		.= '<input type="hidden" name="c" value="' . 
					encode_entities($self->otp) .
					'">' . "\n";
	$ret		.= '<input type="hidden" name="d" value="' . 
					encode_entities($self->id) .
					'">' . "\n";
	$ret		.= "</FORM>\n";
}

sub getB {
	my $self 	= shift;
	return int($self->amount * $self->tid);
}

sub base_url { my $s=shift; return @_ ? ($s->{base_url}=shift) : $s->{base_url} }

1;
