#!/usr/bin/perl -w

use strict ;
use warnings ;

my ($blog_configuration_file,  $blog_directory, $temporary_directory) =  @ARGV ; 

`cp -R $temporary_directory/* /your_server/plog` ;
`cp -R $blog_directory/elements/* /your_server/plog` ;
