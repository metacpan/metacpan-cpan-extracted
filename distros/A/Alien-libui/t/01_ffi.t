use strict;
use warnings;
use Test::More;
use Test::Alien;
use lib '../blib/lib', './blib/lib';
use Alien::libui;
$|++;
#
alien_ok 'Alien::libui';
#
ffi_ok { symbols => ['uiFreeText'] }, with_subtest {
    my $ffi = shift;
    $ffi->load_custom_type( '::StringPointer' => 'string_pointer' );
    my $free_text = $ffi->function( uiFreeText => ['string_pointer'] => 'void' );
    my $line      = 'Hi';
    diag $line;
    $free_text->call( \$line );
    diag $line;
    pass 'Got this far...';

    #ok $line ne 'Hi'; # Windows just ignores this being freed
};
done_testing;
