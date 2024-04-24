package CSAF::Options::Downloader;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
with 'CSAF::Util::Options';

use constant TRUE  => !!1;
use constant FALSE => !!0;

has directory => (
    is      => 'rw',
    default => '.',
    coerce  => sub { my $dir = $_[0]; $dir =~ s{\$}{}; return $dir },
    isa     => sub { Carp::croak 'Unknown directory' unless -e -d $_[0] }
);

has exclude_pattern => (is => 'rw', default => FALSE);
has include_pattern => (is => 'rw', default => FALSE);

has validate        => (is => 'rw', default => FALSE);
has integrity_check => (is => 'rw', default => FALSE);
has signature_check => (is => 'rw', default => FALSE);

has parallel_downloads =>
    (is => 'rw', default => 4, isa => sub { Carp::croak "$_[0] is not a number" unless $_[0] =~ /^\d+$/ });

# TODO
has timeout_after_download =>
    (is => 'rw' => default => 0, isa => sub { Carp::croak "$_[0] is not a number" unless $_[0] =~ /^\d+$/ });

has url      => (is => 'rw');
has insecure => (is => 'rw', default => FALSE);

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Options::Downloader - CSAF::Downloader configurator

=head1 SYNOPSIS

    use CSAF::Options::Downloader;
    my $options = CSAF::Options::Downloader->new( );

    $options->configure(
        url             => 'https://security.acme.tld/advisories/csaf/index.txt',
        insecure        => 1,
        directory       => './csaf-acme-advisories',
        include_pattern => qr{acme-sa-2024-\d+\.json}
    );


=head1 DESCRIPTION

L<CSAF::Options::Downloader> is a configurator of L<CSAF::Downloader>.


=head2 METHODS

L<CSAF::Options::Downloader> inherits all methods from L<CSAF::Util::Options>.


=head2 ATTRIBUTES

=over

=item directory

=item exclude_pattern

=item include_pattern

=item insecure

=item integrity_check

=item parallel_downloads

=item signature_check

=item url

=item validate

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
