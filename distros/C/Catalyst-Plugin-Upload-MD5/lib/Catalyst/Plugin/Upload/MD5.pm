package Catalyst::Plugin::Upload::MD5;

use strict;
use Catalyst::Request::Upload;
use Digest::MD5;

our $VERSION = '0.01';

{
    package Catalyst::Request::Upload;

    sub md5sum {
        my $self = shift;

        unless ( $self->{md5sum} ) {
            $self->{md5sum} = Digest::MD5->new->addfile( $self->fh )->hexdigest;
        }

        return $self->{md5sum};
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Upload::MD5 - Compute MD5 message digest of uploads

=head1 SYNOPSIS

    use Catalyst qw[Upload::MD5];
    
    if ( my $upload = $c->request->upload('field') ) {
        print $upload->md5sum;
    }


=head1 DESCRIPTION

Extends C<Catalyst::Request::Upload> with a MD5 message digest method.

=head1 METHODS

=over 4

=item md5sum

Returns an MD5 message digest of upload in hexadecimal form.

=back

=head1 SEE ALSO

L<Digest::MD5>, L<Catalyst::Request>, L<Catalyst::Request::Upload>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
