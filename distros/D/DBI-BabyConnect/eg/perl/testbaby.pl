#!/usr/bin/perl

use strict;


print qq|

<style type="text/css">
<!--
.footer { padding-right: 5px; 
          padding-left: 5px; 
          padding-bottom: 5px; 
          padding-top: 5px; 
          font-size: 100%;
          border-top: #ffffff 1px solid; 
          border-bottom: #ffffff 1px solid; 
          background: #e5ecf9; 
          text-align: center;
          font-family: arial,sans-serif;
}
-->
</style>
</head>

<body text="#000000" bgcolor="#ffffff">
<pre>
|;

# load the DBI::BabyConnect with caching and persistence enabled
use DBI::BabyConnect 1,1;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/var/www/htdocs/logs/error.log");
$bbconn-> HookTracing(">>/var/www/htdocs/logs/db.log",1);


# the following will be written to STDERR, /var/www/htdocs/logs/error.log
print STDERR "Now fetching records from TABLE2\n";

my $ah;
{
	if ( $ah = $bbconn-> fetchTdaAO('TABLE2', ' ID,LOOKUP,DATASTRING,DATANUM,RECORDDATE_T '," ID=ID ")) { }
	else {
		# check for dbi error
		my $dbierror = $bbconn-> dbierror();
		print "Content-type: text/plain\n\n

	$dbierror
";
		exit;
	}
}


for (my $i=0; $i<@$ah; $i++) {
	print "$i -- ";
	foreach my $k (qw(ID DATASTRING DATANUM RECORDDATE_T)) {
		print $$ah[$i]{$k}, " ";
	}
	print "\n";
}


print qq|
</pre>

|;

my $parent_pid = Apache::BabyConnect::parent_pid;
my @cpids = Apache::BabyConnect::cpids;

# print html formatted table
$bbconn-> htmlStatCC();

print qq|

parent_pid$parent_pid<br>
cpids=@cpids<br>


<div class="footer" align="center">
  <a href="http://search.cpan.org/~maxou/DBI-BabyConnect-0.93/lib/DBI/BabyConnect.pm">DBI::BabyConnect</a>
  -
  <a href="http://search.cpan.org/~maxou/Apache-BabyConnect-0.93/lib/Apache/BabyConnect.pm">Apache::BabyConnect</a>
<!--  -
  <a href="http://search.cpan.org/~maxou/DBI-BabyConnect-BabiesPool-1.00/DBI/BabyConnect/BabiesPool">DBI::BabyConnect::BabiesPool</a>
-->
</div>
  
</body>
</html>

|;

__END__

Test script used with Apache::BabyConnect module.
This script test the connection to a cached DBI::BabyConnect
object.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

