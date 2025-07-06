package CSAF::Validator::OptionalTests;

use 5.010001;
use strict;
use warnings;
use utf8;
use version;

use CSAF::Util::CVSS qw(decode_cvss_vector_string);
use CSAF::Util       qw(tracking_id_to_well_filename);

use File::Basename;
use List::Util qw(first);

use I18N::LangTags::List;

use Moo;
extends 'CSAF::Validator::Base';
with 'CSAF::Util::Log';

use constant DEBUG => $ENV{CSAF_DEBUG};

has tests => (
    is      => 'ro',
    default => sub { [
        '6.2.1',  '6.2.2',  '6.2.3',  '6.2.4',  '6.2.5',  '6.2.6',  '6.2.7',  '6.2.8',  '6.2.9',  '6.2.10',
        '6.2.11', '6.2.12', '6.2.13', '6.2.14', '6.2.15', '6.2.16', '6.2.17', '6.2.18', '6.2.19', '6.2.20'
    ] }
);

my $VERS_REGEXP = qr{^vers:[a-z\\.\\-\\+][a-z0-9\\.\\-\\+]*/.+};


# 6.2.1 Unused Definition of Product ID (*)

sub TEST_6_2_1 { }


# 6.2.2 Missing Remediation

sub TEST_6_2_2 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    my @statuses = qw(first_affected known_affected last_affected under_investigation);

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        my $product_status = $vulnerability->product_status;

        for my $status (@statuses) {

            my @product_ids = @{$product_status->$status};
            my $product_idx = 0;

            foreach my $product_id (@product_ids) {
                if (!$vulnerability->remediations->size) {
                    $self->add_message(
                        type     => 'warning',
                        category => 'optional',
                        path     => "/vulnerabilities/$vuln_idx/product_status/$status/$product_idx",
                        code     => '6.2.2',
                        message  => 'Missing Remediation'
                    );
                }
                $product_idx++;
            }

        }

    });

}


# 6.2.3 Missing Score

sub TEST_6_2_3 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    my @statuses = qw(first_affected known_affected last_affected);

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        my $product_status = $vulnerability->product_status;

        for my $status (@statuses) {

            my @product_ids = @{$product_status->$status};
            my $product_idx = 0;

            foreach my $product_id (@product_ids) {
                if (!$vulnerability->scores->size) {
                    $self->add_message(
                        type     => 'warning',
                        category => 'optional',
                        path     => "/vulnerabilities/$vuln_idx/product_status/$status/$product_idx",
                        code     => '6.2.3',
                        message  => 'Missing Score'
                    );
                }
                $product_idx++;
            }

        }

    });

}


# 6.2.4 Build Metadata in Revision History

sub TEST_6_2_4 {

    my $self = shift;

    my $document_revisions = $self->csaf->document->tracking->revision_history;

    $document_revisions->each(sub {

        my ($revision, $idx) = @_;

        if ($revision->number =~ /\+/) {
            $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => "/document/tracking/revision_history/$idx/number",
                code     => '6.2.4',
                message  => 'Build Metadata in Revision History'
            );
        }

    });

}


# 6.2.5 Older Initial Release Date than Revision History

sub TEST_6_2_5 {

    my $self = shift;

    my $document_revisions = $self->csaf->document->tracking->revision_history;
    return unless $document_revisions->size;

    my $first_document_revision = $document_revisions->first;
    my $initial_release_date    = $self->csaf->document->tracking->initial_release_date;

    if ($initial_release_date < $first_document_revision->date) {
        $self->add_message(
            type     => 'warning',
            category => 'optional',
            path     => '/document/tracking/initial_release_date',
            code     => '6.2.5',
            message  => 'Older Initial Release Date than Revision History'
        );
    }

}


# 6.2.6 Older Current Release Date than Revision History

sub TEST_6_2_6 {

    my $self = shift;

    my $document_revisions = $self->csaf->document->tracking->revision_history;
    return unless $document_revisions->size;

    my $last_document_revision = $document_revisions->last;
    my $current_release_date   = $self->csaf->document->tracking->current_release_date;

    if ($current_release_date < $last_document_revision->date) {
        $self->add_message(
            type     => 'warning',
            category => 'optional',
            path     => '/document/tracking/initial_release_date',
            code     => '6.2.6',
            message  => 'Older Current Release Date than Revision History'
        );
    }

}


# 6.2.7 Missing Date in Involvements

sub TEST_6_2_7 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->involvements->each(sub {

            my ($involvement, $involvement_idx) = @_;

            if (!$involvement->date) {
                $self->add_message(
                    type     => 'warning',
                    category => 'optional',
                    path     => "/vulnerabilities/$vuln_idx/involvements/$involvement_idx",
                    code     => '6.2.7',
                    message  => 'Missing Date in Involvements'
                );
            }

        });

    });

}


