use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;

HR_connect;


SKIP: {
  eval "use JSON 2.0; 1"
    or plan skip_all => "JSON 2.0 does not seem to be installed";

  # fake data
  $dbh->{mock_add_resultset} = [ [qw/emp_id firstname lastname/],
                                 [qw/1      Hector    Berlioz/], ];
  my $emp = HR->table('Employee')->fetch(1);
  $dbh->{mock_add_resultset} = 
    [ [qw/act_id emp_id    d_begin       d_end   dpt_id/],
      [qw/     1      1 01.01.2001  02.02.2002       99/], ];
  $emp->expand('activities');

  my $json_converter = JSON->new->convert_blessed(1);
  my $json_text      = $json_converter->encode($emp);

  like($json_text, qr/"firstname":"Hector"/,   "json contains firstname");
  like($json_text, qr/"d_begin":"01.01.2001"/, "json contains nested d_begin");

  my $data_from_json = $json_converter->decode($json_text);
  is_deeply($emp, $data_from_json,             "json preserved nested strucure");


  done_testing;
}



