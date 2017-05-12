package Catmandu::Fix::File;
use strict;
our $VERSION = "0.011";

use parent 'Exporter';
our @EXPORT;
@EXPORT = qw(
    basename
    dirname
    file_size
    human_byte_size
    Condition::file_test
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

Catmandu::Fix::File - Catmandu fixes to check file attributes

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Fix-File.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-Fix-File)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Fix-File/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-Fix-File)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-Fix-File.png)](http://cpants.cpanauthors.org/dist/Catmandu-Fix-File)

=end markdown

=head1 SYNOPSIS

  use Catmandu::Fix::File;

  # all fix functions are exported by default

=head1 DESCRIPTION

Catmandu::Fix::File includes the following L<Catmandu::Fix> functions:

=over

=item

L<Catmandu::Fix::basename>

=item

L<Catmandu::Fix::dirname>

=item

L<Catmandu::Fix::file_size>

=item

L<Catmandu::Fix::human_byte_size>

=item

L<Catmandu::Fix::Condition::file_test>

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
