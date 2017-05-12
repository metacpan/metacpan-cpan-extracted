package Local::Plugin2;

use base 'Local::Abstract';

use Class::Injection 'Local::Abstract', {
                                            'how'           => 'add',
                                            'returnmethod'  => 'collect',
#                                             'replace'       => 'true',
                                             'priority'       => -20,
#                                             'debug'       => 1,
                                        };



sub test{
  my $this=shift;

  return "this is plugin 2";
}
 



1;