package main;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 8;
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;
my $page = "books/edit";
$mech->get_ok( "http://localhost/$page?isbn=1234", "GET /$page" );

my $form = $mech->current_form;

ok( $form, "Form found" ) or BAIL_OUT("Can't do anything without a form");

is( $form->method, "GET", "Form set to POST method" );

my @inputs = $form->inputs;

is( scalar(@inputs), 7, "Form has expected number of fields" );

my $email = $form->find_input( "email", "text" );
ok( $email, "Found email field" );

if ( my $isbn = $form->find_input( "isbn", "text" ) ) {
    is( $isbn->value, "1234", "ISBN field stickiness set" );
}
else {
    fail("ISBN field not found");
}

$mech->submit();

if ( my $form = $mech->current_form ) {

    my %data = (
        'desc'   => '',
        'title'  => 'A Nestorian Collection of Christological Texts (Syriac)',
        'author' => 'Luise Abramowski',
        'isbn'   => '0521075785',
        'email'  => 'publisher@cambridge.org',
    );

    if ( my $_invalid_fields = $form->find_input( '_invalid_fields', 'hidden' ) ) {
        my @flds = split( /\|/, $_invalid_fields->value );
        ok( eq_array( [ sort @flds ], [qw/author isbn title/] ),
            "Expected invalid fields match" );
    }
    else {
        fail("Hidden field with piped list of invalid field names missing");
    }

    while ( my ( $k, $v ) = each %data ) {
        if ( my @input = $form->find_input($k) ) {
            $_->value($v) for @input;
        }
        else {
            fail("Missing '$k' field");
        }
    }

    $mech->submit();
    ok( $mech->content eq "VALID FORM", "Form submission expected to be valid" );
}
else {
    fail("Form is supposed to be redisplayed");
}

1;
