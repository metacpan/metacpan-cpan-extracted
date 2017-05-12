##-*- Mode: CPerl -*-

##======================================================================
## top-level
package DDC::PP::CQFilter;
use DDC::PP::Object;
use DDC::PP::Constants;
use DDC::Utils qw();
use strict;

##======================================================================
## CQFilter
package DDC::PP::CQFilter;
use strict;
our @ISA = qw(DDC::PP::Object);

sub new {
  my ($that,%opts) = @_;
  return $that->SUPER::new(%opts);
}

sub toString { return "#FILTER[?]"; }

##======================================================================
package DDC::PP::CQFSort;
use strict;
our @ISA = qw(DDC::PP::CQFilter);

__PACKAGE__->defprop('Arg0');
__PACKAGE__->defprop('Arg1');
__PACKAGE__->defprop('Arg2');
__PACKAGE__->defprop('Type');

sub defaultSort { return 'NoSort'; }
sub new {
  my ($that,$sort,$arg0,$arg1,$arg2,%opts) = @_;
  return $that->SUPER::new(Type=>(defined($sort) ? $sort : $DDC::PP::HitSortEnum{$that->defaultSort}),
			   Arg0=>$arg0,
			   Arg1=>$arg1,
			   Arg2=>$arg2,
			   %opts);
}
sub new_i {
  my ($that,$sort,$arg0,$arg1,$arg2,%opts) = @_;
  return $that->new($sort,$arg0,($arg1+0),($arg2+0),%opts);
}

sub argString {
  return !defined($_[1]) || $_[1] eq '' ? '' : DDC::Utils::escapeq($_[1]);
}
sub argStringE {
  return DDC::Utils::escapeq(defined($_[1]) ? $_[1] : '');
}
sub toString {
  my $f = shift;
  my $args = join(',',
		  ($f->{Arg0} ? $f->{Arg0} : qw()),
		  ($f->{Arg1} || $f->{Arg2}
		   ? ((defined($f->{Arg1}) ? $f->{Arg1} : ''),
		      (defined($f->{Arg2}) ? $f->{Arg2} : ''))
		   : qw())
		 );
  return '#'.uc($DDC::PP::HitSortEnumStrings[$f->{Type}]).($args ? "[$args]" : '');
}

sub jsonType { return (FilterType=>$DDC::PP::HitSortEnumStrings[$_[0]{Type}]); }
sub jsonMinMax { return (Min=>$_[0]{Arg1}, Max=>$_[0]{Arg2}); }
sub jsonData { return ($_[0]->jsonType, $_[0]->jsonMinMax); }

##-- ddc-compatible hash-conversion (for toJson())
sub toHash {
  my ($obj,%opts) = @_;
  return $obj->SUPER::toHash(%opts) if (!$opts{json});
  return { class=>$obj->jsonClass, $obj->jsonData };
}

##-- pseudo-accessors (for json)
__PACKAGE__->defalias('Min'=>'Arg1', 0,1);
__PACKAGE__->defalias('Max'=>'Arg2', 0,1);
#sub getFilterType { return $DDC::PP::HitSortEnumStrings[$_[0]{Type}]; }
sub setFilterType { return $_[0]{Type} = $DDC::PP::HitSortEnum{$_[1]}; }


##======================================================================
## CQFRankSort
package DDC::PP::CQFRankSort;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

sub defaultSort { return 'GreaterByRank'; }
sub jsonMinMax { return qw(); }

##======================================================================
## CQFDateSort
package DDC::PP::CQFDateSort;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

sub defaultSort { return 'LessByDate' };
sub new {
  my ($that,$ftype,$lb,$ub,%opts) = @_;
  return $that->SUPER::new($ftype,'',$lb,$ub,%opts);
}

##======================================================================
## CQFSizeSort
package DDC::PP::CQFSizeSort;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

sub defaultSort { return 'LessBySize'; }
sub new {
  my ($that,$ftype,$lb,$ub,%opts) = @_;
  return $that->SUPER::new($ftype,'',$lb,$ub,%opts);
}

##======================================================================
## CQFRandomSort
package DDC::PP::CQFRandomSort;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

sub defaultSort { return 'RandomSort'; }
sub new {
  my ($that,$seed,%opts) = @_;
  return $that->SUPER::new(undef,'',$seed,'',%opts);
}
*new_i = \&new;

##-- ddc-json compat
__PACKAGE__->defalias('Seed'=>'Arg1', 0,1);
sub jsonMinMax { return (Seed=>$_[0]{Arg1}); }

##======================================================================
## CQFBiblSort
package DDC::PP::CQFBiblSort;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

sub defaultSort { return 'LessByFreeBiblField'; }
sub new {
  my ($that,$ftype,$field,$lb,$ub,%opts) = @_;
  return $that->SUPER::new($ftype,$field,$lb,$ub,%opts);
}

sub toString {
  my $f = shift;
  return ('#'.uc($DDC::PP::HitSortEnumStrings[$f->{Type}])
	  .'['.join(',',
		    $f->argString($f->{Arg0}),
		    (defined($f->{Arg1}) || defined($f->{Arg2})
		     ? ($f->argString($f->{Arg1}),$f->argString($f->{Arg2}))
		     : qw()),
		   )
	  .']');
}

##-- ddc-json compat
__PACKAGE__->defalias('Field'=>'Arg0', 0,1);
sub jsonData { return (Field=>$_[0]{Arg0}, $_[0]->SUPER::jsonData); }


##======================================================================
## CQFContextSort
package DDC::PP::CQFContextSort;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

