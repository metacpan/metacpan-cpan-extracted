# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English qw( -no_match_vars );

use Test::More;
use Test::Exception;

use Carp::Proxy fatal => { columns => 40 };

my $banner_rex =
    qr{
          ~{40}                                             \r? \n
          Fatal [ ] << [ ] handle (?: r | [ ] title) [ ] >> \r? \n
          ~{40}                                             \r? \n
      }x;

main();
done_testing();

#-----

sub handler {
    my( $cp, $paragraphs ) = @_;

    $cp->filled( $paragraphs, '' );
    return;
}

sub handle_title {
    my( $cp, $title ) = @_;

    $cp->filled( 'body', $title );
    return;
}

sub main {

    verify_long_words();
    verify_embedded_indentations();
    verify_header();
    verify_empty();
    return;
}

sub verify_header {

    throws_ok{ fatal 'handle_title', undef }
        qr{
              \A
              $banner_rex
              \Q  *** Description ***\E  \r? \n
              \Q    body\E               \r? \n
          }x,
        'Undef title maps to section title (Description)';

    throws_ok{ fatal 'handle_title', '' }
        qr{
              \A
              $banner_rex
              \Q    body\E  \r? \n
          }x,
        'Empty title defeats header generation';

    throws_ok{ fatal 'handle_title', 'Alternate' }
        qr{
              \A
              $banner_rex
              \Q  *** Alternate ***\E  \r? \n
              \Q    body\E
          }x,
        'Explicit title is inserted in header';

    return;
}

sub verify_embedded_indentations {

    throws_ok{ fatal 'handler', <<"EOF" }
The first paragraph should be indented normally - i.e. with four
leading spaces.

  The second paragraph should be left-justified with two extra spaces.

\tThe third paragraph should tab-expand to eight extra spaces.



\t  The fifth input paragraph turns into the fourth output paragraph
indented by ten extra spaces.

\t\tDouble tabs yield sixteen extra spaces.
EOF
        qr{
              \A
              $banner_rex
              [ ]{4}  \QThe first paragraph should be\E      \r? \n
              [ ]{4}  \Qindented normally - i.e. with four\E \r? \n
              [ ]{4}  \Qleading spaces.\E                    \r? \n
                                                             \r? \n
              [ ]{6}  \QThe second paragraph should be\E     \r? \n
              [ ]{6}  \Qleft-justified with two extra\E      \r? \n
              [ ]{6}  \Qspaces.\E                            \r? \n
                                                             \r? \n
              [ ]{12} \QThe third paragraph should\E         \r? \n
              [ ]{12} \Qtab-expand to eight extra\E          \r? \n
              [ ]{12} \Qspaces.\E                            \r? \n
                                                             \r? \n
              [ ]{14} \QThe fifth input paragraph\E          \r? \n
              [ ]{14} \Qturns into the fourth\E              \r? \n
              [ ]{14} \Qoutput paragraph indented\E          \r? \n
              [ ]{14} \Qby ten extra spaces.\E               \r? \n
                                                             \r? \n
              [ ]{20} \QDouble tabs yield\E                  \r? \n
              [ ]{20} \Qsixteen extra\E                      \r? \n
              [ ]{20} \Qspaces.\E                            \r? \n
                                                             \r? \n
          }x,
        'Various amounts of space/tab indentations apply to each paragraph';

    return;
}

sub verify_long_words {

    throws_ok{ fatal 'handler', <<'EOF' }
ExceptionallyLongWordAtTheBeginningOfAParagraphThat should be placed
just fine.
EOF
        qr{
              \A
              $banner_rex
              \Q    ExceptionallyLongWordAtTheBeginningOfAParagraphThat\E \r? \n
              \Q    should be placed just fine.\E                         \r? \n
                                                                          \r? \n
              \Q  *** Stacktrace ***\E                                    \r? \n
          }x,
        'Words exceeding columns at beginning';

    throws_ok{ fatal 'handler', <<'EOF' }
Place this ExceptionallyLongWordOnOneLineAllByItself surrounded by
partial lines
EOF
        qr{
              \A
              $banner_rex
              \Q    Place this\E                                \r? \n
              \Q    ExceptionallyLongWordOnOneLineAllByItself\E \r? \n
              \Q    surrounded by partial lines\E               \r? \n
                                                                \r? \n
              \Q  *** Stacktrace ***\E                          \r? \n
          }x,
        'Words exceeding columns in the middle';


    return;
}

sub verify_empty {

    throws_ok{ fatal 'handler', '' }
        qr{
              \A
              ~+ \r? \n
              \QFatal << handler >>\E \r? \n
              ~+ \r? \n
              \Q  *** Stacktrace ***\E
          }x,
        'Empty filled paragraph omits section';

    my $paragraph_with_only_whitespace = <<"EOF";
The first paragraph

\t

The third, rendered as second
EOF

    throws_ok{ fatal 'handler', $paragraph_with_only_whitespace }
        qr{
              \A
              ~+                                     \r? \n
              \QFatal << handler >>\E                \r? \n
              ~+                                     \r? \n
              \Q    The first paragraph\E            \r? \n
                                                     \r? \n
              \Q    The third, rendered as second\E  \r? \n
                                                     \r? \n
              \Q  *** Stacktrace ***\E
          }x,
        'Empty sub-paragraphs omitted.';

    return;
}
