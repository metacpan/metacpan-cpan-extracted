use Cwd;
use Apache::Wyrd::Services::SAK qw(:all);
use Apache::Wyrd::Services::CodeRing;
use Apache::Wyrd::Interfaces::Setter;
my $directory = getcwd();
$directory = "$directory/t" if (-d 't');

my $count = &count;

print "1..$count\n";

print "not " if (scalar(token_parse("I, me, mine")) != 3);
print "ok 1 - token_parse regular\n";

print "not " if (scalar(token_parse("I,me,mine")) != 3);
print "ok 2 - token_parse condensed comma\n";

print "not " if (scalar(token_parse("I me mine")) != 3);
print "ok 3 - token_parse spaces\n";

print "not " if (scalar(token_parse("I, me mine")) != 2);
print "ok 4 - token_parse mixed spaces and commas\n";

my %hash = (
	Yes		=> 1,
	NO		=> 2,
	maybe	=> 3
);
%hash = %{lc_hash(\%hash)};
print "not " unless (keys %hash == 3 and ($hash{yes} and $hash{no} and $hash{maybe}));
print "ok 5 - lc_hash\n";

print "not " if (${slurp_file("$directory/data/slurp")} ne "slurp");
print "ok 6 - slurp_file\n";

my @hashes = (
	{test	=>	'220022203'},
	{test	=>	'220022201'},
	{test	=>	'220022204'},
	{test	=>	'220022202'}
);

my $joinedstring = join '', map {$_->{'test'}} sort {sort_by_key($a, $b, 'test')} @hashes;

print "not " if ($joinedstring ne '220022201220022202220022203220022204');
print "ok 7 - sort hash by key numerical\n";

$joinedstring = join '', map {$_->{'test'}} sort {sort_by_ikey($a, $b, 'test')} @hashes;

print "not " if ($joinedstring ne '220022201220022202220022203220022204');
print "ok 8 - sort hash by insensitive key numerical\n";

@hashes = (
	{test	=>	'Charlie Autrey'},
	{test	=>	'bartholemew'},
	{test	=>	'anesthesia'},
	{test	=>	'deuteronomy'}
);

$joinedstring = join '', map {$_->{'test'}} sort {sort_by_key($a, $b, 'test')} @hashes;

print "not " if ($joinedstring ne 'Charlie Autreyanesthesiabartholemewdeuteronomy');
print "ok 9 - sort hash by key alphabetical\n";

$joinedstring = join '', map {$_->{'test'}} sort {sort_by_ikey($a, $b, 'test')} @hashes;

print "not " if ($joinedstring ne 'anesthesiabartholemewCharlie Autreydeuteronomy');
print "ok 10 - sort hash by insensitive key alphabetical\n";

@hashes = (
	{test	=>	'deuteronomy'},
	{test	=>	'220022204'},
	{test	=>	'anesthesia'},
	{test	=>	'220022201'},
	{test	=>	'bartholemew'},
	{test	=>	'Charlie Autrey'},
	{test	=>	'220022203'},
	{test	=>	'220022202'}

);

$joinedstring = join '', map {$_->{'test'}} sort {sort_by_key($a, $b, 'test')} @hashes;

print "not " if ($joinedstring ne '220022201220022202220022203220022204Charlie Autreyanesthesiabartholemewdeuteronomy');
print "ok 11 - sort hash by key mixed\n";

$joinedstring = join '', map {$_->{'test'}} sort {sort_by_ikey($a, $b, 'test')} @hashes;

print "not " if ($joinedstring ne '220022201220022202220022203220022204anesthesiabartholemewCharlie Autreydeuteronomy');
print "ok 12 - sort hash by insensitive key mixed\n";

sub count {12}
