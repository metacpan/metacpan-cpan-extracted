package Catalyst::DispatchType::LocalRegex;

use Moose;
extends 'Catalyst::DispatchType::Regex';
has '+_attr' => ( default => 'LocalRegex' );

=head1 NAME

Catalyst::DispatchType::LocalRegex - LocalRegex DispatchType

=head1 SYNOPSIS

See L<Catalyst::DispatchType>.

=head1 DESCRIPTION

B<Status: Deprecated.> Regex dispatch types have been deprecated and removed
from Catalyst core. It is recommend that you use Chained methods or other
techniques instead. As part of the refactoring, the dispatch priority of
Regex vs Regexp vs LocalRegex vs LocalRegexp may have changed. Priority is now
influenced by when the dispatch type is first seen in your application.

When loaded, a warning about the deprecation will be printed to STDERR. To
suppress the warning set the CATALYST_NOWARN_DEPRECATE environment variable to
a true value.

Dispatch type managing path-matching behaviour using regexes.  For
more information on dispatch types, see:

=over 4

=item * L<Catalyst::Manual::Intro> for how they affect application authors

=item * L<Catalyst::DispatchType> for implementation information.

=back

=cut

around '_get_attributes' => sub {
    my ( $orig, $self, $c, $action ) = splice( @_, 0, 4 );
    my @attributes = $self->$orig( $c, $action, @_ );
    return map { $self->_parse_LocalRegex_attr( $c, $action, $_ ) }
        @attributes;
};

sub _parse_LocalRegex_attr {
    my ( $self, $c, $action, $value ) = @_;
    unless ( $value =~ s/^\^// ) { $value = "(?:.*?)$value"; }

    my $prefix = $action->namespace();
    $prefix .= '/' if length( $prefix );

    return "^${prefix}${value}";
}

no Moose;

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
