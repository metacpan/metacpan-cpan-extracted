package Chart::GGPlot::HasDefaultAes;

# ABSTRACT: The role for the 'default_aes' attr

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.0009'; # VERSION

use Types::Standard qw(InstanceOf);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Types qw(AesMapping);

has default_aes => (
    is      => 'ro',
    isa     => AesMapping,
    default => sub { Chart::GGPlot::Aes->new() },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::HasDefaultAes - The role for the 'default_aes' attr

=head1 VERSION

version 0.0009

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
