use 5.016;
use warnings;

use Code::ART;

# Extract test datasets...
my $test_data = do { local $/; readline *DATA };
my @tests     = split /^-+\n/m, $test_data;

# Build tests...
my @preposts;
for my $test (@tests) {
    # Break each before|after line...
    my @testlines = split /\n/, $test;
    my %test;
    for my $testline (@testlines) {
        my ($source, $expected)  = split /\s*\|/, $testline;
        $test{source}   .= "$source\n";
        $test{expected} .= "$expected\n";
    }

    # Detect meta placeholders...
    my %Xpos;
    for my $meta ('A'..'Z') {
        pos($test{expected}) = 0;
        while ($test{expected} =~ m{ (?<placeholder>
                                           (?: \$\#? | [\@%] )
                                           (?&PerlOWS)
                                           (?:
                                                $meta++ (?: :: $meta++ )*+
                                           |
                                                \{
                                                (?&PerlOWS)
                                                $meta++ (?: :: $meta++ )*+
                                                (?&PerlOWS)
                                                \}
                                           )
                                     )
                                     $PPR::X::GRAMMAR
                                   }gcxms)
        {
            push @{ $Xpos{$meta} }, pos($test{expected}) - length($+{placeholder});
        }
    }

    # Build each test for each meta placeholder...
    for my $meta ('A'..'Z') {
        next if !$Xpos{$meta};
        my $expected = $test{source};
        my $replacement;
        for my $pos (@{ $Xpos{$meta} }) {
            substr($expected, $pos)
                =~ s{\A (?<sigil>   (?: \$\#? | [\@%]) (?&PerlOWS) )
                        (?:
                            (?<ocb>                             )
                            (?<name>  \w++ (?: :: \w++ )*+  \b  )
                            (?<ccb>                             )
                        |
                            (?<ocb>   \{ (?&PerlOWS)            )
                            (?<name>  \w++ (?: :: \w++ )*+      )
                            (?<ccb>   (?&PerlOWS) \}            )
                        )
                        $PPR::X::GRAMMAR
                    }
                    { my %match = %+;
                      $match{name} =~ s/\w/$meta/g;
                      $replacement = $match{name};
                      $match{sigil} . $match{ocb} . $replacement . $match{ccb};
                    }xmse;
        }
        for my $pos (@{ $Xpos{$meta} }) {
            push @preposts, { %test,
                              varpos      => $pos,
                              meta        => $meta,
                              replacement => $replacement,
                              expected    => $expected
                            };
        }
    }
}

use Test::More;

for my $test (@preposts) {
    next if $test->{varpos} < 0;
    my $context = substr($test->{source},$test->{varpos},20);
    substr($context, 0, 1) =~ s/(.)/»$1«/;
    $context =~ s/\s+/ /g;
    my $result = rename_variable($test->{source}, $test->{varpos}, $test->{replacement});
    ok !$result->{failed}
        => "Successful rename to $test->{replacement} at position $test->{varpos} ('$context')";
    is $result->{source}, $test->{expected} => " + correct rename";
}

done_testing();


__DATA__
                                                 |
$NS1::var = $var::var;                           |$AAA::AAA = $BBB::BBB;
                                                 |
for $var ($NS1::var, $var::var) {                |for $CCC ($AAA::AAA, $BBB::BBB) {
    say $var if $var ne $NS1::var;               |    say $CCC if $CCC ne $AAA::AAA;
}                                                |}
                                                 |
say $var::var;                                   |say $BBB::BBB;
-----------------------------------------------------------------------------------------------------
my $array = 'array';  # array reference          |my $AAAAA = 'array';  # array reference
my @array = ();       # An actual array          |my @BBBBB = ();       # An actual array
{                                                |{
    our (@array, %array) = (1..10);              |    our (@CCCCC, %DDDDD) = (1..10);
                                                 |
    {                                            |    {
        state ($other, $etc, @array) = 2;        |        state ($other, $etc, @EEEEE) = 2;
        say for map {length} @array;             |        say for map {length} @EEEEE;
    }                                            |    }
                                                 |
    for (keys @array) {                          |    for (keys @CCCCC) {
        $array[$_]                               |        $CCCCC[$_]
            = int(@array[@array])                |            = int(@CCCCC[@CCCCC])
            + int(%array[$array->$array()]);     |            + int(%CCCCC[$AAAAA->$AAAAA()]);
        last if $#array > 0;                     |        last if $#CCCCC > 0;
    }                                            |    }
                                                 |
    for my $array ($array{$array[$array]}) {     |    for my $FFFFF ($DDDDD{$CCCCC[$AAAAA]}) {
        say $array;                              |        say $FFFFF;
    }                                            |    }
                                                 |
    my $x = (my @array) = 'a'..'z';              |    my $x = (my @GGGGG) = 'a'..'z';
                                                 |
    sub foo ($array) { say $array; }             |    sub foo ($HHHHH) { say $HHHHH; }
    sub foo ($allay) { say $array; }             |    sub foo ($allay) { say $AAAAA; }
                                                 |
    my $bar = sub ($array) {                     |    my $bar = sub ($IIIII) {
        say @array x $array;                     |        say @GGGGG x $IIIII;
    };                                           |    };
    my $baz = sub ($allay) {                     |    my $baz = sub ($allay) {
        say @array x $array;                     |        say @GGGGG x $AAAAA;
    };                                           |    };
                                                 |
    $array = $#array . "$array" . '$array';      |    $AAAAA = $#GGGGG . "$AAAAA" . '$array';
                                                 |
    my $array                                    |    my $JJJJJ
        = $#array                                |        = $#GGGGG
        . $                                      |        . $
          #                                      |          #
          array                                  |          AAAAA
        . ${array} x @{array}                    |        . ${AAAAA} x @{GGGGG}
        . qq{$array $array[$array]}              |        . qq{$AAAAA $GGGGG[$AAAAA]}
        . q{$array};                             |        . q{$array};
                                                 |
    say $array;                                  |    say $JJJJJ;
}                                                |}
say @array;                                      |say @BBBBB;
say %array;                                      |say %KKKKK;
