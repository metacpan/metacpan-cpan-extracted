##-*- Mode: CPerl -*-

##======================================================================
## top-level
package DDC::PP::CQuery;
use DDC::PP::Object;
use DDC::Utils qw();
use Carp qw(carp confess);
use strict;


##======================================================================
## CQuery
package DDC::PP::CQuery;
use strict;
our @ISA = qw(DDC::PP::Object);

__PACKAGE__->defprop('Label');
__PACKAGE__->defprop('Options');
sub new {
  my ($that,$label,%opts) = @_;
  return $that->SUPER::new(Label=>$label,%opts);
}

##-- options only
sub _new {
  my $that = shift;
  return $that->SUPER::new(@_);
}

sub Negated { return 0; }
sub Negate { confess((ref($_[0])||$_[0])."::Negate(): attempt to negate non-negatable query"); }

sub GetMatchId { return 0; }
sub SetMatchId { confess((ref($_[0])||$_[0])."::SetMatchId(): attempt to set match-ID for non-token query"); }
sub HasMatchId { $_[0]->GetMatchId != 0; }

sub RootOk { return !$_[0]->Negated; }
sub ClearOptions { delete $_[0]{Options}; }
sub Clear { ; }

sub toString {
  return $_[0]{Label};
}
sub optionsToString {
  return '' if (!$_[0]{Options});
  return $_[0]{Options}->toString;
}
sub toStringFull {
  return $_[0]->toString . $_[0]->optionsToString;
}

##-- stringification utility
sub sqString {
  return DDC::Utils::escapeq(defined($_[1]) ? $_[1] : '');
}


##======================================================================
## CQNegatable
package DDC::PP::CQNegatable;
use strict;
our @ISA = qw(DDC::PP::CQuery);

__PACKAGE__->defprop('Negated');
sub new {
  my ($that,$label,$negated,%opts) = @_;
  return $that->_new(Label=>$label,Negated=>$negated,%opts);
}

sub Negated { return $_[0]->getNegated ? 1 : 0; }
sub Negate  { return $_[0]->setNegated($_[0]->getNegated ? 0 : 1); }

sub NegString {
  my ($obj,$s) = @_;
  return $_[0]->Negated ? "!$s" : $s;
}

##======================================================================
## CQAtomic
package DDC::PP::CQAtomic;
use strict;
our @ISA = qw(DDC::PP::CQNegatable);


##======================================================================
## CQBinOp
package DDC::PP::CQBinOp;
use strict;
our @ISA = qw(DDC::PP::CQNegatable);

__PACKAGE__->defprop('Dtr1');
__PACKAGE__->defprop('Dtr2');
__PACKAGE__->defprop('OpName');
sub new {
  my ($that,$dtr1,$dtr2,$opName,$negated,%opts) = @_;
  return $that->_new(Label=>$opName,OpName=>$opName,Dtr1=>$dtr1,Dtr2=>$dtr2,Negated=>$negated,%opts);
}

sub Children { [grep {defined($_)} @{$_[0]}{qw(Dtr1 Dtr2)}]; }

sub GetMatchId {
  my $obj = shift;
  return (($obj->{Dtr2} && $obj->{Dtr2}->GetMatchId)
	  || ($obj->{Dtr1} && $obj->{Dtr1}->GetMatchId)
	  || 0);
}
sub SetMatchId {
  my ($obj,$id) = @_;
  $obj->{Dtr1}->SetMatchId($id) if ($obj->{Dtr1});
  $obj->{Dtr2}->SetMatchId($id) if ($obj->{Dtr2});
  return $id;
}

sub Clear {
  delete @{$_[0]}{qw(Dtr1 Dtr2)};
}
sub toString {
  my $obj = shift;
  return $obj->NegString("(".$obj->{Dtr1}->toString." ".$obj->{OpName}." ".$obj->{Dtr2}->toString.")");
}

##======================================================================
## CQAnd
package DDC::PP::CQAnd;
use strict;
our @ISA = qw(DDC::PP::CQBinOp);

