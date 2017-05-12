package Acme::Math::PerfectChristmasTree;

use warnings;
use strict;
use Exporter;
use Carp;
use Math::Trig qw/pi/;

use vars qw/$VERSION @ISA @EXPORT_OK/;
BEGIN {
    $VERSION = '0.02';
    @ISA     = qw/Exporter/;
    @EXPORT_OK = qw/calc_perfect_christmas_tree/;
}

sub calc_perfect_christmas_tree {
    my $tree_height = shift;

    if ($tree_height <= 0) {
        croak 'Tree height must be a number greater than zero.';
    }

    my $pi = pi();
    return (
        'number_of_baubles' => _round(sqrt(17) / 20 * $tree_height),
        'tinsel_length' => 13 * $pi / 8 * $tree_height,
        'lights_length' => $pi * $tree_height,
        'star_or_fairy_height' => $tree_height / 10,
    );
}

sub _round {
    my $value = shift;

    return int($value + 0.5);
}

1;
__END__

=encoding utf8

=head1 NAME

Acme::Math::PerfectChristmasTree - Calculate the perfect Christmas tree


=head1 VERSION

This document describes Acme::Math::PerfectChristmasTree version 0.02


=head1 SYNOPSIS

    use Acme::Math::PerfectChristmasTree qw/calc_perfect_christmas_tree/;

    my $tree_height  = 140; #<= centimeter
    my %perfect_tree = calc_perfect_christmas_tree($tree_height);

    # Content of %perfect_tree
    #
    # 'star_or_fairy_height' => 14,
    # 'tinsel_length'        => 714.712328691678,
    # 'number_of_baubles'    => 29,
    # 'lights_length'        => 439.822971502571


=head1 DESCRIPTION

This module calculates perfect Christmas tree. Sorry, "perfect Christmas tree" is not a data tree.
So it has nothing to do with data structure.

This module is using an equation which was devised by mathematics club of The University Of Sheffield.
For more details, refer to the following web site.

L<http://www.shef.ac.uk/news/nr/debenhams-christmas-tree-formula-1.227810>


=head1 METHODS

=over

=item calc_perfect_christmas_tree

Calculates perfect Christmas tree.

This function needs an argument which specify height of tree (please input as centimeter).

This function returns a hash. Keys of hash are...

    'star_or_fairy_height'
    'tinsel_length'
    'number_of_baubles'
    'lights_length'

(Values of hash related to length or height are expressed as centimeter).

=back


=head1 CONFIGURATION AND ENVIRONMENT

Acme::Math::PerfectChristmasTree requires no configuration files or environment variables.


=head1 DEPENDENCIES

Test::Exception (Version 0.31 or later)

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-math-perfectchristmastree@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion C<< <moznion@gmail.com> >>. All rights reserved.

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
