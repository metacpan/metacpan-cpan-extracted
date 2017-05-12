package Algorithm::Statistic;

use strict;
use warnings;
use XSLoader;

use Exporter 5.57 'import';

our $VERSION     = '0.04';
our %EXPORT_TAGS = ( 'all' => [qw<kth_order_statistic median>] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('Algorithm::Statistic', $VERSION);

1;

=head1 NAME

Algorithm::Statistic - different statistical algorithms library

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Algorithm::Statistic qw/:all/;

=head1 DESCRIPTION

This module provides several math and statistical algorithms implementations in C++ XS for perl.

=head1 Functions

=head2 C<< kth_order_statistic(array_ref, k [, \&compare]) >>

This function allows to find k-th order statistic for certain array of elements. 
Note that this function changes input array (like std::nth_element im STL C++) according to the next rule:
element at k-th position will become k-th order atatistic. Each element from the left of k will be less then k-th
and each from the right will be greater. This algorithm works with linear complexity O(n). By default you don't have to specify comparator
for integers and float numbers.

    my $statistic = kth_order_statistic($array_ref, $k);

But in more complex cases it's posible to specify comparator.

    my $statistic_cmp = kth_order_statistic($array_ref, $k, \&compare);

For example C<compare> function could be simple comparison for strings:

    sub compare {
        $_[0] cmp $_[1]
    }

=head2 C<< median(array_ref, \&compare) >>

This function allows to find median for certain array of elements. This method is the same as n/2 kth order statistc.
Like C<kth_order_statistic> this function changes input array according to the same rule.

    my $median = median($array_ref [, \&compare]);

=head1 BUGS

If you find a bug please contact me via email.

=head1 AUTHOR

Igor Karbachinsky <igorkarbachinsky@mail.ru>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015, Igor Karbachinsky. All rights reserved.

=cut
