use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::More tests => 28;
use App::Cmd::Tester;
use Test::AppHighlightWords;

use App::highlight;

## default - only match part of the line
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ 'u' ]);

    like($result->stdout, qr/^foo$/ms,        'foo - no match for "u"'   );
    like($result->stdout, qr/^bar$/ms,        'bar - no match for "u"'   );
    like($result->stdout, qr/^baz$/ms,        'baz - no match for "u"'   );
    like($result->stdout, qr/^q.+u.+x$/ms,    'qux - matched "u"'        );
    like($result->stdout, qr/^q.+u.+u.+x$/ms, 'quux - matched "u"'       );
    like($result->stdout, qr/^corge$/ms,      'corge - no match for "u"' );
    like($result->stdout, qr/^gra.+u.+lt$/ms, 'grault - matched "u"'     );
    like($result->stdout, qr/^garply$/ms,     'garply - no match for "u"');
    like($result->stdout, qr/^waldo$/ms,      'waldo - no match for "u"' );
    like($result->stdout, qr/^fred$/ms,       'fred - no match for "u"'  );
    like($result->stdout, qr/^pl.+u.+gh$/ms,  'plugh - matched "u"'      );
    like($result->stdout, qr/^xyzzy$/ms,      'xyzzy - no match for "u"' );
    like($result->stdout, qr/^th.+u.+d$/ms,   'thud - matched "u"'       );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## full-line
{
    open_words_txt_as_stdin();

    my $result = test_app('App::highlight' => [ '--full-line', 'u' ]);

    like($result->stdout, qr/^foo$/ms,        'foo - no match for "u" (full-line mode)'   );
    like($result->stdout, qr/^bar$/ms,        'bar - no match for "u" (full-line mode)'   );
    like($result->stdout, qr/^baz$/ms,        'baz - no match for "u" (full-line mode)'   );
    like($result->stdout, qr/^.+qux.+$/ms,    'qux - matched "u" (full-line mode)'        );
    like($result->stdout, qr/^.+quux.+$/ms,   'quux - matched "u" (full-line mode)'       );
    like($result->stdout, qr/^corge$/ms,      'corge - no match for "u" (full-line mode)' );
    like($result->stdout, qr/^.+grault.+$/ms, 'grault - matched "u" (full-line mode)'     );
    like($result->stdout, qr/^garply$/ms,     'garply - no match for "u" (full-line mode)');
    like($result->stdout, qr/^waldo$/ms,      'waldo - no match for "u" (full-line mode)' );
    like($result->stdout, qr/^fred$/ms,       'fred - no match for "u" (full-line mode)'  );
    like($result->stdout, qr/^.+plugh.+$/ms,  'plugh - matched "u" (full-line mode)'      );
    like($result->stdout, qr/^xyzzy$/ms,      'xyzzy - no match for "u" (full-line mode)' );
    like($result->stdout, qr/^.+thud.+$/ms,   'thud - matched "u" (full-line mode)'       );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}
