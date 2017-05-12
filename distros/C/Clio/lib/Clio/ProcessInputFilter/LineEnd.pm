
package Clio::ProcessInputFilter::LineEnd;
BEGIN {
  $Clio::ProcessInputFilter::LineEnd::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::ProcessInputFilter::LineEnd::VERSION = '0.02';
}
# ABSTRACT: Process input filter appending LF

use strict;
use Moo::Role;


around 'write' => sub {
    my $orig = shift;
    my $self = shift;

    $self->log->trace(__PACKAGE__, " in use for write");

    $self->$orig(
        map { $_ !~ /\n\z/s ? "$_\n" : $_ } @_
    );
};

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Clio::ProcessInputFilter::LineEnd - Process input filter appending LF

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Input filter which will append C<\n> if needed.

=head1 METHODS

=head2 write

Append C<\n> if needed.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

