package CSAF::Validator::MandatoryTests;

use 5.010001;
use strict;
use warnings;
use utf8;
use version;

use CSAF::Util::CWE qw(get_weakness_name weakness_exists);
use CSAF::Util      qw(collect_product_ids product_in_group_exists);
use CSAF::Schema;

use CVSS;
use CVSS::v2;
use CVSS::v3;

use List::MoreUtils qw(uniq duplicates);
use List::Util      qw(first);
use URI::PackageURL;

use Moo;
extends 'CSAF::Validator::Base';
with 'CSAF::Util::Log';

use constant DEBUG => $ENV{CSAF_DEBUG};

has tests => (
    is      => 'ro',
    default => sub { [
        '6.1.1',    '6.1.2',    '6.1.3',    '6.1.4',     '6.1.5',     '6.1.6',    '6.1.7',    '6.1.8',
        '6.1.9',    '6.1.10',   '6.1.11',   '6.1.12',    '6.1.13',    '6.1.14',   '6.1.15',   '6.1.16',
        '6.1.17',   '6.1.18',   '6.1.19',   '6.1.20',    '6.1.21',    '6.1.22',   '6.1.23',   '6.1.24',
        '6.1.25',   '6.1.26',   '6.1.27.1', '6.1.27.2',  '6.1.27.3',  '6.1.27.4', '6.1.27.5', '6.1.27.6',
        '6.1.27.7', '6.1.27.8', '6.1.27.9', '6.1.27.10', '6.1.27.11', '6.1.28',   '6.1.29',   '6.1.30',
        '6.1.31',   '6.1.32',   '6.1.33',
    ] }
);

my $PURL_REGEX = qr{^pkg:[A-Za-z\\.\\-\\+][A-Za-z0-9\\.\\-\\+]*/.+};

my $SEMVER_REGEXP
    = qr{^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$};


# 6.1.1 Missing Definition of Product ID

sub TEST_6_1_1 {

    my $self = shift;

    my $product_ids = $CSAF::CACHE->{products} || {};

    my @product_statuses = (
        'first_affected',     'first_fixed',   'fixed',       'known_affected',
        'known_not_affected', 'last_affected', 'recommended', 'under_investigation',
    );

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        # /vulnerabilities[]/product_status/first_affected[]
        # /vulnerabilities[]/product_status/first_fixed[]
        # /vulnerabilities[]/product_status/fixed[]
        # /vulnerabilities[]/product_status/known_affected[]
        # /vulnerabilities[]/product_status/known_not_affected[]
        # /vulnerabilities[]/product_status/last_affected[]
        # /vulnerabilities[]/product_status/recommended[]
        # /vulnerabilities[]/product_status/under_investigation[]

        foreach my $product_status (@product_statuses) {

            my $method   = $vulnerability->product_status->can($product_status);
            my @products = @{$method->($vulnerability->product_status)};

            foreach my $product (@products) {
                if (!first { $product eq $_ } keys %{$product_ids}) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/product_status/$product_status",
                        code     => '6.1.1',
                        message  => "Missing Definition of Product ID ($product)"
                    );
                }
            }

        }


        # /vulnerabilities[]/scores[]/products[]

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            foreach my $product (@{$score->products}) {
                if (!first { $product eq $_ } keys %{$product_ids}) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/products",
                        code     => '6.1.1',
                        message  => "Missing Definition of Product ID ($product)"
                    );
                }
            }

        });


        # /vulnerabilities[]/remediations[]/product_ids[]

        $vulnerability->remediations->each(sub {

            my ($remediation, $remediation_idx) = @_;

            foreach my $product (@{$remediation->product_ids}) {
                if (!first { $product eq $_ } keys %{$product_ids}) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/remediations/$remediation_idx/product_ids",
                        code     => '6.1.1',
                        message  => "Missing Definition of Product ID ($product)"
                    );
                }
            }

        });


        # /vulnerabilities[]/threats[]/product_ids[]

        $vulnerability->threats->each(sub {

            my ($threat, $threat_idx) = @_;

            foreach my $product (@{$threat->product_ids}) {
                if (!first { $product eq $_ } keys %{$product_ids}) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/threats/$threat_idx/product_ids",
                        code     => '6.1.1',
                        message  => "Missing Definition of Product ID ($product)"
                    );
                }
            }

        });

    });


    # /product_tree/product_groups[]/product_ids[]

    $self->csaf->product_tree->product_groups->each(sub {

        my ($product_group, $product_group_idx) = @_;

        foreach my $product (@{$product_group->product_ids}) {
            if (!first { $product eq $_ } keys %{$product_ids}) {
                $self->add_message(
                    category => 'mandatory',
                    path     => "/product_tree/product_groups/$product_group_idx/product_ids",
                    code     => '6.1.1',
                    message  => "Missing Definition of Product ID ($product)"
                );
            }
        }

    });


    # /product_tree/relationships[]/product_reference
    # /product_tree/relationships[]/relates_to_product_reference

    $self->csaf->product_tree->relationships->each(sub {

        my ($relationship, $rel_idx) = @_;

        if (my $product = $relationship->product_reference) {

            if (!first { $product eq $_ } keys %{$product_ids}) {
                $self->add_message(
                    category => 'mandatory',
                    path     => "/product_tree/relationships/$rel_idx/product_reference",
                    code     => '6.1.1',
                    message  => "Missing Definition of Product ID ($product)"
                );
            }

        }

        if (my $product = $relationship->relates_to_product_reference) {

            if (!first { $product eq $_ } keys %{$product_ids}) {
                $self->add_message(
                    category => 'mandatory',
                    path     => "/product_tree/relationships/$rel_idx/relates_to_product_reference",
                    code     => '6.1.1',
                    message  => "Missing Definition of Product ID ($product)"
                );
            }

        }

    });


}


# 6.1.2 Multiple Definition of Product ID

