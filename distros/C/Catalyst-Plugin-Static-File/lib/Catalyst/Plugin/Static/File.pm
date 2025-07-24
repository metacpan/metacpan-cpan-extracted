package Catalyst::Plugin::Static::File;

use v5.14;

# ABSTRACT: Serve a specific static file

use Moose::Role;

use File::Spec;
use File::stat;
use IO::File;
use Plack::MIME;
use Plack::Util;
use Try::Tiny;

use namespace::autoclean;

our $VERSION = 'v0.2.4';


sub serve_static_file {
    my ( $c, $path, $type ) = @_;

    my $res = $c->res;

    my $abs = File::Spec->rel2abs("$path");

    try {

        # Ideally we could let the file open fail when a file does not exist, but this seems to cause the process to
        # exit in a way that try/catch cannot handle on some systems.  We can risk a potential race condition where the
        # file disappears between the existence check and opening: the worst case is that it would have the same effect
        # as not checking for file existence.

        die "No such file or directory" unless -e $abs;

        my $fh = IO::File->new( $abs, "r" ) or die $!;

        binmode($fh);
        Plack::Util::set_io_path( $fh, $abs );
        $res->body($fh);

        $type //= Plack::MIME->mime_type($abs);

        my $headers = $res->headers;
        $headers->content_type("$type");

        my $stat = stat($fh);
        $headers->content_length( $stat->size );
        $headers->last_modified( $stat->mtime );

    }
    catch {

        my $error = $_;
        Catalyst::Exception->throw("Unable to open ${abs} for reading: ${error}");

    };

    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Static::File - Serve a specific static file

=head1 VERSION

version v0.2.4

=head1 SYNOPSIS

In your Catalyst class:

  use Catalyst qw/
      Static::File
    /;

In a controller method:

  $c->serve_static_file( $absolute_path, $type );

=head1 DESCRIPTION

This plugin provides a simple method for your L<Catalyst> app to send a specific static file.

Unlike L<Catalyst::Plugin::Static::Simple>,

=over

=item *

It only supports serving a single file, not a directory of static files. Use L<Plack::Middleware::Static> if you want to
serve multiple files.

=item *

It assumes that you know what you're doing. If the file does not exist, it will throw an fatal error.

=item *

It uses L<Plack::MIME> to identify the content type, but you can override that.

=item *

It adds a file path to the file handle, and plays nicely with L<Plack::Middleware::XSendfile> and L<Plack::Middleware::ETag>.

=item *

It does not log anything.

=back

=head1 METHODS

=head2 serve_static_file

  $c->serve_static_file( $absolute_path, $type );

This serves the file in C<$absolute_path>, with the C<$type> content type.

If the C<$type> is omitted, it will guess the type using the filename.

It will also set the C<Last-Modified> and C<Content-Length> headers.

It returns a true value on success.

If you want to use conditional requests, use L<Plack::Middleware::ConditionalGET>.

=head1 SECURITY CONSIDERATIONS

The L<serve_static_file> method does not validate the file that is passed to it.

You should ensure that arbitrary filenames are not passed to it. You should strictly validate any external data that is
used for generating the filename.

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::Plugin::Static::Simple>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Catalyst-Plugin-Static-File>
and may be cloned from L<git://github.com/robrwo/Catalyst-Plugin-Static-File.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.14 or later.  Future releases may only support Perl versions released in the last ten
years.

This module requires Catalyst v5.90129 or later.

=head2 Bugs

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Catalyst-Plugin-Static-File/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
