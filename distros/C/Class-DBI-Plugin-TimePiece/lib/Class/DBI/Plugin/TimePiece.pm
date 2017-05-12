package Class::DBI::Plugin::TimePiece;

use strict;
use warnings;
use Carp;

use vars '$VERSION';

$VERSION = '0.01';

sub import {
    my $class = shift;
    my $pkg   = caller(0);

    no strict 'refs';
    *{"$pkg\::has_a_timepiece"} = sub {
        my $self   = shift;
        my $colum  = shift;
        my $format = shift;

        $self->has_a(
            $colum  => 'Time::Piece',
            inflate => sub { Time::Piece->strptime(shift , $format ) },
            deflate => sub { shift->strftime($format) },
        );
    };
    *{"$pkg\::has_a_tp"} = *{"$pkg\::has_a_timepiece"};
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::TimePiece - Extension to Class::DBI for DB date type.

=head1 VERSION

This documentation refers to Class::DBI::Plugin::TimePiece version 0.01

=head1 SYNOPSIS

  __PACKAGE__->has_a_timepiece( INS_DATE => '%y/%m/%d %H:%M:%S' );
  __PACKAGE__->has_a_tp( UPDATE_DATE => '%y/%m/%d %H:%M:%S' );

=head1 DESCRIPTION

This module is Extensionto Class::DBI for DB date type.

=head1 METHOD

=head2 has_a_timepiece

This method relation to DB date type.

  __PACKAGE__->has_a_timepiece( INS_DATE => '%y/%m/%d %H:%M:%S' );

=head2 has_a_tp

has_a_tp is has_a_timepiece's alias.

  __PACKAGE__->has_a_tp( UPDATE_DATE => '%y/%m/%d %H:%M:%S' );

=head1 DEPENDENCIES

L<Carp>, L<Time::Piece>

=head1 SEE ALSO

L<Carp>, L<Time::Piece>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut

