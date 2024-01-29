use Test2::Bundle::More;
use strict;
use Audio::Nama::Mark;
$ENV{NAMA_VERBOSE_TEST_OUTPUT} and diag ("TESTING $0\n");
my $mark  = Audio::Nama::Mark->new( name => 'thebeginning');


is(  ref $mark , 'Audio::Nama::Mark', "Object creation");
$mark->set_attrib( "gabble", "babble");
is( $mark->attrib("gabble"), 'babble', "attribute store and read");
is( $mark->gabble, 'babble', "access attribute as method");

done_testing();
__END__