use Test::More qw(no_plan);
 
BEGIN { use_ok('A1z::HTML5::Template') };

my $h = new A1z::HTML5::Template;
is( $h->VERSION, 0.22, "Version 0.22");
is( $h->NAME, "Fast and Easy Web Apps", "A complete web page with just 3 lines of perl code");
like ( $h->head, qr/charset=UTF-8/i, "charset UTF-8 is set by default for default content-type");
like ( $h->body, qr/<\/body>/i, "Default - HTML5 compatible web page");