sub TEST_6_1_2 {

    my $self = shift;

    if ($self->csaf->product_tree->branches->size) {

        my @product_ids = ();

        $self->csaf->product_tree->branches->each(sub {
            my ($branch) = @_;
            push @product_ids, collect_product_ids($branch);
        });

        if (duplicates @product_ids) {

            $self->add_message(
                category => 'mandatory',
                path     => '/product_tree/branches[](/branches[])*/product/product_id',
                code     => '6.1.2',
                message  => 'Multiple Definition of Product ID'
            );

        }

    }

    if ($self->csaf->product_tree->full_product_names->size) {

        my @product_ids = ();

        $self->csaf->product_tree->full_product_names->each(sub {
            my ($product, $idx) = @_;
            push @product_ids, collect_product_ids($product);
        });

        if (duplicates @product_ids) {

            $self->add_message(
                category => 'mandatory',
                path     => '/product_tree/full_product_names[]/product_id',
                code     => '6.1.2',
                message  => 'Multiple Definition of Product ID'
            );

        }

    }

    if ($self->csaf->product_tree->relationships->size) {

        my @product_ids = ();

        $self->csaf->product_tree->relationships->each(sub {

            my ($relationship, $rel_idx) = @_;

            if (my $product_id = $relationship->full_product_name->product_id) {
                push @product_ids, $product_id;
            }

            if (duplicates @product_ids) {

                $self->add_message(
                    category => 'mandatory',
                    path     => "/product_tree/relationships/$rel_idx/full_product_name/product_id",
                    code     => '6.1.2',
                    message  => 'Multiple Definition of Product ID'
                );

            }

        });

    }

}


# 6.1.3 Circular Definition of Product ID

sub TEST_6_1_3 {

    my $self = shift;

    $self->csaf->product_tree->relationships->each(sub {

        my ($relationship, $rel_idx) = @_;

        if ($relationship->product_reference eq $relationship->full_product_name->product_id) {
            $self->add_message(
                category => 'mandatory',
                path     => "/product_tree/relationships/$rel_idx/full_product_name/product_id",
                code     => '6.1.3',
                message  => 'Circular Definition of Product ID'
            );
        }

        if ($relationship->relates_to_product_reference eq $relationship->full_product_name->product_id) {
            $self->add_message(
                category => 'mandatory',
                path     => "/product_tree/relationships/$rel_idx/full_product_name/product_id",
                code     => '6.1.3',
                message  => 'Circular Definition of Product ID'
            );
        }

    });

}


# 6.1.4 Missing Definition of Product Group ID

sub TEST_6_1_4 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    my $group_ids = $CSAF::CACHE->{groups} || {};

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->threats->each(sub {

            my ($threat, $threat_idx) = @_;

            foreach my $group_id (@{$threat->group_ids}) {

                if (!first { $group_id eq $_ } keys %{$group_ids}) {

                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/threats/$threat_idx/group_ids",
                        code     => '6.1.4',
                        message  => 'Missing Definition of Product Group ID'
                    );

                }
            }

        });

    });

}


# 6.1.5 Multiple Definition of Product Group ID

sub TEST_6_1_5 {

    my $self = shift;

    my $check = {};

    $self->csaf->product_tree->product_groups->each(sub {

        my ($group, $group_idx) = @_;

        foreach my $product_id (@{$group->product_ids}) {

            $check->{$product_id}++;

            if ($check->{$product_id} > 1) {
                $self->add_message(
                    category => 'mandatory',
                    path     => "/product_tree/product_groups/$group_idx/group_id",
                    code     => '6.1.5',
                    message  => 'Multiple Definition of Product Group ID'
                );
            }

        }

    });

}


# 6.1.6 Contradicting Product Status

sub TEST_6_1_6 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        my $product_status = $vulnerability->product_status;

        my @affected_group = uniq(
            @{$product_status->first_affected},
            @{$product_status->known_affected},
            @{$product_status->last_affected}
        );

        my @not_affected_group        = uniq(@{$product_status->known_not_affected});
        my @fixed_group               = uniq(@{$product_status->first_fixed}, @{$product_status->fixed});
        my @under_investigation_group = uniq(@{$product_status->under_investigation});

        my @check = (@affected_group, @not_affected_group, @fixed_group, @under_investigation_group);

        if (duplicates @check) {

            $self->add_message(
                category => 'mandatory',
                path     => "/vulnerabilities/$vuln_idx/product_status",
                code     => '6.1.6',
                message  => 'Contradicting Product Status'
            );

        }

    });

}


# 6.1.7 Multiple Scores with same Version per Product

sub TEST_6_1_7 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        my $check = {};

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            foreach my $product (@{$score->products}) {

                $check->{$product}++;

                if ($check->{$product} > 1) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/score/$score_idx/products",
                        code     => '6.1.7',
                        message  => 'Multiple Scores with same Version per Product'
                    );
                }

            }
        });

    });

}


# 6.1.8 Invalid CVSS

sub TEST_6_1_8 {

    # /vulnerabilities[]/scores[]/cvss_v2
    # /vulnerabilities[]/scores[]/cvss_v3

    my $self = shift;

    my $SCHEMAS = {
        cvss2 => {'$ref' => 'https://www.first.org/cvss/cvss-v2.0.json'},
        cvss3 => {
            oneOf => [
                {'$ref' => 'https://www.first.org/cvss/cvss-v3.0.json'},
                {'$ref' => 'https://www.first.org/cvss/cvss-v3.1.json'}
            ]
        }
    };

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            if (my $cvss_v3 = $score->cvss_v3) {

                my $v             = CSAF::Schema->validator(($cvss_v3->version eq '3.1' ? 'cvss-v3.1' : 'cvss-v3.0'));
                my @schema_errors = $v->validate($cvss_v3->TO_JSON);

                foreach my $schema_error (@schema_errors) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v3" . $schema_error->path,
                        code     => '6.1.8',
                        message  => sprintf('Invalid CVSS: %s', $schema_error->message)
                    );
                }

            }

            if (my $cvss_v2 = $score->cvss_v2) {

                my $v             = CSAF::Schema->validator('cvss-v2.0');
                my @schema_errors = $v->validate($cvss_v2->TO_JSON);

                foreach my $schema_error (@schema_errors) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v2" . $schema_error->path,
                        code     => '6.1.8',
                        message  => sprintf('Invalid CVSS: %s', $schema_error->message)
                    );
                }

            }

        });
    });

}


# 6.1.9 Invalid CVSS computation

