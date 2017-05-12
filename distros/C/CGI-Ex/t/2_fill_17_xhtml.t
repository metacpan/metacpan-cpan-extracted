# -*- Mode: Perl; -*-

=head1 NAME

2_fill_17_xhtml.t - Test CGI::Ex::Fill's ability to play nice with XHTML

=cut

use strict;
use Test::More tests => 2;

use_ok('CGI::Ex::Fill');

my $html = <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
<html>
<body>
    <input type="radio" name="status" value=0 />Canceled<br>
    <input type="radio" name="status" value=1 />Confirmed<br>
    <input type="radio" name="status" value=2 />Wait List<br>

    <input type="radio" name="status" value=3 />No Show<br>
    <input type="radio" name="status" value=4 />Moved to Another Class<br>
    <input type="radio" name="status" value=5 />Late Cancel<br>
</body>
</html>
EOF

my $q = {
    status => 1,
};

my $output = CGI::Ex::Fill::form_fill($html, $q);

my $matches;
while ($output =~ m!( />)!g) {
  $matches++;
}

ok($matches == 6,
   "Had correct matches ($output)");
