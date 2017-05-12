##-*- Mode: CPerl -*-

## File: DDC::Hit.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: Hit
##======================================================================

package DDC::Hit;
use strict;

##======================================================================
## Globals

##======================================================================
## Constructors, etc.

## $hit = $CLASS_OR_OBJ->new(%args)
##  + %$hit = %args =
##    (
##     raw_  => $raw_data,        ##-- hit data (raw buffer)
##     meta_ => \%meta,           ##-- bibliographic metadata (parsed)
##     ctx_  => \@context,        ##-- hit context (parsed)
##    )
##  where \%meta =
##    {
##     file_ => $ddcFile,
##     scan_ => $ddcScanStr,
##     orig_ => $ddcOrigStr,
##     date_ => $ddcDate,
##     page_ => $ddcPage,
##     rank_ => $ddcRank,
##     rank_debug_ => $ddcRankDebug,
##     indices_ => \@indexNames,
##     $biblField => $biblValue,   ##-- free bibliographic field fata
##    }
##  and @context =
##    [
##     \@leftContext,              ##-- [$w1,$w2,...,$wN]   : pre-hit context: word strings <ddc-v2.0.38 (parsed if array)
##     \@hitTokens,                ##-- [$t1,$t2,...\$tN] : hit tokens: parsed (without expandFields)
##     \@leftContext,              ##-- [$w1,$w2,...,$wN]   : post-hit context: word strings <ddc-v2.0.38 (parsed if array)
##    ]
##  and each $ti = $hitTokens[$i] =
##    [$hl,$f1val,$f2val,...,$fNval]        ##-- without expandFields
##    {hl_=>$matchId, $f1name=>$f1val, ...} ##-- with expandFields
sub new {
  my $that = shift;
  return bless { @_ }, ref($that)||$that;
}

## $hit = $hit->expandFields()
## $hit = $hit->expandFields(\@fieldNames)
##   + expand hit data tokens from arrays to hashes
##   + initial field is always implicitly 'hl_' (highlighting match-id, can be treated as bool)
sub expandFields {
  my ($hit,$names) = @_;
  my @names = ('hl_', @{$names||$hit->{meta_}{indices_}||[]});
  my ($w);
  foreach (grep {defined $_} @{$hit->{ctx_}||[]}) {    ##-- expand deep-encoded json context tokens if available (ddc >= v2.0.38)
    foreach (grep {UNIVERSAL::isa($_,'ARRAY')} @$_) {
      $w = $_;
      $_ = { map {(($names[$_]||"${_}_")=>$w->[$_])} (0..$#$w) };
    }
  }
  return $hit;
}

## $thingy = $obj->TO_JSON()
##  + annoying wrapper for JSON
sub TO_JSON {
  return { %{$_[0]} };
}


1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::Hit - Hit structure for DDC query utilities

=head1 SYNOPSIS

 use DDC::Hit;

 $hit = DDC::Hit->new(keywords=>\%keyword2undef,context=>$context_str,%bibl);
 
 @sents = $hit->parseContext(undef, %opts);
 @sents = DTA::Hit->parseContext($context_str, %opts);


=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

DDC::Hit is the underlying structure for hits returned by DDC::Client.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Hit: Methods
=pod

=head2 Methods

=over 4

=item new

 $hit = $CLASS_OR_OBJ->new(%args);

Object structure / accepted keyword %args:

 keywords  => \@keywords,    ##-- keyword list
 context   => $context_str,  ##-- context string
 $bibl_key => $bibl_val,     ##-- bibliographic data


=item parseContext

  @sents = $hit->parseContext($context_str,%opts);     ##-- object method in list context;
 \@sents = $hit->parseContext($context_str,%opts);     ##-- object method in scalar context
  @sents = DDC::Hit->parseContext($context_str,%opts); ##-- class method in list context
 \@sents = DDC::Hit->parseContext($context_str,%opts); ##-- class method in scalar context

Parse a C<$context_str> as returned by L<DDC::Client|DDC::Client> into perl data structures.
If called as an object method, C<$context_str> may be passed as undef, and defaults to
C<$hit-E<gt>{context}>.
Known options C<%opts>:

 wordSeparator  => $wordSeparatorRegex,  ##-- default=' '
 fieldSeparator => $fieldSeparatorRegex, ##-- default="\x{a7}" (U+00A7 : Latin-1 Supplement / SECTION SIGN : §)
 fieldNames     => \@fieldNames,         ##-- default=undef (none)

returns a list of parsed sentences (list context) or a reference to such a list (scalar context)

 @sents = ($sents[0], ..., $sents[$#s])

where each element $s=$sents[$i] is an ARRAY ref of words

 $s = $sents[$i] = [ $s->[0], ..., $s->[$#$s] ]

and each word C<$w=$s-E<gt>[$j]> is either:

=over 4


=item *

a simple scalar: if C<$opts{fieldSeparator}> was undefined or only 1 field was returned

=item *

a ARRAY ref: if multiple fields were returned and C<$opts{fieldNames}> was undefined

=item *

a HASH ref: if multiple fields were returned and C<$opts{fieldNames}> was defined.
The keys of the HASH are the elements of C<$opts{fieldNames}> and their values are
the corresponding values in the token-data list returned by DDC.
In general, C<$opts{fieldNames}> should contain a list of the token field names
from the C<Indices> line
of the DDC server's F<*.opt> file in the order specified
by the DDC C<IndicesToShow> option.

=back

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl


##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2016 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