sub TEST_6_1_9 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            if (my $cvss_v2 = $score->cvss_v2) {

                #   /vulnerabilities[]/scores[]/cvss_v2/baseScore
                #   /vulnerabilities[]/scores[]/cvss_v2/temporalScore
                #   /vulnerabilities[]/scores[]/cvss_v2/environmentalScore

                my $cvss = CVSS->from_vector_string($cvss_v2->vectorString);

                my @scores = qw(
                    baseScore
                    temporalScore
                    environmentalScore
                );

                foreach my $score (@scores) {

                    if (($cvss_v2->$score && $cvss->$score) && ($cvss->$score != $cvss_v2->$score)) {
                        $self->add_message(
                            category => 'mandatory',
                            path     => "/vulnerabilities/$vuln_idx/score/$score_idx/cvss_v2",
                            code     => '6.1.9',
                            message  => 'Invalid CVSS computation'
                        );
                    }

                }

            }

            if (my $cvss_v3 = $score->cvss_v3) {

                #   /vulnerabilities[]/scores[]/cvss_v3/baseScore
                #   /vulnerabilities[]/scores[]/cvss_v3/baseSeverity
                #   /vulnerabilities[]/scores[]/cvss_v3/temporalScore
                #   /vulnerabilities[]/scores[]/cvss_v3/temporalSeverity
                #   /vulnerabilities[]/scores[]/cvss_v3/environmentalScore
                #   /vulnerabilities[]/scores[]/cvss_v3/environmentalSeverity

                my $cvss = CVSS->from_vector_string($cvss_v3->vectorString);

                my @scores = (qw[
                    baseScore
                    temporalScore
                    environmentalScore
                ]);

                my @severities = qw(
                    baseSeverity
                    temporalSeverity
                    environmentalSeverity
                );

                foreach my $score (@scores) {

                    if (($cvss_v3->$score && $cvss->$score) && ($cvss->$score != $cvss_v3->$score)) {
                        $self->add_message(
                            category => 'mandatory',
                            path     => "/vulnerabilities/$vuln_idx/score/$score_idx/cvss_v3",
                            code     => '6.1.9',
                            message  => 'Invalid CVSS computation'
                        );
                    }

                }

                foreach my $severity (@severities) {

                    if (($cvss_v3->$severity && $cvss->$severity) && ($cvss->$severity ne $cvss_v3->$severity)) {
                        $self->add_message(
                            category => 'mandatory',
                            path     => "/vulnerabilities/$vuln_idx/score/$score_idx/cvss_v3",
                            code     => '6.1.9',
                            message  => 'Invalid CVSS computation'
                        );
                    }

                }

            }

        });
    });
}


# 6.1.10 Inconsistent CVSS

sub TEST_6_1_10 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        $vulnerability->scores->each(sub {

            my ($score, $score_idx) = @_;

            # CVSS 2.0

            if (my $cvss_v2 = $score->cvss_v2) {

                my $vector_string = $cvss_v2->vectorString;
                my $cvss          = CVSS->from_vector_string($vector_string);

                return unless $vector_string;

                my @metrics = (qw[
                    accessVector
                    accessComplexity
                    authentication
                    confidentialityImpact
                    integrityImpact
                    availabilityImpact
                    exploitability
                    remediationLevel
                    reportConfidence
                    collateralDamagePotential
                    targetDistribution
                    confidentialityRequirement
                    integrityRequirement
                    availabilityRequirement
                ]);

                foreach my $metric (@metrics) {

                    my $doc_metric_value = $cvss_v2->$metric;

                    if ($doc_metric_value && $doc_metric_value ne $cvss->$metric) {
                        $self->add_message(
                            category => 'mandatory',
                            path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v2/$metric",
                            code     => '6.1.10',
                            message  => 'Inconsistent CVSS'
                        );
                    }
                }

            }

            # CVSS 3.x

            if (my $cvss_v3 = $score->cvss_v3) {

                my $vector_string = $cvss_v3->vectorString;
                my $cvss          = CVSS->from_vector_string($vector_string);

                return unless $vector_string;

                my @metrics = (qw[
                    availabilityImpact
                    attackComplexity
                    attackVector
                    confidentialityImpact
                    exploitCodeMaturity
                    integrityImpact
                    privilegesRequired
                    reportConfidence
                    remediationLevel
                    scope
                    userInteraction
                    modifiedAvailabilityImpact
                    modifiedAttackComplexity
                    modifiedAttackVector
                    modifiedConfidentialityImpact
                    modifiedIntegrityImpact
                    modifiedPrivilegesRequired
                    modifiedScope
                    modifiedUserInteraction
                ]);

                foreach my $metric (@metrics) {

                    my $doc_metric_value = $cvss_v3->$metric;

                    if ($doc_metric_value && $doc_metric_value ne $cvss->$metric) {
                        $self->add_message(
                            category => 'mandatory',
                            path     => "/vulnerabilities/$vuln_idx/scores/$score_idx/cvss_v3/$metric",
                            code     => '6.1.10',
                            message  => 'Inconsistent CVSS'
                        );
                    }
                }

            }

        });

    });

}


# 6.1.11 CWE

sub TEST_6_1_11 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        if (my $cwe_id = $vulnerability->cwe->id) {

            if (!weakness_exists($cwe_id)) {

                $self->add_message(
                    category => 'mandatory',
                    path     => "/vulnerabilities/$vuln_idx/cwe/id",
                    code     => '6.1.11',
                    message  => 'Unknown CWE'
                );

            }

        }

        if (my $cwe_name = $vulnerability->cwe->name) {

            if (get_weakness_name($vulnerability->cwe->id) ne $cwe_name) {

                $self->add_message(
                    category => 'mandatory',
                    path     => "/vulnerabilities/$vuln_idx/cwe/name",
                    code     => '6.1.11',
                    message  => 'CWE name differs from the official CWE catalog'
                );

            }
        }

    });

}


# 6.1.12 Language

sub TEST_6_1_12 {    # TODO INCOMPLETE

    my $self = shift;

    DEBUG and $self->log->warn('Incomplete Mandatory Test 6.1.12');

    my $document_lang        = $self->csaf->document->lang;
    my $document_source_lang = $self->csaf->document->source_lang;

    if ($document_lang && $document_lang !~ /[a-z]{2,3}/) {
        $self->add_message(
            category => 'mandatory',
            path     => '/document/lang',
            code     => '6.1.12',
            message  => 'Language code is invalid'
        );
    }

    if ($document_source_lang && $document_source_lang !~ /[a-z]{2,3}/) {
        $self->add_message(
            category => 'mandatory',
            path     => '/document/source_lang',
            code     => '6.1.12',
            message  => 'Language code is invalid'
        );
    }

}


# 6.1.13 PURL

sub TEST_6_1_13 {

    my $self = shift;

    # /product_tree/branches[](/branches[])*/product/product_identification_helper/purl

    $self->_TEST_6_1_13_branches($self->csaf->product_tree->branches, "/product_tree/branches");

    # /product_tree/full_product_names[]/product_identification_helper/purl

    $self->csaf->product_tree->full_product_names->each(sub {

        my ($full_product_name, $idx) = @_;

        return unless $full_product_name->product_identification_helper;

        if (my $purl = $full_product_name->product_identification_helper->purl) {
            $self->_TEST_6_1_13_check_purl($purl,
                "/product_tree/full_product_names/$idx/product_identification_helper/purl");
        }

    });

    # /product_tree/relationships[]/full_product_name/product_identification_helper/purl

    $self->csaf->product_tree->relationships->each(sub {

        my ($relationship, $rel_idx) = @_;

        return unless $relationship->full_product_name;
        return unless $relationship->full_product_name->product_identification_helper;

        if (my $purl = $relationship->full_product_name->product_identification_helper->purl) {
            $self->_TEST_6_1_13_check_purl($purl,
                "/product_tree/relationships/$rel_idx/full_product_name/product_identification_helper/purl");
        }

    });

}


