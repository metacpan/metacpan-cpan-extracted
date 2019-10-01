use Test2::Bundle::More;
use strict;
use Audio::Nama::Mark;
$ENV{NAMA_VERBOSE_TEST_OUTPUT} and diag ("TESTING $0\n");
my $mark  = Audio::Nama::Mark->new( name => 'thebeginning');

is(  ref $mark , 'Audio::Nama::Mark', "Object creation");

done_testing();
__END__