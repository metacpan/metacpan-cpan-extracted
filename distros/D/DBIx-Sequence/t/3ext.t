do { print "1..0\n"; exit; } if (not -e 't/config.pl');

print "1..1\n";

print STDERR "\n\nTesting ID release...\n";
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
my $ids_second = {};

for(1..200)
{
	my $id = $sequence->Next('make_test');

	print STDERR "$id".("\b" x length($id));
	if( $ids->{$id} )
	{
		&creve("Sequence generated 2 identical id's.");
	}
	$ids->{$id} = $id;
}	
print STDERR "\n\n";

foreach my $id (keys %$ids)
{
	$sequence->Release('make_test',$id);
	#print STDERR ".";
}

print STDERR "Verifying releases...\n";
for(1..200)
{
	my $id = $sequence->Next('make_test');

	print STDERR "$id".("\b" x length($id));	
	if(!$ids->{$id})
	{
		&creve("Sequence did not relase ID $id");
	}
}
	
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