sub defaultSort { return 'LessByMiddleContext'; }
sub new {
  my ($that,$ftype,$field,$matchid,$offset,$lb,$ub,%opts) = @_;
  return $that->SUPER::new($ftype,$field,$lb,$ub, MatchId=>($matchid||0), Offset=>($offset||0), %opts);
}

sub toString {
  my $f = shift;
  return ('#'.uc($DDC::PP::HitSortEnumStrings[$f->{Type}])
	  .'['.$f->argString($f->{Arg0})
	  .($f->{MatchId} ? " =$f->{MatchId}" : '')
	  .sprintf(" %+d", ($f->{Offset}||0))
	  .(defined($f->{Arg1}) || defined($f->{Arg2})
	    ? join(',', '', $f->argString($f->{Arg1}), $f->argString($f->{Arg2}))
	    : '')
	  .']');
}

sub jsonData { return (Field=>$_[0]{Arg0}, MatchId=>$_[0]{MatchId}, Offset=>$_[0]{Offset}, $_[0]->SUPER::jsonData); }
__PACKAGE__->defalias('Field'=>'Arg0', 0,1);

##======================================================================
## CQFHasField
package DDC::PP::CQFHasField;
use strict;
our @ISA = qw(DDC::PP::CQFSort);

__PACKAGE__->defprop('Negated');
sub defaultSort { return 'NoSort'; }
sub new {
  my ($that,$field,$val,$negated,%opts) = @_;
  return $that->SUPER::new(undef,$field,$val,'',Negated=>($negated||0),%opts);
}

sub Negate { $_[0]{Negated} = $_[0]{Negated} ? 0 : 1; }

sub toString {
  my $f = shift;
  return (($f->{Negated} ? '!' : '')
	  ."#HAS[".$f->argStringE($f->{Arg0}).','.$f->valueString.']'
	 );
}
sub valueString { return $_[0]->argStringE($_[0]{Arg1}); }

sub jsonMinMax { return (Field=>$_[0]{Arg0}, Value=>$_[0]->jsonFieldValue, Negated=>($_[0]{Negated} ? 1 : 0)); }
sub jsonFieldValue { return $_[0]{Arg1}; }
__PACKAGE__->defalias('Field'=>'Arg0', 0,1);
__PACKAGE__->defalias('Value'=>'Arg1', 0,1);

##======================================================================
## CQFHasFieldValue
package DDC::PP::CQFHasFieldValue;
use strict;
our @ISA = qw(DDC::PP::CQFHasField);

##======================================================================
## CQFHasFieldRegex
package DDC::PP::CQFHasFieldRegex;
use strict;
our @ISA = qw(DDC::PP::CQFHasField);

__PACKAGE__->defprop('Regex');
sub new {
  my ($that,$field,$val,$negated,%opts) = @_;
  return $that->SUPER::new($field,$val,$negated,Regex=>$val,%opts);
}

sub valueString { return "/$_[0]{Regex}/"; }

##======================================================================
## CQFHasFieldPrefix
package DDC::PP::CQFHasFieldPrefix;
use strict;
our @ISA = qw(DDC::PP::CQFHasFieldRegex);

sub new {
  my ($that,$field,$val,$negated,%opts) = @_;
  return $that->SUPER::new($field,$val,$negated,Regex=>"^\\Q${val}\\E",%opts);
}

sub valueString { return $_[0]->argStringE($_[0]{Arg1}).'*'; }

##======================================================================
## CQFHasFieldSuffix
package DDC::PP::CQFHasFieldSuffix;
use strict;
our @ISA = qw(DDC::PP::CQFHasFieldRegex);

sub new {
  my ($that,$field,$val,$negated,%opts) = @_;
  return $that->SUPER::new($field,$val,$negated,Regex=>"\\Q${val}\\E\$",%opts);
}

sub valueString { return '*'.$_[0]->argStringE($_[0]{Arg1}); }

##======================================================================
## CQFHasFieldInfix
package DDC::PP::CQFHasFieldInfix;
use strict;
our @ISA = qw(DDC::PP::CQFHasFieldRegex);

sub new {
  my ($that,$field,$val,$negated,%opts) = @_;
  return $that->SUPER::new($field,$val,$negated,Regex=>"\\Q${val}\\E",%opts);
}

sub valueString { return '*'.$_[0]->argStringE($_[0]{Arg1}).'*'; }

##======================================================================
## CQFHasFieldSet
package DDC::PP::CQFHasFieldSet;
use strict;
our @ISA = qw(DDC::PP::CQFHasField);

__PACKAGE__->defprop('Values');
sub new {
  my ($that,$field,$vals,$negated,%opts) = @_;
  return $that->SUPER::new($field,"{}",$negated,Values=>($vals||[]),%opts);
}

sub SetValueString {
  my ($f,$vals) = @_;
  $vals ||= ($f->{Values}||[]);
  return join(',', map {$f->argStringE($_)} @$vals);
}
sub valueString { return '{' . $_[0]->SetValueString . '}'; }

sub jsonFieldValue { return $_[0]{Values}; }



1; ##-- be happy

=pod

=head1 NAME

DDC::PP::CQFilter - pure-perl implementation of DDC::XS::CQFilter

=head1 SYNOPSIS

 use DDC::PP::CQFilter;
 #... stuff happens ...


=head1 DESCRIPTION

The DDC::PP::CQFilter class is a pure-perl fork of the L<DDC::XS::CQFilter|DDC::XS::CQFilter> class,
which see for details.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::XS::CQFilter(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

