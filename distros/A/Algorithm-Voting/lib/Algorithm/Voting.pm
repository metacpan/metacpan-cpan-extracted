# $Id: Voting.pm 60 2008-09-02 12:11:49Z johntrammell $
# $URL: https://algorithm-voting.googlecode.com/svn/tags/rel-0.01-1/lib/Algorithm/Voting.pm $

package Algorithm::Voting;

use strict;
use warnings;

our $VERSION = '0.01';

1;

=pod

=head1 NAME

Algorithm::Voting - voting algorithm implementations

=head1 SYNOPSIS

    use Algorithm::Voting::Ballot;
    use Algorithm::Voting::Plurality;
    my $box = Algorithm::Voting::Plurality->new();    # a ballot box
    foreach my $candidate (get_votes()) {
        $box->add( Algorithm::Voting::Ballot->new($candidate) );
    }
    print $box->as_string;

=head1 DESCRIPTION

Modules in this package implement various voting algorithms (e.g. Plurality,
Sortition, etc.) as well as related objects (ballots, etc.).

=head1 AUTHOR

johntrammell@gmail.com, C<< <johntrammell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests via the Google Code web interface at
L<http://code.google.com/p/algorithm-voting/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Voting

This project is hosted at Google Code.  You can find up-to-date information on
this project at URL L<http://code.google.com/p/algorithm-voting/>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 johntrammell@gmail.com, all rights reserved.

This software is intended for educational and entertainment purposes only.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

