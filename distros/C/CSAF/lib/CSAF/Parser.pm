package CSAF::Parser;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF;
use CSAF::Util qw(file_read);
use CSAF::Schema;
use List::Util qw(first);
use Cpanel::JSON::XS;

use Moo;

has file    => (is => 'ro');
has content => (is => 'ro');
has data    => (is => 'rw');

sub parse {

    my $self = shift;

    if ($self->content || $self->file) {

        my $content = $self->content;

        if ($self->file) {
            Carp::croak sprintf('File "%s" not found', $self->file) unless (-e $self->file);
            $content = file_read($self->file);
        }

        Carp::croak "Empty 'content'" unless $content;

        my $json = eval { Cpanel::JSON::XS->new->decode($content) };

        Carp::croak "Failed to parse the CSAF document: $@" if ($@);

        $self->data($json);

    }

    my $data = $self->data;

    Carp::croak 'Invalid CSAF document' unless (exists $data->{document});

    my $csaf = CSAF->new;

    if (my $document = $data->{document}) {

        $csaf->document->title($document->{title});
        $csaf->document->category($document->{category});
        $csaf->document->csaf_version($document->{csaf_version});

        $csaf->document->lang($document->{lang})               if ($document->{lang});
        $csaf->document->source_lang($document->{source_lang}) if ($document->{source_lang});

        if (my $aggregate_severity = $document->{aggregate_severity}) {
            $csaf->document->aggregate_severity(%{$aggregate_severity});
        }

        if (my $distribution = $document->{distribution}) {

            $csaf->document->distribution(%{$distribution});

            if (my $tlp = $distribution->{tlp}) {
                $csaf->document->distribution->tlp(%{$tlp});
            }

        }

        $csaf->document->publisher(%{$document->{publisher}});

        if (my $notes = $document->{notes}) {
            $csaf->document->notes->item(%{$_}) for (@{$notes});
        }

        if (my $references = $document->{references}) {
            $csaf->document->references->item(%{$_}) for (@{$references});
        }

        if (my $tracking = $document->{tracking}) {
            $csaf->document->tracking(%{$tracking});
            $csaf->document->tracking->generator(%{$tracking->{generator}}) if ($tracking->{generator});
            $csaf->document->tracking->generator->engine(%{$tracking->{generator}->{engine}})
                if ($tracking->{generator}->{engine});
            $csaf->document->tracking->revision_history->item(%{$_}) for (@{$tracking->{revision_history}});
        }

        if (my $acknowledgments = $document->{acknowledgments}) {
            $csaf->document->acknowledgments->item(%{$_}) for (@{$acknowledgments});
        }

    }

    if (my $vulnerabilities = $data->{vulnerabilities}) {
        foreach my $vulnerability (@{$vulnerabilities}) {

            my $vuln = $csaf->vulnerabilities->item(cve => $vulnerability->{cve});

            if (my $cwe = $vulnerability->{cwe}) {
                $vuln->cwe(%{$cwe});
            }

            if (my $notes = $vulnerability->{notes}) {
                $vuln->notes->item(%{$_}) for (@{$notes});
            }

            if (my $references = $vulnerability->{references}) {
                $vuln->references->item(%{$_}) for (@{$references});
            }

            if (my $product_status = $vulnerability->{product_status}) {
                $vuln->product_status(%{$product_status});
            }

            if (my $scores = $vulnerability->{scores}) {
                $vuln->scores->item(%{$_}) for (@{$scores});
            }

            if (my $acknowledgments = $vulnerability->{acknowledgments}) {
                $vuln->acknowledgments->item(%{$_}) for (@{$acknowledgments});
            }

            if (my $remediations = $vulnerability->{remediations}) {
                $vuln->remediations->item(%{$_}) for (@{$remediations});
            }

            if (my $threats = $vulnerability->{threats}) {
                $vuln->threats->item(%{$_}) for (@{$threats});
            }

            if (my $involvements = $vulnerability->{involvements}) {
                $vuln->involvements->item(%{$_}) for (@{$involvements});
            }

            if (my $flags = $vulnerability->{flags}) {
                $vuln->flags->item(%{$_}) for (@{$flags});
            }

            if (my $ids = $vulnerability->{ids}) {
                $vuln->ids->item(%{$_}) for (@{$ids});
            }

        }
    }


    if (my $product_tree = $data->{product_tree}) {

        my $csaf_product_tree = $csaf->product_tree;

        if (my $branches = $product_tree->{branches}) {
            _branches_walk($branches, $csaf_product_tree);
        }

        if (my $relationships = $product_tree->{relationships}) {
            $csaf_product_tree->relationships->item(%{$_}) for (@{$relationships});
        }

        if (my $product_groups = $product_tree->{product_groups}) {
            $csaf_product_tree->product_groups->item(%{$_}) for (@{$product_groups});
        }

        if (my $full_product_names = $product_tree->{full_product_names}) {
            $csaf_product_tree->full_product_names->item(%{$_}) for (@{$full_product_names});
        }

    }

    my $v = $csaf->validator;

    my $schema = CSAF::Schema->validator('strict-csaf-2.0');
    my @errors = $schema->validate($data);

    foreach my $error (@errors) {
        if (first { 'additionalProperties' eq $_ } @{$error->details}) {
            $v->add_message(
                type     => 'warning',
                category => 'optional',
                path     => $error->path,
                code     => '6.2.20',
                message  => $error->message
            );
        }
    }

    return $csaf;

}

