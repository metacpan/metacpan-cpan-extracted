
###
# AxKit::Plugin::DisableXSLTParams - Disable XSLT Params
# Robin Berjon <robin@knowscape.com>
# 26/11/2001 - v0.01
###

package AxKit::Plugin::DisableXSLTParams;
use strict;
use vars qw($VERSION);
$VERSION = '0.01';
# require 'AxKit', 1.5;

#-------------------------------------------------------------------#
# handler
#-------------------------------------------------------------------#
sub handler {
    my $r = shift;
    $r->notes('disable_xslt_params', 1);
}
#-------------------------------------------------------------------#


1;
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

AxKit::Plugin::DisableXSLTParams - Disable XSLT Params

=head1 SYNOPSIS

  # in your Apache conf
  AxAddPlugin  AxKit::Plugin::DisableXSLTParams

=head1 DESCRIPTION

Under normal circumstances, CGI params are passed on top the XSLT
processor. While this can be wanted, it can also have undesirable
effects. Some of those may match variable or other param names that
you use in your XSLT stylesheet, and having them forced upon you
by CGI params can lead to hard to locate bugs.

All you need to do to make them go away is to add this module to
your conf.

The patch that allows this module to work should have been in
AxKit 1.5 but unfortunately it somehow slipped. Currently you'll
need the CVS version of AxKit (see http://axkit.org/ for details on
how to get it) or wait until 1.5.1 or 1.6.

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001,2002 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

AxKit

=cut

