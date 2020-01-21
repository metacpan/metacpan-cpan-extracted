#!/usr/bin/env perl

use warnings;
use strict;

use FindBin '$Bin';

use File::Codeowners;
use Test::More;

subtest 'parse CODEOWNERS files', sub {
    my @basic_arr = ('#wat', '*  @whatever');
    my $basic_str = "#wat\n*  \@whatever\n";
    my $expected = [
        {comment => 'wat'},
        {pattern => '*', owners => ['@whatever']},
    ];
    my $r;

    my $file = File::Codeowners->parse_from_filepath("$Bin/samples/basic.CODEOWNERS");
    is_deeply($r = $file->_lines, $expected, 'parse from filepath') or diag explain $r;

    $file = File::Codeowners->parse_from_array(\@basic_arr);
    is_deeply($r = $file->_lines, $expected, 'parse from array') or diag explain $r;

    $file = File::Codeowners->parse_from_string(\$basic_str);
    is_deeply($r = $file->_lines, $expected, 'parse from string') or diag explain $r;

    open(my $fh, '<', \$basic_str) or die "open failed: $!";
    $file = File::Codeowners->parse_from_fh($fh);
    is_deeply($r = $file->_lines, $expected, 'parse from filehandle') or diag explain $r;
    close($fh);
};

subtest 'query information from CODEOWNERS', sub {
    my $file = File::Codeowners->parse("$Bin/samples/kitchensink.CODEOWNERS");
    my $r;

    is_deeply($r = $file->owners, [
        '@"Lucius Fox"',
        '@bane',
        '@batman',
        '@joker',
        '@robin',
        '@the-penguin',
        'alfred@waynecorp.example.com',
    ], 'list all owners') or diag explain $r;

    is_deeply($r = $file->owners('tricks/Grinning/'), [qw(
        @joker
        @the-penguin
    )], 'list owners matching pattern') or diag explain $r;

    is_deeply($r = $file->patterns, [qw(
        *
        /a/b/c/deep
        /vehicles/**/batmobile.cad
        mansion.txt
        tricks/Explosions.doc
        tricks/Grinning/
    )], 'list all patterns') or diag explain $r;

    is_deeply($r = $file->patterns('@joker'), [qw(
        tricks/Explosions.doc
        tricks/Grinning/
    )], 'list patterns matching owner') or diag explain $r;

    is_deeply($r = $file->unowned, [qw(
        lightcycle.cad
    )], 'list unowned') or diag explain $r;

    is_deeply($r = $file->match('whatever'), {
        owners  => [qw(@batman @robin)],
        pattern => '*',
    }, 'match solitary wildcard') or diag explain $r;
    is_deeply($r = $file->match('subdir/mansion.txt'), {
        owners  => ['alfred@waynecorp.example.com'],
        pattern => 'mansion.txt',
    }, 'match filename') or diag explain $r;
    is_deeply($r = $file->match('vehicles/batmobile.cad'), {
        owners  => ['@"Lucius Fox"'],
        pattern => '/vehicles/**/batmobile.cad',
        project => 'Transportation',
    }, 'match double asterisk') or diag explain $r;
    is_deeply($r = $file->match('vehicles/extra/batmobile.cad'), {
        owners  => ['@"Lucius Fox"'],
        pattern => '/vehicles/**/batmobile.cad',
        project => 'Transportation',
    }, 'match double asterisk again') or diag explain $r;
};

subtest 'parse errors', sub {
    eval { File::Codeowners->parse(\q{meh}) };
    like($@, qr/^Parse error on line 1/, 'parse error');
};

subtest 'handling projects', sub {
    my $file = File::Codeowners->parse("$Bin/samples/kitchensink.CODEOWNERS");
    my $r;

    is_deeply($r = $file->projects, [
        'Transportation',
    ], 'projects listed') or diag explain $r;

    $file->rename_project('Transportation', 'Getting Around');
    is_deeply($r = $file->projects, [
        'Getting Around',
    ], 'project renamed') or diag explain $r;

    is_deeply($r = [@{$file->_lines}[-3 .. -1]], [
        {comment => ' Project: Getting Around', project => 'Getting Around'},
        {},
        {pattern => '/vehicles/**/batmobile.cad', 'owners' => ['@"Lucius Fox"'], project => 'Getting Around'},
    ], 'renaming project properly modifies lines') or diag explain $r;

    $file->update_owners_by_project('Getting Around', '@twoface');
    ok( scalar grep { $_ eq '@twoface' }      @{$file->owners}, 'updating owner adds new owner');
    ok(!scalar grep { $_ eq '@"Lucius Fox"' } @{$file->owners}, 'updating owner removes old owner');
};

subtest 'editing and writing files', sub {
    my $file = File::Codeowners->parse("$Bin/samples/basic.CODEOWNERS");
    my $r;

    $file->update_owners('*' => [qw(@foo @bar @baz)]);
    is_deeply($r = $file->_lines, [
        {comment => 'wat'},
        {pattern => '*', owners => [qw(@foo @bar @baz)]},
    ], 'update owners for a pattern') or diag explain $r;
    is_deeply($r = $file->owners, [qw(@bar @baz @foo)], 'got updated owners') or diag explain $r;

    $file->update_owners('no/such/pattern' => [qw(@wuf)]);
    is_deeply($r = $file->_lines, [
        {comment => 'wat'},
        {pattern => '*', owners => [qw(@foo @bar @baz)]},
    ], 'no change when updating nonexistent pattern') or diag explain $r;

    $file->prepend(comment => 'start');
    $file->append(pattern => 'end', owners => ['@qux']);
    is_deeply($r = $file->_lines, [
        {comment => 'start'},
        {comment => 'wat'},
        {pattern => '*', owners => [qw(@foo @bar @baz)]},
        {pattern => 'end', owners => [qw(@qux)]},
    ], 'prepand and append') or diag explain $r;

    $file->add_unowned('lonely', 'afraid');
    is_deeply($r = $file->unowned, [qw(afraid lonely)], 'set unowned files') or diag explain $r;

    $file->remove_unowned('afraid');
    is_deeply($r = $file->unowned, [qw(lonely)], 'remove unowned files') or diag explain $r;

    is_deeply($r = $file->write_to_array, [
        '#start',
        '#wat',
        '*  @foo @bar @baz',
        'end  @qux',
        '',
        '### UNOWNED (File::Codeowners)',
        '# lonely',
    ], 'format file') or diag explain $r;

    $file->clear_unowned;
    is_deeply($r = $file->unowned, [], 'clear unowned files') or diag explain $r;
};

done_testing;
