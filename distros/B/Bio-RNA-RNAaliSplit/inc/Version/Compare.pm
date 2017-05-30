package Version::Compare;
{
  $Version::Compare::VERSION = '0.14';
}
# ABSTRACT: Compare version strings

use warnings;
use strict;


sub max {
    my $x = shift;
    my $y = shift;
    return ( $x > $y ? $x : $y );
}

## no critic(ProhibitNumberedNames ProhibitCStyleForLoops)
sub version_compare {
    my $ver1 = shift || 0;
    my $ver2 = shift || 0;
    my @v1 = split /[.+:~-]/, $ver1;
    my @v2 = split /[.+:~-]/, $ver2;

    for ( my $i = 0 ; $i < max( scalar(@v1), scalar(@v2) ) ; $i++ ) {

        # Add missing version parts if one string is shorter than the other
        # i.e. 0 should be lt 0.2.1 and not equal, so we append .0
        # -> 0.0.0 <=> 0.2.1 -> -1
        push( @v1, 0 ) unless defined( $v1[$i] );
        push( @v2, 0 ) unless defined( $v2[$i] );
        if ( int( $v1[$i] ) > int( $v2[$i] ) ) {
            return 1;
        }
        elsif ( int( $v1[$i] ) < int( $v2[$i] ) ) {
            return -1;
        }
    }
    return 0;
}
## use critic

## no critic (RequireArgUnpacking ProhibitBuiltinHomonyms)
sub cmp {
    return version_compare(@_);
}
## use critic


1; # End of Version::Compare

__END__

=pod

=head1 NAME

Version::Compare - Compare version strings

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use Version::Compare;

    if(&Version::Compare::version_compare('2.6.26','2.6.0') == 1) {
        print "2.6.26 is greater than 2.6.0\n";
    }

=head1 NAME

Version::Compare - Comparing version strings

=head1 SUBROUTINES/METHODS

=head2 max

Return the bigger of the two numerical values

=head2 version_compare

Compare two unix-style version strings like 2.6.23.1 and 2.6.33 and return and sort-like
return code (1 => LHS bigger, 0 => equal, -1 => RHS bigger)

0.0 < 0.5 < 0.10 < 0.99 < 1 < 1.0~rc1 < 1.0 < 1.0+b1 < 1.0+nmu1 < 1.1 < 2.0

=head2 cmp

See L<version_compare>.

=head1 AUTHOR

Dominik Schulz, C<< <dominik.schulz at gauner.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-version-compare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Version-Compare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Version::Compare

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Version-Compare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Version-Compare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Version-Compare>

=item * Search CPAN

L<http://search.cpan.org/dist/Version-Compare/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dominik Schulz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
