package Business::Fixflo::QuickViewPanel;

=head1 NAME

Business::Fixflo::Property::QuickViewPanel

=head1 DESCRIPTION

A class for a fixflo QVP, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;
use Business::Fixflo::Exception;

extends 'Business::Fixflo::Resource';

use Carp qw/ confess /;

=head1 ATTRIBUTES

    DataTypeName
    Explanation
    QVPTypeId
    Title
    Url

    issue_summary
    issue_status_summary

issue_summary and issue_status_summary will return the corresponding data from
the quick view panel - an array(ref) of hash(refs)

=cut

has [ qw/
    DataTypeName
    Explanation
    QVPTypeId
    Title
    Url
/ ] => (
    is => 'rw',
);

has 'issue_summary' => (
    is  => 'ro',
    isa => sub {
        confess( "$_[0] is not an ARRAY ref" )
            if defined $_[0] && ref $_[0] ne 'ARRAY';
    },
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        return $self->_get if $self->DataTypeName eq 'IssueSummary';
        return;
    },
);

has 'issue_status_summary' => (
    is  => 'ro',
    isa => sub {
        confess( "$_[0] is not an ARRAY ref" )
            if defined $_[0] && ref $_[0] ne 'ARRAY';
    },
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        return $self->_get if $self->DataTypeName eq 'IssueStatusSummary';
        return;
    },
);

=head1 METHODS

=head2 get

Returns the data associated with a QuickViewPanel:

    my ( $issues_of_properties_without_ext_ref ) = grep { $_->QVPTypeId == 40 }
        $ff->quick_view_panels;

    my $key_value_pairs = $issues_of_properties_without_ext_ref->get;

Since there are many QuickViewPanels you can get the data for a specific
QuickViewPanel by calling get on that QuickViewPanel

There are quite a lot of QuickViewPanels, to see them all:

    foreach my $qvp (
        sort { $a->QVPTypeId <=> $b->QVPTypeId }
        $ff->quick_view_panels
    ) {
        printf( "%d - %s",$qvp->QVPTypeId,$qvp->Explanation );
    }

=cut

sub get {
    my ( $self ) = @_;
    return $self->client->api_get( $self->Url );
}

sub _get {
    my ( $self ) = @_;
    return $self->client->api_get( $self->Url );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