sub _branches_walk {

    my ($branches, $csaf) = @_;

    foreach my $branch (@{$branches}) {
        if (defined $branch->{branches}) {
            _branches_walk($branch->{branches}, $csaf->branches->item(%{$branch}));
        }
        else {
            $csaf->branches->item(%{$branch});
        }
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Parser - Parse a CSAF document

=head1 SYNOPSIS

    use CSAF::Parser;

    my $parser = eval { CSAF::Parser->new(file => 'csaf-2023-01.json') };

    Carp::croak "Failed to parse CSAF document" if ($@);

    my $csaf = $parser->parse;

    $csaf->document->title('CSAF Document');

    $csaf->to_string;


=head1 DESCRIPTION

CSAF document parser.

=head2 ATTRIBUTES

=over

=item data

CSAF document hash.

=item file

CSAF document file.

=item content

CSAF document string.

=back

=head2 METHODS

=over

=item new ([file => ($path | <FH>) | content => $json_string | data => $hash])

CSAF document file:

    my $parser = CSAF::Parser->new(file => 'csaf-2023-01.json');

    open (my $fh, '<', 'csaf-2023-01.json') or die $!;
    my $parser = CSAF::Parser->new(file => $fh);


CSAF document in JSON string format:

    my $parser = CSAF::Parser->new(content => <<JSON);
    {
      "document": {
        "category": "csaf_base",
        "csaf_version": "2.0",
        "publisher": {
          "category": "other",
          "name": "OASIS CSAF TC",
          "namespace": "https://csaf.io"
        },
        "title": "Template for generating CSAF files for Validator examples",
        "tracking": {
          "current_release_date": "2021-07-21T10:00:00.000Z",
          "id": "OASIS_CSAF_TC-CSAF_2.0-2021-TEMPLATE",
          "initial_release_date": "2021-07-21T10:00:00.000Z",
          "revision_history": [
            {
              "date": "2021-07-21T10:00:00.000Z",
              "number": "1",
              "summary": "Initial version."
            }
          ],
          "status": "final",
          "version": "1"
        }
      }
    }
    JSON


CSAF document hash:

    my $parser = CSAF::Parser->new(data => {
      "document" => {
        "category" => "csaf_base",
        "csaf_version" => "2.0",
        "publisher" => {
          "category" => "other",
          "name" => "OASIS CSAF TC",
          "namespace" => "https://csaf.io"
        },
        "title" => "Template for generating CSAF files for Validator examples",
        "tracking" => {
          "current_release_date" => "2021-07-21T10:00:00.000Z",
          "id" => "OASIS_CSAF_TC-CSAF_2.0-2021-TEMPLATE",
          "initial_release_date" => "2021-07-21T10:00:00.000Z",
          "revision_history" => [
            {
              "date" => "2021-07-21T10:00:00.000Z",
              "number" => 1,
              "summary" => "Initial version."
            }
          ],
          "status" => "final",
          "version" => 1
        }
      }
    });

=item parse

Parse the provided CSAF document and return L<CSAF>.

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
