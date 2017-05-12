use strict;
use Test::More;
unless ( -e '/usr/share/dict/words' ) {
   plan skip_all => 'No default dict file found';
}

plan tests => 4;
require_ok('Acme::POE::Acronym::Generator');
my $poegen = Acme::POE::Acronym::Generator->new( key => 'C1234    FEDDE' );
isa_ok( $poegen, 'Acme::POE::Acronym::Generator' );
my $string = $poegen->generate();
ok( $string, $string );
diag($string);
my @list = $poegen->generate();
ok( scalar @list == 6, join ' ', @list );
