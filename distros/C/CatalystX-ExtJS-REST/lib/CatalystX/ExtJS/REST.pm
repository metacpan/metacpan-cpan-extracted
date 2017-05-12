#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::ExtJS::REST;
$CatalystX::ExtJS::REST::VERSION = '2.1.3';
# ABSTRACT: Feature-rich REST controller for use with ExtJS

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ExtJS::REST - Feature-rich REST controller for use with ExtJS

=head1 VERSION

version 2.1.3

=head1 SYNOPSIS

 package MyApp::Controller::User;
 
 use Moose;
 BEGIN { extends 'CatalystX::Controller::ExtJS::REST' }
 
 __PACKAGE__->config( default_resultset => 'User',
                     forms             => {
                              default => [
                                  { name => 'id' },
                                  { name => 'email', constraint => 'Required' },
                                  { name => 'password' }
                              ],
                     } );
 
 1;

=head1 DESCRIPTION

This module adds feature-rich REST controllers to your application.

L<CatalystX::Controller::ExtJS::REST> gives examples and describes 
all configuration options.

Have a look at the L<tutorial|CatalystX::ExtJS::Tutorial::Direct>
which shows integration of this controller with L<CatalystX::ExtJS::Direct>.

=head1 SEE ALSO

=over 4

=item L<CatalystX::ExtJS>

Parent namespace. Includes examples and the code for the tutorial.

=item L<CatalystX::ExtJS::Direct>

Enable Ext.Direct in Catalyst controllers.

=back

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
