##-*- Mode: CPerl -*-

##======================================================================
package DDC::XS;

##--------------------------------------------------------------
## Exports: HitSortEnum
our (@HitSortEnum,@HitSortEnumStrings,%HitSortEnum);
BEGIN {
  @HitSortEnum = map {HitSortEnumName($_)} (0..(HitSortsCount()-1));
  @HitSortEnumStrings = map {HitSortEnumString($_)} (0..(HitSortsCount()-1));
  %HitSortEnum = ((map {($HitSortEnum[$_]=>$_)} (0..$#HitSortEnum)),
		  (map {($HitSortEnumStrings[$_]=>$_)} (0..$#HitSortEnum)),
		 );
}

##======================================================================
## Exports
our %EXPORT_TAGS =
  (
   'hitsort' => [qw(@HitSortEnum @HitSortEnumStrings %HitSortEnum), @HitSortEnum],
  );
$EXPORT_TAGS{all}       = [map {@$_} values %EXPORT_TAGS];
$EXPORT_TAGS{constants} = [map {@$_} @EXPORT_TAGS{qw(hitsort)}];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};
our @EXPORT    = qw();

##======================================================================
package DDC::XS::Constants;
use strict;

1; ##-- be happy

=pod

=head1 NAME

DDC::XS::Constants - XS interface to DDC C++ constants

=head1 SYNOPSIS

 use DDC::XS;
 # or
 use DDC::XS qw(:constants);
 
 ##---------------------------------------------------------------------
 ## Top-Level constants (not exported)
 
 $string = DDC::XS::library_version()
 
 ##---------------------------------------------------------------------
 ## ConcCommon.h: HitSortEnum (export-tag ":hitsort")

 # enum values are also available as $DDC::XS::HitSortEnum{NoSort}, etc.
 $i = DDC::XS::NoSort();
 $i = DDC::XS::LessByDate();
 $i = DDC::XS::GreaterByDate();
 $i = DDC::XS::LessBySize();
 $i = DDC::XS::GreaterBySize();
 $i = DDC::XS::LessByFreeBiblField();
 $i = DDC::XS::GreaterByFreeBiblField();
 $i = DDC::XS::LessByRank();
 $i = DDC::XS::GreaterByRank();
 $i = DDC::XS::LessByMiddleContext();
 $i = DDC::XS::GreaterByMiddleContext();
 $i = DDC::XS::LessByLeftContext();
 $i = DDC::XS::GreaterByLeftContext();
 $i = DDC::XS::LessByRightContext();
 $i = DDC::XS::GreaterByRightContext();
 $i = DDC::XS::RandomSort();
 $i = DDC::XS::LessByCountKey();
 $i = DDC::XS::GreaterByCountKey();
 $i = DDC::XS::LessByCountValue();
 $i = DDC::XS::GreaterByCountValue();
 $i = DDC::XS::HitSortsCount();

 # enum labels are also available as $DDC::XS::HitSortEnum[DDC::XS::NoSort], etc.
 $s = DDC::XS::HitSortEnumName($i);

 # enum keywords are also available as $DDC::XS::HitSortEnumStrings[DDC::XS::NoSort], etc.
 $s = DDC::XS::HitSortEnumString($i);


=head1 DESCRIPTION

The DDC::XS::Constants module provides a perl interface to the DDC C++ constants.

=head1 SEE ALSO

perl(1),
DDC::XS(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

