package Business::BancaSella::Decode::Gestpay;

push @ISA,'Business::BancaSella::Gestpay';
use Business::BancaSella::Gestpay;
use URI;
use Carp;


$VERSION = "0.12";
sub Version { $VERSION; }
require 5.004;
use strict;

my $bKeys = {
				currency					=> 'PAY1_UICCODE',
				amount						=> 'PAY1_AMOUNT',
				id							=> 'PAY1_SHOPTRANSACTIONID',
				otp							=> 'PAY1_OTP',
				language					=> 'PAY1_IDLANGUAGE',
				result 						=> 'PAY1_TRANSACTIONRESULT',
				authcode 					=> 'PAY1_AUTHORIZATIONCODE',
				bankid 						=> 'PAY1_BANKTRANSACTIONID',
				errcode 					=> 'PAY1_ERRORCODE',
				errstr						=> 'PAY1_ERRORDESCRIPTION'
			};

#use Class::MethodMaker
#	new_with_init 		=> 'new'
#	,get_set				=> [qw/base_url query_string/];

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
    	$self->{$key} = $value
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
	my %lbKeys = %{$bKeys};
	my $qs	= '?' . $self->{query_string};
	my %qs = URI->new($qs)->query_form;
	die "Malformed uri definition: " . $self->{uri} 
							if (!(exists $qs{a} && exists $qs{b}));
	$self->{shopping}	= $qs{a};
	my @b				= split(/\*P1\*/,$qs{b});
	my %b;
	foreach (@b) {
		my ($key,$value) 	= split(/=/,$_);
		$b{$key}			= $value;
	}
	# assign default keys
	foreach (keys %lbKeys) {
		if (exists $b{$lbKeys{$_}}) {
			$self->{$_}	= $b{$lbKeys{$_}};
		} 
	}
	
	# now we try to fill user personalized keys
	foreach (keys %{$self->{user_params}}) {
		if (exists $b{$_}) {
			$self->{user_params}->{$_} = $b{$_}
		}
	}
	
}

sub result {
	my $self = shift;
	if (@_) { $self->SUPER::result(shift) };
	return $self->SUPER::result eq 'OK';
}

sub query_string { my $s=shift; return @_ ? ($s->{query_string}=shift) : $s->{query_string} }

# Preloaded methods go here.

1;
__END__
