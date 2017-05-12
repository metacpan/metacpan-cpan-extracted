do { print "1..0\n"; exit; } if (not -e 't/config.pl');

print "1..1\n";

print STDERR "\n\nTesting performance...\n";
use DBIx::Sequence;

my $config;
open(CONF, "t/config.pl") || &creve("Could not open t/config.pl");
while(<CONF>) { $config .= $_; }
close CONF;
$config = eval $config;
if($@)
{
        &creve($@);
}

$ENV{'ORACLE_HOME'} = $config->{oracle_home} if(!$ENV{'ORACLE_HOME'});

my $id_total = 2000;
my $sequence = new DBIx::Sequence({
                                                db_dsn => $config->{dsn},
                                                db_user => $config->{user},
                                                db_pw => $config->{userpw},
						state_table => $config->{state_table},
                                                release_table => $config->{release_table},
                                                }) || &creve("Could now initiate a new DBIx::Sequence object.");
my $ids = {};
my $ids_second = {};

use Benchmark;
my $t0 = new Benchmark;

my $last_print;
for(1..$id_total)
{
	my $id = $sequence->Next('make_test');
	print STDERR "$_ ($id)".("\b" x length("$_ ($id)"));
}	
my $t1 = new Benchmark;
$td = timediff($t1, $t0);
print STDERR "This host can generate $id_total id's in: ", timestr($td), "\n";


print STDERR "\n\n";

print "ok 1\n";


sub creve
{
	my $msg = shift;

	print STDERR "\n\n$msg\n";
	
	print STDERR "\nSomething is wrong.\n";
	print STDERR "Contact the author.\n";
	print "not ok 1\n";
	exit;
}
