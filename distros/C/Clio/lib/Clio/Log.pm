
package Clio::Log;
BEGIN {
  $Clio::Log::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Log::VERSION = '0.02';
}
# ABSTRACT: Abstract base class for Clio::Log::* implementations

use strict;
use Moo;
use Carp qw( croak );

with 'Clio::Role::HasContext';


sub BUILD {
    my $self = shift;

    $self->init();
}


sub init { croak "Abstract method"; }


sub logger { croak "Abstract method"; }


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Log - Abstract base class for Clio::Log::* implementations

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    package Clio::Log::MyPackage;

    use Moo;

    extends qw( Clio::Log );

    sub init { ... }

    sub logger { ... }

=head1 DESCRIPTION

Base abstract class for Clio::Log::* implementations.

Logging classes are not to be used directly, but via L<Clio> context, as in:

    $c->log->trace( ... );
    $c->log->debug( ... );

Consumes the L<Clio::Role::HasContext>.

=head1 METHODS

=head2 init

Abstract method called at application start.

=head2 logger

Abstract method which should return the logger object.

=head1 SEE ALSO

=over 4

=item * L<Clio::Log::Log4perl>

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

