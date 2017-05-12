#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2013 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Approx ;
{
  $Config::Model::Approx::VERSION = '1.009';
}

1 ;

=head1 NAME

Config::Model::Approx - Approx configuration file editor

=head1 SYNOPSIS

 # full blown editor
 sudo cme edit approx
 
 # command line use
 sudo cme modify approx distributions:multimedia=http://www.debian-multimedia.org

 use Config::Model ;
 my $model = Config::Model -> new ( ) ;

 my $inst = $model->instance (root_class_name   => 'Approx');
 my $root = $inst -> config_root ;

 $root->load("distributions:multimedia=http://www.debian-multimedia.org") ;

 $inst->write_back() ;

=head1 DESCRIPTION

This module provides a configuration editor for Approx. Running L<cme> as root
will update C</etc/approx/approx.conf>.

Once this module is installed, you can run:

 # cme edit approx

This module and Config::Model can also be used from Perl programs to
modify safely the content of F</etc/approx/approx.conf>.

The Perl API is documented in L<Config::Model> and mostly in
L<Config::Model::Node>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

   Copyright (c) 2009,2012 Dominique Dumont.

   This file is part of Config-Model-Approx.

   Config-Model-Approx is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser Public License as
   published by the Free Software Foundation; either version 2.1 of
   the License, or (at your option) any later version.

   Config-Xorg is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with Config-Model; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

=head1 SEE ALSO

L<cme>, L<Config::Model>,
