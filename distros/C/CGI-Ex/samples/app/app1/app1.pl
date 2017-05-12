#!/usr/bin/perl

=head1 NAME

app1 - Signup application using bare CGI::Ex::App

 * configuration comes from conf file
 * steps are in separate modules

=cut

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use base qw(App1);

App1->navigate;
exit;
