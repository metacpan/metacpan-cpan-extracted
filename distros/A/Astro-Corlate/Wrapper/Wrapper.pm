package Astro::Corlate::Wrapper;

=head1 NAME

Astro::Corlate::Wrapper - Perl extension for wrapping the F95 CORLATE routine.

=head1 SYNOPSIS

  use Astro::Corlate::Wrapper;

  corlate( $catalog, $observation, $log_file $variables,
           $fit_data, $fit_to_data, $histogram, $output );

=head1 DESCRIPTION

A wrapper module for the Fortran95 CORLATE subroutine. Shouldn't be used
directly, access should be through the Astro::Corlate module which provides
an object orientated interface to the routine, as well as handling file
read/writing and permissions.

=cut

# L O A D   M O D U L E S --------------------------------------------------

require 5.005_62;
use strict;
use vars qw($VERSION);
use warnings;
use Carp;
use AutoLoader qw(AUTOLOAD);

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Wrapper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( corlate ) ] );

our @EXPORT_OK = qw / corlate /;

our @EXPORT = qw / /;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

bootstrap Astro::Corlate::Wrapper $VERSION;

=head1 REVISION

$Id: Wrapper.pm,v 1.3 2001/12/12 03:32:15 aa Exp $

=cut

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;

__END__

