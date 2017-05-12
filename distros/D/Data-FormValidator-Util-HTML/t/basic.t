use strict;
use Test::More qw/no_plan/;

my $html = '<input type="text" name="field">';

BEGIN { use_ok( 'Data::FormValidator::Util::HTML' ); };

eval { add_error_tokens(html=>\$html); };
ok(!$@, 'super basic reality check of defaults');

my $out = add_error_tokens(html=>\$html);
like($out,qr/<!-- tmpl_var name="err_field" -->/, 'testing defaults');

$out = add_error_tokens(html=>\$html,prefix=>'magnetic_',);
like($out,qr/<!-- tmpl_var name="magnetic_field" -->/, 'testing custom prefix ');

$out = add_error_tokens(html=>\$html,prefix=>'',);
like($out,qr/<!-- tmpl_var name="field" -->/, 'testing no prefix ');

eval { add_error_tokens(html=>\$html,style=>'nope') };
ok($@, 'expecting to die with non-existent style');

$out = add_error_tokens(html=>\$html,prefix=>'err_',prepend=>'[');
like($out,qr/\[err_field/, 'testing prepend ');

$out = add_error_tokens(html=>\$html,prefix=>'err_',append=>']');
like($out,qr/err_field\]/, 'testing append');
