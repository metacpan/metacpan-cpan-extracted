#!/usr/bin/perl

=head1 NAME

js.pl - simple @INC js printer

=head1 DESCRIPTION

This is necessary because app1.pl hard codes path.

=cut

use strict;
use warnings;

use CGI::Ex;
CGI::Ex->print_js($ENV{'PATH_INFO'});
