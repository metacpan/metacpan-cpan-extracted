# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CSS-Minifier.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('CSS::Minifier', qw(minify)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub filesMatch {
  my $file1 = shift;
  my $file2 = shift;
  my $a;
  my $b;

  while (1) {
    $a = getc($file1);
    $b = getc($file2);

    if (!defined($a) && !defined($b)) { # both files end at same place
      return 1;
    }
    elsif (!defined($b) || # file2 ends first
           !defined($a) || # file1 ends first
           $a ne $b) {     # a and b not the same
      return 0;
    }
  }
}

sub minTest {
  my $filename = shift;
  
  open(INFILE, 't/sheets/' . $filename . '.css') or die("couldn't open file");
  open(GOTFILE, '>t/sheets/' . $filename . '-got.css') or die("couldn't open file");
    minify(input => *INFILE, outfile => *GOTFILE);
  close(INFILE);
  close(GOTFILE);

  open(EXPECTEDFILE, 't/sheets/' . $filename . '-expected.css') or die("couldn't open file");
  open(GOTFILE, 't/sheets/' . $filename . '-got.css') or die("couldn't open file");
    ok(filesMatch(GOTFILE, EXPECTEDFILE));
  close(EXPECTEDFILE);
  close(GOTFILE);
}

BEGIN {
  
  minTest('s2', 'testing s2');    # general
  minTest('s3', 'testing s3');    # self clearing floats with Mac/IE5 comment hack

  is(minify(input => "foo {\na: b;\n}"), 'foo{a:b;}', 'string literal input and ouput');
}
