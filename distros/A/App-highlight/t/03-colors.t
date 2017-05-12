use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::More tests => 28;
use App::Cmd::Tester;
use Test::AppHighlightWords;

use App::highlight;

## default - color cycle
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ 'a', 'o' ]);

    like($result->stdout, qr/^f(.+)o(.+)\1o\2$/ms,          'foo - matched "a" "o"'       );
    like($result->stdout, qr/^b.+a.+r$/ms,                  'bar - matched "a" "o"'       );
    like($result->stdout, qr/^b.+a.+z$/ms,                  'baz - matched "a" "o"'       );
    like($result->stdout, qr/^qux$/ms,                      'qux - no match for "a" "o"'  );
    like($result->stdout, qr/^quux$/ms,                     'quux - no match for "a" "o"' );
    like($result->stdout, qr/^c.+o.+rge$/ms,                'corge - matched "a" "o"'     );
    like($result->stdout, qr/^gr.+a.+ult$/ms,               'grault - matched "a" "o"'    );
    like($result->stdout, qr/^g.+a.+rply$/ms,               'garply - matched "a" "o"'    );
    like($result->stdout, qr/^w(.+)a(.+)ld(?!\1).+o.+$/ms,  'waldo - no match for "a" "o"');
    like($result->stdout, qr/^fred$/ms,                     'fred - no match for "a" "o"' );
    like($result->stdout, qr/^plugh$/ms,                    'plugh - no match for "a" "o"');
    like($result->stdout, qr/^xyzzy$/ms,                    'xyzzy - no match for "a" "o"');
    like($result->stdout, qr/^thud$/ms,                     'thud - no match for "a" "o"' );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## one-color
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ '--one-color', 'a', 'o' ]);

    like($result->stdout, qr/^f(.+)o(.+)\1o\2$/ms,    'foo - matched "a" "o" (one-color mode)'       );
    like($result->stdout, qr/^b.+a.+r$/ms,            'bar - matched "a" "o" (one-color mode)'       );
    like($result->stdout, qr/^b.+a.+z$/ms,            'baz - matched "a" "o" (one-color mode)'       );
    like($result->stdout, qr/^qux$/ms,                'qux - no match for "a" "o" (one-color mode)'  );
    like($result->stdout, qr/^quux$/ms,               'quux - no match for "a" "o" (one-color mode)' );
    like($result->stdout, qr/^c.+o.+rge$/ms,          'corge - matched "a" "o" (one-color mode)'     );
    like($result->stdout, qr/^gr.+a.+ult$/ms,         'grault - matched "a" "o" (one-color mode)'    );
    like($result->stdout, qr/^g.+a.+rply$/ms,         'garply - matched "a" "o" (one-color mode)'    );
    like($result->stdout, qr/^w(.+)a(.+)ld\1o\2$/ms,  'waldo - no match for "a" "o" (one-color mode)');
    like($result->stdout, qr/^fred$/ms,               'fred - no match for "a" "o" (one-color mode)' );
    like($result->stdout, qr/^plugh$/ms,              'plugh - no match for "a" "o" (one-color mode)');
    like($result->stdout, qr/^xyzzy$/ms,              'xyzzy - no match for "a" "o" (one-color mode)');
    like($result->stdout, qr/^thud$/ms,               'thud - no match for "a" "o" (one-color mode)' );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}