# 6.1.14 Sorted Revision History

sub TEST_6_1_14 {

    my $self = shift;

    return unless $self->csaf->document->tracking->revision_history->size;

    # TODO use semver for non-decimal version

    my $last_rev_version = $self->csaf->document->tracking->revision_history->last->number;
    my $doc_version      = $self->csaf->document->tracking->version;

    my $revision_dates = {};

    foreach my $revision (@{$self->csaf->document->tracking->revision_history->items}) {
        $revision_dates->{$revision->date->epoch} = $revision->number;
    }

    my $prev_revision_number = 0;

    foreach (sort { $a <=> $b } keys %{$revision_dates}) {

        my $revision_number = $revision_dates->{$_};

        eval {
            if ($prev_revision_number && version->parse($prev_revision_number) > version->parse($revision_number)) {

                return $self->add_message(
                    category => 'mandatory',
                    path     => '/document/tracking/revision_history',
                    code     => '6.1.14',
                    message  => 'Sorted Revision History'
                );

            }
        };
        $prev_revision_number = $revision_number;
    }

    eval {

        if (version->parse($last_rev_version) > version->parse($doc_version)) {

            return $self->add_message(
                category => 'mandatory',
                path     => '/document/tracking/revision_history',
                code     => '6.1.14',
                message  => 'Sorted Revision History'
            );

        }

    };

}


# 6.1.15 Translator

sub TEST_6_1_15 {

    my $self = shift;

    if ($self->csaf->document->publisher->category eq 'translator' && !$self->csaf->document->source_lang) {

        $self->add_message(
            category => 'mandatory',
            path     => '/document/publisher/category',
            code     => '6.1.15',
            message  => 'Missing "source_lang" for "translator" publisher category'
        );

    }

}


# 6.1.16 Latest Document Version

sub TEST_6_1_16 {

    my $self = shift;

    my $current_version = 0;
    my $last_version    = undef;

    # TODO  Use semver instead of version module
    eval {

        foreach my $revision (@{$self->csaf->document->tracking->revision_history->items}) {
            $last_version = $revision->number if (version->parse($current_version) < version->parse($revision->number));
            $current_version = $revision->number;
        }

        if (version->parse($last_version) > version->parse($self->csaf->document->tracking->version)) {

            $self->add_message(
                category => 'mandatory',
                path     => '/document/tracking/version',
                code     => '6.1.16',
                message  => 'Detected newer revision of document'
            );

        }

    }

}


# 6.1.17 Document Status Draft

sub TEST_6_1_17 {

    my $self = shift;

    my $document_version = $self->csaf->document->tracking->version;
    my $document_status  = $self->csaf->document->tracking->status;

    $document_version =~ /$SEMVER_REGEXP/;

    if ($document_status ne 'draft' && ($document_version eq '0' || (%+ && ($+{major} == 0 || $+{prerelease})))) {
        $self->add_message(
            category => 'mandatory',
            path     => '/document/tracking/version',
            code     => '6.1.17',
            message  => 'Incompatible document status & version'
        );
    }

}


# 6.1.18 Released Revision History

sub TEST_6_1_18 {

    my $self = shift;

    my $document_status    = $self->csaf->document->tracking->status;
    my $document_revisions = $self->csaf->document->tracking->revision_history;

    if ($document_status =~ /(final|interim)/) {

        $document_revisions->each(sub {

            my ($revision, $rev_idx) = @_;

            $revision->number =~ /$SEMVER_REGEXP/;

            if ($revision->number eq '0' || (%+ && ($+{major} == 0))) {
                $self->add_message(
                    category => 'mandatory',
                    path     => "/document/tracking/revision_history/$rev_idx/number",
                    code     => '6.1.18',
                    message  => 'Incompatible revision number with document status'
                );
            }

        });

    }

}


# 6.1.19 Revision History Entries for Pre-release Versions

sub TEST_6_1_19 {

    my $self = shift;

    my $document_revisions = $self->csaf->document->tracking->revision_history;

    $document_revisions->each(sub {

        my ($revision, $rev_idx) = @_;

        $revision->number =~ /$SEMVER_REGEXP/;

        if (%+ && $+{prerelease}) {
            $self->add_message(
                category => 'mandatory',
                path     => "/document/tracking/revision_history/$rev_idx/number",
                code     => '6.1.19',
                message  => 'Revision History contains a pre-release'
            );
        }

    });

}


# 6.1.20 Non-draft Document Version

sub TEST_6_1_20 {

    my $self = shift;

    my $document_version = $self->csaf->document->tracking->version;
    my $document_status  = $self->csaf->document->tracking->status;

    if ($document_status =~ /(final|interim)/) {

        $document_version =~ /$SEMVER_REGEXP/;

        if (%+ && $+{prerelease}) {
            $self->add_message(
                category => 'mandatory',
                path     => '/document/tracking/version',
                code     => '6.1.20',
                message  => qq{Detected a pre-release version with "$document_status" document}
            );
        }
    }


}


# 6.1.21 Missing Item in Revision History

sub TEST_6_1_21 {

    my $self = shift;

    my @revision_numbers = ();

    foreach my $revision (@{$self->csaf->document->tracking->revision_history->items}) {
        push @revision_numbers, $revision->number if ($revision->number =~ /^(\d+)$/);
    }

    my $prev_revision_number = 0;

    foreach my $revision_number (sort @revision_numbers) {
        if (($revision_number - $prev_revision_number) > 1) {
            return $self->add_message(
                category => 'mandatory',
                path     => '/document/tracking/revision_history',
                code     => '6.1.21',
                message  => 'Missing Item in Revision History'
            );
        }
        $prev_revision_number = $revision_number;
    }

}


# 6.1.22 Multiple Definition in Revision History

