use strict;
use warnings;

use Test2::V0;

use DBIx::QuickDB::Pool();

# The username Pool::fetch_db prefixes onto each instance directory. It is
# interpolated into a File::Temp template, so a '/' would send tempdir looking
# for a subdirectory of instance_dir that does not exist, and an unbounded name
# eats into the 107-byte unix socket path budget the instance dir has to fit
# inside.
#
# t/Pool/Pool.pm asks this method for the prefix rather than rebuilding it, which
# keeps the two in step but means that test passes no matter what the rules are.
# The rules themselves are pinned here: removing the sanitizer, the empty
# fallback or the cap used to leave the suite green.

my $CLASS = 'DBIx::QuickDB::Pool';

my @cases = (
    ['plain name is untouched',              'exodist',                'exodist'],
    ['digits and underscores are kept',      'user_42',                'user_42'],
    ['dots and dashes are kept',             'a.b-c',                  'a.b-c'],
    ['a slash cannot escape into a subdir',  'a/b',                    'a_b'],
    ['a leading slash is neutralized',       '/etc',                   '_etc'],
    ['an AD backslash login is neutralized', 'DOMAIN\\jdoe',           'DOMAIN_jdoe'],
    ['an LDAP login is neutralized+capped',  'jdoe@corp.example.com',  'jdoe_corp.ex'],
    ['a space is neutralized',               'foo bar',                'foo_bar'],
    ['a run of invalid chars collapses',     'a@@@b',                  'a_b'],
    ['an all-invalid name is still usable',  '@@@',                    '_'],
    ['"0" survives (length, not truth)',     '0',                      '0'],
    ['".." is just a prefix, not traversal', '..',                     '..'],
    ['an empty name falls back',             '',                       'quickdb'],
    ['exactly 12 characters is untouched',   'abcdefghijkl',           'abcdefghijkl'],
    ['13 characters is capped to 12',        'abcdefghijklm',          'abcdefghijkl'],
    ['a long name is capped to 12',          'a' x 40,                 'a' x 12],
);

for my $case (@cases) {
    my ($desc, $in, $want) = @$case;

    local $ENV{USER} = $in;
    delete local $ENV{USERNAME};

    is($CLASS->instance_dir_user, $want, "$desc (USER='$in')");
}

subtest fallback_precedence => sub {
    {
        delete local $ENV{USER};
        local $ENV{USERNAME} = 'winuser';
        is($CLASS->instance_dir_user, 'winuser', "USERNAME is used when USER is unset");
    }

    {
        delete local $ENV{USER};
        delete local $ENV{USERNAME};
        is($CLASS->instance_dir_user, 'quickdb', "Falls back to 'quickdb' when neither is set");
    }

    {
        local $ENV{USER}     = 'preferred';
        local $ENV{USERNAME} = 'ignored';
        is($CLASS->instance_dir_user, 'preferred', "USER wins over USERNAME");
    }
};

subtest result_is_always_template_safe => sub {
    # Whatever goes in, the result has to be a single path component that
    # File::Temp can prefix onto a template.
    for my $in ('a/b/c', '../../etc', "tab\there", '', '@' x 30, "new\nline") {
        local $ENV{USER} = $in;
        delete local $ENV{USERNAME};

        my $got = $CLASS->instance_dir_user;

        ok(length($got),            "non-empty for input " . (length($in) ? "'$in'" : "''"));
        ok($got !~ m{[/\\]},        "no path separator for input " . (length($in) ? "'$in'" : "''"));
        ok(length($got) <= 12,      "within the cap for input " . (length($in) ? "'$in'" : "''"));
        ok($got =~ m/\A[\w.-]+\z/,  "template-safe characters only for input " . (length($in) ? "'$in'" : "''"));
    }
};

done_testing;
