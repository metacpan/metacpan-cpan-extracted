#########################
use Archive::ByteBoozer2 qw(:crunch :rcrunch);
use File::Slurp;
use Test::More tests => 2;
#########################
sub verify {
  my $expected = join '', map { chr hex } @_;
  my $got = read_file 't/test.prg.b2';
  is $got, $expected, 'compressed data';
  unlink 't/test.prg.b2';
}
#########################
{
  crunch('t/test.prg');
  verify(qw(fe 0f 00 10 54 4c 05 10 00 00 ee 20 d0 84 7f ff));
}
#########################
{
  rcrunch('t/test.prg', 0x4000);
  verify(qw(f2 3f 00 10 54 4c 05 10 00 00 ee 20 d0 84 7f ff));
}
#########################