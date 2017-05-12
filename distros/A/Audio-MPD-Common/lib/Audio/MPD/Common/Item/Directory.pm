#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Audio::MPD::Common::Item::Directory;
# ABSTRACT: a directory object
$Audio::MPD::Common::Item::Directory::VERSION = '2.003';
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };

use base qw{ Audio::MPD::Common::Item };


# -- public attributes


has directory     => ( rw, isa=>Str, required );
has last_modified => ( rw, isa=>Str );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common::Item::Directory - a directory object

=head1 VERSION

version 2.003

=head1 DESCRIPTION

L<Audio::MPD::Common::Item::Directory> is more a placeholder with some
attributes.

The constructor should only be called by L<Audio::MPD::Common::Item>'s
constructor.

=head1 ATTRIBUTES

=head2 $item->directory;

The path to the item's directory.

=head2 $item->last_modified;

Last modification date.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
