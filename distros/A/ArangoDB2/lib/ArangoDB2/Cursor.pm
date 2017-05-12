package ArangoDB2::Cursor;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;



# new
#
# create new instance
sub new
{
    my($class, $arango, $database, $data) = @_;

    my $self = $class->SUPER::new($arango, $database);
    $self->{data} = $data;

    return $self;
}

# all
#
# get all results
sub all
{
    my($self) = @_;
    # need data
    return unless $self->data;

    my $result = $self->data->{result};
    # add any additional batches to the initial result
    while ($self->get) {
        push(@$result, @{$self->data->{result}});
    }

    return $result;
}

# count
#
# get count of results
sub count
{
    my($self) = @_;

    return $self->data && $self->data->{count};
}

# delete
#
# DELETE /_api/cursor/{cursor-identifier}
sub delete
{
    my($self) = @_;
    # need data
    return unless $self->data
        and $self->data->{hasMore};

    return $self->arango->http->delete(
        $self->api_path('cursor', $self->data->{id}),
    );
}

# each
#
# iterate over results calling callback function
sub each
{
    my($self, $func) = @_;
    # require code ref
    die "Invalid Args"
        unless ref $func eq 'CODE';
    # need data
    return unless $self->data;

    my $i=0;

    while () {
        $func->($i++, $_) for @{$self->data->{result}};
        last unless $self->get;
    }

    return;
}

# fullCount
#
# get fullCount for LIMIT result
sub fullCount
{
    my($self) = @_;

    return $self->data && $self->data->{extra} && $self->data->{extra}->{fullCount};
}

# get
#
# PUT /_api/cursor/{cursor-identifier}
#
# get next batch of results from api
sub get
{
    my($self) = @_;
    # need data
    return unless $self->data
        and $self->data->{hasMore};
    # request next batch
    my $res = $self->arango->http->put(
        $self->api_path('cursor', $self->data->{id}),
    ) or return;
    # update internal state
    $self->{data} = $res;
    $self->{i} = 0;

    return $res;
}

# next
#
# get next result
sub next
{
    my($self) = @_;
    # need data
    return unless $self->data;
    # increment counter, starting at 0
    my $i = $self->{i}++;
    # return next result if it exists
    return $self->data->{result}->[$i]
        if exists $self->data->{result}->[$i];
    # try to get more data
    $self->get or return;
    # try read again
    $i = $self->{i}++;
    # return next result if it exists
    return $self->data->{result}->[$i];
}

1;

__END__

=head1 NAME

ArangoDB2::Cursor - ArangoDB cursor API methods

=head1 METHODS

=over 4

=item new

=item all

=item count

=item delete

=item each

=item fullCount

=item get

=item next

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
