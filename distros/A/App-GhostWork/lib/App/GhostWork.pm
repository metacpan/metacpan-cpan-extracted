package App::GhostWork;
######################################################################
#
# App::GhostWork - Barcode Logger(When,Where,Who,What,toWhich,Why)
#
# https://metacpan.org/dist/App-GhostWork
#
# Copyright (c) 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.02';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;

1;

__END__

=pod

=head1 NAME

App::GhostWork - Barcode Logger(When,Where,Who,What,toWhich,Why)

=head1 SYNOPSIS

  C:\WINDOWS> GhostWorkEnglish.bat  [Enter]
  C:\WINDOWS> GhostWorkEnglish.bat  constant-WHY  [Enter]
  
  C:\WINDOWS> GhostWorkJapanese.bat  [Enter]
  C:\WINDOWS> GhostWorkJapanese.bat  constant-WHY  [Enter]

=head1 DESCRIPTION

This software creates a log file from barcode data. The log file is in
LTSV format. Each record has the following labels.

  -----------------------------------------------------
  labels:     meanings
  -----------------------------------------------------
  csv:        All columns as CSV format
  when:       When barcode was read ?
  where:      Where barcode was read ? (COMPUTERNAME)
  who:        Who read the barcode ?
  what:       What barcode read ?
  towhich:    Which status after barcode was read ?
  why:        Why become its status ? (optional)
  looseid:    Moderately unique random numbers
  -----------------------------------------------------

=head2 Command File Name

  English edition is "GhostWorkEnglish.bat".
  Japanese edition is "GhostWorkJapanese.bat".

=head2 Command Line Parameter(s)

  C:\WINDOWS> GhostWorkEnglish.bat  constant-WHY  [Enter]
  
  If WHY is same for all records, you can omit entering WHY each record
  by specifying constant-WHY on command line.
  
  C:\WINDOWS> GhostWorkEnglish.bat  [Enter]
  
  If you don't specify constant-WHY options, you will have to enter WHY
  each record.

=head2 Log File Name

  The barcode information is recorded in a log file with the following
  name.
  -----------------------------------------------------
  LOG/when/towhich/when-towhich-who.ltsv
  -----------------------------------------------------

=head2 ***REMOVE_THIS_TIMESTAMP***

Working time per record can be calculated by comparing the "WHEN" of
adjacent records. The next record after the final work contains string
"***REMOVE_THIS_TIMESTAMP***" as "WHAT". If you want only barcode
records, you need to remove those records.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

