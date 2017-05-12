package Data::Context::BEM::Merge;

# Created on: 2013-11-15 05:13:46
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use version;
use Carp;
use List::Util qw/max /;
use List::MoreUtils qw/uniq pairwise/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.1');

sub merge {
    my ($self, $child, $parent) = @_;

    if ( ! ref $child ) {
        return $child;
    }
    elsif ( ref $child eq 'ARRAY' ) {
        if ( ref $parent ne 'ARRAY' ) {
            $parent = [];
        }
        my $new = [];
        my $max_child  = @$child  - 1;
        my $max_parent = @$parent - 1;

        for my $i ( 0 .. max $max_child, $max_parent ) {
            $new->[$i]
                = exists $child->[$i]
                ? $self->merge( $child->[$i], $parent->[$i] )
                : $parent->[$i];
        }

        return $new;
    }
    elsif ( ref $child eq 'HASH' ) {
        my $new = {};

        for my $key ( uniq sort +(keys %$child), (keys %$parent) ) {
            if ( $key eq 'content' ) {
                $child->{$key}  = [ $child->{$key}  ] if ref $child->{$key}  ne 'ARRAY';
                $parent->{$key} = [ $parent->{$key} ] if ref $parent->{$key} ne 'ARRAY';
            }

            $new->{$key}
                = exists $child->{$key}
                ? $self->merge( $child->{$key}, $parent->{$key} )
                : $parent->{$key};
        }

        return $new;
    }
    else {
        return $child;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::BEM::Merge - Merge algorithm that merges arrays (not appending them)

=head1 VERSION

This documentation refers to Data::Context::BEM::Merge version 0.1

=head1 SYNOPSIS

   use Data::Context::BEM::Merge;

   my $merge = Data::Context::BEM::Merge->new();
   my $merged = $merge->merge({a => [1,2]}, {a => [2,3]});

   # $merged = { a => [2,3] }

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<merge ($ref1, $ref2)>

Merges $ref2 into clone of $ref1.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
