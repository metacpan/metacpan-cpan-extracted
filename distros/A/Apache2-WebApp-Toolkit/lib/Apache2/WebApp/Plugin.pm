#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin - Base class for WebApp Toolkit plugins
#
#  DESCRIPTION
#  A simple mechanism for loading WebApp Toolkit plugins.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin;

use strict;
use warnings;
use base 'Apache2::WebApp::Base';
use Params::Validate qw( :all );

our $VERSION = 0.03;
our $AUTOLOAD;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# load($name)
#
# Include the class (plugin('class')) if it hasn't already been included.

sub load {
    my ($self, $name)
      = validate_pos(@_,
          { type => OBJECT },
          { type => SCALAR }
      );

    $name =~ s/\b(\w)/\u$1/g;

    my $package = "Apache2::WebApp::Plugin::$name";

    unless ( $package->can('isa') ) {
        eval "require $package";

        $self->error("Failed to load package '$package': $@") if $@;
    }

    if ( $package->can('new') ) {
        $self->{ uc($name) } = $package->new;
    }

    return $self->{ uc($name) };
}

#----------------------------------------------------------------------------+
# AUTOLOAD()
#
# Provides pseudo-methods for read-only access to various internal methods.
 
sub AUTOLOAD {
    my $self = shift;
    my $method;
    ($method = $AUTOLOAD) =~ s/.*:://g;
    return if ($method eq 'DESTROY');
    return $self->{ uc($method) };
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin - Base class for WebApp Toolkit plugins

=head1 SYNOPSIS

  my $obj = $c->plugin('Name')->method( ... );     # Apache2::WebApp::Plugin::Name->method

    or

  $c->plugin('Name')->method( ... );

=head1 DESCRIPTION

A simple mechanism for loading WebApp Toolkit plugins.

=head1 PLUGINS

There are many plugins that provide additional functionality to your web application.

L<Apache2::WebApp::Plugin::CGI> - Common methods for dealing with HTTP requests.

L<Apache2::WebApp::Plugin::Cookie> - Common methods for creating and manipulating web browser cookies.

L<Apache2::WebApp::Plugin::DateTime> - Common methods for dealing with Date/Time.

L<Apache2::WebApp::Plugin::DBI> - Database interface wrapper for MySQL, PostGre, and Oracle.

L<Apache2::WebApp::Plugin::File> - Common methods for processing and outputting files.

L<Apache2::WebApp::Plugin::Filters> - Common methods for filtering HTTP request parameters.

L<Apache2::WebApp::Plugin::JSON> - JSON module wrapper.

L<Apache2::WebApp::Plugin::Mail> - Methods for sending template based multi-format e-mail.

L<Apache2::WebApp::Plugin::Memcached> - Cache::Memcached module wrapper.

L<Apache2::WebApp::Plugin::Session> - Provides session handling methods.

L<Apache2::WebApp::Plugin::Session::File> - Store persistent data on the filesystem.

L<Apache2::WebApp::Plugin::Session::Memcached> - Store persistent data using memcached (memory cache daemon).

L<Apache2::WebApp::Plugin::Session::MySQL> - Store persistent data in a MySQL database.

L<Apache2::WebApp::Plugin::Validate> - Common methods used for validating user input.


=head1 INSTALLATION

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::Name'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::Name
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during 
this process to insure write permission is allowed within the intstallation directory.

=head1 SEE ALSO

L<Apache2::WebApp>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
