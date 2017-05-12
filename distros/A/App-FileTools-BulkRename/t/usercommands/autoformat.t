#/usr/bin/perl -w

use Test::More;

use_ok(App::FileTools::BulkRename::UserCommands::AutoFormat, qw(afmt));

sub check_afmt
  { my ($case,$name,$in,$out) = @_;

    $_ = $in;
    afmt($case);
    is( $_, $out, "afmt($case,$name), void context, implicit arg");

    $_ = $in;
    afmt($case,$_);
    is( $_, $out, "afmt($case,$name), void context, explicit arg");

    $_ = $in;
    my $t = afmt($case);
    is( $t, $out, "afmt($case,$name), scalar context, implicit arg");
    
    $t = afmt($case,$in);
    is( $t, $out, "afmt($case,$name), scalar context, explicit arg");
    
    $_ = $in;
    my @t = afmt($case);
    is( $t[0],$out , "afmt($case,$name), list context, implicit arg");
    
    @t = afmt($case,$in);
    is( $t[0],$out , "afmt($case,$name), list context, explicit arg");
  };

check_afmt('any', "undef", undef, undef);
check_afmt('any', "empty", '',    '');

check_afmt('upper',     "simple", "X of WHY", "X OF WHY");
check_afmt('lower',     "simple", "X of WHY", "x of why");
check_afmt('sentence',  "simple", "X of WHY", "X of why");
check_afmt('title',     "simple", "X of WHY", "X Of Why");

# This got more complicated, as highlight now uses the existing
# case of words to help it distinguish things like the right case
# for 'a' in "Eating a Snake" vs "Eating from A to Z".
check_afmt('highlight', "simple", "x of why", "X of Why");

TODO:
  { local $TODO = "autoformat gets these wrong.";

    check_afmt
      ( 'sentence',  "divided"
      , "X is WHY - WHY is X", "X is why - Why is x"
      );
    check_afmt
      ( 'title',     "divided"
      , "X is WHY - WHY is X", "X Is Why - Why Is X"
      );
    check_afmt
      ( 'highlight', "divided"
      , "X is WHY - WHY is X", "X is Why - Why is X"
      );
    check_afmt( 'upper',     "latin-1", "no façade", "NO FAÇADE");
    check_afmt( 'lower',     "latin-1", "no FAÇADE", "no façade");
    check_afmt( 'sentence',  "latin-1", "no FAÇADE", "No façade");
    check_afmt( 'title',     "latin-1", "no FAÇADE", "No Façade");
    check_afmt( 'highlight', "latin-1", "no FAÇADE", "No Façade");

  }

done_testing();