sub TEST_6_1_22 {

    my $self = shift;

    my $check = {};

    $self->csaf->document->tracking->revision_history->each(sub {

        my ($revision, $rev_idx) = @_;

        $check->{$revision->number}++;

        if ($check->{$revision->number} > 1) {

            $self->add_message(
                category => 'mandatory',
                path     => "/document/tracking/revision_history/$rev_idx/number",
                code     => '6.1.22',
                message  => 'Multiple Definition in Revision History'
            );

        }

    });

}


# 6.1.23 Multiple Use of Same CVE

sub TEST_6_1_23 {

    my $self = shift;

    my $check = {};

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        return unless $vulnerability->cve;

        $check->{$vulnerability->cve}++;

        if ($check->{$vulnerability->cve} > 1) {
            $self->add_message(
                category => 'mandatory',
                path     => "/vulnerabilities/$vuln_idx/cve",
                code     => '6.1.23',
                message  => sprintf('Multiple Use of Same CVE (%s)', $vulnerability->cve)
            );
        }

    });

}


# 6.1.24 Multiple Definition in Involvements

sub TEST_6_1_24 {

    my $self = shift;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        return if (!$vulnerability->involvements->size);

        my $check = {};

        foreach my $involvement ($vulnerability->involvements->each) {

            next unless ($involvement->date);

            $check->{$involvement->date->epoch} //= {};
            $check->{$involvement->date->epoch}->{$involvement->party} //= 0;
            $check->{$involvement->date->epoch}->{$involvement->party}++;

            if ($check->{$involvement->date->epoch}->{$involvement->party} > 1) {
                return $self->add_message(
                    category => 'mandatory',
                    path     => "/vulnerabilities/$vuln_idx/involvements",
                    code     => '6.1.24',
                    message  => 'Multiple Definition in Involvements'
                );
            }
        }

    });

}


# 6.1.25 Multiple Use of Same Hash Algorithm

sub TEST_6_1_25 {    # TODO INCOMPLETE

    my $self = shift;

    DEBUG and $self->log->warn('Incomplete Mandatory Test 6.1.25');

    # /product_tree/branches[](/branches[])*/product/product_identification_helper/hashes[]/file_hashes

    $self->_TEST_6_1_25_branches($self->csaf->product_tree->branches, '/product_tree/branches');

    # /product_tree/relationships[]/full_product_name/product_identification_helper/hashes[]/file_hashes

    # TODO INCOMPLETE TEST

    # /product_tree/full_product_names[]/product_identification_helper/hashes[]/file_hashes

    my $full_product_names = $self->csaf->product_tree->full_product_names;

    $full_product_names->each(sub {

        my ($full_product_name, $idx) = @_;

        return unless $full_product_name->product_identification_helper;

        $full_product_name->product_identification_helper->hashes->each(sub {

            my ($hash, $hash_idx) = @_;

            my $check = {};

            $hash->file_hashes->each(sub {

                my ($file_hash, $file_hash_idx) = @_;

                $check->{$file_hash->algorithm}++;

                if ($check->{$file_hash->algorithm} > 1) {

                    my $path = "/product_tree/full_product_names/$idx/product_identification_helper"
                        . "/hashes/$hash_idx/file_hashes/$file_hash_idx/";

                    $self->add_message(
                        category => 'mandatory',
                        path     => $path,
                        code     => '6.1.25',
                        message  => sprintf('Multiple Use of Same Hash Algorithm (%s)', $file_hash->algorithm)
                    );

                }

            });

        });

    });

}


# 6.1.26 Prohibited Document Category Name

sub TEST_6_1_26 {

    my $self = shift;

    my $document_category = $self->csaf->document->category;

    if ($document_category
        !~ /(csaf_base|csaf_security_incident_response|csaf_informational_advisory|csaf_security_advisory|csaf_vex)/)
    {

        if ($document_category =~ /^csaf_/i) {
            $self->add_message(
                category => 'mandatory',
                path     => '/document/category',
                code     => '6.1.26',
                message  => 'Reserved CSAF document category prefix'
            );
        }

        my $check_similar_category = 0;

        my @similar_categories = qw(
            informationaladvisory
            securityincidentresponse
            securityadvisory
            vex
        );

        (my $normalized_category = lc $document_category) =~ s/[-_\s]//g;

        if (first { $normalized_category =~ /^$_/ } @similar_categories) {
            $self->add_message(
                category => 'mandatory',
                path     => '/document/category',
                code     => '6.1.26',
                message  => 'Prohibited document category'
            );
        }

    }
}


# 6.1.27.1 Document Notes

sub TEST_6_1_27_1 {

    my $self = shift;

    my $document_category = $self->csaf->document->category;
    my $document_notes    = $self->csaf->document->notes->items;

    return if (not $document_category =~ /(csaf_informational_advisory|csaf_security_incident_response)/);

    my $have_valid_category = undef;

    foreach my $note (@{$document_notes}) {
        foreach my $category (qw(description details general summary)) {
            $have_valid_category = 1 if ($note->category eq $category);
        }
    }

    if (not $have_valid_category) {
        $self->add_message(
            category => 'mandatory',
            path     => '/document/notes',
            code     => '6.1.27.1',
            message  =>
                'The document notes do not contain an item which has a category of "description", "details", "general" or "summary"'
        );
    }

}


# 6.1.27.2 Document References

sub TEST_6_1_27_2 {

    my $self = shift;

    my $document_category   = $self->csaf->document->category;
    my $document_references = $self->csaf->document->references->items;

    return if (not $document_category =~ /(csaf_informational_advisory|csaf_security_incident_response)/);

    my $have_external_references = undef;

    foreach my $reference (@{$document_references}) {
        $have_external_references = 1 if ($reference->category eq 'external');
    }

    if (not $have_external_references) {
        $self->add_message(
            category => 'mandatory',
            path     => '/document/references',
            code     => '6.1.27.2',
            message  => 'The document references do not contain any item which has the category "external"'
        );
    }

}


# 6.1.27.3 Vulnerabilities

sub TEST_6_1_27_3 {

    my $self = shift;

    if ($self->csaf->document->category eq 'csaf_informational_advisory' && @{$self->csaf->vulnerabilities->items}) {

        $self->add_message(
            category => 'mandatory',
            path     => '/vulnerabilities',
            code     => '6.1.27.3',
            message  =>
                'The "csaf_informational_advisory" profile deals with information that are not classified as vulnerabilities. Therefore, it must not have the "/vulnerabilities" element'
        );

    }

}


# 6.1.27.4 Product Tree

sub TEST_6_1_27_4 {

    my $self = shift;

    my $document_category = $self->csaf->document->category;
    my $product_tree      = $self->csaf->product_tree->TO_CSAF;    # TODO !?

    if ($document_category =~ /(csaf_security_advisory|csaf_vex)/ && !$product_tree) {

        $self->add_message(
            category => 'mandatory',
            path     => '/product_tree',
            code     => '6.1.27.4',
            message  => 'The element "/product_tree" does not exist'
        );

    }

}


