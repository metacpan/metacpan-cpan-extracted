package B::OptreeShortestPath;

use warnings;
use strict;
use B qw( svref_2object );

=head1 NAME

B::OptreeShortestPath - The great new B::OptreeShortestPath!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

This module adds the methods ->shortest_path( $op ) and ->all_paths()
to all B::OP objects in an optree.

=head1 SYNOPSIS

    use B qw( main_root main_start );
    use B::OptreeShortestPath;
    
    for ( main_start()->shortest_path( main_root() ) ) {
        print "$_\n";
    }

=head1 METHODS

=over 4

=item $op->shortest_path( $other_op )

Returns a list of the shortest paths from $op to $other_op. Each path
is a string approximating a bunch of chained method calls.

 "->next->sibling->next",
 "->sibling->sibling->next"

=cut

sub B::OP::shortest_path {
    my ( $op, $target ) = @_;
    my $search = qr/\b$$op\b(.+)\b$$target\b/;

    return if $$op == $$target;

    my @paths;
    my $len;
    for ( $op->all_paths ) {
        next unless /$search/;
        $_ = $1;
        tr/NOFS//cd;

        if ( not defined $len ) {
            $len   = length;
            @paths = $_;
        }
        elsif ( $len < length ) {

        }
        elsif ( $len == length ) {
            my %seen;
            @paths = grep !$seen{$_}++, @paths, $_;
        }
        elsif ( $len > length ) {
            $len   = length;
            @paths = $_;
        }

        die "@paths" if grep length() != $len, @paths;
    }

    # Shortest paths, now fixing up for
    for (@paths) {
        s/N/->next/g;
        s/F/->first/g;
        s/O/->other/g;
        s/S/->sibling/g;
    }

    return @paths;
}

=item $op->all_paths()

Returns a list of paths from this node to all other nodes.

=back

=cut

sub B::OP::all_paths {
    my ( $op, $cx ) = @_;
    $cx = '' if not defined $cx;
    return "$cx SELF" if $cx =~ /\b$$op\b/;

    return (
        (     $cx =~ /^(?:\d+ S )*(?:\d+ N )*$/
            ? $op->next->all_paths("$cx$$op N ")
            : ()
        ),
        (   $cx =~ /^(?:\d+ S )*(?:\d+ N )*(?:\d+ [FS] )*$/
                && $op->can('first') ? $op->first->all_paths("$cx$$op F ")
            : ()
        ),
        (   $cx =~ /^(?:\d+ S )*(?:\d+ N )*(?:\d+ [FS] )*$/
                && $op->can('sibling') ? $op->sibling->all_paths("$cx$$op S ")
            : ()
        ),
    );
}

sub B::NULL::all_paths {"$_[1]NULL"}

sub compile {
    return sub {
        my $sub = svref_2object( sub { 1 for 1; } );
        print "$_\n" for $sub->START->shortest_path( $sub->ROOT );

    };
}

=head1 AUTHOR

Joshua ben Jore, C<< <twists@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-b-optreeshortestpath@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=B-OptreeShortestPath>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Joshua ben Jore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

qq[ "Hey, what does this switch labeled 'Pulsating Ejector' do?"
    "I don't know... I've always been too afraid to find out" ];
