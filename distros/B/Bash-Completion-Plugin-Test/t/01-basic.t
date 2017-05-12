use strict;
use warnings;
use lib 't/lib';

use Test::Tester;
use Bash::Completion::Plugin::Test;
use Test::Exception;
use Test::More;

throws_ok {
    Bash::Completion::Plugin::Test->new;
} qr/plugin parameter required/;

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ^',
            [qw/foo bar baz/], 'test all completions');
    },
    {
        ok   => 1,
        name => 'test all completions',
    },
    'test cursor after blank character',
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin^',
            [qw//], 'test no completions immediately after command');
    },
    {
        ok   => 1,
        name => 'test no completions immediately after command',
    },
    'test cursor at end of command',
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ^',
            [qw/bar baz foo/], 'test all completions');
    },
    {
        ok   => 1,
        name => 'test all completions',
    },
    'test cursor after blank character, different completion order',
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ^',
            [qw/foo baz/]);
    },
    {
        ok => 0,
    },
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ^',
            [qw//]);
    },
    {
        ok => 0,
    },
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin f^',
            [qw/foo/]);
    },
    {
        ok => 1,
    },
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin b^',
            [qw/bar baz/]);
    },
    {
        ok => 1,
    },
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ba^',
            [qw/bar baz/]);
    },
    {
        ok => 1,
    },
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin b^',
            [qw/bar/]);
    },
    {
        ok => 0,
    },
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin foo^',
            [qw/foo/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin foo ^',
            [qw/foo bar baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup ^',
            [qw/foo bar baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup foo^',
            [qw/foo/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup foo ^',
            [qw/bar baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup foo ^',
            [qw/foo bar baz/]);
    },
    {
        ok => 0,
    }
);

throws_ok {
    Bash::Completion::Plugin::Test->new(
        plugin => 'Bash::Completion::Plugins::BadTestPlugin',
    );
} qr/Could not load plugin 'Bash::Completion::Plugins::BadTestPlugin'/;

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ^ bar',
            [qw/foo bar baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin ^ bar',
            [qw/bar baz/]);
    },
    {
        ok => 0,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin b^ bar',
            [qw/bar baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin f^ bar',
            [qw/foo/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPlugin',
        );

        $tester->check_completions('test-plugin f^ bar',
            [qw/bar baz/]);
    },
    {
        ok => 0,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup f^ bar',
            [qw/foo/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup f^ bar',
            [qw/bar baz/]);
    },
    {
        ok => 0,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup b^ bar',
            [qw/bar baz/]);
    },
    {
        ok => 0,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup b^ bar',
            [qw/baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup ^ bar',
            [qw/foo baz/]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        my $tester = Bash::Completion::Plugin::Test->new(
            plugin => 'Bash::Completion::Plugins::TestPluginNoDups',
        );

        $tester->check_completions('test-plugin-nodup ^ bar',
            [qw/foo bar baz/]);
    },
    {
        ok => 0,
    }
);

# XXX test when the cursor is in the middle of the word

done_testing;
