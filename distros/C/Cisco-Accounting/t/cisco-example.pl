## ----------------------------------------------------------------------------------------------
## cisco-example.pl
##
## Example : connect to Cisco router and fetch ip accounting data
##
## $Id$
## $Author$
## $Date$
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

use Cisco::Accounting;
use Data::Dumper;

my %data = (
		'host'		=>	"foo",
		'user'		=>	"user",
		'pwd'		=>	"pass",
		'enable_user'	=>	"user",
		'enable_pwd'	=>	"enable_pass",		
	);

my $acct;	
my @interfaces;
my $output;
my $stats;
my $historical;
my $count = 5;
my $i = 0;
my $interval = 10;

## initialize : make a new object, get the interfaces and enable ip accounting on 2 interfaces
eval {  
	$acct = Cisco::Accounting->new(%data);	
	@interfaces = $acct->get_interfaces();
	$acct->enable_accounting(2,1);  
};
die ($@) if ($@);

## start polling, 5 times with interval of 60 seconds
while ($i < $count)  {

	## parse IP accounnting info and clear the accounting after each 'poll'
	eval {
		print "getting accounting information";
		$acct->do_accounting();
		print " ... OK\n";
		$acct->clear_accounting();
	};
	if ($@)  {
		warn $@;
	}

	$i++;
	sleep $interval if ($i < $count);
}

$output = $acct->get_output();
$stats = $acct->get_statistics();
$historical = $acct->get_history();

# print output
print &Dumper(\@interfaces);
print &Dumper($output);
print &Dumper($stats);
print &Dumper($historical);
