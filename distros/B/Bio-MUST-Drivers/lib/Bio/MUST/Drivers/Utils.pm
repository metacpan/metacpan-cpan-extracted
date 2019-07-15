package Bio::MUST::Drivers::Utils;
# ABSTRACT: Utility functions for drivers
$Bio::MUST::Drivers::Utils::VERSION = '0.191910';
use strict;
use warnings;
use autodie;
use feature qw(say);

use Exporter::Easy (
    OK   => [ qw(stringify_args) ],
);


# TODO: add function for redirecting to /dev/null

sub stringify_args {
    my $args = shift // {};

    my @cli_args = map {                        # concat opts with args and
        join q{ }, $_, ( $args->{$_} // () )    # append boolean flags without
    } keys %{$args};                            # adding extra whitespace
    my $args_str = join q{ }, @cli_args;

    return $args_str;
}

1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Utils - Utility functions for drivers

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
