########################################
# 098.examples -- make sure examples/babel.pl does something reasonable
########################################
use t::lib;
use t::utilBabel;
use Carp;
use English;
use File::Spec;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
my $dbh=$autodb->dbh;

doit('--create');
doit('--reread');
doit();

done_testing();

sub doit {
  my($options)=@_;
  open(SCRIPTOUT,"$EXECUTABLE_NAME -Mblib examples/babel.pl $options |") 
    || confess "Cannot open pipe to execute example script with $options options: $!";
  my @scriptout=<SCRIPTOUT>;
  close SCRIPTOUT;

  $options='no options' unless length $options;
  my $numlines=scalar @scriptout;
  ok($numlines>50,"$options: enough output ($numlines lines)");
  my $check_schema=grep /^check_schema found no errors/,@scriptout;
  ok($check_schema,"$options: check_schema looks okay");

  my $babel_names=$dbh->selectcol_arrayref(qq(SELECT name FROM Babel));
  report_fail(!$dbh->err,"$options: ".$dbh->errstr);
  my $babel_name=scalar(@$babel_names)==1 && $babel_names->[0] eq 'test';
  ok($babel_name,"$options: Babel table looks okay");
}

