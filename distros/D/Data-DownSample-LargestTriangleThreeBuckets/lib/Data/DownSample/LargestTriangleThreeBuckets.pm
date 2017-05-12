package Data::DownSample::LargestTriangleThreeBuckets;

use 5.006;
use strict;
use warnings;

use POSIX;

our $VERSION = '1.00';
				 
sub new
{
  my $caller = shift;

  # In case someone wants to sub-class
  my $caller_is_obj  = ref($caller);
  my $class = $caller_is_obj || $caller;

  # Passing reference or hash
  my $arg_ref;
  if ( ref($_[0]) eq "HASH" ) { $arg_ref = shift @_ }
  else                        { $arg_ref = { shift @_ } }

  # The object data structure
  my $self = bless {
                     'threshold' => $arg_ref->{threshold},
                   }, $class;
 
  return $self; 
}

sub lttb 
{
  my $self = shift @_;
  my $data_ref = shift @_; 
  my $threshold = shift @_ || $self->{threshold};
  
  # Validate input... 
  # ...tbd...
    
  # Bucket size. Leave room for start and end data points
  my $data_len = scalar @$data_ref;
  my $every = ( $data_len - 2) / ( $threshold - 2 );

  my $a_pnt = 0;  # Initially a is the first point in the triangle
  my $next_a_pnt = 0;
  my $max_area_point = (0,0);

  my $sampled_ref = [ $data_ref->[0] ];  # Always add the first point

  # ie c bucket
  my $avg_range_start = int( floor($every) + 1);
  my $avg_range_end   = int( floor(2 * $every) + 1);

  # Get the range for this bucket - ie b bucket
  my $range_offs = 1;
  my $range_to   = int( floor( $every + 1));

  for ( my $inx = 0; $inx < $threshold - 2; $inx++) 
  {
        # Calculate point average for next bucket (containing c)
        my $avg_x = 0;
        my $avg_y = 0;
        
        if ( $avg_range_end >= $data_len ) { $avg_range_end = $data_len }

        my $avg_range_length = $avg_range_end - $avg_range_start;

        for ( ; $avg_range_start < $avg_range_end; $avg_range_start++ )  
        {
              $avg_x += $data_ref->[ $avg_range_start ]->[ 0 ];
              $avg_y += $data_ref->[ $avg_range_start ]->[ 1 ];
        }

        $avg_x /= $avg_range_length;
        $avg_y /= $avg_range_length;

        # Point a
        my $point_ax = $data_ref->[$a_pnt]->[0];
        my $point_ay = $data_ref->[$a_pnt]->[1];

        my $max_area = -1;

        my $diff_ax__avg_x = $point_ax - $avg_x;
        my $diff_avg_y__ay = $avg_y - $point_ay;
        while ( $range_offs < $range_to )
        {
            # Calculate triangle area over three buckets
            my $area = abs( ( $diff_ax__avg_x ) * ( $data_ref->[$range_offs][1] - $point_ay ) -
                         ( $point_ax - $data_ref->[$range_offs][0]) * ( $diff_avg_y__ay ) );
                         
            if ( $area > $max_area )
            {
                $max_area = $area;
                $max_area_point = $data_ref->[$range_offs];
                $next_a_pnt = $range_offs;  # Next a is this b
            }
            $range_offs += 1;
        }  
        
        push @$sampled_ref, $max_area_point;  # Pick this point from the bucket
        $a_pnt = $next_a_pnt;  # This a is the next a (chosen b)
        
        $range_offs = $range_to; 
        $avg_range_start = $avg_range_end;
        $range_to = $avg_range_end;
        $avg_range_end   = int( floor(($inx+3) * $every) + 1);
     
    }
   
    push @$sampled_ref, $data_ref->[$data_len - 1];  # Always add last

    return $sampled_ref;
}

