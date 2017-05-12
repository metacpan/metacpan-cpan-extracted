package Date::Holidays::AT;

use warnings;
use strict;

# Stock modules
use Time::Local;
use POSIX qw(strftime);

# Prerequisite
use Date::Calc 5.0 qw(Add_Delta_Days Easter_Sunday Day_of_Week This_Year);

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(holidays);
use version; our $VERSION = qv("0.1.4");

sub holidays {
    my %parameters = (
                      YEAR     => This_Year(),
                      WHERE    => ['common'],
                      FORMAT   => "%s",
                      WEEKENDS => 1,
                      @_,
                     );

    # Easter is the key to everything
    my ($year, $month, $day) = Easter_Sunday($parameters{'YEAR'});

    # Aliases for holidays
    #
    # neuj = New year's day
    # hl3k = Heilige 3 Koenige
    # jose = Josef
    # tdar = Staatsfeiertag (Tag der Arbeit)
    # flor = Florian
    # mahi = Mariae Himmelfahrt
    # rupe = Rupert
    # volk = Tag der Volksabstimmung
    # nati = Nationalfeiertag
    # alhe = Allerheiligen
    # mart = Martin
    # leop = Leopold
    # maem = Mariae Empfaengnis
    # heab = Heiliger Abend
    # chri = Christtag
    # stef = Stefanitag
    # silv = Silvester
    # karf = Karfreitag
    # ostm = Ostermontag
    # himm = Christi Himmelfahrt
    # pfim = Pfingstmontag
    # fron = Fronleichnam

    # Fixed-date holidays
    #
    my (%holiday, %holidays);

    $holiday{'neuj'} = _date2timestamp($year, 1,  1);     # New year's day
    $holiday{'hl3k'} = _date2timestamp($year, 1,  6);     # Heilige 3 Koenige
    $holiday{'jose'} = _date2timestamp($year, 3,  19);    # Josef
    $holiday{'tdar'} = _date2timestamp($year, 5,  1);     # Staatsfeiertag (Tag der Arbeit)
    $holiday{'flor'} = _date2timestamp($year, 5,  4);     # Florian
    $holiday{'mahi'} = _date2timestamp($year, 8,  15);    # Mariae Himmelfahrt
    $holiday{'rupe'} = _date2timestamp($year, 9,  24);    # Rupert
    $holiday{'volk'} = _date2timestamp($year, 10, 10);    # Tag der Volksabstimmung
    $holiday{'nati'} = _date2timestamp($year, 10, 26);    # Nationalfeiertag
    $holiday{'alhe'} = _date2timestamp($year, 11, 1);     # Allerheiligen
    $holiday{'mart'} = _date2timestamp($year, 11, 11);    # Martin
    $holiday{'leop'} = _date2timestamp($year, 11, 15);    # Leopold
    $holiday{'maem'} = _date2timestamp($year, 12, 8);     # Mariae Empfaengnis
    $holiday{'heab'} = _date2timestamp($year, 12, 24);    # Heiliger Abend
    $holiday{'chri'} = _date2timestamp($year, 12, 25);    # Christtag
    $holiday{'stef'} = _date2timestamp($year, 12, 26);    # Stefanitag
    $holiday{'silv'} = _date2timestamp($year, 12, 31);    # Silvester

    # Holidays relative to Easter
    #
    # Karfreitag (Good Friday) = Easter Sunday minus 2 days
    my ($j_karf, $m_karf, $t_karf) = Date::Calc::Add_Delta_Days($year, $month, $day, -2);
    $holiday{'karf'} = _date2timestamp($j_karf, $m_karf, $t_karf);

    # Ostermontag (Easter Monday) = Easter Sunday plus 1 day
    my ($j_ostm, $m_ostm, $t_ostm) = Date::Calc::Add_Delta_Days($year, $month, $day, 1);
    $holiday{'ostm'} = _date2timestamp($j_ostm, $m_ostm, $t_ostm);

    # Christi Himmelfahrt (Ascension Day) = Easter Sunday plus 39 days
    my ($j_himm, $m_himm, $t_himm) = Date::Calc::Add_Delta_Days($year, $month, $day, 39);
    $holiday{'himm'} = _date2timestamp($j_himm, $m_himm, $t_himm);

    # Pfingsmontag (Whit Monday) = Easter Sunday plus 50 days
    my ($j_pfim, $m_pfim, $t_pfim) = Date::Calc::Add_Delta_Days($year, $month, $day, 50);
    $holiday{'pfim'} = _date2timestamp($j_pfim, $m_pfim, $t_pfim);

    # Fronleichnam (Corpus Christi) = Easter Sunday plus 60 days
    my ($j_fron, $m_fron, $t_fron) = Date::Calc::Add_Delta_Days($year, $month, $day, 60);
    $holiday{'fron'} = _date2timestamp($j_fron, $m_fron, $t_fron);

    # Common holidays througout Austria
    @{ $holidays{'common'} } = qw(neuj hl3k ostm tdar himm pfim fron mahi nati alhe maem chri stef);


    # Extra for Burgenland
    @{ $holidays{'B'} } =   qw(jose karf mart heab silv );
    # Extra for Kaernten
    @{ $holidays{'K'} } =   qw(     karf volk heab silv );
    # Extra for Niederoesterreich
    @{ $holidays{'NOE'} } = qw(     karf leop heab silv );
    # Extra for Oberoesterreich
    @{ $holidays{'OOE'} } = qw(     karf flor heab silv );
    # Extra for Salzburg
    @{ $holidays{'S'} } =   qw(     karf rupe heab silv );
    # Extra for Steiermark
    @{ $holidays{'ST'} } =  qw(jose karf      heab silv );
    # Extra for Tirol
    @{ $holidays{'T'} } =   qw(jose karf      heab silv );
    # Extra for Voralberg
    @{ $holidays{'V'} } =   qw(jose karf      heab silv );
    # Extra for Wien
    @{ $holidays{'W'} } =   qw(     karf leop heab silv );

    # Build list for returning
    #
    my %holidaylist;
    # See what holidays shall be printed
    my $wantall = 0;
    foreach (@{$parameters{'WHERE'}}){
        if ($_ eq 'all'){
            $wantall = 1;
        }
    }
    if (1 == $wantall){
        # All holidays if 'all' is in the WHERE parameter list.
        %holidaylist = %holiday;
    }else{
        # Only specified regions
        foreach my $scope (@{$parameters{'WHERE'}}){
            foreach my $alias(@{$holidays{$scope}}){
                $holidaylist{$alias} = $holiday{$alias};
            }
        }
    }


    # Add the most obscure holidays that were requested through
    # the ADD parameter
    if ($parameters{'ADD'}) {
        foreach my $add (@{ $parameters{'ADD'} }) {
            $holidaylist{$add} = $holiday{$add};
        }
    }

    # If WEEKENDS => 0 was passed, weed out holidays on weekends
    #
    unless (1 == $parameters{'WEEKENDS'}) {

        # Walk the list of holidays
        foreach my $alias (keys(%holidaylist)) {

            # Get day of week. Since we're no longer
            # in Date::Calc's world, use localtime()
            my $dow = (localtime($holiday{$alias}))[6];

            # dow 6 = Saturday, dow 0 = Sunday
            if ((6 == $dow) or (0 == $dow)) {

                # Kick this day from the list
                delete $holidaylist{$alias};
            }
        }
    }

    # Sort values stored in the hash for returning
    #
    my @returnlist;
    foreach (sort { $holidaylist{$a} <=> $holidaylist{$b} } (keys(%holidaylist))) {

        # See if this platform has strftime(%s)
        # if not, inject seconds manually into format string.
        my $formatstring = $parameters{'FORMAT'};
        if (strftime('%s', localtime($holidaylist{$_})) eq '%s') {
            $formatstring =~ s/%{0}%s/$holidaylist{$_}/g;
        }

        # Inject the holiday's alias name into the format string
        # if it was requested by adding %#.
        $formatstring =~ s/%{0}%#/$_/;
        push @returnlist, strftime($formatstring, localtime($holidaylist{$_}));
    }
    return \@returnlist;
}

