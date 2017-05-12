#!/usr/bin/perl

# pdflink -- insert links into PDF files

# Author          : Johan Vromans
# Created On      : Thu Sep 15 11:43:40 2016
# Last Modified By: Johan Vromans
# Last Modified On: Mon Mar 20 09:52:26 2017
# Update Count    : 255
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::PDF::Link;

=head1 NAME

pdflink - insert document links in PDF documents

=head1 DESCRIPTION

B<pdflink> can read and rewrite PDF documents while adding links to
other documents at specified pages.

B<pdflink> is a wrapper around L<App::PDF::Link>, which does all
of the work.

=cut

################ Setup  ################

# Process command line options, config files, and such.
my $env = App::PDF::Link->app_setup( "pdflink", $App::PDF::Link::VERSION );

################ Activate ################

App::PDF::Link->run($env);

1;
