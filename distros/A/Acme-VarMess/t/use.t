use Test::More tests => 4;

use_ok('Acme::VarMess');

$src =<<'.';
           use WWW::Mechanize;
           my $mech = WWW::Mechanize->new();

           $mech->get( $url );

           $mech->follow_link( n => 3 );
           $mech->follow_link( text_regex => qr/download this/i );
           $mech->follow_link( http://host.com/index. );
.

blow(\$src, 't/out');
ok(-e 't/out');
ok(Acme::VarMess::find('mech'));
ok(Acme::VarMess::find('url'));
