use 5.008;
use strict;
use warnings;

package Crypt::XkcdPassword::Words;

BEGIN {
	$Crypt::XkcdPassword::Words::EN::AUTHORITY = 'cpan:TOBYINK';
	$Crypt::XkcdPassword::Words::EN::VERSION   = '0.009';
}

use Carp;
use Moo::Role;

requires qw( description filehandle );

sub cache_key
{
	ref(shift);
}

my %cache;
sub words
{
	my $self = shift;
	
	my $key  = $self->cache_key;
	my $fh   = $self->filehandle;
	
	unless ($cache{$key})
	{
		my @words;
		while (<$fh>)
		{
			chomp;
			push @words, $_ if length;
		}
		$cache{$key} = \@words;
	}
	
	$cache{$key};
}

__PACKAGE__
