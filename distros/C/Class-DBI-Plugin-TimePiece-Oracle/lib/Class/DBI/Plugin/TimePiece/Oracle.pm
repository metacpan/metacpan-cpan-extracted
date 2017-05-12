package Class::DBI::Plugin::TimePiece::Oracle;

use strict;
use warnings;
use Carp;
use Class::DBI::Plugin::DateFormat::Oracle;

use vars '$VERSION';

$VERSION = '0.01';

# This module supports the following %FORMAT.
my %FORMAT = (
    'YYYY'  => '%Y',
    'YY'    => '%y',
    'RRRR'  => '%Y',
    'RR'    => '%y',
    'MM'    => '%m',
    'MON'   => '%b',
    'MONTH' => '%B',
    'DD'    => '%d',
    'HH'    => '%I',
    'HH24'  => '%H',
    'MI'    => '%M',
    'SS'    => '%S',
);

# This module supports the following $SEPARATOR.
my $SEPARATOR = q[\s\-\/\,\;\:];

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    my $format;
    my $nsl_format;

    no strict 'refs';
    *{"$pkg\::has_a_auto_timepiece"} = sub {
        my $self   = shift;
        my $colum  = shift;
        $self->_get_nls_date_format;
        $self->has_a(
            $colum  => 'Time::Piece',
            inflate => sub { Time::Piece->strptime(shift , $format ) },
            deflate => sub { shift->strftime($format) },
        );
    };

    *{"$pkg\::has_a_atp"} = *{"$pkg\::has_a_auto_timepiece"};

    *{"$pkg\::_get_nls_date_format"} = sub {
        my $self = shift;

        if ( defined $format ) {
            return;
        }

        if ( ! defined $nsl_format ) {
            $nsl_format = $self->get_nls_date_format;
        }

        my $chk_target = $nsl_format;
        $format        = $nsl_format;

        for my $key ( reverse sort keys %FORMAT ) {
            $format     =~ s/${key}/$FORMAT{$key}/;
            $chk_target =~ s/${key}//;
        }
        $self->_croak("FORMAT PARSE ERROR!") if ( $chk_target eq q[] && $chk_target =~ /[^${SEPARATOR}]/ );
    };

    goto &Class::DBI::Plugin::DateFormat::Oracle::import;
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::TimePiece::Oracle - Extension to Class::DBI for Oracle DATE type.

=head1 VERSION

This documentation refers to Class::DBI::Plugin::TimePiece::Oracle version 0.01

=head1 SYNOPSIS

 __PACKAGE__->has_a_auto_timepiece( INS_DATE );
 __PACKAGE__->has_a_atp( UPDATE_DATE );

=head1 DESCRIPTION

This module is Extensionto Class::DBI for Oracle DATE type.
This module supports Oracle DATE TYPE limitedly.
This module supports the following FORMAT.

 - YYYY
 - YY
 - RRRR
 - RR
 - MM
 - MON
 - MONTH
 - DD
 - HH
 - HH24
 - MI
 - SS

=head1 METHOD

=head2 has_a_auto_timepiece

This method is automatic related by useing Time::Piece for Oracle date type.
This method need Class::DBI::Plugin::DateFormat::Oracle's get_nls_date_format method.

 __PACKAGE__->has_a_auto_timepiece( INS_DATE );

INS_DATE colum related to Time::Piece Object.

=head2 has_a_atp

has_a_atp is has_a_auto_timepiece'a alias.

=head2 _get_nls_date_format

_get_nls_date_format converts nls_date_format into Time::Piece format.

=head1 DEPENDENCIES

L<Carp>, L<Time::Piece>, L<Class::DBI::Plugin::DateFormat::Oracle>

=head1 SEE ALSO

L<Carp>, L<Time::Piece>, L<Class::DBI::Plugin::DateFormat::Oracle>

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
