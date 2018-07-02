#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2015-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Approx ;
$Config::Model::Approx::VERSION = '1.011';
use Config::Model 2.123;

1 ;

# ABSTRACT: Approx configuration file editor

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Approx - Approx configuration file editor

=head1 VERSION

version 1.011

=head1 SYNOPSIS

 # Check approx content
 cme check approx

 # full blown editor
 sudo cme edit approx

 # command line use
 sudo cme modify approx 'distributions:multimedia=http://www.debian-multimedia.org'

 # Perl API
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

=head1 BUGS

The configuration file is reformatted when written.

=head1 SEE ALSO

=over

=item *

L<cme>

=item *

L<Using cme wiki page|https://github.com/dod38fr/config-model/wiki/Using-cme>

=back

=head1 SEE ALSO

L<cme>, L<Config::Model>,

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2018 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
