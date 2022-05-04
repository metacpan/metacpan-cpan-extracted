package MyParamApp;

use base qw/MyApp1/;
use CGI::Application::Plugin::RunmodeParseKeyword;

startmode test ($id) { "id=$id" }
runmode array (@stuff) {
    return "stuff=@stuff; input = [" . join( ", ", map { ">$_<" } @_) . "]"
        . scalar(@stuff) . " - " . scalar(@_);
}
1;

