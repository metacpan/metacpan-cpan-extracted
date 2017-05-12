#!perl -T

use Test::More tests => 1;

BEGIN
{
    use_ok('App::Math::Tutor') || BAIL_OUT "Couldn't load App::Math::Tutor!";
}

diag("Testing App::Math::Tutor $App::Math::Tutor::VERSION, Perl $], $^X");
