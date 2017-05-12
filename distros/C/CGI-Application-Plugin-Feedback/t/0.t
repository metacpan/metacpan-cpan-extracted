use Test::Simple 'no_plan';
use lib './lib';
use lib './t';

ok( eval 'require CGI::Application::Plugin::Feedback' , 'require plugin evals ok');


$ENV{CGI_APP_RETURN_ONLY} = 1;



use CGIApp;

ok(1,'used module');

my $a = new CGIApp;

$a->feedback('Sentence one.');
$a->feedback('Sentence two.');
$a->feedback('Sentence three.');

ok( $a->run, 'ran 1');





# ------

$a->start_mode('show_feedback');


$a->feedback('sure, why not 2..');

ok( $a->run,'ran after');









