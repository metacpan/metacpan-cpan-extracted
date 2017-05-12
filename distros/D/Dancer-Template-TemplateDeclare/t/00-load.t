use strict;
no warnings;

use Test::More tests => 1;
use Dancer 1.3050 qw/ :tests /;

BEGIN {
    use_ok( 'Dancer::Template::TemplateDeclare' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::TemplateDeclare $Dancer::Template::TemplateDeclare::VERSION, Dancer $Dancer::VERSION, Perl $], $^X" );
