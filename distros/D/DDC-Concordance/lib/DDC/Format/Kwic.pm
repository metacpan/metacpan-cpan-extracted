##-*- Mode: CPerl -*-

## File: DDC::Format::Kwic.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: output formatting: keywords-in-context
##======================================================================

package DDC::Format::Kwic;
use File::Basename;
use Carp;
use strict;

##======================================================================
## Globals
our @ISA = qw(DDC::Format);

BEGIN {
  *isa = \&UNIVERSAL::isa;
}

##======================================================================
## Constructors, etc.

## $fmt = $CLASS_OR_OBJ->new(%args)
##  + %args:
##    (
##     start=>$previous_hit_num, ##-- pre-initial hit number (default=0)
##     highlight=>[$pre,$post],  ##-- highlighting substrings
##     width=>$nchars,           ##-- context width; default=32
##     useMatchIds=>$bool,       ##-- whether to use match-ids if available; undef (default) if non-trivial match-ids are specified
##    )
sub new {
  my $that = shift;
  return bless {
		highlight=>['__','__'],
		width=>32,
		useMatchIds=>undef,
		@_
	       }, ref($that)||$that;
}

## $fmt = $fmt->reset()
##  + reset counters, etc.
sub reset {
  $_[0]{start}=0;
  return $_[0]->SUPER::reset();
}

##======================================================================
## Helper functions

## $len = maxlen(@strings)
sub maxlen {
  my $l = 0;
  do { $l=length($_) if (length($_) > $l) } foreach (@_);
  return $l;
}

##======================================================================
## API

## $str = $fmt->toString($hitList)
sub toString {
  my ($fmt,$hits) = @_;

  if ($hits->{counts_} && @{$hits->{counts_}}) {
    ##-- count-query: format as text
    my ($i);
    my @lens = map {$i=$_; maxlen(map {$_->[$i]} @{$hits->{counts_}})} (0..$#{$hits->{counts_}[0]});
    my $fmt  = join("\t", map {"%-${_}s"} @lens)."\n";
    return join('', map {sprintf($fmt,@$_)} @{$hits->{counts_}});
  }

  my $xlen = $fmt->{width} || 2**31;
  my $hnum = $hits->{start};
  my $useMatchIds = defined($fmt->{useMatchIds}) ? $fmt->{useMatchIds} : (grep {$_>0 && $_!=1} map {$_->{hl_}} map {@{$_->{ctx_}[1]}} @{$hits->{hits_}});

  my (@hits);
  foreach my $hit (@{$hits->{hits_}}) {
    ##-- hit key: number + file basename + page
    my $f = basename($hit->{meta_}{file_});
    $f =~ s/\..*$//;
    my $p     = defined($hit->{meta_}{page_}) ? $hit->{meta_}{page_} : 0;
    my $pagei = (grep {$hit->{meta_}{indices_}[$_] eq 'page'} (0..$#{$hit->{meta_}{indices_}}))[0];
    my $targetMatchId = $useMatchIds ? (sort {$a<=>$b} grep {$_} map {$_->{hl_}} @{$hit->{ctx_}[1]})[0] : undef;

    ##-- hit context
    my $fkey = $hits->{defaultField} || $hit->{meta_}{indices_}[0] || 'w';
    my (@l,@c,@r);
    my $ary = \@l;
    my $hl  = '__';
    foreach (map {@$_} @{$hit->{ctx_}}) {
      if ($ary eq \@l && ref($_) && ($useMatchIds ? $_->{hl_}==$targetMatchId : $_->{hl_})) {
	$ary=\@c;
	$p=$_->{page} if (!$p && defined($_->{page}));
      }
      elsif ($ary eq \@c) {
	$ary = \@r;
      }
      $hl = ($ary eq \@c ? '__' : '_');
      push(@$ary, (ref($_)
		   ? ($_->{hl_}
		      ? ($hl.$_->{$fkey}.$hl.($useMatchIds ? "/$_->{hl_}" : ''))
		      : $_->{$fkey})
		   : $_));
    }

    my $ls = join(' ', @l);
    my $rs = join(' ', @r);
    substr($ls, 0,       length($ls)-$xlen+3, '...') if (length($ls) > $xlen);
    substr($rs, $xlen-3, length($rs)-$xlen+3, '...') if (length($rs) > $xlen);

    push(@hits,[$hnum++, "[$f:$p]", $ls, join(' ',@c), $rs]);
  }

  my $ln = maxlen(map {$_->[0]} @hits);
  my $lf = maxlen(map {$_->[1]} @hits);
  my $ll = maxlen(map {$_->[2]} @hits);
  my $lc = maxlen(map {$_->[3]} @hits);
  my $lr = maxlen(map {$_->[4]} @hits);
  return (
	  "# Hit(s) $hits[0][0]-$hits[$#hits][0] of $hits->{nhits_}\n"
	  .join('', map {sprintf("%${ln}d: %-${lf}s  %${ll}s  %-${lc}s  %-${lr}s\n", @$_)} @hits)
	 );
}

1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::Format::Kwic - Keyword-in-context (KWIC) formatting for DDC hits

=head1 SYNOPSIS

 use DDC::Concordance;

 $hitList = DDC::Client::Distributed->new()->query('foo&&bar'); ##-- get some hits

 $fmt  = DDC::Format::Kwic->new(width=>$nchars);
 $str = $fmt->toString($hitList);        ##-- conversion to string
 $fmt->toFile($hitList,$filename);       ##-- output to file
 $fmt->toFh($hitList,$fh);               ##-- output to filehandle

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

Class for formatting L<DDC::Hit|DDC::Hit> objects as keyword-in-context (KWIC) lines.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Kwic: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DDC::Format::Kwic inherits from L<DDC::Format|DDC::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Kwic: Constructors, etc.
=pod

=head2 Constructors, etc.

=over 4

=item new

 $fmt = $CLASS_OR_OBJ->new(%args);

Accepted keywords in %args:

  start       => $previous_hit_num, ##-- pre-initial hit number (default=0)
  highlight   => [$pre,$post],      ##-- highlighting substrings (default=['__','__'])
  width       => $nchars,           ##-- context width; default=32
  useMatchIds => $bool,             ##-- whether to use match-ids if available; undef (default) if non-trivial match-ids are specified

=item reset

 $fmt = $fmt->reset();

Resets the formatting object.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Kwic: Helper functions
=pod

=head2 Helper functions

=over 4

=item hitString

 $hitStr = $fmt->hitString($hit);

Formats a single C<$hit> as a string,
incrementing the counter C<$fmt-E<gt>{start}> as a side-effect.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Kwic: API
=pod

=head2 API

=over 4

=item toString

 $str = $fmt->toString($hitList);

Implements L<DDC::Format::toString()|DDC::Format/toString>.

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

Copyright (C) 2014-2016 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
