# -*- Mode: Perl; -*-

=head1 NAME

2_fill_11_target.t - Test CGI::Ex::Fill's ability to fill hidden fields

=cut

use strict;
use Test::More tests => 4;

use_ok('CGI::Ex::Fill');

my $form = <<EOF;
<FORM name="foo1">
<INPUT TYPE="TEXT" NAME="foo1" value="nada">
</FORM>
<FORM name="foo2">
<INPUT TYPE="TEXT" NAME="foo2" value="nada">
</FORM>
<FORM>
<INPUT TYPE="TEXT" NAME="foo3" value="nada">
</FORM>
EOF
  ;

my %fdat = (
  foo1 => 'bar1',
  foo2 => 'bar2',
  foo3 => 'bar3',
);

my $output = CGI::Ex::Fill::form_fill($form, \%fdat, 'foo2');

my @v = $output =~ m/<input .*?value="(.*?)"/ig;
ok($v[0] eq 'nada');
ok($v[1] eq 'bar2');
ok($v[2] eq 'nada');
