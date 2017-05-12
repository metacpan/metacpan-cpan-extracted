#!/home/berov/active_perl/bin/perl
package ourobscurepackage;
BEGIN {
    $ENV{SITE_ROOT}= "/opt/apache2/htdocs/recipes";
}
use utf8;
use strict;
use warnings;
use lib ( $ENV{SITE_ROOT}.'/perl/lib' );
use CGI::Ex::Recipes;
CGI::Ex::Recipes->new({
    'base_dir_abs' => $ENV{SITE_ROOT},
    'conf_path'=>'',
    'conf_die_on_fail'=>1,
    'conf_file' =>'conf/Recipes.conf' 
})->navigate();