# 6.2.8 Use of MD5 as the only Hash Algorithm

sub TEST_6_2_8 { shift->_TEST_weak_algo('md5') }


# 6.2.9 Use of SHA-1 as the only Hash Algorithm

sub TEST_6_2_9 { shift->_TEST_weak_algo('sha1') }


# 6.2.10 Missing TLP label

sub TEST_6_2_10 {

    my $self = shift;

    if (!$self->csaf->document->distribution->tlp->label) {
        $self->add_message(
            type     => 'warning',
            category => 'optional',
            path     => '/document/distribution/tlp/label',
            code     => '6.2.10',
            message  => 'Missing TLP label'
        );
    }

}


# 6.2.11 Missing Canonical URL

sub TEST_6_2_11 {

    my $self = shift;

    my $have_self = 0;

    my $tracking_id  = $self->csaf->document->tracking->id;
    my $doc_filename = tracking_id_to_well_filename($tracking_id);

    $self->csaf->document->references->each(sub {

        my ($reference, $ref_idx) = @_;

        return if ($reference->category ne 'self');

        $have_self = 1;

        my $url = $reference->url;

        if ($url !~ /^https\:/) {
            return $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => "/document/references/$ref_idx",
                code     => '6.2.11',
                message  => 'Missing Canonical URL'
            );
        }

        if (basename($url) ne $doc_filename) {
            return $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => "document/references/$ref_idx",
                code     => '6.2.11',
                message  => 'Missing Canonical URL'
            );
        }

    });

    if (!$have_self) {
        $self->add_message(
            type     => 'warning',
            category => 'optional',
            path     => '/document/references',
            code     => '6.2.11',
            message  => 'Missing Canonical URL'
        );
    }

}


# 6.2.12 Missing Document Language

sub TEST_6_2_12 {

    my $self = shift;

    if (!$self->csaf->document->lang) {
        $self->add_message(
            type     => 'warning',
            category => 'optional',
            path     => '/document/lang',
            code     => '6.2.12',
            message  => 'Missing Document Language'
        );
    }

}


# 6.2.13 Sorting

sub TEST_6_2_13 { DEBUG and shift->log->info('6.2.13 Sorting => TODO Unimplementable test') }


# 6.2.14 Use of Private Language

sub TEST_6_2_14 {

    my $self = shift;

    my %check = (
        '/document/lang'        => $self->csaf->document->lang,
        '/document/source_lang' => $self->csaf->document->source_lang
    );

    foreach (keys %check) {

        my $path = $_;
        my $lang = $check{$path};

        next unless $lang;

        # Subtags in official testsuite (optional/oasis_csaf_tc-csaf_2_0-2021-6-2-14-*.json)
        if ($lang =~ /\-(AA|XP|ZZ|QM|QABC)$/i) {
            return $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $path,
                code     => '6.2.14',
                message  => 'Use of Private Language'
            );
        }

        if ($lang =~ /(q([a-t])([a-z]))/gi) {

            return $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $path,
                code     => '6.2.14',
                message  => 'Use of Private Language'
            );

        }

        if (!I18N::LangTags::List::is_decent($lang)) {
            return $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $path,
                code     => '6.2.14',
                message  => 'Use of Private Language'
            );
        }

    }

}


# 6.2.15 Use of Default Language

sub TEST_6_2_15 {

    my $self = shift;

    my %check = (
        '/document/lang'        => $self->csaf->document->lang,
        '/document/source_lang' => $self->csaf->document->source_lang
    );

    foreach (keys %check) {

        my $path = $_;
        my $lang = $check{$path};

        next unless $lang;

        if ($lang eq 'i-default') {
            return $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $path,
                code     => '6.2.15',
                message  => 'Use of Default Language'
            );
        }

    }

}


# 6.2.16 Missing Product Identification Helper

sub TEST_6_2_16 {

    my $self = shift;

    return if (!$self->csaf->product_tree);

    $self->csaf->product_tree->full_product_names->each(sub {

        my ($full_product_name, $full_product_name_idx) = @_;

        if (!$full_product_name->product_identification_helper) {
            $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => "/product_tree/full_product_names/$full_product_name_idx",
                code     => '6.2.16',
                message  => 'Missing Product Identification Helper'
            );
        }

    });

    $self->csaf->product_tree->relationships->each(sub {

        my ($relationship, $relationship_idx) = @_;

        return if (!$relationship->full_product_name);

        my $path              = "/product_tree/relationships/$relationship_idx/full_product_name";
        my $full_product_name = $relationship->full_product_name;

        if (!$full_product_name->product_identification_helper) {
            $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $path,
                code     => '6.2.16',
                message  => 'Missing Product Identification Helper'
            );
        }

    });

    if ($self->csaf->product_tree->branches->size) {
        $self->_TEST_6_2_16_walk_branches($self->csaf->product_tree->branches, '/product_tree/branches');
    }

}


