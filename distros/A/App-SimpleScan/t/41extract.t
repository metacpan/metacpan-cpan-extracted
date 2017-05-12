use Test::More;

BEGIN {
  use_ok(qw(App::SimpleScan));
}

my $app = new App::SimpleScan;

my %tests = (
  'a b c d e' =>
  [qw(a b c d e)],
  'ar bg ca cs da en et fi fr de el es fa he hr hu is id it ja ko lv lt no nl pl pt ro ru sk sr sl sv th tr szh tzh' => 
  [qw(ar bg ca cs da en et fi fr de el es fa he hr hu is id it ja ko lv lt no nl pl pt ro ru sk sr sl sv th tr szh tzh)],
  "'this line has a" =>
  [qw('this line has a)],
  'au es de asia' =>
  [qw(au es de asia)],
  qq{'this' 'is' 'quoted'},
  [qw(this is quoted)],
  qq( 'Master Librarian' 'Mailing Lists' 'Perl modules' 'Perl scripts') =>
  [ 'Master Librarian', 'Mailing Lists', 'Perl modules', 'Perl scripts'],
);

while ( my($test_input, $expected) = each %tests) {
  my @got = $app->expand_backticked($test_input);
  is_deeply \@got, $expected, "output for '$test_input'";
}

done_testing(1 + int keys %tests);