sub _date2timestamp {

    # Turn Date::Calc's y/m/d format into a UNIX timestamp
    my ($y, $m, $d) = @_;
    my $timestamp = timelocal(0, 0, 0, $d, ($m - 1), $y);
    return $timestamp;
}

1;
__END__

1; # End of code Date::Holidays::AT

=head1 NAME

Date::Holidays::AT - Determine Austrian holidays

=head1 SYNOPSIS

  use Date::Holidays::AT qw(holidays);
  my $feiertage_ref = holidays();
  my @feiertage     = @$feiertage_ref;

=head1 DESCRIPTION

This module exports a single function named B<holidays()> which returns a list of 
Austrian holidays in a given year. 

=head1 KNOWN HOLIDAYS

The module knows about the following holidays:

    neuj = New year's day
    hl3k = Heilige 3 Koenige
    jose = Josef
    tdar = Staatsfeiertag (Tag der Arbeit)
    flor = Florian
    mahi = Mariae Himmelfahrt
    rupe = Rupert
    volk = Tag der Volksabstimmung
    nati = Nationalfeiertag
    alhe = Allerheiligen
    mart = Martin
    leop = Leopold
    maem = Mariae Empfaengnis
    heab = Heiliger Abend
    chri = Christtag
    stef = Stefanitag
    silv = Silvester
    karf = Karfreitag
    ostm = Ostermontag
    himm = Christi Himmelfahrt
    pfim = Pfingstmontag
    fron = Fronleichnam

Please refer to the module source for detailed information about how every 
holiday is calculated.  Too much detail would be far beyond the scope of this 
document, but it's not particularly hard once you've found the date for
Easter.