# 6.1.27.5 Vulnerability Notes

sub TEST_6_1_27_5 {

    my $self = shift;

    return if (not $self->csaf->document->category =~ /(csaf_security_advisory|csaf_vex)/);

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        if (!$vulnerability->notes->size) {
            $self->add_message(
                category => 'mandatory',
                path     => "/vulnerabilities/$vuln_idx",
                code     => '6.1.27.5',
                message  => 'The vulnerability item has no "notes" element'
            );
        }

    });

}


# 6.1.27.6 Product Status

sub TEST_6_1_27_6 {

    my $self = shift;

    return if (not $self->csaf->document->category eq 'csaf_security_advisory');

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        if (!$vulnerability->product_status->TO_CSAF) {
            $self->add_message(
                category => 'mandatory',
                path     => "/vulnerabilities/$vuln_idx",
                code     => '6.1.27.6',
                message  => 'The vulnerability item has no "product_status" element'
            );
        }

    });

}


# 6.1.27.7 VEX Product Status

sub TEST_6_1_27_7 {

    my $self = shift;

    return if (not $self->csaf->document->category eq 'csaf_vex');

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        my @check = (
            @{$vulnerability->product_status->fixed},
            @{$vulnerability->product_status->known_affected},
            @{$vulnerability->product_status->known_not_affected},
            @{$vulnerability->product_status->under_investigation}
        );

        unless (@check) {
            $self->add_message(
                category => 'mandatory',
                path     => "/vulnerabilities/$vuln_idx/product_status",
                code     => '6.1.27.7',
                message  =>
                    'None of the elements "fixed", "known_affected", "known_not_affected", or "under_investigation" is present in "product_status"'
            );
        }

    });


}


# 6.1.27.8 Vulnerability ID

sub TEST_6_1_27_8 {

    my $self = shift;

    return if (not $self->csaf->document->category eq 'csaf_vex');

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        if (!$vulnerability->cve && $vulnerability->ids->size == 0) {
            $self->add_message(
                category => 'mandatory',
                path     => "/vulnerabilities/$vuln_idx",
                code     => '6.1.27.8',
                message  => 'None of the elements "cve" or "ids" is present'
            );
        }

    });

}


# 6.1.27.9 Impact Statement

sub TEST_6_1_27_9 {

    my $self = shift;

    return if (not $self->csaf->document->category eq 'csaf_vex');
    return unless $self->csaf->vulnerabilities->size;

    my $product_ids = $CSAF::CACHE->{products} || {};

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        return unless @{$vulnerability->product_status->known_not_affected};

        my @status_product_ids = @{$vulnerability->product_status->known_not_affected};

        CSAF::Util::List->new(@status_product_ids)->each(sub {

            my ($product_id, $product_id_idx) = @_;

            my $threat_test = 0;
            my $flag_test   = 0;

            $vulnerability->threats->grep(sub { $_->category eq 'impact' })->each(sub {

                my ($threat, $threat_idx) = @_;

                if (first { $product_id eq $_ } @{$threat->product_ids}) {
                    $threat_test = 1;
                    return;
                }

                foreach my $group_id (@{$threat->group_ids}) {

                    if (product_in_group_exists($self->csaf, $product_id, $group_id)) {
                        $threat_test = 1;
                        return;
                    }

                }

                $threat_test = 0;

            });

            $vulnerability->flags->each(sub {

                my ($flag, $flag_idx) = @_;

                if (first { $product_id eq $_ } @{$flag->product_ids}) {
                    $flag_test = 1;
                    return;
                }

                foreach my $group_id (@{$flag->group_ids}) {

                    if (product_in_group_exists($self->csaf, $product_id, $group_id)) {
                        $flag_test = 1;
                        return;
                    }

                }

                $flag_test = 0;

            });

            if (!$flag_test && !$threat_test) {
                $self->add_message(
                    category => 'mandatory',
                    path     =>
                        sprintf('/vulnerabilities/%s/product_status/known_not_affected/%s', $vuln_idx, $product_id_idx),
                    code    => '6.1.27.9',
                    message => 'Impact Statement'
                );
            }

        });

    });

}


# 6.1.27.10 Action Statement

sub TEST_6_1_27_10 {

    my $self = shift;

    return if (not $self->csaf->document->category eq 'csaf_vex');
    return unless $self->csaf->vulnerabilities->size;

    my $product_ids = $CSAF::CACHE->{products} || {};

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        return unless @{$vulnerability->product_status->known_affected};

        my @status_product_ids = @{$vulnerability->product_status->known_affected};

        CSAF::Util::List->new(@status_product_ids)->each(sub {

            my ($product_id, $product_id_idx) = @_;

            my $threat_test = 0;

            $vulnerability->remediations->each(sub {

                my ($remediation, $remediation_idx) = @_;

                if (first { $product_id eq $_ } @{$remediation->product_ids}) {
                    $threat_test = 1;
                    return;
                }

                foreach my $group_id (@{$remediation->group_ids}) {

                    if (product_in_group_exists($self->csaf, $product_id, $group_id)) {
                        $threat_test = 1;
                        return;
                    }

                }

                $threat_test = 0;

            });

            if (!$threat_test) {
                $self->add_message(
                    category => 'mandatory',
                    path     => "/vulnerabilities/$vuln_idx/product_status/known_not_affected/$product_id_idx",
                    code     => '6.1.27.10',
                    message  => 'Action Statement'
                );
            }

        });

    });

}


# 6.1.27.11 Vulnerabilities

sub TEST_6_1_27_11 {

    my $self = shift;

    if (   $self->csaf->document->category =~ /(csaf_security_advisory|csaf_vex)/
        && $self->csaf->vulnerabilities->size == 0)
    {

        $self->add_message(
            category => 'mandatory',
            path     => '/vulnerabilities',
            code     => '6.1.27.11',
            message  => 'The element "/vulnerabilities" does not exist'
        );

    }

}


# 6.1.28 Translation

sub TEST_6_1_28 {

    my $self = shift;

    my $document_lang        = $self->csaf->document->lang;
    my $document_source_lang = $self->csaf->document->source_lang;

    if ($document_lang && $document_source_lang && ($document_lang eq $document_source_lang)) {
        $self->add_message(
            category => 'mandatory',
            path     => '/document/lang',
            code     => '6.1.28',
            message  => qq{The document language and the source language have the same value "$document_lang"}
        );
    }

}


