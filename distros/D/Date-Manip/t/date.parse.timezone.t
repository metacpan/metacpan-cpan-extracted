#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'date :: parse (with timezone)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  my $err = $obj->parse(@test);
  if ($err) {
     return $obj->err();
  } else {
     $out = $obj->printf("%g");
     return($out);
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2013-10-04-00:00:00,America/New_York");

$tests="

'today at midnight UTC'              => 'Fri, 04 Oct 2013 00:00:00 UTC'

'today at midnight'                  => 'Fri, 04 Oct 2013 00:00:00 EDT'

'yesterday at midnight UTC'          => 'Thu, 03 Oct 2013 00:00:00 UTC'

'yesterday at midnight'              => 'Thu, 03 Oct 2013 00:00:00 EDT'

'1st at midnight UTC'                => 'Tue, 01 Oct 2013 00:00:00 UTC'

'1st at midnight'                    => 'Tue, 01 Oct 2013 00:00:00 EDT'

'last month at midnight UTC'         => 'Wed, 04 Sep 2013 00:00:00 UTC'

'last month at midnight'             => 'Wed, 04 Sep 2013 00:00:00 EDT'

'0 day ago at midnight UTC'          => 'Fri, 04 Oct 2013 00:00:00 UTC'

'0 day ago at midnight'              => 'Fri, 04 Oct 2013 00:00:00 EDT'

'1 day ago at midnight UTC'          => 'Thu, 03 Oct 2013 00:00:00 UTC'

'1 day ago at midnight'              => 'Thu, 03 Oct 2013 00:00:00 EDT'

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