sub new {
  my ($that,$dtr1,$dtr2) = @_;
  return $that->SUPER::new($dtr1,$dtr2,"&&");
}

##======================================================================
## CQOr
package DDC::PP::CQOr;
use strict;
our @ISA = qw(DDC::PP::CQBinOp);

sub new {
  my ($that,$dtr1,$dtr2) = @_;
  return $that->SUPER::new($dtr1,$dtr2,"||");
}

##======================================================================
## CQWith
package DDC::PP::CQWith;
use strict;
our @ISA = qw(DDC::PP::CQBinOp);

__PACKAGE__->defprop('MatchId');
sub new {
  my ($that,$dtr1,$dtr2,$matchid,%opts) = @_;
  return $that->SUPER::new($dtr1,$dtr2,"WITH",0,MatchId=>($matchid||0),%opts);
}

sub GetMatchId {
  my $obj = shift;
  return $obj->{MatchId} || $obj->SUPER::GetMatchId();
}
sub SetMatchId {
  $_[0]{MatchId} = $_[1];
}

sub toString {
  return $_[0]->SUPER::toString().($_[0]{MatchId} ? " =$_[0]{MatchId}" : '');
}

##======================================================================
## CQWithout
package DDC::PP::CQWithout;
use strict;
our @ISA = qw(DDC::PP::CQWith);

sub new {
  my ($that,$dtr1,$dtr2,$matchid,%opts) = @_;
  return $that->SUPER::new($dtr1,$dtr2,$matchid,OpName=>"WITHOUT",%opts);
}

##======================================================================
## CQWithor
package DDC::PP::CQWithor;
use strict;
our @ISA = qw(DDC::PP::CQWith);

sub new {
  my ($that,$dtr1,$dtr2,$matchid,%opts) = @_;
  return $that->SUPER::new($dtr1,$dtr2,$matchid,OpName=>"WITHOR",%opts);
}

##======================================================================
## CQToken
package DDC::PP::CQToken;
use strict;
our @ISA = qw(DDC::PP::CQAtomic);

__PACKAGE__->defprop('IndexName');
__PACKAGE__->defprop('Value');
__PACKAGE__->defprop('MatchId');
sub new {
  my ($that,$index,$value,$matchid,%opts) = @_;
  return $that->_new(Label=>$value,Negated=>0,IndexName=>($index||''),Value=>$value,MatchId=>($matchid||0),%opts);
}

*GetMatchId = *getMatchId;
*SetMatchId = *setMatchId;

sub OperatorKey { return '_'; }
sub IndexName { return $_[0]{IndexName} || '' }
sub BreakName { return $_[0]{BreakName} || '' }

sub IndexString { return $_[0]->IndexName eq '' ? '' : ('$'.$_[0]->IndexName.'='); }
sub ValueString { return $_[0]->sqString($_[0]->{Value}); }
sub MatchIdString { return $_[0]{MatchId} ? " =$_[0]{MatchId}" : ''; }

sub toString {
  my $obj = shift;
  return $obj->NegString($obj->IndexString . $obj->ValueString . $obj->MatchIdString);
}

##======================================================================
## CQTokExact
package DDC::PP::CQTokExact;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub OperatorKey { return '@'; }
sub ValueString { return '@'.$_[0]->sqString($_[0]->{Value}); }

##======================================================================
## CQTokAny
package DDC::PP::CQTokAny;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub OperatorKey { return '*'; }
sub ValueString { return '*'; }

##======================================================================
## CQTokAnchor
package DDC::PP::CQTokAnchor;
use strict;
our @ISA = qw(DDC::PP::CQToken);

__PACKAGE__->defprop('ValueInt');
sub new {
  my ($that,$index,$value,%opts) = @_;
  return $that->SUPER::new($index,$value,0,ValueInt=>$value,%opts);
}

sub OperatorKey { return '.'; }
sub IndexString { return '$.'.$_[0]->IndexName.'='; }
sub ValueString { return $_[0]{ValueInt} || 0; }

