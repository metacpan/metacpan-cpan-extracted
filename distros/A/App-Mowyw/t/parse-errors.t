use Test::More tests => 10;
use strict;
use warnings;

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my %meta = ( VARS => {}, FILES => ['none'], );

sub dies_ok {
    my ($str, $msg) = @_;

    eval {
        parse_str($str, \%meta);
    };
    ok $@,  $msg;
}

my @strs = (
       q{ [% comment },
       q{ [[[ comment },
       q{ [% nonkeyword %] },
       q{ [% ifvar foo bar %] },
       q{ [% for a bar b %] },
       q{ [% for a in %] },
       q{ [% for a %] },
       q{ [% for %] },
       q{ [% for a in undefined_variable %] },
);
for (@strs){
    dies_ok($_, $_);
}
