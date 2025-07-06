package CSAF::Options::Writer;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
with 'CSAF::Util::Options';

use constant TRUE  => !!1;
use constant FALSE => !!0;

has update_index   => (is => 'rw', default => TRUE);
has update_changes => (is => 'rw', default => TRUE);

has create_sha256_integrity => (is => 'rw', default => TRUE);
has create_sha512_integrity => (is => 'rw', default => TRUE);
has create_gpg_signature    => (is => 'rw', default => FALSE);

has gpg_passphrase => (is => 'rw');
has gpg_key        => (is => 'rw');

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Options::Writer - CSAF::Writer configurator

=head1 SYNOPSIS

    use CSAF::Options::Writer;
    my $options = CSAF::Options::Writer->new( );

    $options->configure(
        create_sha256_integrity => 0,
        create_gpg_signature    => 1,
        update_index            => 1,
        update_changes          => 1
    );

    if (my $passphrase = get_passphrase_from_stdin) {
        $options->gpg_passphrase($passphrase);
    }


=head1 DESCRIPTION

L<CSAF::Options::Writer> is a configurator of L<CSAF::Writer>.


=head2 METHODS

L<CSAF::Options::Writer> inherits all methods from L<CSAF::Util::Options>.


=head2 ATTRIBUTES

=over

=item update_index

Create and update the C<index.txt> file (default C<TRUE>).

=item update_changes

Create and update the C<changes.csv> file (default C<TRUE>).

=item create_sha256_integrity

Create SHA256 integrity file C<*.sha256> for the provided CSAF document (default C<TRUE>).

=item create_sha512_integrity

Create SHA512 integrity file C<*.sha512> for the provided CSAF document (default C<TRUE>).

=item create_gpg_signature

Sign the CSAF document with GPG and create signature file C<*.sha256> (default C<FALSE>).

=item gpg_key

Specify the default GPG key.

=item gpg_passphrase

Specify the passphrase for the provided GPG key.

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

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
