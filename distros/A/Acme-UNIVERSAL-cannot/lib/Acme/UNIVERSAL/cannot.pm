package Acme::UNIVERSAL::cannot;

use warnings;
use strict;

=head1 NAME

Acme::UNIVERSAL::cannot - Just so that Acme::LOLCat->cannot('has')

=cut

our $VERSION = '0.01';

sub UNIVERSAL::cannot { ! UNIVERSAL::can(@_); }

sub UNIVERSAL::cant { goto \&UNIVERSAL::cannot; }

sub can::t { goto \&UNIVERSAL::cannot; }

=head1 SYNOPSIS

    use Acme::UNIVERSAL::cannot;
    use Acme::LOLCat; # Should be fixed in 0.0.5 hopefully.

    Acme::LOLCat->cannot('has');
    Acme::LOLCat->can't('has');
    Acme::LOLCat->cant('has');

=head1 BLAME

ElPenguin made me do it.

Nicholas Clark suggested C<< ->can't() >>

=head1 AUTHOR

Tomas Doran (t0m), C<< <bobtfish at bobtfish.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-universal-cannot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-UNIVERSAL-cannot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Tomas Doran, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::UNIVERSAL::cannot
