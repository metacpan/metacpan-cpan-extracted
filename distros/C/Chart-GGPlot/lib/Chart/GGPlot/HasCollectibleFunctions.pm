package Chart::GGPlot::HasCollectibleFunctions;

# ABSTRACT: The role for the 'ggplot_functions' classmethod

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.0003'; # VERSION


requires 'ggplot_functions';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::HasCollectibleFunctions - The role for the 'ggplot_functions' classmethod

=head1 VERSION

version 0.0003

=head1 DESCRIPTION

=head1 CLASS METHODS

=head2 ggplot_functions

    ggplot_functions()

Returns an arrayref like below,

    [
        {
            name => $func_name,
            code => $func_coderef,
            pod  => $pod,           # function doc
        },
        ...
    ]

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
