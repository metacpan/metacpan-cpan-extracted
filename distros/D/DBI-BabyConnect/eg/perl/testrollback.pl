#!/usr/bin/perl

use strict;

use DBI::BabyConnect 1,1;


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


my $bbconn1 = DBI::BabyConnect->new(
    'BABYCONNECT_001',
);
$bbconn1-> HookError(">>/var/www/htdocs/logs/error.log");
$bbconn1-> HookTracing(">>/var/www/htdocs/logs/db.log",1);


test_rollback_sub($bbconn1);


print qq|
DONE!

<div class="footer" align="center">
  <a href="http://YOUPROCESS_HOST/">DBI::BabyConnect</a>
  -
  <a href="http://YOUPROCESS_HOST/intl/en/disclaimer.html">Apache2::BabyConnect</a>
</div>
  
</body>
</html>

|;



sub test_rollback_sub {
my $bbconn = shift;

$bbconn-> saveLags();
$bbconn->raiseerror(0);
$bbconn->printerror(1);
$bbconn->autocommit(0);
$bbconn->autorollback(1);


my $sql = qq{
		INSERT INTO TABLE1 (ID,DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T)
		VALUES
		(1,'data string',1234,'bin code','bin data',SYSDATE())
	};


# if ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=1 then
# rollback and exit() is handled within DBI::BabyConnect
$bbconn-> do($sql);

# if ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=0 then nothing
# will happen on do() error, and script will continue.
# however you can exit yourself. This will be mod_perl exit()
#defined ($bbconn-> do($sql)) || (exit);

# or you can rollback() yourself, and continue
#defined ($bbconn-> do($sql)) || ($bbconn-> rollback);

my $sql = qq{
	INSERT INTO TABLE1
	(DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T)
	VALUES
	('abc string',1234,'bin code','bin data',SYSDATE())
};

$bbconn-> do($sql);

$bbconn-> restoreLags();

}

__END__

Test script used with Apache::BabyConnect module.
This script test the rollback of DBI::BabyConnect objects
whenever they are used with Apache::BabyConnect module.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

