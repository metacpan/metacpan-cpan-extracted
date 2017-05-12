package ArangoDB2::Graph::Edge;

use strict;
use warnings;

use base qw(
    ArangoDB2::Graph::Vertex
);

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;


# POST /_api/gharial/graph-name/edge/collection-name
sub create
{
    my($self, $data, $args) = @_;
    # require data
    die "Invlalid args"
        unless ref $data eq 'HASH';
    # process args
    $args = $self->_build_args($args, ['from', 'to']);
    # from and to go in data
    $data->{_from} = delete $args->{from};
    $data->{_to} = delete $args->{to};

    return $self->SUPER::create($data, $args);
}

# from
#
# get/set from
sub from { shift->_get_set_id('from', @_) }

# to
#
# get/set to
sub to { shift->_get_set_id('to', @_) }

# _class
#
# internal name for class
sub _class { 'edge' }

# _register
#
# internal name for object index
sub _register { 'edges' }


1;

__END__

=head1 NAME

ArangoDB2::Graph::Edge - ArangoDB edge API methods

=head1 DESCRIPTION

=head1 ORIGINAL METHODS

=over 4

=item create

=item from

=item to

=back

=head1 INHERITED METHODS

=over 4

=item new

=item delete

=item get

=item keepNull

=item patch

=item replace

=item waitForSync

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
