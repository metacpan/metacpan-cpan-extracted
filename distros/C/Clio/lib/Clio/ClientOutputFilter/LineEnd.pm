
package Clio::ClientOutputFilter::LineEnd;
BEGIN {
  $Clio::ClientOutputFilter::LineEnd::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::ClientOutputFilter::LineEnd::VERSION = '0.02';
}
# ABSTRACT: Client output filter appending CRLF

use strict;
use Moo::Role;


around 'write' => sub {
    my $orig = shift;
    my $self = shift;

    $self->log->trace(__PACKAGE__, " in use for write");

    $self->$orig(
        map { $_ !~ /\r\n\z/s ? "$_\r\n" : $_ } @_
    );

};

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Clio::ClientOutputFilter::LineEnd - Client output filter appending CRLF

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Output filter which will append C<\r\n> if needed.

=head1 METHODS

=head2 write

Append C<\r\n> if needed.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

