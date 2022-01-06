package Chart::GGPlot::HasNonMissingAes;

# ABSTRACT: The role for the 'non_missing_aes' attr

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Types::Standard qw(ArrayRef);


has non_missing_aes => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::HasNonMissingAes - The role for the 'non_missing_aes' attr

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 non_missing_aes

This attr is for specifying additional variables to be used in
C<remove_missing()>.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