##======================================================================
## CQTokRegex
package DDC::PP::CQTokRegex;
use strict;
our @ISA = qw(DDC::PP::CQToken);

__PACKAGE__->defprop('RegexNegated');
sub new {
  my ($that,$index,$regex,$negated,%opts) = @_;
  return $that->SUPER::new($index,$regex,0,%opts);
}

sub OperatorKey { return '/_/'; }
sub ValueString {
  my $re = defined($_[0]{Value}) ? $_[0]{Value} : '';
  $re =~ s{/}{\\/}g;
  return ($_[0]{RegexNegated} ? '!' : '')."/$re/";
}

##======================================================================
## CQTokSet
package DDC::PP::CQTokSet;
use strict;
our @ISA = qw(DDC::PP::CQToken);

__PACKAGE__->defprop('Values');
sub new {
  my ($that,$index,$rawValue,$values,%opts) = @_;
  return $that->SUPER::new($index,$rawValue,0,Values=>($values||[]),%opts);
}

sub OperatorKey { return '@_' };
sub SetValueString {
  my ($obj,$values) = @_;
  $values ||= $obj->{Values};
  return join(',', map {$obj->sqString($_)} @$values);
}
sub ValueString {
  return '@{' . $_[0]->SetValueString . '}';
}

##======================================================================
## CQTokInfl
package DDC::PP::CQTokInfl;
use strict;
our @ISA = qw(DDC::PP::CQTokSet);

__PACKAGE__->defprop('Expanders');
sub new {
  my ($that,$index,$value,$expanders,%opts) = @_;
  return $that->SUPER::new($index,$value,[$value],Expanders=>($expanders||[]),Value=>$value,%opts);
}
sub newSet {
  my ($that,$index,$values,$expanders,%opts) = @_;
  return $that->SUPER::new($index,"$values",$values,Expanders=>($expanders||[]),Value=>"$values",%opts);
}

sub OperatorKey { return '_'; }
sub ExpanderString {
  my $obj = shift;
  return '' if (!@{$obj->{Expanders}||[]});
  return join('|', '', map {!defined($_) || $_ eq '' ? '-' : $_} @{$obj->{Expanders}});
}
sub ValueString {
  my $obj = shift;
  return $obj->DDC::PP::CQToken::ValueString . $obj->ExpanderString;
}

##======================================================================
## CQTokSetInfl
package DDC::PP::CQTokSetInfl;
use strict;
our @ISA = qw(DDC::PP::CQTokInfl);

__PACKAGE__->defprop('RawValues');
sub new {
  my ($that,$index,$values,$expanders,%opts) = @_;
  return $that->SUPER::new($index,$values,$expanders,RawValues=>$values,%opts);
}

sub ValueString {
  my $obj = shift;
  return '{' . $obj->SetValueString($obj->{RawValues}) . '}' . $obj->ExpanderString;
}

##======================================================================
## CQTokPrefix
package DDC::PP::CQTokPrefix;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub new {
  my ($that,$index,$prefix,%opts) = @_;
  return $that->SUPER::new($index,$prefix,0,%opts);
}
sub OperatorKey { return '/_/'; }
sub ValueString { return $_[0]->sqString($_[0]{Value}).'*'; }

##======================================================================
## CQTokSuffix
package DDC::PP::CQTokSuffix;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub new {
  my ($that,$index,$suffix,%opts) = @_;
  return $that->SUPER::new($index,$suffix,0,%opts);
}
sub OperatorKey { return '/_/'; }
sub ValueString { return '*'.$_[0]->sqString($_[0]{Value}); }

##======================================================================
## CQTokInfix
package DDC::PP::CQTokInfix;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub new {
  my ($that,$index,$infix,%opts) = @_;
  return $that->SUPER::new($index,$infix,0,%opts);
}
sub OperatorKey { return '/_/'; }
sub ValueString { return '*'.$_[0]->sqString($_[0]{Value}).'*'; }

