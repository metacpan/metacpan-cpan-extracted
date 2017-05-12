package Collision::Util;

use warnings;
use strict;

BEGIN {
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( 
            check_contains check_contains_rect 
            check_collision check_collision_rect
    );
    our %EXPORT_TAGS = (
        all => \@EXPORT_OK,
        std => [qw( check_contains check_collision )],
    );
}

use Carp ();

our $VERSION = '0.01';


sub check_contains {
    my ($self, $target) = (@_);
    
    Carp::croak "must receive a target"
        unless $target;
    
    my @ret = ();
    my $ref = ref $target;
    if ( $ref eq 'ARRAY' ) {
        my $id = 0;
        foreach ( @{$target} ) {
            $id++;
            if (check_contains_rect($self, $_) ) {
                push @ret, $id;
                last unless wantarray;
            }
        }
    }
    elsif ( $ref eq 'HASH' ) {
        foreach ( keys %{$target} ) {
            if (check_contains_rect($self, $target->{$_}) ) {
                push @ret, $_;
                last unless wantarray;
            }
        }
    }
    else {
        return check_contains_rect($self, $target);
    }
    return wantarray ? @ret : $ret[0];
}

sub check_contains_rect {
    Carp::croak "must receive a target"
        unless $_[1];

    my $contains;
    eval {
        $contains = ($_[0]->x <= $_[1]->x) 
            && ($_[0]->y <= $_[1]->y) 
            && ($_[0]->x + $_[0]->w >= $_[1]->x + $_[1]->w) 
            && ($_[0]->y + $_[0]->h >= $_[1]->y + $_[1]->h) 
            && ($_[0]->x + $_[0]->w > $_[1]->x) 
            && ($_[0]->y + $_[0]->h > $_[1]->y)
            ;
    };
    Carp::croak "elements should have x, y, w, h accessors" if $@;
    return $contains;
}

sub check_collision {
    my ($self, $target) = (@_);
    
    Carp::croak "must receive a target"
        unless $target;
    
    my @ret = ();
    my $ref = ref $target;
    if ( $ref eq 'ARRAY' ) {
        my $id = 0;
        foreach ( @{$target} ) {
            $id++;
            if (check_collision_rect($self, $_) ) {
                push @ret, $id;
                last unless wantarray;
            }
        }
    }
    elsif ( $ref eq 'HASH' ) {
        foreach ( keys %{$target} ) {
            if (check_collision_rect($self, $target->{$_}) ) {
                push @ret, $_;
                last unless wantarray;
            }
        }
    }
    else {
        return check_collision_rect($self, $target);
    }
    return wantarray ? @ret : $ret[0];
}

sub check_collision_rect {
    Carp::croak "must receive a target"
        unless $_[1];

    my $collide;
    eval {
        $collide = (
               ($_[0]->x >= $_[1]->x && $_[0]->x < $_[1]->x + $_[1]->w)  
            || ($_[1]->x >= $_[0]->x && $_[1]->x < $_[0]->x + $_[0]->w)
           ) 
           &&
           (
               ($_[0]->y >= $_[1]->y && $_[0]->y < $_[1]->y + $_[1]->h)
            || ($_[1]->y >= $_[0]->y && $_[1]->y < $_[0]->y + $_[0]->h)
           )
           ;
    };
    Carp::croak "elements should have x, y, w, h accessors" if $@;
    return $collide;
}


42;
__END__
=head1 NAME

Collision::Util - A selection of general collision detection utilities

=head1 SYNOPSIS

Say you have a class with C<< ->x() >>, C<< ->y() >>, C<< ->w() >>, and 
C<< ->h() >> accessors, like L<< SDL::Rect >> or the one below:

  package Block;
  use Class::XSAccessor {
      constructor => 'new',
      accessors   => [ 'x', 'y', 'w', 'h' ],
  };
  
let's go for a procedural approach:
  
  use Collision::Util ':std';
  
  my $rect1 = Block->new( x =>  1, y =>  1, w => 10, h => 10 );
  my $rect2 = Block->new( x =>  5, y =>  9, w =>  6, h =>  4 );
  my $rect3 = Block->new( x => 16, y => 12, w =>  3, h =>  3 );
  
  check_collision($rect1, $rect2);  # true
  check_collision($rect3, $rect1);  # false
  
  # you can also check them all in a single run:
  check_collision($rect1, [$rect2, $rect3] );
  
