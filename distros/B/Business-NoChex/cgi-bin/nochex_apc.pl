#!/usr/bin/perl -w

use Business::NoChex;
use DBI;

my($payment)= Business::NoChex->new({ recipient => 'test2@nochex.com' });

open (LOGFILE ,">> ../capture.txt") or die "failed to open logfile : $!\n";

if ($payment->is_valid){
  print LOGFILE "valid payment rx\n";
  print LOGFILE $payment->transaction_id ."\n";

  my($dbh) = dbConnect();

  if(checkUnique($payment)){
     recordPayment($dbh,$payment);
  }
}else{
  print LOGFILE "declined\n";
  print LOGFILE $payment->cgi->query_string;
}

close LOGFILE;

exit 0;

sub dbConnect{
  my $database = 'dbname';
  my $host = 'localhost';
  my $user = 'dbuser';
  my $password = 'dbpass';
  return DBI->connect("DBI:mysql:$database:$host", $user, $password);
}

sub checkUnique{
  my($payment)=shift;

  return 1;

}

sub recordPayment{
  my($dbh,$payment) =@_;
  my($sql) = 'INSERT INTO receipts SET rcpt_id = ?,amount=?,user_email=?, item=? , created=NOW()';
  my($sth) = $dbh->prepare($sql);
  if($sth->execute($payment->transaction_id,$payment->amount,$payment->from_email,$payment->order_id)){
    my($id) = $dbh->{mysql_insertid};
    print LOGFILE "inserted as $id\n";
  }else{
    print LOGFILE $dbh->errstr();
  }
}
