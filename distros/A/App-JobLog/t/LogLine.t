#!/usr/bin/perl

# ABSTRACT: checks sanity of App::JobLog::Log::Line

use 5.006;
use strict;
use warnings;
use App::JobLog::Log::Line;

use Test::More;
use Test::Fatal;

# test API
my $module = 'App::JobLog::Log::Line';

# TODO test for crucial methods

my ( $line, $ll, $stringification );
subtest 'regression' => sub {
    ( $line = <<'END') =~ s/^\s++|\s++//g;
2011  1  3  2 41 36:5:j n Hn\\;tM_{'*T. A~kE#V2T M+&_%3WZu\\;`! v-/)%do FE-"CK, Us 9N|ix E
END
    is( exception { $module->parse($line) }, undef, 'the code lived', );
    ( $line = <<'END') =~ s/^\s++|\s++//g;
2011  1  1  2 23 30:5:n15{O[d ~46 >e +B!j
END
    is( exception { $module->parse($line) }, undef, 'the code lived', );
};

subtest 'date parsing' => sub {
    $line = '2011 2 8 9 50 12:la di da:this is the description';
    $ll   = $module->parse($line);
    is( $ll->time->year,   2011, 'correct year' );
    is( $ll->time->month,  2,    'correct month' );
    is( $ll->time->day,    8,    'correct day' );
    is( $ll->time->hour,   9,    'correct hour' );
    is( $ll->time->minute, 50,   'correct minute' );
    is( $ll->time->second, 12,   'correct second' );
};

subtest 'event type' => sub {
    ok( $ll->is_event,     'identified line as event description' );
    ok( $ll->is_beginning, 'identified line as beginning of event' );
};

subtest 'return types' => sub {
    is( ref $ll->description, 'ARRAY', 'description is array ref' );
    is( ref $ll->tags,        'ARRAY', 'tags is array ref' );
};

# check stringification
subtest 'stringification' => sub {
    $stringification = '2011  2  8  9 50 12:da di la:this is the description';
    is( $ll->to_string, $stringification, 'stringifies as expected' );
};

subtest 'tag escaping' => sub {
    push @{ $ll->tags }, 'uh oh', 'Foo::Bar', '\\';
    $stringification =
'2011  2  8  9 50 12:Foo\\:\\:Bar \\\\ da di la uh\\ oh:this is the description';
    is( $ll->to_string, $stringification, 'escapes tags properly' );
    my %tags = map { $_ => 1 } @{ $ll->tags };
    ok( $tags{'uh oh'},    'retains tag containing space without escape' );
    ok( $tags{'Foo::Bar'}, 'retains tag containing colon without escape' );
    ok( $tags{'\\'},       'retains tag containing slash without escape' );
};

subtest 'tag existence tests' => sub {
    ok( $ll->all_tags( 'la', 'di', 'da' ), 'all_tags method works 1' );
    ok( !$ll->all_tags( 'la', 'di', 'da', 'quux' ), 'all_tags method works 2' );
    ok( $ll->exists_tag( 'la', 'di', 'da', 'quux' ),
        'exists_tag method works 1' );
    ok( !$ll->exists_tag('quux'), 'exists_tag method works 2' );
    $ll->tags = [];
    ok( @{ $ll->tags } == 0, 'cleared tags' );
};

subtest 'description modification' => sub {
    push @{ $ll->description }, 'yada yada';
    $stringification = '2011  2  8  9 50 12::this is the description;yada yada';
    is( $ll->to_string, $stringification,
        'multiple element description stringifies correctly' );
    $ll->description = [];
    ok( @{ $ll->description } == 0, 'cleared description' );
    push @{ $ll->description }, ';', '\\';
    $stringification = '2011  2  8  9 50 12::\\;;\\\\';
    is( $ll->to_string, $stringification, 'description correctly escaped' );
    my %description = map { $_ => 1 } @{ $ll->description };
    ok( $description{';'},
        'retains description containing semicolon without escape' );
    ok( $description{'\\'},
        'retains description containing slash without escape' );
};

subtest 'comments' => sub {
    $line = ' # this is the comment ';
    $ll   = $module->parse($line);
    ok( $ll->is_comment, 'recognized comment' );
    is( $ll->comment, 'this is the comment', 'extracted comment' );
};

subtest 'done event' => sub {
    $line = '2011 2 8 9 50 13:DONE';
    $ll   = $module->parse($line);
    ok( $ll->is_event, 'recognizes done event as event' );
    ok( $ll->is_end,   'recognizes done event as end' );
};

subtest 'blank line' => sub {
    $line = '   ';
    $ll   = $module->parse($line);
    ok( $ll->is_blank, 'recognizes blank lines' );
    is( $ll->text, $line, 'retains text of blank lines' );
};

subtest 'malformed lines' => sub {
    $line = '2011 2 8 9 50 13:';
    $ll   = $module->parse($line);
    ok( $ll->is_malformed, 'recognizes malformed lines' );
    is( $ll->text, $line, 'retains text of malformed lines' );
};

done_testing();
