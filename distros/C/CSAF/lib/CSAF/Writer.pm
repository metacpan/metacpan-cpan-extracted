package CSAF::Writer;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use CSAF::Util qw(tracking_id_to_well_filename file_write gpg_sign);
use CSAF::Options::Writer;
use Digest::SHA           qw(sha256_hex sha512_hex);
use File::Basename        qw(basename dirname);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile);
use Tie::File;

use Moo;
extends 'CSAF::Base';
with 'CSAF::Util::Log';

use constant DEBUG => $ENV{CSAF_DEBUG};

has options => (
    isa   => sub { Carp::croak q{Not "CSAF::Options::Writer" object} unless ref($_[0]) eq 'CSAF::Options::Writer' },
    is    => 'lazy',
    build => 1,
);

sub _build_options { CSAF::Options::Writer->new }

has directory => (is => 'rw', required => 1, isa => sub { Carp::croak qq{Output directory not found} unless -d $_[0] });

sub write {

    my ($self) = @_;

    my $csaf_id                   = $self->csaf->document->tracking->id;
    my $csaf_json                 = $self->csaf->renderer->render;
    my $csaf_directory            = $self->directory;
    my $csaf_filename             = tracking_id_to_well_filename($csaf_id);
    my $csaf_file_year            = $self->csaf->document->tracking->initial_release_date->year;
    my $csaf_current_release_date = $self->csaf->document->tracking->current_release_date->datetime;

    my $json_file_path     = catfile($csaf_directory, $csaf_file_year, $csaf_filename);
    my $index_file_path    = catfile($csaf_directory, 'index.txt');
    my $changes_file_path  = catfile($csaf_directory, 'changes.csv');
    my $csaf_document_path = catfile($csaf_file_year, $csaf_filename);

    if (DEBUG) {
        $self->log->debug("Destination directory : $csaf_directory");
        $self->log->debug("CSAF document         : $csaf_filename");
        $self->log->debug("CSAF document path    : $json_file_path");
        $self->log->debug("index.txt path        : $index_file_path");
        $self->log->debug("changes.csv path      : $changes_file_path");
        $self->log->debug("SHA256 file path      : $json_file_path.sha256") if $self->options->create_sha256_integrity;
        $self->log->debug("SHA512 file path      : $json_file_path.sha512") if $self->options->create_sha512_integrity;
        $self->log->debug("Signature file path   : $json_file_path.asc")    if $self->options->create_gpg_signature;
    }

    make_path(dirname($json_file_path));

    $self->log->info("Save $csaf_id document ($csaf_filename)");

    file_write($json_file_path, $csaf_json);

    if ($self->options->create_sha256_integrity) {
        $self->log->info("Create SHA256 integrity file ($csaf_filename.sha256)");
        file_write("$json_file_path.sha256", sprintf("%s  %s\n", sha256_hex($csaf_json), $csaf_filename));
    }

    if ($self->options->create_sha512_integrity) {
        $self->log->info("Create SHA512 integrity file ($csaf_filename.sha512)");
        file_write("$json_file_path.sha512", sprintf("%s  %s\n", sha512_hex($csaf_json), $csaf_filename));
    }

    if ($self->options->create_gpg_signature) {

        $self->log->info("Sign CSAF document with GPG and create signature file ($csaf_filename.asc)");

        my $result = gpg_sign(
            key        => $self->options->gpg_key,
            passphrase => $self->options->gpg_passphrase,
            plaintext  => $csaf_json
        );

        DEBUG and $self->log->debug($_) for (split("\n", $result->{status}));

        if ($result->{exit_code} == 0) {
            file_write("$json_file_path.asc", $result->{stdout});
        }
        else {
            $self->log->error($result->{logger});
        }

    }

    if ($self->options->update_index) {

        $self->log->info("Update index.txt file ($index_file_path)");

        tie my @index_data, 'Tie::File', $index_file_path or Carp::croak "Unable to write $index_file_path";
        push @index_data, $csaf_document_path unless grep /^$csaf_document_path$/, @index_data;

        @index_data = ((), sort { $b cmp $a } @index_data);

    }

    if ($self->options->update_changes) {

        $self->log->info("Update changes.csv file ($changes_file_path)");

        my $changes_row = join ',', qq{"$csaf_document_path"}, qq{"$csaf_current_release_date"};

        tie my @changes_data, 'Tie::File', $changes_file_path or Carp::croak "Unable to write $changes_file_path";
        push @changes_data, $changes_row unless grep /^$changes_row$/, @changes_data;

        @changes_data = ((), sort { (split(/\,/, $b))[1] cmp(split(/\,/, $a))[1] } @changes_data);

    }

    return 1;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Writer - Write and distributes CSAF documents

=head1 SYNOPSIS

    use CSAF::Writer;

    my $writer = CSAF::Writer->new(
        csaf      => $csaf,
        directory => '/var/www/html/advisories/csaf'
    );

    $writer->options->configure(
        create_gpg_signature => 1
        gpg_key              => '0123456789',
        gpg_passphrase       => 'MY_C00L_Passphrase!'
    );

    if ($writer->write) {
        say "CSAF document created";
    }



=head1 DESCRIPTION

L<CSAF::Writer> covers most of the requirements of "Distributing CSAF documents".


=over

=item * 7.1.2 Requirement 2: Filename

=item * 7.1.11 Requirement 11: One folder per year

=item * 7.1.12 Requirement 12: index.txt

=item * 7.1.13 Requirement 13: changes.csv

=item * 7.1.18 Requirement 18: Integrity

=item * 7.1.19 Requirement 19: Signatures

=back

L<https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html>


=head2 METHODS

L<CSAF::Writer> inherits all methods from L<CSAF::Base> and implements the following new ones.

=over

=item $writer->write ( $directory_path )

Write the CSAF document in the specified C<$directory> and create this structure:

     [ ROOT ]
        |
        |--> [ YEAR ]
        |       |--> CSAF document (.json)
        |       |--> SHA256 integrity file (.sha256)
        |       |--> SHA512 integrity file (.sha512)
        |       \--> GPG signature file (.asc)
        |
        |--> Index file (index.txt)
        \--> Changes file (changes.csv)

This directory structure is "ready" to be published through in webserver
(Apache, NGINX and others) via "HTTPS".

    $writer->write('/var/www/html/advisories/csaf');


=item $writer->options

Change the default options for L<CSAF::Options::Writer> configurator.

    $writer->options->configure(
        create_sha256_integrity => 0,
        create_gpg_signature    => 1,
        update_index            => 1,
        update_changes          => 1
    );

    if (my $passphrase = get_passphrase_from_stdin) {
        $writer->options->gpg_passphrase($passphrase);
    }

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