# 6.1.29 Remediation without Product Reference

sub TEST_6_1_29 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    my $product_ids = $CSAF::CACHE->{products} || {};

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        return unless $vulnerability->remediations->size;

        $vulnerability->remediations->each(sub {

            my ($remediation, $remediation_idx) = @_;

            if (!@{$remediation->product_ids}) {
                return $self->add_message(
                    category => 'mandatory',
                    path     => "/vulnerabilities/$vuln_idx/remediations/$remediation_idx",
                    code     => '6.1.29',
                    message  => 'Remediation without Product Reference'
                );
            }

            foreach my $product_id (@{$remediation->product_ids}) {
                if (!first { $product_id eq $_ } keys %{$product_ids}) {
                    return $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/remediations/$remediation_idx",
                        code     => '6.1.29',
                        message  => 'Remediation without Product Reference'
                    );
                }
            }

        });

    });

}


# 6.1.30 Mixed Integer and Semantic Versioning

sub TEST_6_1_30 {

    my $self = shift;

    my $document_version   = $self->csaf->document->tracking->version;
    my $document_revisions = $self->csaf->document->tracking->revision_history;

    my $revision_ver_in_semver = 0;
    my $revision_ver_in_int    = 0;

    my $document_ver_in_semver = 0;
    my $document_ver_in_int    = 0;

    $document_revisions->each(sub {

        my ($revision, $rev_idx) = @_;

        if ($revision->number =~ /$SEMVER_REGEXP/) {
            $revision_ver_in_semver++;
        }
        else {
            $revision_ver_in_int++;
        }

    });

    if ($document_version =~ /$SEMVER_REGEXP/) {
        $document_ver_in_semver++;
    }
    else {
        $document_ver_in_int++;
    }

    if ($document_ver_in_int && $revision_ver_in_semver || $document_ver_in_semver && $revision_ver_in_int) {
        $self->add_message(
            category => 'mandatory',
            path     => "/document/tracking/version",
            code     => '6.1.30',
            message  => 'Mixed Integer and Semantic Versioning'
        );
    }

}


# 6.1.31 Version Range in Product Version

sub TEST_6_1_31 {

    my $self = shift;

    return if (not $self->csaf->product_tree);

    $self->_TEST_6_1_31_branches($self->csaf->product_tree->branches, "/product_tree/branches");

}


# 6.1.32 Flag without Product Reference

sub TEST_6_1_32 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    my $product_ids = $CSAF::CACHE->{products} || {};

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        return unless $vulnerability->flags->size;

        $vulnerability->flags->each(sub {

            my ($flag, $flag_idx) = @_;

            if (!@{$flag->group_ids} && !@{$flag->product_ids}) {
                return $self->add_message(
                    category => 'mandatory',
                    path     => "/vulnerabilities/$vuln_idx/flags/$flag_idx",
                    code     => '6.1.32',
                    message  => 'Flag without Product Reference'
                );
            }

            foreach my $product (keys %{$product_ids}) {

                if (@{$flag->product_ids} && !first { $product eq $_ } @{$flag->product_ids}) {
                    return $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/flags/$flag_idx",
                        code     => '6.1.32',
                        message  => 'Flag without Product Reference'
                    );
                }

                if (@{$flag->group_ids} && !first { $product eq $_ } @{$flag->group_ids}) {
                    return $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/flags/$flag_idx",
                        code     => '6.1.32',
                        message  => 'Flag without Product Reference'
                    );
                }
            }

        });

    });

}


# 6.1.33 Multiple Flags with VEX Justification Codes per Product

sub TEST_6_1_33 {

    my $self = shift;

    return unless $self->csaf->vulnerabilities->size;

    $self->csaf->vulnerabilities->each(sub {

        my ($vulnerability, $vuln_idx) = @_;

        my @product_ids = ();

        $vulnerability->flags->each(sub {

            my ($flag, $flag_idx) = @_;

            foreach my $product_id (@{$flag->product_ids}) {

                if (first { $product_id eq $_ } @product_ids) {
                    return $self->add_message(
                        category => 'mandatory',
                        path     => "/vulnerabilities/$vuln_idx/flags/$flag_idx",
                        code     => '6.1.33',
                        message  => 'Multiple Flags with VEX Justification Codes per Product'
                    );
                }

                push @product_ids, $product_id;

            }

            foreach my $group_id (@{$flag->group_ids}) {

                $self->csaf->product_tree->product_groups->each(sub {

                    my ($group) = @_;

                    if ($group->group_id eq $group_id) {

                        foreach my $product_id (@{$group->product_ids}) {

                            if (first { $product_id eq $_ } @product_ids) {
                                return $self->add_message(
                                    category => 'mandatory',
                                    path     => "/vulnerabilities/$vuln_idx/flags/$flag_idx",
                                    code     => '6.1.33',
                                    message  => 'Multiple Flags with VEX Justification Codes per Product'
                                );
                            }

                            push @product_ids, $product_id;

                        }

                    }

                });

            }

        });

    });

}


sub _TEST_6_1_13_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $branch_idx) = @_;

        $self->_TEST_6_1_13_branches($branch->branches, "$path/$branch_idx/branches");

        return unless $branch->product;
        return unless $branch->product->product_identification_helper;
        return unless $branch->product->product_identification_helper->purl;

        $self->_TEST_6_1_13_check_purl($branch->product->product_identification_helper->purl,
            "$path/$branch_idx/product");

    });

}

sub _TEST_6_1_13_check_purl {

    my ($self, $purl, $path) = @_;

    my $is_invalid = 0;

    $is_invalid = 1 if $purl !~ /$PURL_REGEX/;

    eval { URI::PackageURL->from_string($purl) };

    if ($@) {
        $is_invalid = 1 if $@;
        DEBUG and $self->log->error($@);
    }

    if ($is_invalid) {
        $self->add_message(category => 'mandatory', path => $path, code => '6.1.13', message => 'Invalid purl');
    }

}

sub _TEST_6_1_25_branches {

    my ($self, $branches, $path) = @_;

    $branches->each(sub {

        my ($branch, $branch_idx) = @_;

        $self->_TEST_6_1_25_branches($branch->branches, "$path/$branch_idx/branches");

        if (   $branch->product
            && $branch->product->product_identification_helper
            && $branch->product->product_identification_helper->hashes->size)
        {

            $branch->product->product_identification_helper->hashes->each(sub {

                my ($hash, $hash_idx) = @_;

                my $check = {};

                $hash->file_hashes->each(sub {

                    my ($file_hash, $file_hash_idx) = @_;

                    $check->{$file_hash->algorithm}++;

                    if ($check->{$file_hash->algorithm} > 1) {

                        $self->add_message(
                            type => 'Mandatory Test',
                            path =>
                                "/$path/$branch_idx/product_identification_helper/hashes/$hash_idx/file_hashes/$file_hash_idx/",
                            code    => '6.1.25',
                            message => sprintf('Multiple Use of Same Hash Algorithm (%s)', $file_hash->algorithm)
                        );

                    }

                });

            });

        }

    });
}

