package MyApp2;

use MyApp1;
use base qw/MyApp1/;
use CGI::Application::Plugin::RunmodeDeclare;

startmode new_start { "start in subclass" }
errormode new_oops ($error) { "oops in MyApp2: $error" }
runmode arrest { die "arrest\n" }

1;

