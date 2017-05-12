#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::JSON - JSON module wrapper
#
#  DESCRIPTION
#  Interface to the JSON (JavaScript Object Notation) encoder/decoder.  
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::JSON;

use strict;
use warnings;
use base 'Apache2::WebApp::Plugin';
use JSON;

our $VERSION = 0.10;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# new(\%config)
#
# Constructor method used to instantiate a new template object.

sub new {
    my $class  = shift;
    my $config = (ref $_[0] eq 'HASH') ? shift : { @_ };
    my $self   = bless( {}, $class );
    return $self->_init($config) || $class->error;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%params)
#
# Return to the caller a new JSON object.

sub _init {
    my ( $self, $params ) = @_;
    return new JSON;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin::JSON - JSON module wrapper

=head1 SYNOPSIS

  my $obj = $c->plugin('JSON')->method( ... );     # Apache2::WebApp::Plugin::JSON->method()

    or

  $c->plugin('JSON')->method( ... );

=head1 DESCRIPTION

Interface to the JSON (JavaScript Object Notation) encoder/decoder.

L<http://json.org>

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  JSON

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-JSON-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::JSON'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::JSON
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<JSON>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
