package AntDen;

use strict;
use warnings;

=head1 NAME

AntDen - A is a general computing platform

=cut

our $VERSION = '0.0.1';
our $PATH;

require 5.000;
require Exporter;
our @EXPORT_OK = qw( $PATH );
our @ISA = qw(Exporter);
use FindBin qw( $RealBin );

BEGIN{
   my @path;
   for( split /\//, $RealBin )
   {
       push @path, $_;
       last if $_ eq 'AntDen';
   }
   die 'nofind AntDenPATH' unless @path;
   $PATH = join '/', @path;
   $path[-1] = 'mydan';
   $ENV{MYDanPATH} = join '/', @path;
};

=head1 MODULES

=head3 Scheduler

platform scheduler
 
=head3 Controller

platform controller

=head3 Slave

platform slave

=head1 AUTHOR

Lijinfeng, C<< <lijinfeng2011 at github.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 lijinfeng2011.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1;
