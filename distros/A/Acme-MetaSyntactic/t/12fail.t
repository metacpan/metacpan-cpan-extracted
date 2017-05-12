use Test::More tests => 1;

require Acme::MetaSyntactic;
eval { import Acme::MetaSyntactic 'this_theme_does_not_exist'; };
like( $@, qr!^Can't locate Acme/MetaSyntactic/this_theme_does_not_exist.pm in \@INC!,
      "No such theme");

