package Date::Holidays::SK;

use strict;
use warnings;

our $VERSION = '0.02';

use Date::Simple;
use Date::Easter;

use Exporter qw(import);
our @EXPORT_OK = qw(
   is_sk_holiday
   is_sk_holiday_today
   sk_holidays
);

# Fixed-date holidays {'MMDD' => 'NAME'}
my $FIX = {
   '0101' => 'Deň vzniku Slovenskej republiky',
   '0106' => 'Zjavenie Pána (Traja králi)',
   '0501' => 'Sviatok práce',
   '0508' => 'Deň víťazstva nad fašizmom',
   '0705' => 'Sviatok svätého Cyrila a Metoda',
   '0829' => 'Výročie SNP',
   '0901' => 'Deň Ústavy Slovenskej republiky',
   '0915' => 'Sedembolestná Panna Mária',
   '1101' => 'Sviatok všetkých svätých',
   '1117' => 'Deň boja za slobodu a demokraciu',
   '1224' => 'Štedrý deň',
   '1225' => 'Prvý sviatok vianočný',
   '1226' => 'Druhý sviatok vianočný',
};

# The only variable-date holiday is Easter Monday and Easter Friday -- we deal with that separately
my $EF = 'Veľkonočný piatok';
my $EM = 'Veľkonočný pondelok';

sub is_sk_holiday {
   my ($year, $month, $day) = @_;

   my $k = sprintf "%02d%02d", $month, $day;

   # for fixed dates
   return $FIX->{$k}
      if exists $FIX->{$k};

   my $diff = Date::Simple->new($year, $month, $day) - Date::Simple->new($year, easter($year));
   # Easter Sunday +1 -> Easter Monday.
   return $EM if ( $diff == 1 );
   # Easter Sunday -2 -> Easter Friday.
   return $EF if ( $diff == -2 );

   return 0;
}

sub sk_holidays {

   my ($year, $month, $day) = @_;

   my $easter = Date::Simple->new($year, easter($year));
   # Easter Monday is the day after Easter
   my $em = $easter + 1;
   # Easter Friday is 2 days before Easter
   my $ef = $easter - 2;

   # Easter Key ($ek) is a string in the form 'MMDD'
   my $emk = sprintf "%02d%02d", $em->month, $em->day;
   my $efk = sprintf "%02d%02d", $ef->month, $ef->day;

   # $h is a reference to a hash containing the results
   my $h;

   if ( ! $month ) {

      #print "DEBUG: only year given\n";
      $h = {%$FIX};
      $h->{$emk} = $EM;
      $h->{$efk} = $EF;

   } elsif ( ! $day ) {

      #print "DEBUG: only year and month given\n";
      my $m = sprintf "%02d", $month;
      foreach my $k (keys %$FIX) {
         $h->{$k} = $FIX->{$k} if $k =~ m/\A$m/;
      }
      $h->{$emk} = $EM if $emk =~ m/\A$m/;
      $h->{$efk} = $EF if $efk =~ m/\A$m/;

   } else {

      #print "DEBUG: year, month, and day given\n";
      my $k = sprintf "%02d%02d", $month, $day;
      $h->{$k} = $FIX->{$k} if exists $FIX->{$k};
      $h->{$emk} = $EM if $emk == $k;
      $h->{$efk} = $EF if $efk == $k;

   }

   return $h;
}

sub is_sk_holiday_today {
   my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
   $year  += 1900;
   $month += 1;
   return is_sk_holiday( $year, $month, $day );
}

1;

__END__

=encoding utf8

=head1 NAME

Date::Holidays::SK - determine Slovak Republic bank holidays

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

   use Date::Holidays::SK qw(
      is_sk_holiday
      is_sk_holiday_today
      sk_holidays
   );

   my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
   $year  += 1900;
   $month += 1;
   print "Woohoo" if is_sk_holiday( $year, $month, $day );
   
   # or
   
   print "Woohoo" if is_sk_holiday_today;

   my $hashref;
   $hashref = sk_holidays(2014);        # full listing for 2014
   $hashref = sk_holidays(2014, 4);     # just for April, 2014
   $hashref = sk_holidays(2014, 4, 8);  # just for April 8, 2014

=head1 DESCRIPTION

This module provides a simple way to get information on Slovak Republic
bank holidays.

This module is a clone of L<Date::Holidays::CZ>.

=head1 DEPENDENCIES

Date::Holidays::SK depends on the following two modules:

=over 8

=item * L<Date::Simple>

=item * L<Date::Easter>

=back

=head1 SLOVAK REPUBLIC BANK HOLIDAYS

=head2 Fixed and variable

With two exceptions, the dates of all Slovak Republic bank holidays
are fixed. The exception is Easter Friday and Monday.

See L<http://en.wikipedia.org/wiki/Public_holidays_in_Slovakia>

=head1 EXPORT

=over 8

=item * is_sk_holiday

=item * is_sk_holiday_today

=item * sk_holidays

=back

=head1 SUBROUTINES/METHODS

=head2 C<is_sk_holiday>

Takes three named arguments:

=over 8

=item * C<year>, four-digit number

=item * C<month>, 1-12, two-digit number

=item * C<day>, 1-31, two-digit number

=back

=head2 C<sk_holidays>

Takes one to three arguments: C<year> (four-digit number), C<month> (1-12, two-digit number),
and C<day> (1-31, two-digit number).  Returns a reference to a hash in which
the keys are 'MMDD' (month and day, concatenated) and the values are
the names of all the various bank holidays that fall within the year, month, or day
indicated by the arguments.

=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad at gmail.com> >>

adjusted for Slovakia by

Jozef Kutej C<< <jkutej at cpan.org> >>

=head1 SEE ALSO

L<Date::Holidays::CZ>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
