package Business::BancaSella::Gateway;

$VERSION = "0.11";
sub Version { $VERSION; }
require 5.004;
use strict;
use warnings;

my %fields 	=
    (
     shopping		=>		undef,
     otp			=>		undef,
     amount			=>		undef,
     id				=>		undef,
     tid			=>		undef,
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
sub tid { my $s=shift; return @_ ? ($s->{tid}=shift) : $s->{tid} }

sub uri { my $s=shift; return $s->{uri} }
sub form { my $s=shift; return $s->{form} }
sub result { my $s=shift; return $s->{result} }
sub authcode { my $s=shift; return $s->{authcode} }

# Preloaded methods go here.

1;
__END__
