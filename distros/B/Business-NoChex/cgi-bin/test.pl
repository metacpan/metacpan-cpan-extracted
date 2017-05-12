#!/usr/bin/perl -w

use Business::NoChex;

open (LOGFILE ,">> ../capture.txt") or die "failed to open logfile : $!\n";

my($payment)= Business::NoChex->new({ recipient => 'test2@nochex.com' });

if ($payment->is_valid){
  print LOGFILE "valid payment rx\n";
  foreach my $field ($payment->post_fields){
    print LOGFILE "$field -> ".$payment->$field."\n";
  }
}elsif($payment->declined){
  print LOGFILE "declined :( \n";
}else{
  print LOGFILE "random badness has happened\n";
}

close LOGFILE;

print <<END;
Content-type: text/html

<html>
<head></head>
<body>Boo!</body>
</html>
END

exit 0;
