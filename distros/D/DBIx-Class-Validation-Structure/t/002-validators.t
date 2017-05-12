use strict;

use lib './local/lib/perl5';
use lib qw{ ./t/lib };

use utf8;

use Test::More;
use DBIx::Class::Validation::Structure;

# ----- Testing _val_email -----
subtest '_val_email' => sub {
    # Blank and mandatory
    subtest 'mandatory' => sub {
        my $mand = 1;
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_email( $mand, '' ) ],
            [ undef, { msg => 'address is blank or not valid' } ],
'a blank value should give "blank or not valid" error'
        );
    };

    subtest 'non-mandatory' => sub {
        my $mand = 0;
        # Malformated email
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_email( $mand, 'test' ) ],
            [ undef, { msg => 'address is blank or not valid' } ],
'a invalid value should give "blank or not valid" error'
        );

        # Undef and non-mandatory email
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_email( $mand, undef ) ],
            [''], 'is undefined should return blank' );

        # Blank and non-mandatory email
        is_deeply( [ DBIx::Class::Validation::Structure::_val_email( $mand, '' ) ],
            [''], 'is blank should return blank' );

        # Properly formatted email
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_email(
                    $mand, 'test@example.com'
                )
            ],
            ['test@example.com'],
            'a valid value should return the value'
        );
    };
};

# ----- Testing _val_text -----

subtest '_val_text' => sub {
    # Blank and mandatory
    subtest 'mandatory' => sub {
        my $mand = 1;
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_text( $mand, 32, '' ) ],
            [ undef, { msg => 'cannot be blank' } ],
            'a blank value should give "cannot be blank" error'
        );
    };

    subtest 'nom-mandatory' => sub {
        my $mand = 0;
        # Over length at 8 chars
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_text(
                    $mand, 8, 'abcdefghij'
                )
            ],
            [ undef, { msg => 'is limited to 8 characters' } ],
'length limited to 8 and a 10 character value should give "is limited to 8" error'
        );

        # Malformated text
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_text( $mand, 8, '•' ) ],
            [
                undef,
                {
                    msg =>
'can only use letters, 0-9 and -.,\'\"!&#$?:()[]=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)'
                }
            ],
'a invalid value should give "can only use letters..." error'
        );

        # Undef and non-mandatory text
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_text( $mand, 8, undef ) ],
            [undef], 'is undefined should return undef' );

        # Blank and non-mandatory text
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_text( $mand, 8, '' ) ],
            [''], 'is blank should return blank' );

        # Properly formatted text
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_text(
                    $mand, 32, 'Hello this is a test.'
                )
            ],
            ['Hello this is a test.'],
            'a valid value should return the value'
        );
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_text( $mand, 32, '0' ) ],
            ['0'],
'a falsy valid value should return the same value'
        );
    };
};

# ----- Testing _val_password -----

subtest '_val_password' => sub {
    subtest 'mandatory' => sub {
        my $mand = 1;
        # Blank and mandatory
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_password( $mand, 32, '' ) ],
            [ undef, { msg => 'cannot be blank' } ],
            'a blank value should give "cannot be blank" error'
        );
    };

    subtest 'non-mandatory' => sub {
        my $mand = 0;
        # Over length at 8 chars
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_password(
                    $mand, 8, 'abcdefghij'
                )
            ],
            [ undef, { msg => 'is limited to 8 characters' } ],
'Is non-Mandatory, length limited to 8 and a 10 character value should give "is limited to 8" error'
        );

        # Malformated password
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_password( $mand, 8, '•' ) ],
            [
                undef,
                {
                    msg =>
'can only use letters, 0-9 and -.,\'\"!&#$?:()[]=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)'
                }
            ],
'a invalid value should give "can only use letters..." error'
        );

        # Undef and non-mandatory password
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_password(
                    $mand, 8, undef
                )
            ],
            [undef],
            'is undefined should return undef'
        );

        # Blank and non-mandatory password
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_password( $mand, 8, '' ) ],
            [''], 'is blank should return blank' );

        # Properly formatted password
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_password(
                    $mand, 32, 'Hello this is a test.'
                )
            ],
            ['Hello this is a test.'],
            'a valid value should return the value'
        );

        # Properly formatted password with {}s
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_password(
                    $mand, 32, '$hash{asdfkl}'
                )
            ],
            ['$hash{asdfkl}'],
'a valid (with {}s) value should return the value'
        );
    };
};

# ----- Testing _val_int -----

subtest '_val_int' => sub {
    subtest 'mandatory' => sub {
        my $mand = 1;
        # Blank and mandatory
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_int( $mand, '' ) ],
            [ undef, { msg => 'cannot be blank' } ],
'a blank value should give "cannot be blank." error'
        );
    };

    subtest 'non-mandatory' => sub {
        my $mand = 0;
        # Malformated int
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_int( $mand, 'df' ) ],
            [ undef, { msg => 'can only use numbers' } ],
'a invalid value should give "can only use letters..." error'
        );

        # Blank and non-mandatory int
        is_deeply( [ DBIx::Class::Validation::Structure::_val_int( $mand, '' ) ],
            [''], 'is blank should return blank' );

        # Properly formatted int
        is_deeply( [ DBIx::Class::Validation::Structure::_val_int( $mand, -32 ) ],
            [-32],
            'a valid value should return the value' );
    };
};

# ----- Testing _val_selected -----

subtest '_val_selected' => sub {
    # Blank
    is_deeply(
        [ DBIx::Class::Validation::Structure::_val_selected('') ],
        [ undef, { msg => 'must be selected' } ],
        'A blank value should give "must be selected" error'
    );

    # Not Blank
    is_deeply( [ DBIx::Class::Validation::Structure::_val_selected(3) ],
        [3], 'A Valid value should return the value' );
};

# ----- Testing _val_number -----

subtest '_val_number' => sub {
    subtest 'mandatory' => sub {
        my $mand = 1;
        # Blank and mandatory
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_number( $mand, 8, '' ) ],
            [ undef, { msg => 'cannot be blank' } ],
'a blank value should give "cannot be blank." error'
        );
    };

    subtest 'non-mandatory' => sub {
        my $mand = 0;
        # Malformated number
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_number( $mand, 8, 'df' ) ],
            [ undef, { msg => 'can only use numbers and . or -' } ],
'a invalid value should give "can only use..." error'
        );

        # Blank and non-mandatory number
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_number( $mand, 8, '' ) ],
            [''], 'is blank should return blank' );

        # Over length number
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_number(
                    $mand, 8, 349237402348250
                )
            ],
            [ undef, { msg => 'is limited to 8 characters' } ],
'a valid value but over length should return the "is limited" error'
        );

        # Over length number again
        is_deeply(
            [
                DBIx::Class::Validation::Structure::_val_number(
                    $mand, 10, 349237402348250
                )
            ],
            [ undef, { msg => 'is limited to 10 characters' } ],
'a valid value but over length should return the "is limited" error'
        );

        # Properly formatted number
        is_deeply(
            [ DBIx::Class::Validation::Structure::_val_number( $mand, 8, -32 ) ],
            [-32],
            'a valid value should return the value'
        );
    };
};

done_testing;
