package Date::Holidays::IE;
use strict;

=head1 NAME

Date::Holidays::IE - Determine Irish holidays - Current EIRE public and bank holiday dates up to 2025

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Date::Holidays::IE qw( holidays is_holiday);

    # All EIRE holidays for 2023
    my $holidays = holidays( year => 2023 );

    if (is_holiday(
            year => 2023, month => 12, day => 25
           )
    ) {
        print "No work today!";
    }

    # simpler "date" parameter
    if ( is_holiday( date => '2023-12-25' ) ) {
        print "No work today!";
    }

=head1 DESCRIPTION

A L<Date::Holidays> compatible library with EIRE national holiday dates
available from L<https://openholidaysapi.org/>

=head1 EXPORTS

Exports C<holidays> and C<is_holiday> functions

=cut

use base qw( Date::Holidays::Super Exporter );

our %EXPORT_TAGS = ( 'all' => [ qw( holidays is_holiday ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(holidays is_holiday);

our $VERSION = '0.01';
our $ALL_HOLIDAYS = _build_all_holidays();

=head1 FUNCTIONS

=head2 is_holiday

=cut

sub is_holiday {
  my %args = $_[0] =~ m/[^0-9-]/ ? @_ : ( year => $_[0], month => $_[1], day => $_[2] );

  my ( $yyyy, $month, $day ) = ( $args{date} )
    ? $args{date} =~ m{^([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})$}
    : @args{qw( year month day )};

  unless ($yyyy && $month && $day) {
    die "Must specify either 'date' or 'year', 'month' and 'day'";
  }
  my $mm = $month ? sprintf('%02d', $month) : undef;
  my $dd = $day ? sprintf('%02d', $day) : undef;

  my $holiday = $ALL_HOLIDAYS->{$yyyy}{$mm}{$dd}{name};
  return $holiday;
}

=head2 holidays

=cut

sub holidays {
  my %args = $_[0] =~ m/[^0-9-]/ ? @_ : ( year => $_[0], month => $_[1], day => $_[2] );

  my ( $yyyy, $month, $day ) = ( $args{date} )
    ? $args{date} =~ m{^([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})$}
    : @args{qw( year month day )};

  unless ($yyyy) {
    die "Must specify either 'date' or 'year'";
  }

  my $mm = $month ? sprintf('%02d', $month) : undef;
  my $dd = $day ? sprintf('%02d', $day) : undef;
  my $holidays = { };
  if ($dd) {
    my $holiday = $ALL_HOLIDAYS->{$yyyy}{$mm}{$dd};
    if ($holiday) {
      $holidays = { "$mm$dd" => $ALL_HOLIDAYS->{$yyyy}{$mm}{$dd}{name} };
    }
  } elsif ($mm) {
    foreach my $dd ( keys %{$ALL_HOLIDAYS->{$yyyy}{$mm}} ) {
      $holidays->{"${mm}${dd}"} = $ALL_HOLIDAYS->{$yyyy}{$mm}{$dd}{name};
    }
  } else {
    foreach my $mm (keys %{$ALL_HOLIDAYS->{$yyyy}}) {
      foreach my $dd ( keys %{$ALL_HOLIDAYS->{$yyyy}{$mm}} ) {
        $holidays->{"${mm}${dd}"} = $ALL_HOLIDAYS->{$yyyy}{$mm}{$dd}{name};
      }
    }
  }
  return $holidays;
}


###############

sub _build_all_holidays {
  return {
          '2023' => {
                      '08' => {
                                '07' => {
                                          'date' => '2023-08-07',
                                          'name' => 'August Holiday'
                                        }
                              },
                      '02' => {
                                '06' => {
                                          'name' => 'Saint Brigid\'s Day',
                                          'date' => '2023-02-06'
                                        }
                              },
                      '05' => {
                                '01' => {
                                          'date' => '2023-05-01',
                                          'name' => 'May Day'
                                        }
                              },
                      '03' => {
                                '17' => {
                                          'name' => 'Saint Patrick\'s Day',
                                          'date' => '2023-03-17'
                                        }
                              },
                      '06' => {
                                '05' => {
                                          'name' => 'June Holiday',
                                          'date' => '2023-06-05'
                                        }
                              },
                      '10' => {
                                '30' => {
                                          'date' => '2023-10-30',
                                          'name' => 'October Holiday'
                                        }
                              },
                      '12' => {
                                '25' => {
                                          'date' => '2023-12-25',
                                          'name' => 'Christmas Day'
                                        },
                                '26' => {
                                          'name' => 'St. Stephen\'s Day',
                                          'date' => '2023-12-26'
                                        }
                              },
                      '01' => {
                                '01' => {
                                          'name' => 'New Year\'s Day',
                                          'date' => '2023-01-01'
                                        }
                              },
                      '04' => {
                                '10' => {
                                          'date' => '2023-04-10',
                                          'name' => 'Easter Monday'
                                        }
                              }
                    },
          '2024' => {
                      '04' => {
                                '01' => {
                                          'name' => 'Easter Monday',
                                          'date' => '2024-04-01'
                                        }
                              },
                      '01' => {
                                '01' => {
                                          'date' => '2024-01-01',
                                          'name' => 'New Year\'s Day'
                                        }
                              },
                      '06' => {
                                '03' => {
                                          'date' => '2024-06-03',
                                          'name' => 'June Holiday'
                                        }
                              },
                      '10' => {
                                '28' => {
                                          'name' => 'October Holiday',
                                          'date' => '2024-10-28'
                                        }
                              },
                      '12' => {
                                '26' => {
                                          'name' => 'St. Stephen\'s Day',
                                          'date' => '2024-12-26'
                                        },
                                '25' => {
                                          'date' => '2024-12-25',
                                          'name' => 'Christmas Day'
                                        }
                              },
                      '05' => {
                                '06' => {
                                          'date' => '2024-05-06',
                                          'name' => 'May Day'
                                        }
                              },
                      '03' => {
                                '17' => {
                                          'name' => 'Saint Patrick\'s Day',
                                          'date' => '2024-03-17'
                                        }
                              },
                      '02' => {
                                '05' => {
                                          'name' => 'Saint Brigid\'s Day',
                                          'date' => '2024-02-05'
                                        }
                              },
                      '08' => {
                                '05' => {
                                          'date' => '2024-08-05',
                                          'name' => 'August Holiday'
                                        }
                              }
                    },
          '2025' => {
                      '02' => {
                                '03' => {
                                          'name' => 'Saint Brigid\'s Day',
                                          'date' => '2025-02-03'
                                        }
                              },
                      '08' => {
                                '04' => {
                                          'date' => '2025-08-04',
                                          'name' => 'August Holiday'
                                        }
                              },
                      '05' => {
                                '05' => {
                                          'name' => 'May Day',
                                          'date' => '2025-05-05'
                                        }
                              },
                      '03' => {
                                '17' => {
                                          'name' => 'Saint Patrick\'s Day',
                                          'date' => '2025-03-17'
                                        }
                              },
                      '06' => {
                                '02' => {
                                          'date' => '2025-06-02',
                                          'name' => 'June Holiday'
                                        }
                              },
                      '10' => {
                                '27' => {
                                          'name' => 'October Holiday',
                                          'date' => '2025-10-27'
                                        }
                              },
                      '12' => {
                                '25' => {
                                          'date' => '2025-12-25',
                                          'name' => 'Christmas Day'
                                        },
                                '26' => {
                                          'date' => '2025-12-26',
                                          'name' => 'St. Stephen\'s Day'
                                        }
                              },
                      '04' => {
                                '21' => {
                                          'date' => '2025-04-21',
                                          'name' => 'Easter Monday'
                                        }
                              },
                      '01' => {
                                '01' => {
                                          'name' => 'New Year\'s Day',
                                          'date' => '2025-01-01'
                                        }
                              }
                    }
        };
}

=head1 SEE ALSO

=over 4

=item *

L<Date::Holidays>

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/hashbangperl/Date-Holidays-IE/issues>.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/hashbangperl/Date-Holidays-IE>

=head1 AUTHOR

Aaron Trevena teejay@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Amtivo Group Plc

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.34.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
