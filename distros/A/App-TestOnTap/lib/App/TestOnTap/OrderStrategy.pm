package App::TestOnTap::OrderStrategy;

use strict;
use warnings;

our $VERSION = '1.001';
my $version = $VERSION;
$VERSION = eval $VERSION;

use List::Util qw(shuffle);
use Sort::Naturally qw(nsort);

# CTOR
#
sub new
{
	my $class = shift;
	my $strategy = shift || 'none';

	die("Unknown order strategy: $strategy\n") unless $strategy =~ /^(?:none|(r?)(?:alphabetic|natural)|random)$/i;

	my $self = bless( { strategy => $strategy, reverse => ($1 ? 1 : 0) }, $class);
	
	return $self;
}

# order a list according to the desired strategy
#
sub orderList
{
	my $self = shift;
	my @l = @_;

	if ($self->{strategy} ne 'none')
	{
		if ($self->{strategy} =~ /^r?alphabetic$/)
		{
			@l = sort(@l);
			@l = reverse(@l) if $self->{reverse};
		}
		elsif ($self->{strategy} =~ /^(r?)natural$/)
		{
			@l = nsort(@l);
			@l = reverse(@l) if $self->{reverse};
		}
		elsif ($self->{strategy} eq 'random')
		{
			@l = shuffle(@l);
		}
	}	

	return @l;
}

sub getStrategyName
{
	my $self = shift;
	
	return $self->{strategy};
}

1;
