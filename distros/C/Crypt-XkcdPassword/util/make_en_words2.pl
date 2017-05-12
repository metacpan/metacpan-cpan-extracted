use 5.010001;
use strict;
use Web::Magic;

print <<'HEADER';
package Crypt::XkcdPassword::Words::EN::Roget;
use 5.010001;
BEGIN {
	$Crypt::XkcdPassword::Words::EN::Roget::AUTHORITY = 'cpan:TOBYINK';
	$Crypt::XkcdPassword::Words::EN::Roget::VERSION   = '0.003';
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

my $magic = Web::Magic
	-> new('http://www.gutenberg.org/cache/epub/22/pg22.txt')
	-> assert_success;

my @words =
	grep { /^[A-Z]+$/i }
	split /\W/,
	$magic->content;

my %words;
foreach (@words)
{
	if (not exists $words{lc $_})
	{
		$words{lc $_} = $_;
	}
	elsif ($words{lc $_} =~ /^[A-Z]+$/)
	{
		$words{lc $_} = $_;
	}
}

say foreach sort values %words;
