use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::More tests => 42;
use App::Cmd::Tester;
use Test::AppHighlightWords;

use App::highlight;

## basic highlight behaviour
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ 'ba' ]);

    like($result->stdout, qr/^foo$/ms,      'foo - no match for "ba"'   );
    like($result->stdout, qr/^.+ba.+r$/ms,  'bar - matched "ba"'        );
    like($result->stdout, qr/^.+ba.+z$/ms,  'baz - matched "ba"'        );
    like($result->stdout, qr/^qux$/ms,      'qux - no match for "ba"'   );
    like($result->stdout, qr/^quux$/ms,     'quux - no match for "ba"'  );
    like($result->stdout, qr/^corge$/ms,    'corge - no match for "ba"' );
    like($result->stdout, qr/^grault$/ms,   'grault - no match for "ba"');
    like($result->stdout, qr/^garply$/ms,   'garply - no match for "ba"');
    like($result->stdout, qr/^waldo$/ms,    'waldo - no match for "ba"' );
    like($result->stdout, qr/^fred$/ms,     'fred - no match for "ba"'  );
    like($result->stdout, qr/^plugh$/ms,    'plugh - no match for "ba"' );
    like($result->stdout, qr/^xyzzy$/ms,    'xyzzy - no match for "ba"' );
    like($result->stdout, qr/^thud$/ms,     'thud - no match for "ba"'  );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## basic highlight behaviour - two matches
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ 'ba', 'q' ]);

    like($result->stdout, qr/^foo$/ms,      'foo - no match for "ba" "q"'   );
    like($result->stdout, qr/^.+ba.+r$/ms,  'bar - matched "ba" "q"'        );
    like($result->stdout, qr/^.+ba.+z$/ms,  'baz - matched "ba" "q"'        );
    like($result->stdout, qr/^.+q.+ux$/ms,  'qux - matched "ba" "q"'        );
    like($result->stdout, qr/^.+q.+uux$/ms, 'quux - matched "ba" "q"'       );
    like($result->stdout, qr/^corge$/ms,    'corge - no match for "ba" "q"' );
    like($result->stdout, qr/^grault$/ms,   'grault - no match for "ba" "q"');
    like($result->stdout, qr/^garply$/ms,   'garply - no match for "ba" "q"');
    like($result->stdout, qr/^waldo$/ms,    'waldo - no match for "ba" "q"' );
    like($result->stdout, qr/^fred$/ms,     'fred - no match for "ba" "q"'  );
    like($result->stdout, qr/^plugh$/ms,    'plugh - no match for "ba" "q"' );
    like($result->stdout, qr/^xyzzy$/ms,    'xyzzy - no match for "ba" "q"' );
    like($result->stdout, qr/^thud$/ms,     'thud - no match for "ba" "q"'  );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## basic highlight behaviour - three matches
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ 'ba', 'q', 'y' ]);

    like($result->stdout, qr/^foo$/ms,           'foo - no match for "ba" "q" "y"'   );
    like($result->stdout, qr/^.+ba.+r$/ms,       'bar - matched "ba" "q" "y"'        );
    like($result->stdout, qr/^.+ba.+z$/ms,       'baz - matched "ba" "q" "y"'        );
    like($result->stdout, qr/^.+q.+ux$/ms,       'qux - matched "ba" "q" "y"'        );
    like($result->stdout, qr/^.+q.+uux$/ms,      'quux - matched "ba" "q" "y"'       );
    like($result->stdout, qr/^corge$/ms,         'corge - no match for "ba" "q" "y"' );
    like($result->stdout, qr/^grault$/ms,        'grault - no match for "ba" "q" "y"');
    like($result->stdout, qr/^garpl.+y.+$/ms,    'garply - matched "ba" "q" "y"'     );
    like($result->stdout, qr/^waldo$/ms,         'waldo - no match for "ba" "q" "y"' );
    like($result->stdout, qr/^fred$/ms,          'fred - no match for "ba" "q" "y"'  );
    like($result->stdout, qr/^plugh$/ms,         'plugh - no match for "ba" "q" "y"' );
    like($result->stdout, qr/^x.+y.+zz.+y.+$/ms, 'xyzzy - matched "ba" "q" "y"'      );
    like($result->stdout, qr/^thud$/ms,          'thud - no match for "ba" "q" "y"'  );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}
