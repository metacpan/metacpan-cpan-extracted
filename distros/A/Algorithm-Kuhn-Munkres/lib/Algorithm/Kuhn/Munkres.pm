package Algorithm::Kuhn::Munkres;

use warnings;
use strict;
use Carp;
use List::Util qw( sum );
use base 'Exporter';
our @EXPORT_OK = qw( max_weight_perfect_matching assign );
our $VERSION = '1.0.7';

my @weights;
my $N;
my %S;
my %T;
my @labels_u;
my @labels_v;
my @min_slack;
my %matching_u;
my %matching_v;


sub _improve_labels {
    my ($val) = @_;

    foreach my $u (keys %S) {
        $labels_u[$u] -= $val;
    }

    for (my $v = 0; $v < $N; $v++) {
        if (exists($T{$v})) {
            $labels_v[$v] += $val;
        } else {
            $min_slack[$v]->[0] -= $val;
        }
    }
}

sub _improve_matching {
    my ($v) = @_;
    my $u = $T{$v};
    if (exists($matching_u{$u})) {
        _improve_matching($matching_u{$u});
    }
    $matching_u{$u} = $v;
    $matching_v{$v} = $u;
}

sub _slack {
    my ($u,$v) = @_;
    my $val = $labels_u[$u] + $labels_v[$v] - $weights[$u][$v];
    return $val;
}

sub _augment {

    while (1) {
        my ($val, $u, $v);
        for (my $x = 0; $x < $N; $x++) {
            if (!exists($T{$x})) {
                if (!defined($val) || ($min_slack[$x]->[0] < $val)) {
                    $val = $min_slack[$x]->[0]; 
                    $u = $min_slack[$x]->[1];
                    $v = $x;
                }
            }
        }
        die "u should be in S" if (!exists($S{$u}));
        if ($val > 0) {
            _improve_labels($val);
        }
        die "slack(u,v) should be 0" if (_slack($u,$v) != 0);
        $T{$v} = $u;
        if (exists($matching_v{$v})) {
            my $u1 = $matching_v{$v};
            die "u1 should not be in S" if (exists($S{$u1}));
            $S{$u1} = 1;
            for (my $x = 0; $x < $N; $x++) {
                my $s = _slack($u1,$x);
                if (!exists($T{$x}) && $min_slack[$x]->[0] > $s) {
                    $min_slack[$x] = [$s, $u1];
                }
            }                 
        } else {
            _improve_matching($v);
            return;
        }
    }

}

sub max_weight_perfect_matching {

    %S = ();
    %T = ();
    @labels_u = ();
    @labels_v = ();
    @min_slack = ();
    %matching_u = ();
    %matching_v = ();

    @weights = @_;
    $N = scalar @weights;
    for (my $i = 0; $i < $N; $i++) {
        $labels_v[$i] = 0;    
    }
    for (my $i = 0; $i < $N; $i++) {
        my $max = 0;
        for (my $j = 0; $j < $N; $j++) {
            if ($weights[$i][$j] > $max) {
                $max = $weights[$i][$j];
            }        
        }
        $labels_u[$i] = $max;
    }    


    while ($N > scalar keys %matching_u) {
        my $free;
        for (my $x = 0; $x < $N; $x++) {
            if (!exists($matching_u{$x})) {
                $free = $x;
                last;
            }                         
        }

        %S = ($free => 1);
        %T = ();
        @min_slack = ();
        for (my $i = 0; $i < $N; $i++) {
            my $x = [_slack($free,$i), $free];
            push @min_slack, $x;
        }
        _augment();
    }

    my $val = sum(@labels_u) + sum(@labels_v);
    return ($val, \%matching_u);

}

sub assign {
    max_weight_perfect_matching(@_);
}

sub _show_hash {
    my ($hash_ref) = @_;
    my $output = "{";
    foreach my $key (sort keys %$hash_ref) {
        $output .= "$key" . ": " . $hash_ref->{$key} . ", "; 
    }
    $output =~ s/, $//;
    $output .= "}";
    return $output;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Algorithm::Kuhn::Munkres - Determines the maximum weight perfect matching in a weighted complete bipartite graph


=head1 VERSION

This document describes Algorithm::Kuhn::Munkres version 1.0.7


=head1 SYNOPSIS

    use Algorithm::Kuhn::Munkres qw( assign );
    my @matrix = ([1,2,3,4],[2,4,6,8],[3,6,9,12],[4,8,12,16]);
    my ($cost,$mapping) = assign(@matrix);
 
  
=head1 DESCRIPTION

    Implementation of the Kuhn-Munkres algorithm. The algorithm finds the maximum weight
    perfect matching in a weighted complete bipartite graph. This problem is also known as 
    the "Assignment Problem".

=head1 INTERFACE 

=over 4

=item max_weight_perfect_matching

Determines the maximum weight perfect matching in a weighted complete bipartite graph.
The single argument is a matrix representing the weights of the edges in the bipartite graph.
The matrix must be implemented as a list of array objects.
The output is a tuple consisting of the total weight (cost) of the perfect matching, and
a reference to a hash representing edges in the mapping.

    use Algorithm::Kuhn::Munkres qw( assign );
    my @matrix = ([1,2,3,4],[2,4,6,8],[3,6,9,12],[4,8,12,16]);
    my ($cost,$mapping) = assign(@matrix);
    

=item assign

Synonym for max_weight_perfect_matching

=back

=head1 DIAGNOSTICS

    Ideally, I would list every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies. I'm not that good a person right now.


=head1 CONFIGURATION AND ENVIRONMENT

Algorithm::Kuhn::Munkres requires no configuration files or environment variables.


=head1 DEPENDENCIES

List::Util

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-algorithm-kuhn-munkres@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Martin-Louis Bright  C<< <mlbright@gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This implementation is a translation of the python code at 
http://www.enseignement.polytechnique.fr/informatique/INF441/INF441b/code/kuhnMunkres.py

To understand the algorithm, the following web resources were invaluable:
(http://www.cse.ust.hk/~golin/COMP572/Notes/Matching.pdf),
(http://www.topcoder.com/tc?module=Static&d1=tutorials&d2=hungarianAlgorithm),
(http://www.math.uwo.ca/~mdawes/courses/344/kuhn-munkres.pdf)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Martin-Louis Bright C<< <mlbright@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
