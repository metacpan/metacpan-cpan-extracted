package TestBlogApp;

use base qw/ Catalyst /;

use Catalyst qw/
	ConfigLoader
	Static::Simple	
/;

__PACKAGE__->config(
    'Plugin::ConfigLoader' => {
        file => __PACKAGE__->path_to('../../testblogapp.conf'),
     },
);


# Start the application
__PACKAGE__->setup;


1;
