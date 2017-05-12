use strict;
use Test::More tests => 8;
use CGI::FCKeditor;

my $fck = CGI::FCKeditor->new();
ok( defined $fck, 'new() ok' );

$fck->set_name('fck');
ok( $fck->set_name eq 'fck', 'set_name() ok' );

$fck->set_base('/dir/');
ok( $fck->set_base eq '/dir/', 'set_base() ok' );

$fck->set_width('100%');
ok( $fck->set_width eq '100%', 'set_width() ok' );

$fck->set_height('500');
ok( $fck->set_height eq '500', 'set_height() ok' );

$fck->set_set('Basic');
ok( $fck->set_set eq 'Basic', 'set_set() ok' );

$fck->set_value('Read ME');
ok( $fck->set_value eq 'Read ME', 'set_value() ok' );

ok( $fck->fck, 'fck ok' );

