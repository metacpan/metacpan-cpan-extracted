package CSAF::Renderer::HTML;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Util qw(tt_templates_path);
use Template;

use Moo;
extends 'CSAF::Renderer::Base';
with 'CSAF::Util::Log';

sub render {

    my ($self, %options) = @_;

    my $products = $CSAF::CACHE->{products} || {};

    my $max_base_score = 0;

    $self->csaf->build;

    foreach my $vuln ($self->csaf->vulnerabilities->each) {
        foreach my $score ($vuln->scores->each) {
            if ($score->cvss_v3 && $score->cvss_v3->baseScore && $max_base_score < $score->cvss_v3->baseScore) {
                $max_base_score = $score->cvss_v3->baseScore;
            }
        }
    }

    my %tt_options = (
        PRE_CHOMP => 1,
        TRIM      => 1,
        ENCODING  => 'UTF-8',
        VARIABLES => {
            document        => $self->csaf->document,
            product_tree    => $self->csaf->product_tree,
            vulnerabilities => $self->csaf->vulnerabilities,
            max_base_score  => $max_base_score,
        },
        FILTERS => {
            product_name => sub {
                my ($product_id) = @_;
                return $products->{$product_id} || $product_id;
            }
        }
    );

    my $template = $options{template} || 'default';
    my $vars     = $options{vars}     || {};
    my $output   = undef;

    $template .= '.tt2' unless $template =~ /\.tt2$/;

    unless (-e $template) {
        $tt_options{INCLUDE_PATH} = tt_templates_path;
    }

    my $tt = Template->new(%tt_options) or Carp::croak $Template::ERROR;

    $self->log->debug("Render CSAF document using $template template");

    $tt->process($template, $vars, \$output) or Carp::croak $tt->error;

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Renderer::HTML - Render a CSAF document in HTML

=head1 SYNOPSIS

    use CSAF::Renderer::HTML;
    my $renderer = CSAF::Renderer::HTML->new( csaf => $csaf );

    my $html = $renderer->render;


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Renderer::HTML> inherits all methods from L<CSAF::Renderer::Base> and implements the following new ones.

=over

=item $renderer->render ( [%options] )

Render a CSAF document in HTML format using L<Template> Toolkit.

Available options:

=over

=item vars

Optional variables for L<Template> Toolkit.

=item template

Use an alternative template

=back

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
