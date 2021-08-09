#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use 5.014;

use Test::More tests => 1;

sub _lines2re
{
    return join( qq#\r?\n#, @_ ) . qq#\r?\n?#;
}

sub test_tac
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($args) = @_;

    my @files = @{ $args->{files} };
    my @flags = @{ $args->{flags} };
    my $blurb = $args->{blurb};

    # die "@flags @files";
    my $re = _lines2re( @{ $args->{lines} } );
    subtest "tac-n $blurb" => sub {
        plan tests => 2;

        like( scalar(`$^X -Ilib bin/tac-n @flags @files`),
            qr#\A$re\z#ms, $args->{blurb} );

        like(
            scalar(
                `$^X -Ilib -E "use App::Tac_n; App::Tac_n->run()" @flags @files`
            ),
            qr#\A$re\z#ms,
            $args->{blurb}
        );
    };
    return;
}

# TEST
test_tac(
    {
        blurb => "single file tac-n",
        files => [qw( t/data/sort/three-words.txt )],
        flags => [qw/ /],
        lines => [ split /\n/, <<'EOF'],
\s*8\s+the wonderful unicorn
\s*7\s+based little mint
\s*6\s+the meta protocol
\s*5\s+a little love
\s*4\s+mooing persistent cat
\s*3\s+mooing yodelling dog
\s*2\s+row by row
\s*1\s+column by pencil
EOF
    }
);

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2021 by Shlomi Fish

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
