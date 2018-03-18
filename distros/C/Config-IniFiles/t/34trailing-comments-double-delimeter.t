#!/usr/bin/perl

# See: https://rt.cpan.org/Ticket/Display.html?id=105255
# RT #105255

use strict;
use warnings;

use Test::More tests => 1;

use Config::IniFiles;

# Test of handle_trailing_comment enabled
{
    my $ini_contents = <<'EOF';
[MySect]
key=val ; a comment ; further comment

EOF

    my $cfg = Config::IniFiles->new(
        -file                    => \$ini_contents,
        -handle_trailing_comment => 1,
    );

    # TEST
    is( scalar( $cfg->val( "MySect", "key" ) ),
        "val", "Value with a double trailing comment." );
}

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2015 by Shlomi Fish

This program is distributed under the MIT (X11) License:
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