sub _TEST_6_1_31_branches {

    my ($self, $branches, $path) = @_;

    my @bad_ranges = qw( < <= > >= );
    my @bad_words  = qw( after all before earlier later prior versions );

    $branches->each(sub {

        my ($branch, $idx) = @_;

        $self->_TEST_6_1_31_branches($branch->branches, "$path/$idx/branches");

        if ($branch->category eq 'product_version') {

            my @branch_name_parts = split /\s/, lc $branch->name;

            foreach my $word (@bad_words) {

                if (first { $word eq $_ } @branch_name_parts) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "$path/name",
                        code     => '6.1.31',
                        message  => 'Version Range in Product Version'
                    );
                }
            }

            foreach my $range (@bad_ranges) {
                if (lc $branch->name =~ /$range/) {
                    $self->add_message(
                        category => 'mandatory',
                        path     => "$path/name",
                        code     => '6.1.31',
                        message  => 'Version Range in Product Version'
                    );
                }
            }
        }

    });
}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Validator::MandatoryTests

=head1 SYNOPSIS

    use CSAF::Validator::MandatoryTests;

    my $v = CSAF::Validator::MandatoryTests->new( csaf => $csaf );

    $v->exec_test('6.1.5');
    $v->TEST_6_1_5;


=head1 DESCRIPTION

Mandatory tests MUST NOT fail at a valid L<CSAF> document.

    6.1.1 Missing Definition of Product ID
    6.1.2 Multiple Definition of Product ID
    6.1.3 Circular Definition of Product ID
    6.1.4 Missing Definition of Product Group ID
    6.1.5 Multiple Definition of Product Group ID
    6.1.6 Contradicting Product Status
    6.1.7 Multiple Scores with same Version per Product
    6.1.8 Invalid CVSS
    6.1.9 Invalid CVSS computation
    6.1.10 Inconsistent CVSS
    6.1.11 CWE
    6.1.12 Language
    6.1.13 PURL
    6.1.14 Sorted Revision History
    6.1.15 Translator
    6.1.16 Latest Document Version
    6.1.17 Document Status Draft
    6.1.18 Released Revision History
    6.1.19 Revision History Entries for Pre-release Versions
    6.1.20 Non-draft Document Version
    6.1.21 Missing Item in Revision History
    6.1.22 Multiple Definition in Revision History
    6.1.23 Multiple Use of Same CVE
    6.1.24 Multiple Definition in Involvements
    6.1.25 Multiple Use of Same Hash Algorithm
    6.1.26 Prohibited Document Category Name
    6.1.27 Profile Tests
        6.1.27.1 Document Notes
        6.1.27.2 Document References
        6.1.27.3 Vulnerabilities
        6.1.27.4 Product Tree
        6.1.27.5 Vulnerability Notes
        6.1.27.6 Product Status
        6.1.27.7 VEX Product Status
        6.1.27.8 Vulnerability ID
        6.1.27.9 Impact Statement
        6.1.27.10 Action Statement
        6.1.27.11 Vulnerabilities
    6.1.28 Translation
    6.1.29 Remediation without Product Reference
    6.1.30 Mixed Integer and Semantic Versioning
    6.1.31 Version Range in Product Version
    6.1.32 Flag without Product Reference
    6.1.33 Multiple Flags with VEX Justification Codes per Product

=head2 METHODS

L<CSAF::Validator::MandatoryTests> inherits all methods from L<CSAF::Validator::Base> and implements the following new ones.

=over

=item TEST_6_1_1

Missing Definition of Product ID

=item TEST_6_1_2

Multiple Definition of Product ID

=item TEST_6_1_3

Circular Definition of Product ID

=item TEST_6_1_4

Missing Definition of Product Group ID

=item TEST_6_1_5

Multiple Definition of Product Group ID

=item TEST_6_1_6

Contradicting Product Status

=item TEST_6_1_7

Multiple Scores with same Version per Product

=item TEST_6_1_8

Invalid CVSS

=item TEST_6_1_9

Invalid CVSS computation

=item TEST_6_1_10

Inconsistent CVSS

=item TEST_6_1_11

CWE

=item TEST_6_1_12

Language

=item TEST_6_1_13

PURL

=item TEST_6_1_14

Sorted Revision History

=item TEST_6_1_15

Translator

=item TEST_6_1_16

Latest Document Version

=item TEST_6_1_17

Document Status Draft

=item TEST_6_1_18

Released Revision History

=item TEST_6_1_19

Revision History Entries for Pre-release Versions

=item TEST_6_1_20

Non-draft Document Version

=item TEST_6_1_21

Missing Item in Revision History

=item TEST_6_1_22

Multiple Definition in Revision History

=item TEST_6_1_23

Multiple Use of Same CVE

=item TEST_6_1_24

Multiple Definition in Involvements

=item TEST_6_1_25

Multiple Use of Same Hash Algorithm

=item TEST_6_1_26

Prohibited Document Category Name

=item TEST_6_1_27_1

Profile Test - Document Notes

=item TEST_6_1_27_2

Profile Test - Document References

=item TEST_6_1_27_3

Profile Test - Vulnerabilities

=item TEST_6_1_27_4

Profile Test - Product Tree

=item TEST_6_1_27_5

Profile Test - Vulnerability Notes

=item TEST_6_1_27_6

Profile Test - Product Status

=item TEST_6_1_27_7

Profile Test - VEX Product Status

=item TEST_6_1_27_8

Profile Test - Vulnerability ID

=item TEST_6_1_27_9

Profile Test - Impact Statement

=item TEST_6_1_27_10

Profile Test - Action Statement

=item TEST_6_1_27_11

Profile Test - Vulnerabilities

=item TEST_6_1_28

Translation

=item TEST_6_1_29

Remediation without Product Reference

=item TEST_6_1_30

Mixed Integer and Semantic Versioning

=item TEST_6_1_31

Version Range in Product Version

=item TEST_6_1_32

Flag without Product Reference

=item TEST_6_1_33

Multiple Flags with VEX Justification Codes per Product


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