As you might have already realized, you can just as easily bundle collision 
detection into your objects:

  package CollisionBlock;
  use Class::XSAccessor {
      constructor => 'new',
      accessors   => [ 'x', 'y', 'w', 'h' ],
  };
  
  # if your class has the (x, y, w, h) accessors,
  # imported functions will behave just like methods!
  use Collision::Util ':std';
  
Then, further in your code:

  my $rect1 = CollisionBlock->new( x =>  1, y =>  1, w => 10, h => 10 );
  my $rect2 = CollisionBlock->new( x =>  5, y =>  9, w =>  6, h =>  4 );
  my $rect3 = CollisionBlock->new( x => 16, y => 12, w =>  3, h =>  3 );
  
  $rect1->check_collision( $rect2 );  # true
  $rect3->check_collision( $rect1 );  # false
  
  # you can also check if them all in a single run:
  $rect1->check_collision( [$rect2, $rect3] );


=head1 DESCRIPTION

Collision::Util contains sets of several functions to help you detect 
collisions in your programs. While it focuses primarily on games, you can use 
it for any application that requires collision detection.

=head1 EXPORTABLE SETS

Collision::Util doesn't export anything by default. You have to explicitly 
define function names or one of the available helper sets below:

=head2 :std

exports C<< check_collision() >> and C<< check_contains() >>.

=head2 :rect

exports C<< check_collision_rect() >> and C<< check_contains_rect() >>.

=head2 :circ

TODO

=head2 :dot

TODO

=head2 :all

exports all functions.

=head1 MAIN UTILITIES

=head2 check_contains ($source, $target)

=head2 check_contains ($source, [$target1, $target2, $target3, ...])

=head2 check_contains ($source, { key1 => $target1, key2 => $target2, ...})


  if ( check_contains($ball, $goal) ) {
      # SCORE !!
  }
  
  die if check_contains($hero, \@bullets);

Returns the index (starting from 1, so you always get a 'true' value) of the 
first target item completely inside $source. Otherwise returns undef.

  my @visible = check_contains($area, \@enemies);

If your code context wants it to return a list, C<< inside >> will return a 
list of all indices (again, 1-based) completely inside $source. If no 
elements are found, an empty list is returned. 

  my @names = check_contains($track, \%horses);

Similarly, you can also check which (if any) elements of a hash are inside 
your element, which is useful if you group your objects like that instead of 
in a list.

=head2 check_collision ($source, $target)

=head2 check_collision ($source, [$target1, $target2, $target3, ...])

=head2 check_collision ($source, { key1 => $target1, key2 => $target2, ...})

  if ( check_collision($player, $wall) ) {
      # ouch
  }

  die if check_collision($hero, \@lava_pits);

Returns the index (starting from 1, so you always get a 'true' value) of the 
first target item that collides with $source. Otherwise returns undef.

  my @hits = check_collision($planet, \@asteroids);

If your code context wants it to return a list, C<< inside >> will return a 
list of all indices (again, 1-based) that collide with $source. If no 
elements are found, an empty list is returned.

  my @keys = check_collision($foo, \%bar);

Similarly, you can also check which (if any) elements of a hash are colliding
with your element, which is useful if you group your objects like that instead 
of in a list.


=head1 USING IT IN YOUR OBJECTS

TODO (but SYNOPSIS should give you a hint)

=head1 DIAGNOSTICS

=over 4

=item * I<< "must receive a target" >>

You tried calling the function without a target. Remember, syntax is
always C<< foo($source, $target) >>, or, if you're not using it 
directly and the collision is a method inside object C<$source>, then 
it's L<< $source->foo($target) >>. Here of course you should replace 
I<foo> with the name of the C<< Collision::Util >> function you want.

=item * I<< "elements should have x, y, w, h accessors" >>

Both C<$source> and C<$target> must be objects with accessors for C<x> 
(I<< left coordinate >> ), C<y> (I<< top coordinate >> ), C<w> 
(I<< object's width >> ), and C<h> (I<< object's height >> ).

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Many thanks to Kartik Thakore for his help and insights.


=head1 BUGS

Please report any bugs or feature requests to C<bug-collision-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Collision-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Collision::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Collision-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Collision-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Collision-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/Collision-Util/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2010 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

