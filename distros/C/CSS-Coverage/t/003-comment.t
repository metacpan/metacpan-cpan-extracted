use strict;
use warnings;
use Test::More;
use CSS::Coverage;

my @documents = (\"
    <html>
        <body>
            <p>Hello <a onclick='foo();'>world</a>!</p>
        </body>
    </html>
");

{
    my $css = "
        a {
            font-weight: bold
        }

        a.clicked {
            text-decoration: line-through;
        }

        button {
            padding: 0;
        }

        a:hover {
            color: red;
        }
    ";

    my $report = CSS::Coverage->new(
        css       => \$css,
        documents => \@documents,
    )->check;

    is_deeply([$report->unmatched_selectors], ["a.clicked", "button"], "a.clicked didn't match");
}

{
    my $css = "
        a {
            font-weight: bold
        }

        a.clicked {
            /* coverage:ignore */
            text-decoration: line-through;
        }

        button {
            padding: 0;
        }

        a:hover {
            color: red;
        }
    ";

    my $report = CSS::Coverage->new(
        css       => \$css,
        documents => \@documents,
    )->check;

    is_deeply([$report->unmatched_selectors], ["button"], "a.clicked was ignored");
}

{
    my $css = "
        a {
            font-weight: bold
        }

        /* coverage:ignore */
        a.clicked {
            text-decoration: line-through;
        }

        button {
            padding: 0;
        }

        a:hover {
            color: red;
        }
    ";

    my $report = CSS::Coverage->new(
        css       => \$css,
        documents => \@documents,
    )->check;

    is_deeply([$report->unmatched_selectors], ["button"], "a.clicked was ignored");
}

done_testing;

