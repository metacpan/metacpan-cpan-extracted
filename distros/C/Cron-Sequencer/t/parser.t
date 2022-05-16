#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

require_ok('Cron::Sequencer::Parser')
    or BAIL_OUT('When Cron::Sequencer fails to even load, nothing is going to work');

# We assume that the tests for Algorithm::Cron sufficiently test its parser for
# time strings, so we concentrate on our code here (the env parser and the
# special strings)

my @fields = qw(min hour mday mon wday);

for ([hourly => { min => 0, }],
     [daily => { min => 0, hour => 0 }],
     [midnight => { min => 0, hour => 0 }],
     [weekly => { min => 0, hour => 0, wday => 0 }],
     [monthly => { min => 0, hour => 0, mday => 1 }],
     [annually => { min => 0, hour => 0, mon => 0, mday => 1 }],
     [yearly => { min => 0, hour => 0, mon => 0, mday => 1 }],
 ) {
    my ($special, $expect) = @$_;
    $special = '@' . $special;

    my $have = Cron::Sequencer::Parser::_parser(\"$special woof!", "Bother!");

    cmp_deeply($have, [{
        file => "Bother!",
        lineno => 1,
        when => $special,
        command => 'woof!',
        whenever => isa('Algorithm::Cron'),
    }], "Special string $special");

    for my $field (@fields) {
        my $whenever = $have->[0]->{whenever};
        my $want = defined $expect->{$field} ? [$expect->{$field}] : [];
        cmp_deeply([$whenever->$field], $want, "$special $field");
    }
}

cmp_deeply(Cron::Sequencer::Parser::_parser(\'@reboot woof!', "Oops!"),
           [], 'Special string @reboot is ignored');

like(exception {
        Cron::Sequencer::Parser::_parser(\'@woof reboot!', "Oops!");
     }, qr/^Unknown special string \@woof at line 1 of Oops!/,
     'Special string @woof is unknown');

my $crontab = <<"EOT";
# This is a comment
   # This too
   #IS=Comment
#STILL=Comment

0 1 2 3 4 woof!

FOO=BAR

 1 2 3 4 5 woof!\t

FOO=BAZ

02\t03\t04\t05\t06\tw o o f !
EOT
my $have = Cron::Sequencer::Parser::_parser(\$crontab, "Comments!");

cmp_deeply($have, [
    {
        file => "Comments!",
        lineno => 6,
        when => '0 1 2 3 4',
        command => 'woof!',
        whenever => isa('Algorithm::Cron'),
    },
    {
        file => "Comments!",
        lineno => 10,
        when => '1 2 3 4 5',
        command => "woof!\t",
        env => {
            FOO => 'BAR',
        },
        whenever => isa('Algorithm::Cron'),
    },
    {
        file => "Comments!",
        lineno => 14,
        when => "02\t03\t04\t05\t06",
        command => 'w o o f !',
        env => {
            FOO => 'BAZ',
        },
        whenever => isa('Algorithm::Cron'),
    },
], "Captures env");

$have = Cron::Sequencer::Parser::_parser(\$crontab, "ignore", undef, {
    10 => 1,
    12 => 1,
});

cmp_deeply($have, [
    {
        file => "ignore",
        lineno => 6,
        when => '0 1 2 3 4',
        command => 'woof!',
        whenever => isa('Algorithm::Cron'),
    },
    {
        file => "ignore",
        lineno => 14,
        when => "02\t03\t04\t05\t06",
        command => 'w o o f !',
        env => {
            FOO => 'BAR',
        },
        whenever => isa('Algorithm::Cron'),
    },
], "ignore ignores lines");


for (['FOO=BAR', 'FOO', 'BAR', 'normal'],
     ['FOO=BAR=BAZ', 'FOO', 'BAR=BAZ', 'value contains ='],
     [' SPACE = TRIMMED ', 'SPACE', 'TRIMMED', 'spaces ignored'],
     ["\tTAB=[ \t]\t \t ", 'TAB', "[ \t]", 'embedded spaces retained'],
     [" O'Leary = Every airport's recurring = nightmare",
      "O'Leary", "Every airport's recurring = nightmare",
      "quotes only matter at start"],
     ['FOO==BAR', 'FOO', '=BAR', 'only the first = matters'],
     # vixie cron will parse these, but as it invokes commands as /bin/sh -c ...
     # it is likely that the shell will filter them out from the environment it
     # creates for the command(s) that it invokes. (at least, dash does this)
     ['!=PLING', '!', 'PLING', 'anything goes'],
     ['!#=TYPO', '!#', 'TYPO', 'at least as far as the parser is concerned'],
     # The empty *value* is sane and legal. It's all the empty keys that are not
     # really legal, and accepting a completely missing key is certainly quirky.
     # Note that FOO= won't parse (but would be useful in a shell script)
     # but =BAR will parse (but will get stripped by any sane shell)
     ['""=NOWT', "", 'NOWT', '"" key is empty'],
     ["''=ZILCH", "", 'ZILCH', "'' key is empty"],
     ["=NADA", "", 'NADA', "empty key is empty"],
     ['""=""', "", "", '"" both empty'],
     ["''=''", "", "", "'' both empty"],
     ['=""', "", "", 'no key, "" value'],
     ["=''", "", "", "no key, '' value"],
 ) {
    my ($input, $key, $value, $desc) = @$_;
    my $have
        = Cron::Sequencer::Parser::_parser(\"$input\n* * * * * woof!", "Env test!");

    cmp_deeply($have, [{
        file => "Env test!",
        lineno => 2,
        when => '* * * * *',
        command => 'woof!',
        env => {
            $key => $value,
        },
        whenever => isa('Algorithm::Cron'),
    }], "env $desc");
}