##======================================================================
## CQTokPrefixSet
package DDC::PP::CQTokPrefixSet;
use strict;
our @ISA = qw(DDC::PP::CQTokSet);

sub new {
  my ($that,$index,$prefixes,%opts) = @_;
  return $that->SUPER::new($index,"$prefixes",($prefixes||[]),%opts);
}

sub OperatorKey { return '/_/'; }
sub ValueString { return '{' . $_[0]->SetValueString . '}*'; }

##======================================================================
## CQTokSuffixSet
package DDC::PP::CQTokSuffixSet;
use strict;
our @ISA = qw(DDC::PP::CQTokSet);

sub new {
  my ($that,$index,$suffixes,%opts) = @_;
  return $that->SUPER::new($index,"$suffixes",($suffixes||[]),%opts);
}

sub OperatorKey { return '/_/'; }
sub ValueString { return '*{' . $_[0]->SetValueString . '}'; }

##======================================================================
## CQTokInfixSet
package DDC::PP::CQTokInfixSet;
use strict;
our @ISA = qw(DDC::PP::CQTokSet);

sub new {
  my ($that,$index,$infixes,%opts) = @_;
  return $that->SUPER::new($index,"$infixes",($infixes||[]),%opts);
}

sub OperatorKey { return '/_/'; }
sub ValueString { return '*{' . $_[0]->SetValueString . '}*'; }

##======================================================================
## CQTokMorph
package DDC::PP::CQTokMorph;
use strict;
our @ISA = qw(DDC::PP::CQToken);

__PACKAGE__->defprop('Items');
sub new {
  my ($that,$index,$items,%opts) = @_;
  return $that->SUPER::new(($index||'MorphPattern'),"$items",0, Items=>($items||[]), %opts);
}

sub Append {
  my ($obj,$item) = @_;
  push(@{$obj->{Items}},$item);
}

sub OperatorKey { return '[_]'; }
sub ValueString { return '[' . join(',', map {$_[0]->sqString($_)} @{$_[0]{Items}||[]}). ']'; }

##======================================================================
## CQTokLemma
package DDC::PP::CQTokLemma;
use strict;
our @ISA = qw(DDC::PP::CQTokMorph);

sub new {
  my ($that,$index,$value,%opts) = @_;
  return $that->DDC::PP::CQToken::new(($index||'Lemma'),$value,0,%opts);
}

sub OperatorKey { return '%_'; }
sub ValueString { return '%' . $_[0]->sqString($_[0]{Value}); }

##======================================================================
## CQTokThes
package DDC::PP::CQTokThes;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub new {
  my ($that,$index,$value,%opts) = @_;
  return $that->SUPER::new(($index||'Thes'),$value,0,%opts);
}

sub OperatorKey { return ':{_}'; }
sub ValueString { return ':{' . $_[0]->sqString($_[0]{Value}) . '}'; };

##======================================================================
## CQTokChunk
package DDC::PP::CQTokChunk;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub new {
  my ($that,$index,$value,%opts) = @_;
  return $that->SUPER::new(($index||''),$value,0,%opts);
}

sub OperatorKey { return '^_'; }
sub ValueString { return '^' . $_[0]->sqString($_[0]{Value}); }

##======================================================================
## CQTokFile
package DDC::PP::CQTokFile;
use strict;
our @ISA = qw(DDC::PP::CQToken);

sub new {
  my ($that,$index,$filename,%opts) = @_;
  return $that->SUPER::new($index,$filename,0,%opts);
}

sub OperatorKey { return '<_'; }
sub ValueString { return '<' . $_[0]->sqString($_[0]{Value}); }

##======================================================================
## CQNear
package DDC::PP::CQNear;
use strict;
our @ISA = qw(DDC::PP::CQNegatable);

__PACKAGE__->defprop('Dtr1');
__PACKAGE__->defprop('Dtr2');
__PACKAGE__->defprop('Dtr3');
__PACKAGE__->defprop('Dist');
sub new {
  my ($that,$dist,$dtr1,$dtr2,$dtr3,%opts) = @_;
  return $that->SUPER::new("NEAR",0,Dist=>(defined($dist) ? $dist : 1), Dtr1=>$dtr1, Dtr2=>$dtr2, Dtr3=>$dtr3, %opts);
}

