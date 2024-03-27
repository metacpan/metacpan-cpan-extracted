#!/usr/bin/perl
use warnings;
use strict;

# PODNAME: get-azure-token.pl
# ABSTRACT: Get JWT tokens from Azure

require Bundle::WATERKIP::CLI::Azure;
Bundle::WATERKIP::CLI::Azure->run()

__END__

=pod

=encoding UTF-8

=head1 NAME

get-azure-token.pl - Get JWT tokens from Azure

=head1 VERSION

version 0.002

=head1 SYNOPSIS

get-azure-token.pl --help [ OPTIONS ]

=head1 OPTIONS

=over

=item * --help (this help)

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
