use Test::More;
use Acme::Perl::Consensual;

my $year = [localtime(time)]->[5] + 1900;
unless ($year==2012 or $year==2013)
{
	plan skip_all => "This test won't work in the future.";
}

plan tests => 11;

my $gb = Acme::Perl::Consensual->new(locale => 'gb');  # UK
my $jp = Acme::Perl::Consensual->new(locale => 'jp');  # Japan
my $id = Acme::Perl::Consensual->new(locale => 'id');  # Indonesia

ok not $gb->perl_can('5.14.0');
ok not $gb->perl_can('5.005');
ok     $gb->perl_can('5.001');

ok not $jp->perl_can('5.14.0');
ok     $jp->perl_can('5.005');
ok     $jp->perl_can('5.001');

ok not $id->perl_can('5.14.0');
ok not $id->perl_can('5.005');
ok not $id->perl_can('5.001');

if ($] > 5.015)
{
	$ENV{LC_LEGAL} = 'gb';
	ok not eval "use Acme::Perl::Consensual -check";
	ok($@ =~ /failed age of consent check/)
		or diag "\$\@ is really '$@'";
}
else
{
	ok skip => 'no op' for 1..2;
}