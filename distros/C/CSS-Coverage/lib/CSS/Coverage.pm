package CSS::Coverage;
{
  $CSS::Coverage::VERSION = '0.04';
}
use Moose;
use CSS::SAC;
use CSS::Coverage::Document;
use CSS::Coverage::XPath;
use CSS::Coverage::Report;
use HTML::TreeBuilder::XPath;

with 'CSS::Coverage::DocumentDelegate';

has css => (
    is       => 'ro',
    isa      => 'Str|ScalarRef',
    required => 1,
);

has documents => (
    is       => 'ro',
    isa      => 'ArrayRef[Str|ScalarRef]',
    required => 1,
);

has html_trees => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => '_build_html_trees',
    lazy    => 1,
);

has _sac_document => (
    is      => 'ro',
    isa     => 'CSS::Coverage::Document',
    default => sub { CSS::Coverage::Document->new(delegate => shift) },
    lazy    => 1,
);

has _report => (
    is      => 'rw',
    isa     => 'CSS::Coverage::Report',
    clearer => '_clear_report',
);

has _ignore_next_rule => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub _build_html_trees {
    my $self = shift;
    my @trees;

    for my $document (@{ $self->documents }) {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->ignore_unknown(0);

        if (ref($document)) {
            $tree->parse($$document);
            $tree->eof;
        }
        else {
            $tree->parse_file($document);
        }

        push @trees, $tree;
    }

    return \@trees;
}

sub check {
    my $self = shift;

    my $sac = CSS::SAC->new({
        DocumentHandler => $self->_sac_document,
    });

    my $report = CSS::Coverage::Report->new;
    $self->_report($report);

    my $css = $self->css;
    if (ref($css)) {
        $sac->parse({ string => $$css });
    }
    else {
        $sac->parse({ filename => $css });
    }

    $self->_clear_report;

    return $report;
}

# -- CSS::Coverage::DocumentDelegate

sub _check_selector {
    my ($self, $selector) = @_;

    if ($self->_ignore_next_rule) {
        $self->_ignore_next_rule(0);
        return;
    }

    my $xpath = CSS::Coverage::XPath->new($selector)->to_xpath;

    for my $tree (@{ $self->html_trees }) {
        if ($tree->exists($xpath)) {
            return;
        }
    }

    if ($self->_report) {
        $self->_report->add_unmatched_selector($selector);
    }
    else {
        warn "This selector matches no documents: $selector\n";
    }
}

sub _got_coverage_directive {
    my ($self, $directive) = @_;

    if ($directive eq 'dynamic' || $directive eq 'ignore') {
        $self->_ignore_next_rule(1);
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

CSS::Coverage

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    css-coverage style.css index.html second.html
        Unmatched selectors (3):
            div.form-actions button:first-child
            .expanded span.open
            ul.attn li form textarea


    my $coverage = CSS::Coverage->new(
        css       => $css_file,
        documents => \@html_files,
    );

    my $report = $coverage->check;

    print for $report->unmatched_selectors;

=head1 DESCRIPTION

Every CSS rule in your stylesheets have a cost. Browser must parse
them and apply them to your document. Your maintainers have to understand what each rule is doing. If a CSS rule doesn't appear to match any part of the document, maintainers wonder "is that intentional, or just a typo?"

So it is useful excise unused CSS rules. Unfortunately it is very
tedious to manually confirm whether a particular CSS selector matches
any of your documents. There are browser-based tools, like one that
ships in Chrome, that do this for you. However, they do not presently
check multiple pages. Browser tools are also not great for running
in a continuous integration environment.

This module and its associated C<css-coverage> script provide a
good first stab at paring down the list of rules to manually check.

=head2 JavaScript

Modern HTML pages are living, breathing, dynamic documents.
CSS::Coverage can only I<statically> check whether a CSS selector
matches an HTML document. So if you manipulate the DOM in JavaScript,
CSS::Coverage may report false positives. There's certainly a point
where CSS::Coverage provides diminishing returns if your page is
very JavaScript-heavy. But for static, or mostly-static, pages,
CSS::Coverage should be useful.

If you know that a particular rule only matches when JavaScript
runs, you can add a comment like this either inside or before that
CSS rule:

    a.clicked {
        /* coverage: dynamic */
        text-decoration: line-through;
    }

    /* coverage: dynamic */
    a.clicked {
        text-decoration: line-through;
    }

Either directive will cause CSS::Coverage to skip that rule entirely.

=head1 NAME

CSS::Coverage - Confirm that your CSS matches your DOM

=head1 VERSION

version 0.04

=head1 ATTRIBUTES

=head2 css (Str|ScalarRef)

If given a string, C<css> is treated as a filename. If given as a scalar reference, C<css> is treated as CSS code.

=head2 documents (ArrayRef[Str|ScalarRef])

A list of HTML documents. For each document, strings are treated as filenames; scalar reference as raw HTML code.

=head1 METHODS

=head2 check

Runs a coverage check of the given CSS against the given documents. Returns a L<CSS::Coverage::Report> object.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
