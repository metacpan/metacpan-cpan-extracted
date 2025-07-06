package CSAF::Validator::InformativeTests;

use 5.010001;
use strict;
use warnings;
use utf8;
use version;

use List::Util qw(first);
use CSAF::Util qw(uniq);

use Moo;
extends 'CSAF::Validator::Base';

use constant DEBUG => $ENV{CSAF_DEBUG};

has tests => (
    is      => 'ro',
    default =>
        sub { ['6.3.1', '6.3.2', '6.3.3', '6.3.4', '6.3.5', '6.3.6', '6.3.7', '6.3.8', '6.3.9', '6.3.10', '6.3.11'] }
);

my $VERS_REGEXP = qr{^vers:[a-z\\.\\-\\+][a-z0-9\\.\\-\\+]*/.+};


# 6.3.1 Use of CVSS v2 as the only Scoring System

sub TEST_6_3_1 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            if ($score->cvss_v2 && !$score->cvss_v3) {
                $self->add_message(
                    type     => 'info',
                    category => 'informative',
                    path     => "/vulnerabilities/$vuln_idx/scores/$score_idx",
                    code     => '6.3.1',
                    message  => 'Use of CVSS v2 as the only Scoring System'
                );
            }

        });

    });

}


# 6.3.2 Use of CVSS v3.0

sub TEST_6_3_2 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            if ($score->cvss_v3 && $score->cvss_v3->version eq '3.0') {
                $self->add_message(
                    type     => 'info',
                    category => 'informative',
                    path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v3/version",
                    code     => '6.3.2',
                    message  => 'Use of CVSS v3.0'
                );
            }

            if ($score->cvss_v3 && $score->cvss_v3->vectorString =~ /^CVSS\:3.0/) {
                $self->add_message(
                    type     => 'info',
                    category => 'informative',
                    path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v3/vectorString",
                    code     => '6.3.2',
                    message  => 'Use of CVSS v3.0'
                );
            }

        });

    });

}


# 6.3.3 Missing CVE

sub TEST_6_3_3 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        if (!$vulnerability->cve) {
            $self->add_message(
                type     => 'info',
                category => 'informative',
                path     => "/vulnerabilities/$vuln_idx/cve",
                code     => '6.3.3',
                message  => 'Missing CVE'
            );
        }

    });

}


# 6.3.4 Missing CWE

sub TEST_6_3_4 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        if (!$vulnerability->cwe->id) {
            $self->add_message(
                type     => 'info',
                category => 'informative',
                path     => "/vulnerabilities/$vuln_idx/cwe",
                code     => '6.3.4',
                message  => 'Missing CWE'
            );
        }

    });

}


# 6.3.5 Use of Short Hash

sub TEST_6_3_5 {

    my $self = shift;

    # /product_tree/branches[](/branches[])*/product/product_identification_helper/hashes[]/file_hashes[]/value

    $self->_TEST_6_3_5_branches($self->csaf->product_tree->branches, "/product_tree/branches");

    # /product_tree/full_product_names[]/product_identification_helper/hashes[]/file_hashes[]/value

    $self->csaf->product_tree->full_product_names->each(sub {

        my ($full_product_name, $full_product_name_idx) = @_;

        return unless $full_product_name->product_identification_helper;

        $self->_TEST_6_3_5_product_identification_helper(
            $full_product_name->product_identification_helper,
            "/product_tree/full_product_names/$full_product_name_idx"
        );

    });

    # /product_tree/relationships[]/full_product_name/product_identification_helper/hashes[]/file_hashes[]/value

    $self->csaf->product_tree->relationships->each(sub {

        my ($relationship, $rel_idx) = @_;

        return unless $relationship->full_product_name;
        return unless $relationship->full_product_name->product_identification_helper;

        $self->_TEST_6_3_5_product_identification_helper(
            $relationship->full_product_name->product_identification_helper,
            "/product_tree/relationships/$rel_idx");

    });

}


# 6.3.6 Use of non-self referencing URLs Failing to Resolve

sub TEST_6_3_6 { }


# 6.3.7 Use of self referencing URLs Failing to Resolve
sub TEST_6_3_7 { }


# 6.3.8 Spell check

sub TEST_6_3_8 { }


# 6.3.9 Branch Categories

sub TEST_6_3_9 {

    my $self = shift;

    return if (not $self->csaf->product_tree);

    $self->_TEST_6_3_9_branches($self->csaf->product_tree->branches, "/product_tree/branches", []);

}


# 6.3.10 Usage of Product Version Range

sub TEST_6_3_10 {


    my $self = shift;

    return if (not $self->csaf->product_tree);

    $self->_TEST_6_3_10_branches($self->csaf->product_tree->branches, "/product_tree/branches");

}


# 6.3.11 Usage of V as Version Indicator

sub TEST_6_3_11 {

    my $self = shift;

    return if (not $self->csaf->product_tree);

    $self->_TEST_6_3_11_branches($self->csaf->product_tree->branches, "/product_tree/branches");

}


