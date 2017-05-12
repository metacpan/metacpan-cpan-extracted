use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';
use Test::Class::Load ':all';

my $file = __FILE__;

{
# line 1
    eval { load_class('Class::NonExistent') };
    my $e = $@;

    unlike(
        $e,
        qr/at .+Load\.pm line \d+/,
        'load_class exception does not refer to Class::Load internals'
    );

    unlike(
        $e,
        qr/at .+Runtime\.pm line \d+/,
        'load_class exception does not refer to Module::Runtime internals'
    );

    like(
        $e,
        qr/Can't locate [^\n]+ at \Q$file\E line 1/,
        'error appears from the spot that called load_class'
    );
}

{
    my ( $ok, $e ) = try_load_class('Class::NonExistent::Take2');

    unlike(
        $e,
        qr/at .+Load\.pm line \d+/,
        'try_load_class exception does not refer to Class::Load internals'
    );

    unlike(
        $e,
        qr/at .+Runtime\.pm line \d+/,
        'try_load_class exception does not refer to Module::Runtime internals'
    );
}

{
# line 2
    eval { load_first_existing_class('Class::NonExistent::Take3') };
    my $e = $@;

    unlike(
        $e,
        qr/at .+Load\.pm line \d+/,
        'load_first_existing_class exception does not refer to Class::Load internals'
    );

    unlike(
        $e,
        qr/at .+Runtime\.pm line \d+/,
        'load_first_existing_class exception does not refer to Module::Runtime internals'
    );

    like(
        $e,
        qr/Can't locate [^\n]+ at \Q$file\E line 2/,
        'error appears from the spot that called load_first_existing_class'
    );
}

{
# line 3
    eval { load_first_existing_class('Class::Load::SyntaxError') };
    my $e = $@;

    unlike(
        $e,
        qr/at .+Load\.pm line \d+/,
        'load_first_existing_class exception does not refer to Class::Load internals'
    );

    unlike(
        $e,
        qr/at .+Runtime\.pm line \d+/,
        'load_first_existing_class exception does not refer to Module::Runtime internals'
    );

    like(
        $e,
        qr/Compilation failed .+? at \Q$file\E line 3/s,
        'error appears from the spot that called load_first_existing_class'
    );
}

{
# line 4
    eval { load_optional_class('Class::Load::SyntaxError') };
    my $e = $@;

    unlike(
        $e,
        qr/at .+Load\.pm line \d+/,
        'load_optional_class exception does not refer to Class::Load internals'
    );

    unlike(
        $e,
        qr/at .+Runtime\.pm line \d+/,
        'load_optional_class exception does not refer to Module::Runtime internals'
    );

    like(
        $e,
        qr/Compilation failed .+? at \Q$file\E line 4/s,
        'error appears from the spot that called load_optional_class'
    );
}

done_testing();