# ------------------------------------
sub lttb_ref
{
  my $self = shift @_;
  my $data_ref = shift @_; 
  my $threshold = shift @_ || $self->{threshold};
  
  # Validate input... 
  # ...tbd...
    
  # Bucket size. Leave room for start and end data points
  my $data_len = scalar @$data_ref;
  my $every = ( $data_len - 2) / ( $threshold - 2 );

  my $a_pnt = 0;  # Initially a is the first point in the triangle
  my $next_a_pnt = 0;
  my $max_area_point = (0,0);

  my $sampled_ref = [ $data_ref->[0] ];  # Always add the first point

  for ( my $inx = 0; $inx < $threshold - 2; $inx++) 
  {
        # Calculate point average for next bucket (containing c)
        my $avg_x = 0;
        my $avg_y = 0;
        my $avg_range_start = int( floor(($inx+1) * $every) + 1);
        my $avg_range_end   = int( floor(($inx+2) * $every) + 1);
        
        if ( $avg_range_end >= $data_len ) { $avg_range_end = $data_len }

        my $avg_range_length = $avg_range_end - $avg_range_start;
  
        for ( ; $avg_range_start < $avg_range_end; $avg_range_start++ ) 
        {
              $avg_x += $data_ref->[ $avg_range_start ]->[ 0 ];
              $avg_y += $data_ref->[ $avg_range_start ]->[ 1 ];
        }

        $avg_x /= $avg_range_length;
        $avg_y /= $avg_range_length;

        # Get the range for this bucket
        my $range_offs = int( floor(( $inx+0 ) * $every) + 1);
        my $range_to   = int( floor(( $inx+1 ) * $every) + 1);

        # Point a
        my $point_ax = $data_ref->[$a_pnt]->[0];
        my $point_ay = $data_ref->[$a_pnt]->[1];

        my $max_area = -1;

        while ( $range_offs < $range_to )
        {
            # Calculate triangle area over three buckets
            my $area = abs( ( $point_ax - $avg_x) * ( $data_ref->[$range_offs][1] - $point_ay ) -
                         ( $point_ax - $data_ref->[$range_offs][0]) * ( $avg_y - $point_ay))*0.5;
                         
            if ( $area > $max_area )
            {
                $max_area = $area;
                $max_area_point = $data_ref->[$range_offs];
                $next_a_pnt = $range_offs;  # Next a is this b
            }
            $range_offs += 1;
        }  
        
        push @$sampled_ref, $max_area_point;  # Pick this point from the bucket
        $a_pnt = $next_a_pnt;  # This a is the next a (chosen b)
    }
   
    push @$sampled_ref, $data_ref->[$data_len - 1];  # Always add last

    return $sampled_ref;
}
  
#__data_ref__

=head1 NAME

Data::DownSample::LargestTriangleThreeBuckets 

=head1 VERSION

Version 1.00

=cut

=head1 DESCRIPTION

Implements a downsample technique known as Largest Triangle Three Buckets as defined 
in Sveinn Steinarsson MS thesis. 

http://skemman.is/stream/get/1946/15343/37285/3/SS_MSthesis.pdf

The idea is to downsample a data set without losing the visual 
character of the plotted data.  The technique draws on ideas in cartographic 
generalization or polyline simplification.  This technique is often useful in 
client-server applications such as webserver-browser where the length of the data far exceeds the pixels available to 
plot. Reducing the data size significantly speeds up data transfer and rendering time.

=head1 SYNOPSIS
    
use Data::DownSample::LargestTriangleThreeBuckets;

my $lttb = new Data::DownSample::LargestTriangleThreeBuckets( {threshold=>1000} );

my $data_src = [ [1,2], [2,3], [3,4], [4,5], ... ]; # <-- load your data source here as reference to a list of a list

my $data_sampled = $lttb->lttb($data_src);
        
     
=head1 SUBROUTINES/METHODS

=head2 lttb()

my $data_sampled = $lttb->lttb($data_src);

Also can overwrite the class threashold variable such as 

my $data_sampled = $lttb->lttb($data_src,20000);

This function is an optimized version of the algorithm given in Sveinn Steinarsson paper.  
Several of the math operation are factored out of the loops and it executes better than 
33% faster. 

=head2 lttb_ref()

my $data_sampled = $lttb->lttb_ref($data_src);

The reference function implimentation of the algorithm given in 
Sveinn Steinarsson paper and used to verify that the optimized version 
is giving correct results. 

=head1 AUTHOR

Steve Troxel, C<< <troxel at perlworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-downsample-largesttrianglethreebuckets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-DownSample-LargestTriangleThreeBuckets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::DownSample::LargestTriangleThreeBuckets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-DownSample-LargestTriangleThreeBuckets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-DownSample-LargestTriangleThreeBuckets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-DownSample-LargestTriangleThreeBuckets>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-DownSample-LargestTriangleThreeBuckets/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Troxel.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Data::DownSample::LargestTriangleThreeBuckets
