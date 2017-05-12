package Catalyst::Plugin::Upload::Digest;
our $VERSION = '0.03';
use strict;

use Catalyst::Request::Upload;
use Digest;

{
    package Catalyst::Request::Upload;
our $VERSION = '0.03';

    sub digest {
        my $self = shift;

        Digest->new( @_ )->addfile( $self->fh );
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Upload::Digest - Compute digest of uploads with L<Digest>

=head1 SYNOPSIS

    use Catalyst qw< Upload::Digest >;

    if ( my $upload = $c->request->upload( 'field' ) ) {
        # Get Digest::Whirlpool object
        my $whirlpool = $upload->digest( 'Whirlpool' );

        # Get the digest of the uploaded file, addfile() has already
        # been called on its filehandle.
        my $hexdigest = $whirlpool->hexdigest;

        # I want a SHA-512 digest too!
        my $sha512digest = $upload->digest( 'SHA-512' )->digest;
    }

=head1 DESCRIPTION

Extends C<Catalyst::Request::Upload> with a L</digest> method that
wraps L<Digest>'s L<construction|Digest/"OO INTERFACE"> method. Any
arguments to it will be passed directly to Digest's constructor. The
return value is the relevant digest object that has already been
populated with the file handle of the uploaded file, so retrieving its
digest will work as expected.

=head1 EXAMPLE

This module is distributed with a Catalyst example application called
B<Upload::Digest>, see the F<example/Upload-Digest> directory in this
distribution for how to run it.

=head1 CAVEATS

To avoid being overly smart the C<digest> method does not cache the
digest for a given upload object / algorithm pair. If it is required
to get the digest for a given file at two separate places in the
program the user may wish to store the result somewhere to improve
performance, or no do so because the speed of popular digest is likely
not to become a bottleneck for most files.

=head1 BUGS

Please report any bugs that aren't already listed at
L<http://rt.cpan.org/Dist/Display.html?Queue=Catalyst-Plugin-Upload-Digest> to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Catalyst-Plugin-Upload-Digest>

=head1 SEE ALSO

L<Digest>, L<Catalyst::Request::Upload>

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
