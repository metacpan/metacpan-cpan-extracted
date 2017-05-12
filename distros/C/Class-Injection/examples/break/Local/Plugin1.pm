package Local::Plugin1;

use base 'Local::Abstract';

use Class::Injection 'Local::Abstract', {
                                            'how'           => 'add',
                                            'returnmethod'  => 'collect',
                                            'replace'       => 'true',
                                            'debug'       => 'true',
                                        };



sub test{
  my $this=shift;

  Class::Injection::break;

  return "this is plugin 1";
}
 



1;