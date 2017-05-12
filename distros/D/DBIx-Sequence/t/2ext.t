do { print "1..0\n"; exit; } if (not -e 't/config.pl');

use strict;
use POSIX ":sys_wait_h";

if($^O =~ /win/i)
{
	print "1..0\n";
	exit;
}

print "1..1\n";

print STDERR "\n\nTesting asynchronous sequence ID generation...\n";
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

my $ids = {};
my $pids = [];
my $failed = 0;
my $parent_pid = $$;

my $pid;
open(IDLOG, ">dbi_sequence_test.log") || &creve("Could not open ID LOG: $!");

my $ids_per_child = 500;
my $childs = 5;
my $total_ids = $ids_per_child * $childs;

for my $child (1..$childs)
{
	if($pid = fork())
	{
		push @$pids, $pid;
		print STDERR "Forked $pid, ";
	}
	else
	{
		my $sequence = new DBIx::Sequence({
                                                db_dsn => $config->{dsn},
                                                db_user => $config->{user},
                                                db_pw => $config->{userpw},
						state_table => $config->{state_table},
                                                release_table => $config->{release_table},
                                                }) || &creve("Could now initiate a new DBIx::Sequence object.");

		for(1..$ids_per_child)
		{

			my $id = $sequence->Next('make_test');
			print STDERR $id.("\b" x length($id));

			print IDLOG "$id\n";
			if( $ids->{$id} )
			{
				$failed = 1;
			}
			$ids->{$id} = $id;
		}	
		exit 0;
	}
}

print "\n";
foreach my $child (@$pids)
{
	waitpid($child,0);
}

close IDLOG;

print STDERR "\nReviewing generated id's...\n";
open(IDLOG, "dbi_sequence_test.log") || &creve("Could not analyze our log! $!");
while(<IDLOG>)
{
	my $id = $_;
	chomp $id;
	print STDERR "$id".("\b" x length($id));
	if($ids->{$id})
	{
		$failed = 1;
	}
	$ids->{$id} = $id;
}
close IDLOG;

print STDERR "Generated a total of: ".(keys %$ids)." ids.\n";
print STDERR "Should have generated: ".$total_ids." ids.\n\n";

if($failed == 1)
{	
	&creve("Sequence generated 2 identical id's in asynchronous mode.");
}
else
{	
	unlink "dbi_sequence_test.log";
	print "ok 1\n";
}


sub creve
{
	my $msg = shift;

	unlink "dbi_sequence_test.log";
	print STDERR "$msg\n";
	
	print STDERR "\nSomething is wrong.\n";
	print STDERR "Contact the author.\n";
	print STDERR "not ok 1\n";
	print "not ok 1\n";
	exit;
}
