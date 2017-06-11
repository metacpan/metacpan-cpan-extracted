package App::PS1::Plugin::Date;

# Created on: 2011-06-21 09:48:24
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use English qw/ -no_match_vars /;

our $VERSION = 0.05;

sub date {
    my ($self, $options) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    $year += 1900;
    $mon++;
    my $date = sprintf "%04d-%02d-%02d", $year, $mon, $mday;
    if ( $self->cols && $self->cols > 60 ) {
        $date .= sprintf " %02d:%02d:%02d", $hour, $min, $sec;
    }

    return $self->surround( length $date, $self->colour('date') . $date );
}

1;

__END__

=head1 NAME

App::PS1::Plugin::Date - Adds the current date to prompt

=head1 VERSION

This documentation refers to App::PS1::Plugin::Date version 0.05.

=head1 SYNOPSIS

   use App::PS1::Plugin::Date;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<date ()>

The current date and time

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077)
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
