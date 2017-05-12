##-*- Mode: CPerl -*-

##======================================================================
## top-level
package DDC::PP::CQueryOptions;
use DDC::PP::Constants;
use DDC::PP::Object;
use DDC::Utils qw();
use Carp qw(carp confess);
use strict;

##======================================================================
## CQueryOptions
package DDC::PP::CQueryOptions;
use strict;
our @ISA = qw(DDC::PP::Object);

__PACKAGE__->defprop($_)
  foreach (qw(ContextSentencesCount EnableBibliography DebugRank SeparateHits Filters Subcorpora)); #Within
sub getWithin { return $_[0]{Within}; }
sub setWithin { return $_[0]{Within} = UNIVERSAL::isa($_[1],'ARRAY') ? $_[1] : [$_[1]]; }
__PACKAGE__->defalias('ContextCount'=>'ContextSentencesCount',0,1);

sub new {
  my ($that,%opts) = @_;
  return $that->SUPER::new(EnableBibliography=>1,Filters=>[],Subcorpora=>[],Within=>[],%opts);
}

sub swap {
  my ($a,$b) = @_;
  my %tmp = %$b;
  %$b = %$a;
  %$a = %tmp;
  return $a;
}

sub Clear {
  @{$_[0]{Filters}} = @{$_[0]{Subcorpora}} = qw();
}

__PACKAGE__->nomethod('CanFilterByFile');

sub Children { return [ @{$_[0]{Filters}||[]} ]; }

sub sqString { return DDC::Utils::escapeq(defined($_[1]) ? $_[1] : ''); }
sub toString {
  my $qo = shift;
  return (
	  ($qo->{Within} ? join('', map {" #WITHIN ".$qo->sqString($_)} @{$qo->{Within}}) : '')
	  .($qo->{ContextSentencesCount} ? " #CNTXT $qo->{ContextSentencesCount}" : '')
	  .($qo->{SeparateHits} ? " #SEPARATE" : '')
	  .(!$qo->{EnableBibliography} ? " #FILENAMES" : '')
	  .($qo->{DebugRank} ? " #DEBUG_RANK" : '')
	  .join('', map { " ".$_->toString } @{$qo->{Filters}||[]})
	  .($qo->{Subcorpora} && @{$qo->{Subcorpora}} ? (" :".join(',', map {$qo->sqString($_)} @{$qo->{Subcorpora}})) : '')
	 );
}

##-- ddc-compatible hash-conversion (for toJson())
sub toHash {
  my ($obj,%opts) = @_;
  return $obj->SUPER::toHash(%opts) if (!$opts{json});
  return { class=>$obj->jsonClass, $obj->jsonData };
}
sub jsonData {
  my $qo = shift;
  return (($qo->{Within} && $qo->{Within} ? (Within=>$qo->{Within}) : qw()),
	  ($qo->{ContextSentencesCount} ? (ContextCount=>$qo->{ContextSentencesCount}) : qw()),
	  ($qo->{SeparateHits} ? (SeparateHits=>$qo->{SeparateHits}) : qw()),
	  ($qo->{EnableBibliography} ? (EnableBibliography=>$qo->{EnableBibliography}) : qw()),
	  ($qo->{DebugRank} ? (DebugRank=>$qo->{DebugRank}) : qw()),
	  (Filters=>[map {($_->toHash(json=>1))} @{$qo->{Filters}||[]}]),
	  ($qo->{Subcorpora} && @{$qo->{Subcorpora}} ? (Subcorpora=>$qo->{Subcorpora}) : qw()),
	 );
}


1; ##-- be happy

=pod

=head1 NAME

DDC::PP::CQueryOptions - pure-perl implementation of DDC::XS::CQueryOptions

=head1 SYNOPSIS

 use DDC::PP::CQueryOptions;
 #... stuff happens ...


=head1 DESCRIPTION

The DDC::PP::CQueryOptions class is a pure-perl fork of the L<DDC::XS::CQueryOptions|DDC::XS::CQueryOptions> class,
which see for details.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::XS::CQueryOptions(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

