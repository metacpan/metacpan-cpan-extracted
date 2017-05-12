##-*- Mode: CPerl -*-

##======================================================================
## top-level
package DDC::PP::CQCount;
use DDC::PP::Constants;
use DDC::PP::CQuery;
use Carp qw(carp confess);
use strict;

##======================================================================
## CQCountKeyExpr
package DDC::PP::CQCountKeyExpr;
use strict;
our @ISA = qw(DDC::PP::CQuery);

sub CanCountByFile { return 1; }

##======================================================================
## CQCountKeyExprConstant
package DDC::PP::CQCountKeyExprConstant;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExpr);

sub defaultLabel { return '*'; }
sub new {
  my ($that,$label,%opts) = @_;
  return $that->SUPER::new(($label||$that->defaultLabel),%opts);
}

sub toString { return '@'.$_[0]->sqString($_[0]{Label}); }

##======================================================================
## CQCountKeyExprMeta
package DDC::PP::CQCountKeyExprMeta;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExpr);

##======================================================================
## CQCountKeyExprFileId
package DDC::PP::CQCountKeyExprFileId;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprMeta);

sub defaultLabel { return 'fileid'; }

##======================================================================
## CQCountKeyExprIndexed
package DDC::PP::CQCountKeyExprIndexed;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprMeta);

sub defaultLabel { return 'file'; }

##======================================================================
## CQCountKeyExprFileName
package DDC::PP::CQCountKeyExprFileName;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprIndexed);

sub defaultLabel { return 'filename'; }

##======================================================================
## CQCountKeyExprDate
package DDC::PP::CQCountKeyExprDate;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprIndexed);

sub defaultLabel { return 'date'; }

##======================================================================
## CQCountKeyExprDateSlice
package DDC::PP::CQCountKeyExprDateSlice;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprDate);

__PACKAGE__->defprop('Slice');
sub new {
  my ($that,$label,$slice,%opts) = @_;
  return $that->SUPER::new($label,Slice=>$slice,%opts); ##-- lower-case 'slice' in DDC, should be ok
}

sub toString { return $_[0]->sqString($_[0]{Label}).'/'.($_[0]{Slice}||1); }

##======================================================================
## CQCountKeyExprBibl
package DDC::PP::CQCountKeyExprBibl;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprIndexed);

sub defaultLabel { return ''; }
sub new {
  my ($that,$attr,%opts) = @_;
  return $that->SUPER::new($attr,%opts);
}

sub toString { return $_[0]->sqString($_[0]{Label}); }

##======================================================================
## CQCountKeyExprRegex
package DDC::PP::CQCountKeyExprRegex;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprIndexed);

__PACKAGE__->defprop('Src');
__PACKAGE__->defprop('Pattern');
__PACKAGE__->defprop('Replacement');
__PACKAGE__->defprop('Modifiers');
__PACKAGE__->defprop('isGlobal');
sub defaultLabel { return 'regex'; }
sub new {
  my ($that,$src,$pat,$repl,$mods,%opts) = @_;
  return $that->SUPER::new(undef,Src=>$src,Pattern=>$pat,Replacement=>$repl,Modifiers=>$mods,IsGlobal=>0,%opts);
}

sub Children { [grep {defined($_)} $_[0]{Src}]; }

sub Clear { delete $_[0]{Src}; }
sub toString {
  return '(' . $_[0]{Src}->toString . " ~ s/$_[0]{Pattern}/$_[0]{Replacement}/$_[0]{Modifiers})";
}

##======================================================================
## CQCountKeyExprToken
package DDC::PP::CQCountKeyExprToken;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExprIndexed);

__PACKAGE__->defprop('IndexName');
__PACKAGE__->defprop('MatchId');
__PACKAGE__->defprop('Offset');
sub defaultLabel { return 'token'; }
sub new {
  my ($that,$index,$matchid,$offset,%opts) = @_;
  return $that->SUPER::new(undef,IndexName=>($index||"Token"),MatchId=>($matchid||0),Offset=>($offset||0),%opts);
}

sub CanCountByFile { return 0; }
*GetMatchId = \&getMatchId;
*SetMatchId = \&setMatchId;

sub toString {
  return ('$'
	  .$_[0]{IndexName}
	  .($_[0]{MatchId} ? sprintf(" =%hhu", $_[0]{MatchId}) : '')
	  .($_[0]{Offset}  ? sprintf(" %+d", $_[0]{Offset}) : '')
	 );
}

##======================================================================
## CQCountKeyExprList
package DDC::PP::CQCountKeyExprList;
use strict;
our @ISA = qw(DDC::PP::CQCountKeyExpr);

__PACKAGE__->defprop('Exprs');
sub defaultLabel { return 'list'; }
sub new {
  my $that = shift;
  return $that->SUPER::new(undef,Exprs=>[],@_);
}


