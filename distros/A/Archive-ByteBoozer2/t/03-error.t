#########################
use Archive::ByteBoozer2 qw(:crunch :ecrunch);
use File::Touch;
use Test::Exception;
use Test::More tests => 7;
#########################
{
  dies_ok { crunch('t/dummy.prg') } 'non-existent file';
}
#########################
{
  touch('t/test.prg.b2');
  dies_ok { crunch('t/test.prg') } 'target file exists';
  unlink('t/test.prg.b2');
}
#########################
{
  dies_ok { ecrunch('t/dummy.prg', 'invalid') } 'invalid address';
}
#########################
{
  dies_ok { ecrunch('t/test.prg', 0x10000) } 'too large address';
}
#########################
{
  dies_ok { ecrunch('t/test.prg', -1) } 'negative address';
}
#########################
{
  lives_ok { ecrunch('t/test.prg', 0x0000) } 'minimal address';
  unlink('t/test.prg.b2');
}
#########################
{
  lives_ok { ecrunch('t/test.prg', 0xffff) } 'maximal address';
  unlink('t/test.prg.b2');
}
#########################