package Catmandu::Fix::Date;
use strict;
our $VERSION = "0.0131";

use parent 'Exporter';
our @EXPORT;
@EXPORT = qw(
    datetime_format
    datetime_diff
    end_day
    end_week
    end_year
    split_date
    start_day
    start_week
    start_year
    timestamp
);

foreach my $fix (@EXPORT) {
    eval <<EVAL; ## no critic
        require Catmandu::Fix::$fix;
        Catmandu::Fix::$fix ->import( as => '$fix' );
EVAL
    die "Failed to use Catmandu::Fix::$fix\n" if $@;
}


1;
__END__

=head1 NAME

Catmandu::Fix::Date - Catmandu fixes for processing dates

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Fix-Date.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-Fix-Date)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Fix-Date/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-Fix-Date)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-Fix-Date.png)](http://cpants.cpanauthors.org/dist/Catmandu-Fix-Date)

=end markdown

=head1 SYNOPSIS

  use Catmandu::Fix::Date;

  # all fix functions are exported by default
  my $item = { date => '2001-11-09' };
  split_date($item, 'date');
  # $item == { date => { year => 2001, month => 11, day => 9 } }

=head1 DESCRIPTION

Catmandu::Fix::Date includes the following L<Catmandu::Fix> functions for
processing dates:

=over

=item

L<Catmandu::Fix::datetime_format>

=item

L<Catmandu::Fix::datetime_diff>

=item

L<Catmandu::Fix::timestamp>

=item

L<Catmandu::Fix::start_day>

=item

L<Catmandu::Fix::end_day>

=item

L<Catmandu::Fix::start_week>

=item

L<Catmandu::Fix::end_week>

=item

L<Catmandu::Fix::start_year>

=item

L<Catmandu::Fix::end_year>

=item

L<Catmandu::Fix::split_date>

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
