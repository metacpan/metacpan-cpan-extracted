use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::More tests => 18;
use App::Cmd::Tester;
use Test::AppHighlightWords;

use App::highlight;

## show bad spaces - highlight spaces which appear at the end of lines
{
    open_words_txt_as_stdin('words_with_spaces.txt');

    my $result = test_app('App::highlight' => [ '--show-bad-spaces' ]);

    like($result->stdout, qr/^test$/ms,                                  '"test" - no bad spaces'                                );
    like($result->stdout, qr/^test with spaces$/ms,                      '"test with spaces" - no bad spaces'                    );
    like($result->stdout, qr/^test with spaces on the end\S+    \S+$/ms, '"test with spaces on the end    " - matched bad spaces');
    like($result->stdout, qr/^just spaces on the next line$/ms,          '"just spaces on the next line" - no bad spaces'        );
    like($result->stdout, qr/^\S+        \S+$/ms,                        '"        " - matched bad spaces'                       );
    like($result->stdout, qr/^empty line next$/ms,                       '"empty line next" - no bad spaces'                     );
    like($result->stdout, qr/^$/ms,                                      '"" - no bad spaces'                                    );
    like($result->stdout, qr/^end of test$/ms,                           '"end of test" - no bad spaces'                         );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## show bad spaces - with --no-color
{
    open_words_txt_as_stdin('words_with_spaces.txt');

    my $result = test_app('App::highlight' => [ '--show-bad-spaces', '--no-color' ]);

    like($result->stdout, qr/^test$/ms,                            '"test" - no bad spaces'                                );
    like($result->stdout, qr/^test with spaces$/ms,                '"test with spaces" - no bad spaces'                    );
    like($result->stdout, qr/^test with spaces on the endXXXX$/ms, '"test with spaces on the end    " - matched bad spaces');
    like($result->stdout, qr/^just spaces on the next line$/ms,    '"just spaces on the next line" - no bad spaces'        );
    like($result->stdout, qr/^XXXXXXXX$/ms,                        '"        " - matched bad spaces'                       );
    like($result->stdout, qr/^empty line next$/ms,                 '"empty line next" - no bad spaces'                     );
    like($result->stdout, qr/^$/ms,                                '"" - no bad spaces'                                    );
    like($result->stdout, qr/^end of test$/ms,                     '"end of test" - no bad spaces'                         );

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();

}