for my $quote1 ("", "'", '"') {
    for my $quote2 ("", "'", '"') {
        for my $space_mask (0 .. 255) {
            # 8 of "space or empty string"
            my @spaces;
            for my $i (0 .. 7) {
                $spaces[$i] = $space_mask & (1 << $i) ? ' ' : "";
            }
            my $input =
                $spaces[0] . $quote1 . $spaces[1]
                . 'KEY'
                . $spaces[2] . $quote1 . $spaces[3]
                . '='
                . $spaces[4] . $quote2 . $spaces[5]
                . 'VALUE'
                . $spaces[6] . $quote2 . $spaces[7];
            my $key = $quote1 ? $spaces[1] . 'KEY' . $spaces[2] : 'KEY';
            my $value = $quote2 ? $spaces[5] . 'VALUE' . $spaces[6] : 'VALUE';

            my $have
                = Cron::Sequencer::Parser::_parser(\"$input\n* * * * * woof!", "Env test!");

            cmp_deeply($have, [{
                file => "Env test!",
                lineno => 2,
                when => '* * * * *',
                command => 'woof!',
                env => {
                    $key => $value,
                },
                whenever => isa('Algorithm::Cron'),
            }], sprintf "env <%s> <%s> %08b", $quote1, $quote2, $space_mask);
        }
    }
}

# As it's fairly easy to adapt that test for many many permuations of empty
# values, let's do it:

for my $quote1 ("", "'", '"') {
    # Note, "FOO=" won't parse - you can't have an empty value.
    # (Due to a quirk of the parser, you can have an empty key.)
    for my $quote2 ("'", '"') {
        for my $space_mask (0 .. 255) {
            # 4 of "space or empty string"
            my @spaces;
            for my $i (0 .. 3) {
                $spaces[$i] = $space_mask & (1 << $i) ? ' ' : "";
            }
            my $input =
                $spaces[0] . $quote1 . 'KEY' . $quote1 . $spaces[1]
                . '='
                . $spaces[2] . $quote2 . $quote2 . $spaces[3];

            my $have
                = Cron::Sequencer::Parser::_parser(\"$input\n* * * * * woof!", "Env test!");

            cmp_deeply($have, [{
                file => "Env test!",
                lineno => 2,
                when => '* * * * *',
                command => 'woof!',
                env => {
                    KEY => "",
                },
                whenever => isa('Algorithm::Cron'),
            }], sprintf "env <%s> <%s> %04b", $quote1, $quote2, $space_mask);
        }
    }
}

for (['FOO=', 'omitted value is not legal'],
     ['=', 'bare = sign is not legal'],
     ['"FOO=BAR"=BAZ', '= is not legal in key, even with "" quotes'],
     ["'FOO=BAR'=BAZ", "= is not legal in key, even with '' quotes"],
     ["\"FOO\nBAR\"=BAZ", 'newline is not legal in key, even with "" quotes',
      qr/Can't parse '"FOO'/],
     ["'FOO\nBAR'=BAZ", "newline is not legal in key, even with '' quotes",
      qr/Can't parse ''FOO'/],
     ["FOO=\"BAR\nBAZ\"", 'newline is not legal in value, even with "" quotes',
      qr/Can't parse 'FOO="BAR'/],
     ["FOO='BAR\nBAZ'", "newline is not legal in value, even with '' quotes",
      qr/Can't parse 'FOO='BAR'/],
     ['"FOO"BAR=BAZ', 'text after ""-quoted key'],
     ["'FOO'BAR=BAZ", "text after ''-quoted key"],
     ['FOO="BAR"BAZ', 'text after ""-quoted value'],
     ['FOO="BAR" BAZ', 'text after ""-quoted value (whitespace)'],
     ["FOO='BAR'BAZ", "text after ''-quoted value"],
     ["FOO='BAR' BAZ", "text after ''-quoted value (whitespace)"],
 ) {
    my ($input, $desc, $want) = @$_;
    my $have = exception {
        Cron::Sequencer::Parser::_parser(\"$input\n* * * * * woof!", "Env test!");
    };
    like($have, $want // qr/\ACan't parse '\Q$input\E'/, $desc);
}

$crontab = <<"EOT";
=
0 1 2 3 4 woof!
EOT

$have = Cron::Sequencer::Parser::_parser(\$crontab, "ignore trumps errors", undef, {
    1 => 1,
});

cmp_deeply($have, [{
        file => "ignore trumps errors",
        lineno => 2,
        when => '0 1 2 3 4',
        command => 'woof!',
        whenever => isa('Algorithm::Cron'),
    }], 'ignore is processed first');

done_testing();
