# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

my $original;
my $replacement;
BEGIN{
    $original    = 78;     #----- Default for 'columns is 78
    $replacement = 50;

    use_ok( 'Carp::Proxy',
            fatal     => {},
            fatal_col => { columns => $replacement },
          );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->columns( $setting )
        if defined $setting;

    #-----
    # As this file tests 'columns' we need something that will be influenced
    # by changes to columns.  Banner ~~~~~ lines and filled paragraphs are
    # the two things.  This paragraph is long enough that it should get
    # wrapped.
    #-----
    $cp->filled(<<'EOF', 'fill');
Now is the time for all good men to come to the aid of their country.  The
quick brown fox jumps over the lazy dog.
EOF

    #-----
    # We might as well verify that fixed paragraphs do not change their
    # representation with changes to columns.
    #-----
    $cp->fixed(<<'EOF', 'fix');
1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890
abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz
EOF
    return;
}

sub main {

    #-----
    # Columns affects where line breaks occur so we need to be pedantic
    # about where newlines happen.  Hopefully this works for all platforms.
    #-----
    my $newline = qr{ \r? \n }x;

    #-----
    # The fixed() section should be invariant with changes to 'columns'.
    #-----
    my $fixed_portion =
        qr{
              \Q  *** fix ***\E                            $newline
              [ ]{4} \Q1234567890 1234567890 1234567890 \E
                     \Q1234567890 1234567890 1234567890 \E
                     \Q1234567890\E                        $newline

              [ ]{4} abcdefghijklmnopqrstuvwxyz [ ]
                     abcdefghijklmnopqrstuvwxyz            $newline
          }x;

    my $orig_rex =
        qr{
              \A
              ~{$original}                                $newline
              \QFatal << handler >>\E                     $newline
              ~{$original}                                $newline

              \Q  *** fill ***\E                          $newline
              [ ]{4} \QNow is the time for all good men \E
                     \Qto come to the aid of their \E
                     \Qcountry. The\E                     $newline

              [ ]{4} \Qquick brown fox jumps over the \E
                     \Qlazy dog.\E                        $newline

                                                          $newline
              $fixed_portion
          }x;

    my $repl_rex =
        qr{
              \A
              ~{$replacement}                             $newline
              \QFatal << handler >>\E                     $newline
              ~{$replacement}                             $newline

              \Q  *** fill ***\E                          $newline
              [ ]{4} \QNow is the time for all good \E
                     \Qmen to come to\E                   $newline
              [ ]{4} \Qthe aid of their country. The \E
                     \Qquick brown fox\E                  $newline
              [ ]{4} \Qjumps over the lazy dog.\E         $newline

                                                          $newline

              $fixed_portion
          }x;


    foreach my $tuple
        ([ \&fatal,     undef,        $orig_rex, 'default'     ],
         [ \&fatal,     $replacement, $repl_rex, 'override'    ],
         [ \&fatal_col, undef,        $repl_rex, 'constructed' ],
         [ \&fatal_col, $original,    $orig_rex, 'cons-over'   ],
        ) {

        my( $proxy, $setting, $rex, $title ) = @{ $tuple };

        throws_ok{ $proxy->( 'handler', $setting ) }
            $rex,
            "banner width and filled change with columns for $title";
    }

    return;
}