=head1 USAGE

=head2 OUTPUT FORMAT

The list returned by B<holidays()> consists of UNIX-Style timestamps in seconds 
since The Epoch. You may pass a B<strftime()> style format string to get the 
dates in any format you desire:

  my $feiertage_ref = holidays(FORMAT=>"%d.%m.%Y");

This might be considered "hard to use" by some people, so here are a few 
examples to get you started:

  FORMAT=>"%d.%m.%Y"              25.12.2001
  FORMAT=>"%Y%m%d"                20011225
  FORMAT=>"%a, %B %d"             Tuesday, December 25

Please consult the manual page of B<strftime()> for a complete list of available
format definitions.

There is, however, one "proprietary" extension to the formats of B<strftime()>:
The format definition I<%#> will print the internal abbreviation used for each
holiday. 

  FORMAT=>"%#:%d.%m"              wei1:25.12.

As the module doesn't want to deal with i18n 
issues, you'll have to find your own way to translate the aliases into your 
local language. See the I<example/feiertage.pl> script included in the
Date::Holidays::DE distribution to get the idea. This was added in version 0.6. 


=head2 LOCAL HOLIDAYS

The module also knows about different regulations throughout Austria

When calling B<holidays()>, the resulting list by default contains the list of 
Austria-wide holidays.

You can specify one ore more of the following federal states to get the list of 
holidays local to that state:

  B    Burgenland
  K    Kaernten
  NOE  Niederoesterreich
  OOE  Oberoesterreich
  S    Salzburg
  ST   Steiermark
  T    Tirol
  W    Wien

For example,

  my $feiertage_ref = holidays(WHERE=>['W', 'S']);

returns the list of holidays local to Wien or Salzburg.

To get the list of local holidays along with the default list of common
Austrian holidays, use the following:

  my $feiertage_ref = holidays(WHERE=>['common', 'ST']);

returns the list of common Austrian holidays merged with the list of holidays
specific to Steiermark.

You can also request a list containing all holidays this module knows about:

  my $feiertage_ref = holidays(WHERE=>['all']);

will return a list of all known holidays.

=head2 ADDITIONAL HOLIDAYS

There are a number of holidays that aren't really holidays, e.g. New Year's Eve 
and Christmas Eve. These aren't contained in the I<common> set of holidays 
returnd by the B<holidays()> function. The aforementioned I<silv> and I<heab> 
are probably the most likely ones that you'll need.

If you want one or several of them to appear in the output from B<holidays()>, 
use the following:

  my $feiertage_ref = holidays(ADD=>['heab', 'silv']);

=head2 SPECIFYING THE YEAR

By default, B<holidays()> returns the holidays for the current year. Specify
a year as follows:

  my $feiertage_ref = holidays(YEAR=>2004);

=head2 HOLIDAYS ON WEEKENDS

By default, B<holidays()> includes Holidays that occur on weekends in its 
listing.

To disable this behaviour, set the I<WEEKENDS> option to 0:

  my $feiertage_ref = holidays(WEEKENDS=>0);

=head1 COMPLETE EXAMPLE

Get all holidays for Ausria in 2004, count New Year's Eve and 
Christmas Eve as Holidays. Exclude weekends and return the date list in human
readable format:

  my $feiertage_ref = holidays(FORMAT   => "%a, %d.%m.%Y"
                               WHERE    => ['common'],
                               WEEKENDS => 0,
                               YEAR     => 2004,
                               ADD      => ['heab', 'silv']);

=head1 PREREQUISITES

Uses B<Date::Calc 5.0> for all calculations. Makes use of the B<POSIX> and 
B<Time::Local> modules from the standard Perl distribution.

=head1 BUGS & SUGGESTIONS

If you run into a miscalculation, need some sort of feature or an additional
holiday, or if you know of any new changes to the funky holiday situation, 
please drop the author a note.

=head1 LIMITATIONS

B<Date::Calc> works with year, month and day numbers exclusively. Even though
this module uses B<Date::Calc> for all calculations, it represents the calculated
holidays as UNIX timestamps (seconds since The Epoch) to allow for more
flexible formatting. This limits the range of years to work on to 
the years from 1972 to 2037. 

B<Date::Holidays::AT> doesn't know anything about past holiday regulations.

B<Date::Holidays::AT> is not configurable. Holiday changes don't come over
night and a new module release can be rolled out within a single day.

B<Date::Holidays::AT> probably won't work in Microsoft's "Windows" operating 
environment.

=head1 ACKNOWLEDGEMENTS

Thanks to Martin Schmitt E<lt>mas at scsy dot deE<gt>. B<Date::Holidays::AT>
is based on B<Date::Holidays::DE>.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 SEE ALSO

=over

=item L<perl>

=item L<Date::Calc>

=item L<Date::Holidays>

=back

=head1 COPYRIGHT

Copyright 2007 plusW, Rolf Schaufelberger.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
