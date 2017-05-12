#!/usr/bin/perl

use lib '/home/ron/perl5/lib/perl5/';
use common::sense;

use CGI;
use CGI::Untaint;

use Text::Xslate;

# ---------------

my($cgi)       = CGI -> new;
my($dir_name)  = '/dev/shm/html';
my($file_name) = 'test.untaint.html';
my($templater) = Text::Xslate -> new
(
	input_layer => '',
	path        => $dir_name,
);
my($handler) = CGI::Untaint -> new(map{ $_ => $cgi -> param($_) } $cgi -> param);
my($file)    = $handler -> extract(-as_upload => 'name');
my($param)   =
{
		filename => $$file{filename},
		payload  => $$file{payload},
};

print $cgi -> header, $templater -> render($file_name, $param);
