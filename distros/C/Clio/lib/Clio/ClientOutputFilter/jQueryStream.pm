
package Clio::ClientOutputFilter::jQueryStream;
BEGIN {
  $Clio::ClientOutputFilter::jQueryStream::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::ClientOutputFilter::jQueryStream::VERSION = '0.02';
}
# ABSTRACT: Client output filter for jQueryStream

use strict;
use Moo::Role;


around 'handshake' => sub {
    my $orig = shift;
    my $self = shift;

    $self->log->trace(__PACKAGE__, " in use for handshake");
    my $msg = $self->id
            .';'.
            " " x 1024
            .';';

    $self->writer->write( $msg );

    $self->$orig( @_ );
};


around 'write' => sub {
    my $orig = shift;
    my $self = shift;

    $self->log->trace(__PACKAGE__, " in use for write");

    $self->$orig(
        map {
            length($_)
            .';'.
            $_
            .";\r\n"
        } @_
    );

};

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Clio::ClientOutputFilter::jQueryStream - Client output filter for jQueryStream

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Output filter for L<jQueryStream 1.2|https://code.google.com/p/jquery-stream/>.

=head1 METHODS

=head2 handshake

Initial handshake sends client's ID.

=head2 write

Wraps message in format required by jQueryStream.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

