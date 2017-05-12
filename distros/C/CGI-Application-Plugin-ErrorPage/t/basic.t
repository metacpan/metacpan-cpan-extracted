
package foo;

use base CGI::Application;
use CGI::Application::Plugin::ErrorPage 'error';

no warnings 'redefine';
sub error {
     my $c = shift;
     return $c->CGI::Application::Plugin::ErrorPage::error(
         tmpl => \'Surprise! <tmpl_var title> <tmpl_var msg>',
         @_,
     );
}


package main;
use Test::More 'no_plan';

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
my $q = CGI->new;
$q->param('rm' => 'missing'); 
my $foo = foo->new( QUERY => $q );

is( 
    $foo->error( title => 'Technical Failure', msg   => 'BOOM!'),
    'Surprise! Technical Failure BOOM!',
);

like(
    $foo->run,
    qr/\QSurprise! The requested page was not found. (The page tried was: missing)/,
    "testing AUTOLOAD default functionality" 
);
