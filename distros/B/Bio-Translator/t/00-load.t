#!perl

use Test::More tests => 2;

BEGIN {
    use_ok('Bio::Translator');
    use_ok('Bio::Translator::Utils');
}

diag("Testing Bio::Translator $Bio::Translator::VERSION, Perl $], $^X");
