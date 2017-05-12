do { print "1..0\n"; exit; } if (not -e 't/config.pl');

print "1..1\n";

print STDERR "\n\nTesting synchronous sequence ID generation...\n";
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

my $sequence = new DBIx::Sequence({
						db_dsn => $config->{dsn},
						db_user => $config->{user},
						db_pw => $config->{userpw},	
						state_table => $config->{state_table},
						release_table => $config->{release_table},
						}) || &creve("Could now initiate a new DBIx::Sequence object.");

my $ids = {};

my $gen_ids = 1000;
for(1..$gen_ids)
{
	my $id = $sequence->Next('make_test');

	my $length = length($id);
	print STDERR "$id".("\b"x$length);
	if( $ids->{$id} )
	{
		&creve("Sequence generated 2 identical id's.");
	}
	$ids->{$id} = $id;
}	
print STDERR "\n\n";

print "ok 1\n";


sub creve
{
	my $msg = shift;

	print "$msg\n";
	
	print "\nSomething is wrong.\n";
	print "Contact the author.\n";
	print "not ok 1\n";
	exit;
}
