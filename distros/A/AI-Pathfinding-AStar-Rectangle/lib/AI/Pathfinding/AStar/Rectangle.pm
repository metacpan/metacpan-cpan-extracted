package AI::Pathfinding::AStar::Rectangle;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use AI::Pathfinding::AStar::Rectangle ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(create_map
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(	
);

our $VERSION = '0.23';

require XSLoader;
XSLoader::load('AI::Pathfinding::AStar::Rectangle', $VERSION);

# Preloaded methods go here.

sub foreach_xy{
    my $self = shift;
    my $sub  = shift;
    no strict 'refs';
    local *a= *{ caller() . '::a' };
    local *b= *{ caller() . '::b' };
    local ($a, $b );
    local $_;
    for $a ( $self->start_x .. $self->last_x ){
	for $b ( $self->start_y .. $self->last_y ){
	    $_ = $self->get_passability( $a, $b );
	    &$sub();
	}
    };
}
sub foreach_xy_set{
    my $self = shift;
    my $sub  = shift;

    no strict 'refs';
    local *a= *{ caller() . '::a' };
    local *b= *{ caller() . '::b' };
    local ($a, $b );
    local $_;
    for $a ( $self->start_x .. $self->last_x ){
	for $b ( $self->start_y .. $self->last_y ){
	    $_ = $self->get_passability( $a, $b );
	    $self->set_passability( $a, $b, (scalar &$sub()) );
	};
    };

}
sub create_map($){
    unshift @_, __PACKAGE__;
    goto &new;
}

1 for ($a, $b); #suppress warnings

sub set_passability_string{
    my $self = shift;
    my $passability = shift;
    die "Bad passabilitity param for set_passability_string" unless $self->width * $self->height == length( $passability );
    $self->foreach_xy_set( sub { substr $passability, 0, 1, '' } );

}
sub get_passability_string{
    my $self = shift;
    my $buf = '';
    $self->foreach_xy( sub { $buf.= chr( $_)} );
    return $buf;
}


sub draw_path{
    my $map  = shift;
    my ($x, $y) = splice @_, 0, 2;
    my $path  = shift;

    my @map;
    $map->foreach_xy( sub {$map[$a][$b]= $_} );

# draw path
    my %vect = (
            #      x  y
            1 => [-1, 1, ], 
            2 => [ 0, 1, '.|'],
            3 => [ 1, 1, '|\\'],
            4 => [-1, 0, '|<'],
            6 => [ 1, 0, '|>'],
            7 => [-1,-1, '|\\'],
            8 => [ 0,-1, '\'|'],
            9 => [ 1,-1, '|/']
    );

    my @path = split //, $path;
    print "Steps: ".scalar(@path)."\n";
    for ( @path )
    {
            $map[$x][$y] = '|o';
            $x += $vect{$_}->[0];
            $y -= $vect{$_}->[1];
            $map[$x][$y] = '|o';
    }

    printf "%02d", $_ for 0 .. $map->last_x;
    print "\n";
    for my $y ( 0 .. $map->last_y - 1 )
    {
            for my $x ( 0 .. $map->last_x - 1 )
            {
                    print $map[$x][$y] eq 
                    '1' ? "|_" : ( 
                    $map[$x][$y] eq '0' ? "|#" : ( 
                    $map[$x][$y] eq '3' ? "|S" : ( 
                    $map[$x][$y] eq '4' ? "|E" : $map[$x][$y] ) ) );
            }
            print "$y\n";
    }
}

1;
__END__

=head1 NAME

AI::Pathfinding::AStar::Rectangle -  AStar algorithm  on rectangle map

=head1 SYNOPSIS

  use AI::Pathfinding::AStar::Rectangle qw(create_map);

  my $map = create_map({height=>10, width=>10}); 

  # 
  # -or- 
  #
  # $map = AI::Pathfinding::AStar::Rectangle->new({{height=>10, width=>10});

  for my $x ($map->start_x..$map->last_x){
      for my $y ($map->start_y..$map->last_y){
          $map->set_passability($x, $y, $A[$x][$y]) # 1 - Can pass througth , 0 - Can't pass
      }
  }
  
  my $path = $map->astar( $from_x, $from_y, $to_x, $to_y);

  print $path, "\n"; # print path in presentation of "12346789" like keys at keyboard


=head1 DESCRIPTION

AI::Pathfinding::AStar::Rectangle provide abstraction for Rectangle map with AStar algoritm

=head1 OBJECT METHODS

=over 4

=item new { "width" => map_width, "height" => map_heigth }

Create AI::Pathfinding::AStar::Rectangle object. Object represent map with given height and width.

=item set_passability  x, y, value # value: 1 - can pass through point, 0 - can't 

Set passability for point(x,y)

=item get_passability (x,y)

Get passability for point

=item astar(from_x, from_y, to_x, to_y)

Search path from one point to other

return path like "1234..9"

where
1 - mean go left-down
2 - down
3 - down-right 
...
9 - right-up

=item dastar( from_x, from_y, to_x, to_y)
    Return diagonal path with AI 
=item width()

Get map width

=item height()

Get map height

=item start_x(), start_y()

Get/Set coords for leftbottom-most point 

=item set_start_xy( self, x, y)

Set coordinates of left-bootom point

=item last_x(), last_y()

Get coords for right-upper point 

=item foreach_xy( BLOCK )

Call BLOCK for every point on map.

$map->foreach_xy( sub { $A[$a][$b] = $_ }) 
($a, $b, $_) (x, y, passability) 

=item foreach_xy_set( sub { $A[$a][$b] });

 set passability for every point at map. 
 BLOCK must return passability for point ($a, $b);
 $a and  $b must be global var not declared as my, our, 

=item is_path_valid( start_x, start_y, path)
    Check if path is valid path, all points from ( start_x, start_y ) to path end is passable
    
    In list context return ( end_x, end_y, weigth, true or false )

=item path_goto( start_x, start_y, path)

In list context return 
( end_x, end_y, weigth )
    weight is sum of <diagonal (1379)> * 14 + <short path> * 10

=item draw_path( start_x, start_y, path)
 print path to STDOUT
 #!/usr/bin/perl 
 #
 my $m = AI::Pathfinding::AStar::Rectangle->new({ width => 16, height => 8 });

 $m->foreach_xy_set( sub {  $a < 12 && 1<$b && $b <9 } );
 $m->draw_path( 5, 5, '1666666888' );
 
Result: 

#    Steps: 10
#    00010203040506070809101112131415
#    |#|#|#|#|#|#|#|#|#|#|#|#|#|#|#0
#    |#|#|#|#|#|#|#|#|#|#|#|#|#|#|#1
#    |_|_|_|_|_|_|_|_|_|_|_|_|#|#|#2
#    |_|_|_|_|_|_|_|_|_|_|_|_|#|#|#3
#    |_|_|_|_|o|o|o|o|o|o|o|_|#|#|#4
#    |_|_|_|_|_|o|_|_|_|_|o|_|#|#|#5
#    |_|_|_|_|_|_|_|_|_|_|o|_|#|#|#6
#    |_|_|_|_|_|_|_|_|_|_|o|_|#|#|#7
#    |_|_|_|_|_|_|_|_|_|_|_|_|#|#|#8


=head2 EXAMPLES

See ./examples 

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

A.G. Grishaev, E<lt>gtoly@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A.G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