sub Children { [grep {defined($_)} @{$_[0]}{qw(Dtr1 Dtr2 Dtr3)}]; }

sub Clear { delete @{$_[0]}{qw(Dtr1 Dtr2 Dtr3)}; }

sub GetMatchId {
  my $obj = shift;
  return (($obj->{Dtr3} && $obj->{Dtr3}->GetMatchId)
	  || ($obj->{Dtr2} && $obj->{Dtr2}->GetMatchId)
	  || ($obj->{Dtr1} && $obj->{Dtr2}->GetMatchId)
	  || 0
	 );
}
sub SetMatchId {
  my ($obj,$id) = @_;
  $obj->{Dtr1}->SetMatchId($id) if ($obj->{Dtr1});
  $obj->{Dtr2}->SetMatchId($id) if ($obj->{Dtr2});
  $obj->{Dtr3}->SetMatchId($id) if ($obj->{Dtr3});
  return $id;
}

sub toString {
  return $_[0]->NegString("NEAR(".join(',', (map {$_->toString} grep {defined $_} @{$_[0]}{qw(Dtr1 Dtr2 Dtr3)}), $_[0]{Dist}).")");
}

##======================================================================
## CQSeq
package DDC::PP::CQSeq;
use strict;
our @ISA = qw(DDC::PP::CQAtomic);

__PACKAGE__->defprop('Items');
__PACKAGE__->defprop('Dists');
__PACKAGE__->defprop('DistOps');
sub new {
  my ($that,$items,$dists,$distops,%opts) = @_;
  return $that->SUPER::new('""',0, Items=>($items||[]), Dists=>($dists||[]), DistOps=>($distops||[]), %opts);
}
sub new1 {
  my ($that,$item,%opts) = @_;
  return $that->new([$item],[],[],%opts);
}

sub Append {
  my ($obj,$nextItem,$nextDist,$nextDistOp) = @_;
  $nextDistOp ||= '<';
  if (@{$obj->{Items}}) {
    push(@{$obj->{Dists}}, $nextDist);
    push(@{$obj->{DistOps}}, $nextDistOp);
  }
  push(@{$obj->{Items}}, $nextItem);
}

sub Clear { @{$_[0]{Items}} = @{$_[0]{Dists}} = @{$_[0]{DistOps}} = qw(); }

sub Children { return $_[0]{Items}||[]; }
sub GetMatchId {
  my ($id);
  foreach (@{$_[0]{Items}||[]}) {
    return $id if ($_ && ($id=$_->GetMatchId));
  }
  return 0;
}
sub SetMatchId {
  my ($obj,$id) = @_;
  foreach (@{$_[0]{Items}||[]}) {
    $_->SetMatchId($id) if (UNIVERSAL::can($_,'SetMatchId'));
  }
  return $id;
}

sub toString {
  my $obj = shift;
  return $obj->NegString('"'
			 .join(' ',
			       map {
				 ($obj->{Items}[$_]->toString,
				  ($_ < $#{$obj->{Items}} && ($obj->{Dists}[$_] || ($obj->{DistOps}[$_]||'<') ne '<')
				   ? ("#".($obj->{DistOps}[$_]||'<').($obj->{Dists}[$_]||'0'))
				   : qw()))
			       } (0..$#{$obj->{Items}}))
			 .'"');
}



1; ##-- be happy

=pod

=head1 NAME

DDC::PP::CQuery - pure-perl implementation of DDC::XS::CQuery

=head1 SYNOPSIS

 use DDC::PP::CQuery;
 #... stuff happens ...


=head1 DESCRIPTION

The DDC::PP::CQuery class is a pure-perl fork of the L<DDC::XS::CQuery|DDC::XS::CQuery> class,
which see for details.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::XS(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

