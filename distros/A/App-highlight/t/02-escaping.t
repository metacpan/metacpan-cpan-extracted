use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::More tests => 42;
use App::Cmd::Tester;
use Test::AppHighlightWords;

use App::highlight;

## default = escape
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ '[abcde]+' ]);

    like($result->stdout, qr/^foo$/ms,      'foo - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^bar$/ms,      'bar - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^baz$/ms,      'baz - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^qux$/ms,      'qux - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^quux$/ms,     'quux - no match for "[abcde]+" (default = escape)'  );
    like($result->stdout, qr/^corge$/ms,    'corge - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^grault$/ms,   'grault - no match for "[abcde]+" (default = escape)');
    like($result->stdout, qr/^garply$/ms,   'garply - no match for "[abcde]+" (default = escape)');
    like($result->stdout, qr/^waldo$/ms,    'waldo - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^fred$/ms,     'fred - no match for "[abcde]+" (default = escape)'  );
    like($result->stdout, qr/^plugh$/ms,    'plugh - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^xyzzy$/ms,    'xyzzy - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^thud$/ms,     'thud - no match for "[abcde]+" (default = escape)'  );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## explicit escape mode
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ '--escape', '[abcde]+' ]);

    like($result->stdout, qr/^foo$/ms,      'foo - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^bar$/ms,      'bar - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^baz$/ms,      'baz - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^qux$/ms,      'qux - no match for "[abcde]+" (default = escape)'   );
    like($result->stdout, qr/^quux$/ms,     'quux - no match for "[abcde]+" (default = escape)'  );
    like($result->stdout, qr/^corge$/ms,    'corge - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^grault$/ms,   'grault - no match for "[abcde]+" (default = escape)');
    like($result->stdout, qr/^garply$/ms,   'garply - no match for "[abcde]+" (default = escape)');
    like($result->stdout, qr/^waldo$/ms,    'waldo - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^fred$/ms,     'fred - no match for "[abcde]+" (default = escape)'  );
    like($result->stdout, qr/^plugh$/ms,    'plugh - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^xyzzy$/ms,    'xyzzy - no match for "[abcde]+" (default = escape)' );
    like($result->stdout, qr/^thud$/ms,     'thud - no match for "[abcde]+" (default = escape)'  );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## no-escape / regex mode
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ '--no-escape', '[abcde]+' ]);

    like($result->stdout, qr/^foo$/ms,           'foo - no match for "[abcde]+" (no-escape mode)'  );
    like($result->stdout, qr/^.+ba.+r$/ms,       'bar - match for "[abcde]+" (no-escape mode)'     );
    like($result->stdout, qr/^.+ba.+z$/ms,       'baz - match for "[abcde]+" (no-escape mode)'     );
    like($result->stdout, qr/^qux$/ms,           'qux - no match for "[abcde]+" (no-escape mode)'  );
    like($result->stdout, qr/^quux$/ms,          'quux - no match for "[abcde]+" (no-escape mode)' );
    like($result->stdout, qr/^.+c.+org.+e.+$/ms, 'corge - match for "[abcde]+" (no-escape mode)'   );
    like($result->stdout, qr/^gr.+a.+ult$/ms,    'grault - match for "[abcde]+" (no-escape mode)'  );
    like($result->stdout, qr/^g.+a.+rply$/ms,    'garply - match for "[abcde]+" (no-escape mode)'  );
    like($result->stdout, qr/^w.+a.+l.+d.+o$/ms, 'waldo - match for "[abcde]+" (no-escape mode)'   );
    like($result->stdout, qr/^fr.+ed.+$/ms,      'fred - match for "[abcde]+" (no-escape mode)'    );
    like($result->stdout, qr/^plugh$/ms,         'plugh - no match for "[abcde]+" (no-escape mode)');
    like($result->stdout, qr/^xyzzy$/ms,         'xyzzy - no match for "[abcde]+" (no-escape mode)');
    like($result->stdout, qr/^thu.+d.+$/ms,      'thud - match for "[abcde]+" (no-escape mode)'    );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}
