package Algorithm::LatticePoints;

use 5.008001;
use strict;
use warnings;

require Exporter;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;

sub new($&){
    my $class = shift;
    my $coderef = shift;
    bless $coderef, $class;
}

sub visit{
    my $self = shift;
    my ( $start, $end ) = @_;
    my $loop = 'LOOP';
    $loop =~ s{LOOP}{
        "for my \$i$_ (\$start->[$_]..\$end->[$_]){LOOP}"
    }ex for ( 0 .. @$start - 1 );
    my $args = join ",", map { '$i' . $_ } reverse( 0 .. @$start - 1 );
    $loop =~ s{LOOP}{\$self->($args)};
    eval $loop;
}

if ( $0 eq __FILE__ ) {
    my $al = Algorithm::LatticePoints->new(
        sub {
            printf "[%s]\n", join( ", ", @_ );
        }
    );
    $al->visit( [ 0, 0, 0 ], [ 9, 9, 9 ] );
}

1;
__END__

=head1 NAME

Algorithm::LatticePoints - Run code for each lattice points

=head1 SYNOPSIS

  use Algorithm::LatticePoints;
    my $al = Algorithm::LatticePoints->new(
        sub {
            printf "[%s]\n", join( ", ", @_ );
        }
    );
    $al->visit( [0,0,0,0], [9,9,9,9] );

    # instead of 
    for my $t (0..9){
      for my $z (0..9){
        for my $y (0..9){
          for my $x (0..9){
            print "[$x, $y, $z, $t]\n";
          }
        }
      }
    }

=head1 DESCRIPTION

Lattice-point handling is a common chore.  You do it for image
processing, 3-d processing, and more.  Usually you do it via nested
for loops but it is boring and tedious.  This module loops for you
instead.

=head2 METHODS

=over 2

=item new(\&coderef)

Pass a coderef which processes each lattice point.

=item visit([$s1,$s2...$sn],[$e1,$e2...$en])

Runs the code for each latice point between
[$s1,$s2...$sn] and [$e1,$e2...$en], inclusive.

=back

=head2 EXPORT

None.


=head1 PERFOMANCE

Compared to good old for loops, you will lose 20% performance for 10^3
lattice but only 4% for 10^4 lattice.  The larger the lattice gets the
less the performance loss impacts.

=head1 SEE ALSO

L<perlsyn>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
