package CSAF::Type::Document;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Carp;

use CSAF::Type::AggregateSeverity;
use CSAF::Type::Distribution;
use CSAF::Type::Publisher;
use CSAF::Type::Tracking;
use CSAF::Type::Acknowledgments;
use CSAF::Type::Notes;
use CSAF::Type::References;

extends 'CSAF::Type::Base';

has category     => (is => 'rw', default => 'csaf_base', required => 1);
has csaf_version => (is => 'rw', default => '2.0');
has lang         => (is => 'rw', default => 'en', coerce => sub { (my $lang = $_[0]) =~ tr /_/-/; $lang });
has title        => (is => 'rw');
has source_lang  => (is => 'rw', coerce => sub { (my $lang = $_[0]) =~ tr /_/-/; $lang });

sub aggregate_severity {
    my ($self, %params) = @_;
    $self->{aggregate_severity} ||= CSAF::Type::AggregateSeverity->new(%params);
}

sub distribution {
    my ($self, %params) = @_;
    $self->{distribution} ||= CSAF::Type::Distribution->new(%params);
}

sub tracking {
    my ($self, %params) = @_;
    $self->{tracking} ||= CSAF::Type::Tracking->new(%params);
}

sub publisher {
    my ($self, %params) = @_;
    $self->{publisher} ||= CSAF::Type::Publisher->new(%params);
}

sub acknowledgments {
    my $self = shift;
    $self->{acknowledgments} ||= CSAF::Type::Acknowledgments->new(@_);
}

sub notes {
    my $self = shift;
    $self->{notes} ||= CSAF::Type::Notes->new(@_);
}

sub references {
    my $self = shift;
    $self->{references} ||= CSAF::Type::References->new(@_);
}

sub TO_CSAF {

    my $self = shift;

    # TODO
    Carp::croak 'Missing document title' unless $self->title;

    my $output = {
        category     => $self->category,
        csaf_version => $self->csaf_version,
        distribution => $self->distribution,
        publisher    => $self->publisher,
        title        => $self->title,
        tracking     => $self->tracking,
        lang         => $self->lang,
    };

    if (@{$self->acknowledgments->items}) {
        $output->{acknowledgments} = $self->acknowledgments;
    }

    if (@{$self->notes->items}) {
        $output->{notes} = $self->notes;
    }

    if ($self->aggregate_severity->text || $self->aggregate_severity->namespace) {
        $output->{aggregate_severity} = $self->aggregate_severity;
    }

    if (@{$self->references->items}) {
        $output->{references} = $self->references;
    }

    $output->{source_lang} = $self->source_lang if ($self->source_lang);

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Document

=head1 SYNOPSIS

    use CSAF::Type::Document;
    my $type = CSAF::Type::Document->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Document> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->acknowledgments

=item $type->aggregate_severity

=item $type->category

=item $type->csaf_version

=item $type->distribution

=item $type->lang

=item $type->notes

=item $type->publisher

=item $type->references

=item $type->source_lang

=item $type->title

=item $type->tracking

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
