use strict;
use warnings;
use utf8;

use Fennec::Declare class => 'DSL::HTML::Compiler';

BEGIN { use_ok $CLASS }

my $perl = compile_from_html( 'foo', <<EOT ) || die $!;
<html>
    <head>
        <title>foo</title>
        <link href="b.css" rel="stylesheet" type="text/css" />
        <script src="a.js"></script>
    </head>

    <body>
        <div id="foo" class="bar baz">
            xxx
        </div>
        <p>
        yyyy
        <div id="foo" class="bar baz">
            xxx
        </div>
    </body>
</html>
EOT

my $want = <<EOT;
use strict;
use warnings;
use utf8;
use DSL::HTML;

template foo {
    tag head {
        tag title {
            text q'foo';
        }

        css q'b.css';

        js q'a.js';
    }

    tag div('class' => q'bar baz', 'id' => q'foo') {
        text q' xxx ';
    }

    tag p {
        text q' yyyy ';

        tag div('class' => q'bar baz', 'id' => q'foo') {
            text q' xxx ';
        }
    }
}

1;
EOT

is($perl, $want, "Got generated perl");

done_testing;
