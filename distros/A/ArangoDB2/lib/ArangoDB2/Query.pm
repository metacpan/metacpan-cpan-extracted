package ArangoDB2::Query;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

use ArangoDB2::Cursor;

my $JSON = JSON::XS->new->utf8;



# new
#
# create new instance
sub new
{
    my($class, $arango, $database, $query) = @_;

    my $self = $class->SUPER::new($arango, $database);
    $self->query($query);

    return $self;
}

# batchSize
#
# maximum number of result documents
sub batchSize { shift->_get_set('batchSize', @_) }

# count
#
# boolean flag that indicates whether the number of documents in the
# result set should be returned.
sub count { shift->_get_set_bool('count', @_) }

# execute
#
# POST /_api/cursor
sub execute
{
    my($self, $bind, $args) = @_;
    # process args
    $args = $self->_build_args($args, [qw(
        batchSize fullCount count query ttl
    )]);
    # fullCount is an exception that belongs under options
    $args->{options}->{fullCount} = delete $args->{fullCount}
        if exists $args->{fullCount};
    # set bindVars if bind is passed
    $args->{bindVars} = $bind
        if defined $bind;
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('cursor'),
        undef,
        $JSON->encode($args),
    ) or return;

    return ArangoDB2::Cursor->new($self->arango, $self->database, $res);
}

# fullCount
#
# include result count greater than LIMIT
#
# default false
sub fullCount { shift->_get_set_bool('fullCount', @_) }

# explain
#
# POST /_api/explain
sub explain
{
    my($self) = @_;

    return $self->arango->http->post(
        $self->api_path('explain'),
        undef,
        $JSON->encode({query => $self->query}),
    );
}

# parse
#
# POST /_api/query
sub parse
{
    my($self) = @_;

    return $self->arango->http->post(
        $self->api_path('query'),
        undef,
        $JSON->encode({query => $self->query}),
    );
}

# query
#
# AQL query
sub query { shift->_get_set('query', @_) }

# ttl
#
# an optional time-to-live for the cursor (in seconds)
sub ttl { shift->_get_set('ttl', @_) }

1;

__END__

=head1 NAME

ArangoDB2::Query - ArangoDB query API methods

=head1 METHODS

=over 4

=item new

=item batchSize

=item count

=item execute

=item fullCount

=item explain

=item parse

=item query

=item ttl

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

