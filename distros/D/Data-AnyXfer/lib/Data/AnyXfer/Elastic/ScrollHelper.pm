package Data::AnyXfer::Elastic::ScrollHelper;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Const::Fast;

use namespace::autoclean;


use Search::Elasticsearch::Scroll ();
use Search::Elasticsearch::Client::6_0::Scroll ();

with 'Data::AnyXfer::Elastic::Role::Wrapper';


=head1 NAME

    Data::AnyXfer::Elastic::ScrollHelper - ScrollHelper for ES

=head1 DESCRIPTION

A wrapper around C<Search::Elasticsearch::Scroll> instance for ES search, for
scrolling through batches of ES results.

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::ScrollHelper;

    my $scroll_helper = Data::AnyXfer::Elastic::ScrollHelper->new(
        extract_results => $extract_results,
        scroll_helper   => $self->es->scroll_helper,
    );

    while (my $result = $scroll_helper->next) {
        ...
    }

=head1 ATTRIBUTES

=head2 C<scroll_helper>

The instance of C<Search::Elasticsearch::Scroll> from the ES search. Required.

=cut

has scroll_helper => (
    is => 'ro',
    isa => AnyOf[
        InstanceOf['Search::Elasticsearch::Scroll'],
        InstanceOf['Search::Elasticsearch::Client::6_0::Scroll']
    ],
    required => 1,
);

=head2 C<extract_results>

Should the results be extracted? Changes the results returned by L<./next> and
L<./drain_buffer>.

=cut

has extract_results => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

# don't inject index and type when calling "_wrap_methods"
has is_inject_index_and_type => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# methods to wrap
const my @METHODS => (

    # METHODS
    'aggregations',
    'buffer_size',
    'refill_buffer',
    'finish',

);

# wrap methods
sub BUILD {
    my $self = shift;

    $self->_wrap_methods( $self->scroll_helper, \@METHODS );

    return $self;
}

=head1 METHODS

=head2 C<next>

    while (my $result = $scroll_helper->next) {
        ...
    }

Fetch the next result from ES buffer - fetching more results if required.
Returns empty list when there are no more results.

If L<./extract_results> is true then the results are extracted from
C<_source>.

=cut

sub next {
    my $self = shift;

    my $return = $self->scroll_helper->next(@_);

    return unless $return;

    return $self->extract_results && $return
        ? $return->{_source}
        : $return;
}

=head2 C<drain_buffer>

    while ($scroll_helper->refill_buffer) {

        my @results = $scroll_helper->drain_buffer;

        ...
    }

Empties the buffer and returts a list of results from it.

If L<./extract_results> is true then the results are extracted from
C<_source>.

=cut

sub drain_buffer {
    my $self = shift;

    my @results = $self->scroll_helper->drain_buffer(@_);

    return $self->extract_results
        ? map { $_->{_source} } @results
        : @results;
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

