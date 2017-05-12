#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::File - Plugin providing file handling methods
#
#  DESCRIPTION
#  Common methods for processing and outputting files.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::File;

use strict;
use warnings;
use base 'Apache2::WebApp::Plugin';
use MIME::Types;
use Params::Validate qw( :all );

our $VERSION = 0.07;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# open( \%controller, $file, $force_download )
#
# Open the file in a web browser window. 

sub open {
    my ( $self, $c, $file, $force_download )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF },
          { type => SCALAR  },
          { type => SCALAR, optional => 1 }
          );

    my ( $name, $mime_type ) = $file =~ /(\w+)\.(\w{3,4})\z/;

    $name =~ s/[^\w\s.]//g;   # strip invalid characters
    $name =~ s/^\s+//g;       # strip leading spaces
    $name =~ s/\s/_/g;        # fill in the gaps

    my $filename = "$name\.$mime_type";

    my $mt = MIME::Types->new;

    my $content_type = $mt->mimeTypeOf($mime_type);

    if ($force_download) {
        $c->request->headers_out->add( 'Cache-Control'       => 'private'                       );
        $c->request->headers_out->add( 'Content-disposition' => "attachment;filename=$filename" );
        $c->request->headers_out->add( 'Content-Type'        => $content_type                   );
        $c->request->headers_out();
    }
    else {
        $c->request->content_type($content_type);
    }

    my $buffer = "";

    # send file as a binary stream
    binmode STDOUT;

    local *FILE;
    open (FILE, $file) or $self->error("Cannot open file: $!");
    while ( read( FILE, $buffer, 4_096 ) ) {
        print STDOUT $buffer;
    }
    close(FILE);
    exit;
}

#----------------------------------------------------------------------------+
# download( \%controller, $file )
#
# Force the file as a web browser download. 

sub download {
    my ( $self, $c, $file ) = @_;

    $self->open( $c, $file, 1 );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%params)
#
# Return a reference of $self to the caller.

sub _init {
    my ( $self, $params ) = @_;
    return $self;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin::File - Plugin providing file handling methods

=head1 SYNOPSIS

  my $obj = $c->plugin('File')->method( ... );     # Apache2::WebApp::Plugin::File->method()

    or

  $c->plugin('File')->method( ... );

=head1 DESCRIPTION

Common methods for processing and outputting files.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  MIME::Types
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-File-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::File'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::File
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 open

Open the file in a web browser window.

  $c->plugin('File')->open( \%controller, '/path/to/file' );

=head2 download

Force the file as a web browser download.

  $c->plugin('File')->download( \%controller, '/path/to/file' );

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Apache2::Request>, L<MIME::Types>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
