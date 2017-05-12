package Date::Holidays::CA_ES;
{
  $Date::Holidays::CA_ES::VERSION = '0.03';
}

use strict;
use warnings;

use DateTime;

use base 'Date::Holidays::ES';

sub holidays {
    my ($self, %params) = @_;

    my $es_h = $self->SUPER::holidays(%params);
    my $ct_h = {
       '0624' => 'Sant Joan',
       '0911' => 'Diada Nacional',
       '1226' => 'Sant Esteve',
       '0106' => 'Reis',
    };

    my %reverse = reverse %$es_h;
    my $v_santo = $reverse{'Viernes Santo'};

    # 'Pasqua Florida' is always 3 days after 'Viernes Santo'
    my $p_florida = DateTime->new(
        year  => $params{year},
        month => substr($v_santo, 0, 2),
        day   => substr($v_santo, 2, 2),
    )->add( days => 3 );
    my (undef, $month, $day) = split '-', $p_florida->ymd();
    $ct_h->{"$month$day"} = 'Pasqua Florida';

    my %merge = ( %$es_h, %$ct_h );
    return \%merge;
}

1;
__END__

=head1 NAME

Date::Holidays::CA_ES - Catalan holidays

=head1 SYNOPSIS

  use Date::Holidays;

  my $dh = Date::Holidays->new( countrycode => 'ca_es', nocheck => 1 );

=head1 DESCRIPTION

This module provide the official holidays for Catalonia, an Autonomous
Community of Spain. It makes use of Date::Holidays::ES as parent class, since
the catalan holidays are the spanish ones plus some more.

Notice that "ca_es" is not a valid ISO 3166 code, so the "nocheck" option set
to true in the constructor is mandatory to use this module.

The following Catalan holidays have fixed dates (remember to take a look to the
spanish ones as well!)

  6  Jan           Reis
  24 Jun           Sant Joan
  11 Sep           Diada Nacional
  26 Dec           Sant Esteve

The following Catalan holiday hasn't a fixed date:

  Pasqua Florida    Three days after the spanish holiday "Viernes Santo"

=head1 METHODS

The methods are identical to Date::Holidays::ES ones, except those with the
"es" country code in them. Since "ca_es", is not a valid ISO country code,
those methods are not provided.

=head2 holidays

This is the only implemented method, adding the catalan holidays to the days
provided by Date::Holidays::ES

=head1 SEE ALSO

L<Date::Holidays::ES>,

=head1 AUTHOR

Miquel Ruiz, E<lt>mruiz@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Miquel Ruiz.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

