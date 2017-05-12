package ArangoDB2::Edge;

use strict;
use warnings;

use base qw(
    ArangoDB2::Document
);



# create
#
# override ArangoDB2::Document create so that we can add from
# and to values to the request
sub create
{
    my($self, $data, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['from','to']);
    # call ArangoDB2::Document::create
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

ArangoDB2::Edge - ArangoDB edge API methods

=head1 DESCRIPTION

ArangoDB edges are fundamentally documents, with a few extra features
thrown in.  ArangoDB2::Edge inherits most of its methods from
ArangoDB2::Document.

=head1 ORIGINAL METHODS

=over 4

=item create

=item from

=item to

=back

=head1 INHERITED METHODS

=over 4

=item data

=item delete

=item get

=item head

=item keepNull

=item list

=item policy

=item replace

=item rev

=item type

=item update

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
