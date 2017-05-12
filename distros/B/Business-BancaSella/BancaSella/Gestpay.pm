package Business::BancaSella::Gestpay;

$VERSION = "0.12";
sub Version { $VERSION; }
require 5.004;
use strict;
use Carp;


my %fields 	=
    (
     shopping			=>		undef,
     otp					=>		undef,
     amount				=>		undef,
     id						=>		undef,
     currency			=> 		undef,
     language			=> 		undef,
     cardnumber		=> 		undef,
     expmonth			=> 		undef,
     expyear			=> 		undef,
     name					=> 		undef,
     mail					=> 		undef,
     user_params 	=>		{},
     );

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
}

sub shopping { my $s=shift; return @_ ? ($s->{shopping}=shift) : $s->{shopping} }	
sub otp { my $s=shift; return @_ ? ($s->{otp}=shift) : $s->{otp} }
sub amount { my $s=shift; return @_ ? ($s->{amount}=shift) : $s->{amount} }
sub id { my $s=shift; return @_ ? ($s->{id}=shift) : $s->{id} }
sub currency { my $s=shift; return @_ ? ($s->{currency}=shift) : $s->{currency} }
sub language { my $s=shift; return @_ ? ($s->{language}=shift) : $s->{language} }
sub cardnumber { my $s=shift; return @_ ? ($s->{cardnumber}=shift) : $s->{cardnumber} }
sub expmonth { my $s=shift; return @_ ? ($s->{expmonth}=shift) : $s->{expmonth} }
sub expyear { my $s=shift; return @_ ? ($s->{expyear}=shift) : $s->{expyear} }
sub name { my $s=shift; return @_ ? ($s->{name}=shift) : $s->{name} }
sub mail { my $s=shift; return @_ ? ($s->{mail}=shift) : $s->{mail} }
sub user_params { my $s=shift; return @_ ? ($s->{user_params}=shift) : $s->{user_params} }

sub uri { my $s=shift; return $s->{uri} }
sub form { my $s=shift; return $s->{form} }
sub result { my $s=shift; return $s->{result} }
sub authcode { my $s=shift; return $s->{authcode} }
sub bankid { my $s=shift; return $s->{bankid} }
sub errcode { my $s=shift; return $s->{errcode} }
sub errstr { my $s=shift; return $s->{errstr} }
	

# Preloaded methods go here.

1;
__END__
