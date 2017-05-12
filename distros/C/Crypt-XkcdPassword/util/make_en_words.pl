use 5.010001;
use strict;
use Web::Magic;

print <<'HEADER';
package Crypt::XkcdPassword::Words::EN;
use 5.010001;
BEGIN {
	$Crypt::XkcdPassword::Words::EN::AUTHORITY = 'cpan:TOBYINK';
	$Crypt::XkcdPassword::Words::EN::VERSION   = '0.003';
}
my @words;
sub words
{
	unless (@words)
	{
		while (<DATA>)
		{
			chomp;
			push @words, $_ if length;
		}
	}
	
	\@words
}
__PACKAGE__
__DATA__
HEADER

for my $thousand (0..9)
{
	my $start  = (1_000 * $thousand) + 1;
	my $finish = (1_000 * $thousand) + 1_000;
	my $magic  = Web::Magic->new("http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/${start}-${finish}?action=raw");

	$magic =~ s{ \[\[ ([\w'-]+) \]\] }
	{
		say lc $1 if length $1;
		$1;
	}gex;
}
