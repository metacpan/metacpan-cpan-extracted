package Auto;
#Class with autoloaded methods. Same interface as Simple.

use strict;
use warnings;

sub new
{
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
	$self->_init(@_);
	return $self;
}

*new_inflate = \&new;

sub _init
{
	my $self = shift;
	my $string = shift;
	
	$self->{string} = $string;
	$self->{can} = {get_string => 1, set_string => 1, callsub => 1};
}

sub can
{
	my $self = shift;
	return $self->{can}{shift(@_)};
}

sub AUTOLOAD
{
	use vars '$AUTOLOAD';
	$AUTOLOAD =~ /.*::(\w+)/;
	my $method = $1;
	
	my $self = shift;
	
	unless ($self->can($method))
	{
		use Carp;
		Carp::croak(sprintf qq{Can\'t locate object method "%s" via package "%s" }, $method, ref $self )#Error message stolen from Class::WhiteHole
	}
	
	return (caller(1))[4] if ($method eq 'callsub');
	
	$self->{string} = shift(@_) if ($method eq 'set_string');
	return $self->{string};
}

sub DESTROY #no autoloading DESTROY.
{ return undef;}

1;