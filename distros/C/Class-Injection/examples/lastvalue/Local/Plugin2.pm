package Local::Plugin2;

use Data::Dumper;
use base 'Local::Abstract';

use Class::Injection 'Local::Abstract', {
                                            'how'           => 'add',
                                            'returnmethod'  => 'collect',
                                            'replace'       => 'true',
                                        };



sub test{
  my $this=shift;

  print "here is plugin 2 and discovers results of plugin 1\n";

  print Dumper( Class::Injection::lastvalue );

  return "this is plugin 2";
}
 



1;