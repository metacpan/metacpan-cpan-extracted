#!/usr/bin/perl
use warnings;
use strict;

# PODNAME: jwt-decrypt
# ABSTRACT: Decrypt JWT tokens

require Bundle::WATERKIP::CLI::JWT;
Bundle::WATERKIP::CLI::JWT->run()

__END__

=pod

=encoding UTF-8

=head1 NAME

jwt-decrypt - Decrypt JWT tokens

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
