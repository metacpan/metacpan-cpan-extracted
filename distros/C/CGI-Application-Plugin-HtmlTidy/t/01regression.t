
use strict;
use Test::More tests => 3;

our $classname;
BEGIN{
	$classname = 'CGI::Application::Plugin::HtmlTidy';
	use_ok($classname);
}

### regression tests

use CGI::Application::Plugin::HtmlTidy;
# public methods
can_ok($classname, qw/htmltidy htmltidy_clean htmltidy_validate/);

# bundled config file
like($classname->__find_config(), qr!CGI/Application/Plugin/HtmlTidy/tidy.conf!, "Find our bundled config file");