sub _TEST_6_3_5_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $branch_idx) = @_;

        $self->_TEST_6_3_5_branches($branch->branches, "$path/$branch_idx/branches");

        return unless $branch->product;
        return unless $branch->product->product_identification_helper;

        $self->_TEST_6_3_5_product_identification_helper($branch->product->product_identification_helper,
            "$path/branch/$branch_idx/product");

    });


}

sub _TEST_6_3_5_product_identification_helper {

    my ($self, $product_identification_helper, $path) = @_;

    $product_identification_helper->hashes->each(sub {

        my ($hash, $hash_idx) = @_;

        $hash->file_hashes->each(sub {
            my ($file_hash, $file_hash_idx) = @_;

            if (length($file_hash) < 64) {
                $self->add_message(
                    type     => 'info',
                    category => 'informative',
                    path     => "$path/product_identification_helper/hashes/$hash_idx/file_hashes/$file_hash_idx/value",
                    code     => '6.3.5',
                    message  => 'Use of Short Hash'
                );
            }

        });

    });

}

sub _TEST_6_3_9_branches {

    my ($self, $branches, $path, $categories) = @_;

    my @sorted_categories = qw[vendor product_name product_version];

    $branches->each(sub {

        my ($branch, $idx) = @_;

        push @{$categories}, $branch->category if $branch->category eq 'vendor';
        push @{$categories}, $branch->category if $branch->category eq 'product_name';
        push @{$categories}, $branch->category if $branch->category eq 'product_version';

        $self->_TEST_6_3_9_branches($branch->branches, "$path/$idx/branches", $categories);

        my $is_invalid = undef;

        my @uniq_categories = uniq(@{$categories});

        for my $category (@sorted_categories) {
            $is_invalid = 1 if (!first { $_ eq $category } @{$categories});
        }

        for (my $i = 0; $i < @uniq_categories; $i++) {
            $is_invalid = 1 if ($uniq_categories[$i] ne $sorted_categories[$i]);
        }

        if ($is_invalid) {
            $self->add_message(
                type     => 'info',
                category => 'informative',
                path     => "$path/category",
                code     => '6.3.9',
                message  => 'Branch Categories'
            );
        }

    });
}

sub _TEST_6_3_10_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $idx) = @_;

        $self->_TEST_6_3_10_branches($branch->branches, "$path/$idx/branches");

        if ($branch->category eq 'product_version_range') {

            $self->add_message(
                type     => 'info',
                category => 'informative',
                path     => "$path/category",
                code     => '6.3.10',
                message  => 'Usage of Product Version Range'
            );

        }

    });
}

sub _TEST_6_3_11_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $idx) = @_;

        $self->_TEST_6_3_11_branches($branch->branches, "$path/$idx/branches");

        if ($branch->category eq 'product_version') {

            if ($branch->name =~ /^[vV][0-9].*$/) {
                $self->add_message(
                    type     => 'info',
                    category => 'informative',
                    path     => "$path/name",
                    code     => '6.3.11',
                    message  => 'Usage of V as Version Indicator'
                );
            }

        }

    });
}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Validator::InformativeTests

=head1 SYNOPSIS

    use CSAF::Validator::InformativeTests;

    my $v = CSAF::Validator::InformativeTests->new( csaf => $csaf );

    $v->exec_test('6.3.11');
    $v->TEST_6_3_11;


=head1 DESCRIPTION

Informative tests provide insights in common mistakes and bad practices. 
They MAY fail at a valid L<CSAF> document. It is up to the issuing party to decide
whether this was an intended behavior and can be ignore or should be treated.

    6.3.1 Use of CVSS v2 as the only Scoring System
    6.3.2 Use of CVSS v3.0
    6.3.3 Missing CVE
    6.3.4 Missing CWE
    6.3.5 Use of Short Hash
    6.3.6 Use of non-self referencing URLs Failing to Resolve (*)
    6.3.7 Use of self referencing URLs Failing to Resolve (*)
    6.3.8 Spell check (*)
    6.3.9 Branch Categories
    6.3.10 Usage of Product Version Range
    6.3.11 Usage of V as Version Indicator

(*) actually not tested in this L<CSAF> distribution.

=head2 METHODS

L<CSAF::Validator::InformativeTests> inherits all methods from L<CSAF::Validator::Base> and implements the following new ones.

=over

=item TEST_6_3_1

Use of CVSS v2 as the only Scoring System

=item TEST_6_3_2

Use of CVSS v3_0

=item TEST_6_3_3

Missing CVE

=item TEST_6_3_4

Missing CWE

=item TEST_6_3_5

Use of Short Hash

=item TEST_6_3_6

Use of non-self referencing URLs Failing to Resolve

=item TEST_6_3_7

Use of self referencing URLs Failing to Resolve

=item TEST_6_3_8

Spell check (*)

=item TEST_6_3_9

Branch Categories

=item TEST_6_3_10

Usage of Product Version Range

=item TEST_6_3_11

Usage of V as Version Indicator


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
