#!perl

use strict;
use CGI::Application::Framework;
use CGI::Carp 'fatalsToBrowser';

CGI::Application::Framework->run_app(
    projects => '!!- relpath_projects_dir -!!',
);





