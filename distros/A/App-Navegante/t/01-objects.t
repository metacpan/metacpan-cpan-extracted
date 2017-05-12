#!perl -T

use Test::More tests => 2;

use App::Navegante::CGI;

my %args = ();
my $t = App::Navegante::CGI->new(%args);
isa_ok($t, "App::Navegante::CGI");

can_ok ($t, $_) for qw{ createCGI };