# 6.2.17 CVE in field IDs

sub TEST_6_2_17 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->ids->each(sub {

            my ($id, $id_idx) = @_;

            if ($id->text =~ /^CVE-[0-9]{4}-[0-9]{4,}$/) {
                $self->add_message(
                    type     => 'warning',
                    category => 'optional',
                    path     => "/vulnerabilities/$vuln_idx/ids/$id_idx",
                    code     => '6.2.17',
                    message  => 'CVE in field IDs'
                );
            }

        });

    });

}


# 6.2.18 Product Version Range without vers

sub TEST_6_2_18 {

    my $self = shift;

    return if (not $self->csaf->product_tree);

    $self->_TEST_6_2_18_branches($self->csaf->product_tree->branches, "/product_tree/branches");

}


# 6.2.19 CVSS for Fixed Products

sub TEST_6_2_19 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            my $fixed_products = 0;

            foreach my $product_id (@{$score->products}) {
                $fixed_products = 1 if (first { $product_id eq $_ } @{$vulnerability->product_status->fixed});
                $fixed_products = 1 if (first { $product_id eq $_ } @{$vulnerability->product_status->first_fixed});
            }

            return if (!$fixed_products);

            if (my $cvss = $score->cvss_v2) {

                my $is_invalid = 0;

                if (!$cvss->targetDistribution) {

                    $is_invalid = 1;

                    my $decoded = decode_cvss_vector_string($score->cvss_v2->vectorString);

                    if (!defined($decoded->{targetDistribution})) {
                        $is_invalid = 1;
                    }
                    else {
                        $is_invalid = 0;
                    }

                }

                if ($is_invalid) {
                    $self->add_message(
                        type     => 'warning',
                        category => 'optional',
                        path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v2",
                        code     => '6.2.19',
                        message  => 'CVSS for Fixed Products'
                    );
                }
            }

            if (my $cvss = $score->cvss_v3) {

                my $is_invalid = 0;

                if (   !$cvss->modifiedIntegrityImpact
                    || !$cvss->modifiedAvailabilityImpact
                    || !$cvss->modifiedConfidentialityImpact)
                {

                    $is_invalid = 1;

                    my $decoded = decode_cvss_vector_string($score->cvss_v3->vectorString);

                    if (   !defined($decoded->{modifiedIntegrityImpact})
                        || !defined($decoded->{modifiedAvailabilityImpact})
                        || !defined($decoded->{modifiedConfidentialityImpact}))
                    {
                        $is_invalid = 1;
                    }
                    else {
                        $is_invalid = 0;
                    }

                }

                if ($is_invalid) {
                    $self->add_message(
                        type     => 'warning',
                        category => 'optional',
                        path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v3",
                        code     => '6.2.19',
                        message  => 'CVSS for Fixed Products'
                    );
                }

            }

        });

    });

}


# 6.2.20 Additional Properties
sub TEST_6_2_20 { DEBUG and shift->log->info('6.2.20 Additional Properties => Test implemented in "CSAF::Parser"') }


sub _TEST_6_2_18_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $branch_idx) = @_;

        $self->_TEST_6_2_18_branches($branch->branches, "$path/$branch_idx/branches");

        if ($branch->category eq 'product_version_range') {

            if ($branch->name !~ /$VERS_REGEXP/) {
                $self->add_message(
                    type     => 'warning',
                    category => 'optional',
                    path     => "$path/name",
                    code     => '6.2.18',
                    message  => 'Product Version Range without vers'
                );
            }

        }

    });
}

sub _TEST_weak_algo_product_identification_helper {

    my ($self, $product_identification_helper, $algo, $path) = @_;

    my $MESSAGES = {
        md5  => ['6.2.8', 'Use of MD5 as the only Hash Algorithm'],
        sha1 => ['6.2.9', 'Use of SHA-1 as the only Hash Algorithm'],
    };

    my ($code, $message) = @{$MESSAGES->{$algo}};

    $product_identification_helper->hashes->each(sub {

        my ($hash, $hash_idx) = @_;

        my $check = 0;

        $hash->file_hashes->each(sub {
            my ($file_hash, $file_hash_idx) = @_;
            $check++ if ($file_hash->algorithm eq $algo);
        });

        if ($check == $hash->file_hashes->size) {

            $path .= "/product_identification_helper/hashes/$hash_idx/file_hashes";

            $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $path,
                code     => $code,
                message  => $message
            );

        }

    });

}

