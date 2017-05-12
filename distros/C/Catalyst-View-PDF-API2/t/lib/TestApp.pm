package TestApp;
use strict;
use warnings;

use Catalyst;

$DB::single=1;

__PACKAGE__->config(
   'View::PDF::API2' => 
		    {
		     INCLUDE_PATH => __PACKAGE__->path_to('root','pdf_templates'),
		     COMPILE_EXT  => 'c',
		     TEMPLATE_EXTENSION => '.tt',
		     CATALYST_VAR => 'Catalyst',  
		    }
);



__PACKAGE__->setup;

1;
