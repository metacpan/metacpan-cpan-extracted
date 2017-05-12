# -*- Mode: Perl; -*-

=head1 NAME

2_fill_13_password.t - Test CGI::Ex::Fill's ability to not fill passwords

=cut

use strict;
use Test::More tests => 3;

use_ok('CGI::Ex::Fill');

local $/;
my $html = qq{<input type="password" name="foo">};
my $q = {foo => 'bar'};

my $output = CGI::Ex::Fill::form_fill($html, $q, undef, 0);
ok($output !~ /value="bar"/);

$output = CGI::Ex::Fill::form_fill($html, $q, undef);
ok($output =~ /value="bar"/);



