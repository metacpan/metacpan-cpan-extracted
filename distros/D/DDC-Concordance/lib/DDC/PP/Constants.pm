##-*- Mode: CPerl -*-

##======================================================================
package DDC::PP;

##--------------------------------------------------------------
## ddcConfig.h
sub library_version { return "2.2.3"; }


##--------------------------------------------------------------
## ConcCommon.h: HitSortEnum
our @HitSortEnum = qw(
		       NoSort
		       LessByDate GreaterByDate
		       LessBySize GreaterBySize
		       LessByFreeBiblField GreaterByFreeBiblField
		       LessByRank GreaterByRank
		       LessByMiddleContext GreaterByMiddleContext
		       LessByLeftContext GreaterByLeftContext
		       LessByRightContext GreaterByRightContext
		       RandomSort
		       LessByCountKey GreaterByCountKey
		       LessByCountValue GreaterByCountValue
		    );
our @HitSortEnumStrings = qw(
			      no_sort
			      asc_by_date desc_by_date
			      asc_by_size desc_by_size
			      asc desc
			      asc_by_rank desc_by_rank
			      asc_middle desc_middle
			      asc_left desc_left
			      asc_right desc_right
			      random
			      asc_by_key desc_by_key
			      asc_by_count desc_by_count
			   );

our %HitSortEnum = ((map {($HitSortEnum[$_]       =>$_)} (0..$#HitSortEnum)),
		    (map {($HitSortEnumStrings[$_]=>$_)} (0..$#HitSortEnumStrings))
		   );
sub HitSortEnumName { return $HitSortEnum[$_[0]]; }
sub HitSortsCount { return scalar @HitSortEnum; }
sub HitSortEnumString { return $HitSortEnumStrings[$_[0]]; }

foreach my $ename (@HitSortEnum) {
  no strict 'refs';
  *$ename = sub { return $HitSortEnum{$ename}; };
}

##======================================================================
## Exports
our %EXPORT_TAGS =
  (
   'hitsort' => [qw(@HitSortEnum @HitSortEnumStrings %HitSortEnum HitSortEnumString), @HitSortEnum],
  );
$EXPORT_TAGS{all}       = [map {@$_} values %EXPORT_TAGS];
$EXPORT_TAGS{constants} = [map {@$_} @EXPORT_TAGS{qw(hitsort)}];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};
our @EXPORT    = qw();

##======================================================================
package DDC::PP::Constants;
use strict;

1; ##-- be happy

=pod

=head1 NAME

DDC::PP::Constants - pure-perl DDC::XS clone: constants

=head1 SYNOPSIS

 use DDC::PP;
 # or
 use DDC::PP qw(:constants);
 
 ##---------------------------------------------------------------------
 ## Top-Level constants (not exported)
 
 $string = DDC::PP::library_version();
 
 ##---------------------------------------------------------------------
 ## ConcCommon.h: HitSortEnum (export-tag ":hitsort")

 # enum values are also available as $DDC::PP::HitSortEnum{NoSort}, etc.
 $i = DDC::PP::NoSort();
 $i = DDC::PP::LessByDate();
 $i = DDC::PP::GreaterByDate();
 $i = DDC::PP::LessBySize();
 $i = DDC::PP::GreaterBySize();
 $i = DDC::PP::LessByFreeBiblField();
 $i = DDC::PP::GreaterByFreeBiblField();
 $i = DDC::PP::LessByRank();
 $i = DDC::PP::GreaterByRank();
 $i = DDC::PP::LessByMiddleContext();
 $i = DDC::PP::GreaterByMiddleContext();
 $i = DDC::PP::LessByLeftContext();
 $i = DDC::PP::GreaterByLeftContext();
 $i = DDC::PP::LessByRightContext();
 $i = DDC::PP::GreaterByRightContext();
 $i = DDC::PP::RandomSort();
 $i = DDC::PP::LessByCountKey();
 $i = DDC::PP::GreaterByCountKey();
 $i = DDC::PP::LessByCountValue();
 $i = DDC::PP::GreaterByCountValue();
 $i = DDC::PP::HitSortsCount();

 # enum labels are also available as $DDC::PP::HitSortEnum[DDC::PP::NoSort], etc.
 $s = DDC::PP::HitSortName($i);


=head1 DESCRIPTION

The DDC::PP::Constants is pure-perl fork of the L<DDC::XS::Constants|DDC::XS::Constants> module.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2020 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