sub Clear { @{$_[0]{Exprs}} = qw(); }
sub empty { return !$_[0]{Exprs} || !@{$_[0]{Exprs}}; }
sub PushKey { push(@{$_[0]{Exprs}},$_[1]); }

sub CanCountByFile { return !grep {$_ && !$_->CanCountByFile} @{$_[0]{Exprs}||[]}; }
sub GetMatchId {
  my ($id);
  foreach (@{$_[0]{Exprs}||[]}) {
    return $id if ($_ && ($id=$_->GetMatchId));
  }
  return 0;
}
#sub SetMatchId  ##-- not implemented

sub Children { return $_[0]{Exprs} || []; }

sub toString {
  return join(',', map {$_->toString} @{$_[0]{Exprs}||[]});
}

##======================================================================
## CQCount
package DDC::PP::CQCount;
use strict;
our @ISA = qw(DDC::PP::CQuery);

__PACKAGE__->defprop('Dtr');
__PACKAGE__->defprop('Sample');
__PACKAGE__->defprop('Sort');
__PACKAGE__->defprop('Lo');
__PACKAGE__->defprop('Hi');
__PACKAGE__->defprop('Keys');
sub new {
  my ($that,$dtr,$keys,$samp,$sort,$lo,$hi,%opts) = @_;
  return $that->SUPER::new('COUNT',Dtr=>$dtr,Keys=>$keys,Sample=>($samp||-1),Sort=>($sort||DDC::PP::NoSort),Lo=>$lo,Hi=>$hi,%opts);
}

sub Children { [grep {defined($_)} @{$_[0]}{qw(Dtr Keys)}]; }

sub Clear { delete @{$_[0]}{qw(Dtr Keys)}; }
sub GetMatchId {
  return (($_[0]{Keys} && $_[0]{Keys}->GetMatchId)
	  || ($_[0]{Dtr} && $_[0]{Dtr}->GetMatchId)
	  || 0);
}

sub toString {
  return "COUNT(" . $_[0]{Dtr}->toString . $_[0]{Dtr}->optionsToString .")".  $_[0]->countOptionsToString;
}
sub countOptionsToString {
  my $obj = shift;
  return (
	  ($obj->{Keys} && !$obj->{Keys}->empty ? (" #BY[".$obj->{Keys}->toString."]") : '')
	  .($obj->{Sample} && $obj->{Sample} > 0 ? " #SAMPLE $obj->{Sample}" : '')
	  .($obj->{Sort} != $DDC::PP::HitSortEnum{NoSort}
	    ? (" #".uc($DDC::PP::HitSortEnumStrings[$obj->{Sort}])
	       .($obj->{Lo} || $obj->{Hi}
		 ? ("[".($obj->{Lo} ? $obj->sqString($obj->{Lo}) : '')
		    .",".($obj->{Hi} ? $obj->sqString($obj->{Hi}) : '')
		    ."]")
		 : '')
	      )
	    : '')
	 );
}

##======================================================================
## CQKeys
package DDC::PP::CQKeys;
use strict;
our @ISA = qw(DDC::PP::CQuery);

__PACKAGE__->defprop('QCount');
__PACKAGE__->defprop('CountLimit');
__PACKAGE__->defprop('IndexNames');
__PACKAGE__->defprop('MatchId');
sub new {
  my ($that,$qcount,$climit,$ixnames,%opts) = @_;
  return $that->SUPER::new('KEYS',QCount=>$qcount,CountLimit=>($climit||-1),IndexNames=>($ixnames||[]),%opts);
}

sub GetMatchId {
  return ($_[0]{MatchId}
	  || ($_[0]{QCount} && $_[0]{QCount}->GetMatchId)
	  || 0);
}
*SetMatchId = \&setMatchId;

sub toString {
  my $obj = shift;
  return (
	  ($obj->{IndexNames} && @{$obj->{IndexNames}}
	   ? ('$('.join(',', map {$obj->sqString($_)} @{$obj->{IndexNames}}).')=')
	   : '')
	  .'KEYS('
	  .($obj->{QCount}
	    ? (($obj->{QCount}{Dtr} ? ($obj->{QCount}{Dtr}->toString.$obj->{QCount}{Dtr}->optionsToString) : '')
	       .$obj->{QCount}->countOptionsToString)
	    : '')
	  .($obj->{CountLimit} > 0 ? " #CLIMIT $obj->{CountLimit}" : '')
	  .')'
	  .($obj->{MatchId} ? " =$obj->{MatchId}" : '')
	 );
}



1; ##-- be happy

=pod

=head1 NAME

DDC::PP::CQCount - pure-perl implementation of DDC::XS::CQCount

=head1 SYNOPSIS

 use DDC::PP::CQCount;
 #... stuff happens ...


=head1 DESCRIPTION

The DDC::PP::CQCount class is a pure-perl fork of the L<DDC::XS::CQCount|DDC::XS::CQCount> class,
which see for details.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::XS::CQCount(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

