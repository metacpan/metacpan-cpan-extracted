use strict;     
use Test::More tests => 37;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');



test_columns("book", "add", [ qw/ Title Author Genre Borrower Borrowed Format ISBN Publisher / ], [ qw/ Year / ] );

test_columns("book", "list", [ qw/ Borrower Author Genre Format Borrowed Title
                         ISBN / ], [qw/ Publisher Year Pages /]);

test_columns("borrower", "list", [ qw/ Email Name Url / ], [ qw/ Phone / ] );
test_columns("borrower", "add", [ qw/ Email Name Url Phone / ]);
test_columns("borrower", "view/1", [ qw/ Email Name Url Phone / ]);



sub test_columns {
    my ($controller, $action, $column_names, $missing_column_names) = @_;
    $missing_column_names ||= [];
    my $html;

    diag("Check column existance and naming (/$controller/$action)");
    ok($html = get("/$controller/$action"), "GET /$controller/$action ok");
    for my $name (@$column_names) {
        like($html, qr/$name/si, "  Colname ($name) ok");
    }

    for my $name (@$missing_column_names) {
        unlike($html, qr/$name/si, "  No colname ($name) ok");
    }
    
}


__END__
