package Chart::GGPlot::HasLabeller;

# ABSTRACT: The role for the 'labeller' attr

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.002001'; # VERSION

use Types::Standard qw(CodeRef Str);

use Chart::GGPlot::Types qw(Labeller);


has labeller => (
    is      => 'ro',
    isa     => Labeller,
    default => 'value',
    coerce  => 1
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::HasLabeller - The role for the 'labeller' attr

=head1 VERSION

version 0.002001

=head1 ATTRIBUTES

=head2 labeller

A L<Chart::GGPlot::Labeller> object, or a string of one of

for :list
*C<"value">
Only displays the value of a factor.
*C<"both">
Displays both the variable name and the factor.
*C<"context">
Context-dependent and uses C<"value"> for single factor
faceting and C<"both"> when multiple factors are involved.

=head1 SEE ALSO

L<Chart::GGPlot::Facet>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
