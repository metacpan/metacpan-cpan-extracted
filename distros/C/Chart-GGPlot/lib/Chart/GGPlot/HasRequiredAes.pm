package Chart::GGPlot::HasRequiredAes;

# ABSTRACT: The role for the 'required_aes' attr

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.0009'; # VERSION

use Types::Standard qw(ArrayRef);


classmethod required_aes() { [] }


method check_required_aes($aesthetics) {
    my %aesthetics = map { $_ => 1 } @$aesthetics;
    my $missing_aes = $self->required_aes->grep(sub { !exists $aesthetics{$_} } );
    return if @$missing_aes == 0;

    croak( sprintf("%s requires the following missing aesthetics: %s",
        ref($self), join( ', ', @$missing_aes ) ));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::HasRequiredAes - The role for the 'required_aes' attr

=head1 VERSION

version 0.0009

=head1 DESCRIPTION

=head1 CLASS METHODS

=head2 required_aes 

=head1 METHODS

=head2 check_required_aes($aesthetics)

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
