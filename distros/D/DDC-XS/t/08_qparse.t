# -*- Mode: CPerl -*-
use Test::More;

#use lib qw(../blib/lib ../blib/arch);
use lib qw(.);
use DDC::XS;
use File::Basename;

my $TEST_DIR = File::Basename::dirname($0);
my $loadpl = do "$TEST_DIR/parseme.pl"
  or die("$0: failed to load $TEST_DIR/parseme.pl: $@");
ok($loadpl,"loaded parseme.pl");

my $parsefile = $0;
$parsefile =~ s/\.t$/.dat/;
ok(-e $parsefile, "expectations file exists - $parsefile");

qtestfile(sub {
            my $rc = eval { DDC::XS->parse($_[0]) };
            warn("$0: parse error for '$_[0]': $@") if ($@);
            return $rc;
          }, $parsefile);
done_testing();