sub _TEST_weak_algo {

    my ($self, $algo) = @_;

    return if (!$self->csaf->product_tree);

    $self->csaf->product_tree->full_product_names->each(sub {

        my ($full_product_name, $full_product_name_idx) = @_;

        return if (!$full_product_name->product_identification_helper);

        my $product_identification_helper = $full_product_name->product_identification_helper;

        my $path = "/product_tree/full_product_names/$full_product_name_idx";

        $self->_TEST_weak_algo_product_identification_helper($product_identification_helper, $algo, $path);

    });

    $self->csaf->product_tree->relationships->each(sub {

        my ($relationship, $relationship_idx) = @_;

        return if (!$relationship->full_product_name);
        return if (!$relationship->full_product_name->product_identification_helper);

        my $product_identification_helper = $relationship->full_product_name->product_identification_helper;

        my $path = "/product_tree/relationships/$relationship_idx/full_product_name";

        $self->_TEST_weak_algo_product_identification_helper($product_identification_helper, $algo, $path);

    });

    if ($self->csaf->product_tree->branches->size) {
        $self->_TEST_weak_algo_walk_branches($self->csaf->product_tree->branches, $algo, "/product_tree/branches");
    }

}

sub _TEST_weak_algo_walk_branches {

    my ($self, $branches, $algo, $path) = @_;

    $branches->each(sub {

        my ($branch, $branch_idx) = @_;

        $self->_TEST_weak_algo_walk_branches($branch->branches, $algo, "$path/$branch_idx/branches");

        if ($branch->product && $branch->product->product_identification_helper) {
            $self->_TEST_weak_algo_product_identification_helper($branch->product->product_identification_helper,
                $algo, "$path/product/product_identification_helper");
        }

    });
}

sub _TEST_6_2_16_walk_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $branch_idx) = @_;

        $self->_TEST_6_2_16_walk_branches($branch->branches, "$path/$branch_idx/branches");

        if ($branch->product && !$branch->product->product_identification_helper) {
            $self->add_message(
                type     => 'warning',
                category => 'optional',
                path     => "$path/$branch_idx",
                code     => '6.2.16',
                message  => 'Missing Product Identification Helper'
            );
        }

    });
}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Validator::OptionalTests

=head1 SYNOPSIS

    use CSAF::Validator::OptionalTests;

    my $v = CSAF::Validator::OptionalTests->new( csaf => $csaf );

    $v->exec_test('6.2.2');
    $v->TEST_6_2_2;


=head1 DESCRIPTION

Optional tests SHOULD NOT fail at a valid L<CSAF> document without a good reason.
Failing such a test does not make the L<CSAF> document invalid. These tests may
include information about features which are still supported but expected to be
deprecated in a future version of L<CSAF>.

    6.2.1 Unused Definition of Product ID (*)
    6.2.2 Missing Remediation
    6.2.3 Missing Score
    6.2.4 Build Metadata in Revision History
    6.2.5 Older Initial Release Date than Revision History
    6.2.6 Older Current Release Date than Revision History
    6.2.7 Missing Date in Involvements
    6.2.8 Use of MD5 as the only Hash Algorithm
    6.2.9 Use of SHA-1 as the only Hash Algorithm
    6.2.10 Missing TLP label
    6.2.11 Missing Canonical URL
    6.2.12 Missing Document Language
    6.2.13 Sorting (*)
    6.2.14 Use of Private Language
    6.2.15 Use of Default Language
    6.2.16 Missing Product Identification Helper
    6.2.17 CVE in field IDs
    6.2.18 Product Version Range without vers
    6.2.19 CVSS for Fixed Products
    6.2.20 Additional Properties (**)

(*) actually not tested in this L<CSAF> distribution.

(**) tested in L<CSAF::Parser>

=head2 METHODS

L<CSAF::Validator::OptionalTests> inherits all methods from L<CSAF::Validator::Base> and implements the following new ones.

=over

=item TEST_6_2_1

Unused Definition of Product ID

=item TEST_6_2_2

Missing Remediation

=item TEST_6_2_3

Missing Score

=item TEST_6_2_4

Build Metadata in Revision History

=item TEST_6_2_5

Older Initial Release Date than Revision History

=item TEST_6_2_6

Older Current Release Date than Revision History

=item TEST_6_2_7

Missing Date in Involvements

=item TEST_6_2_8

Use of MD5 as the only Hash Algorithm

=item TEST_6_2_9

Use of SHA-1 as the only Hash Algorithm

=item TEST_6_2_10

Missing TLP label

=item TEST_6_2_11

Missing Canonical URL

=item TEST_6_2_12

Missing Document Language

=item TEST_6_2_13

Sorting

=item TEST_6_2_14

Use of Private Language

=item TEST_6_2_15

Use of Default Language

=item TEST_6_2_16

Missing Product Identification Helper

=item TEST_6_2_17

CVE in field IDs

=item TEST_6_2_18

Product Version Range without vers

=item TEST_6_2_19

CVSS for Fixed Products

=item TEST_6_2_20

Additional Properties

Tested in L<CSAF::Parser>

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
