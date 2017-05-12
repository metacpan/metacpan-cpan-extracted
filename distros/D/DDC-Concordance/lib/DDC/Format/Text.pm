#-*- Mode: CPerl -*-

## File: DDC::Format::Text.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: output formatting
##======================================================================

package DDC::Format::Text;
use Text::Wrap qw(wrap);
use IO::File;
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
##     columns=>$ncols,          ##-- for text wrapping [default=80]
##     useMatchIds=>$bool,       ##-- whether to use match-ids if available; undef (default) if non-trivial match-ids are specified
##    )
sub new {
  my $that = shift;
  return bless {
		highlight=>['__','__'],
		columns=>80,
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

## $hitStr = $fmt->hitString($hit, $fieldName, $hitNumber, $useMatchIds)
sub hitString {
  my ($fmt,$hit,$fkey,$hnum,$useMatchIds) = @_;
  $fkey = 'w' if (!defined($fkey));
  $hnum =  0  if (!$hnum);
  $Text::Wrap::columns = $fmt->{columns};
  my $ctx    = $hit->{ctx_};
  my $ctxstr = join(' ',
		    (map {ref($_) ? $_->{$fkey} : $_} @{$ctx->[0]}),
		    ' ',
		    (map { $_->{hl_} ? "__$_->{$fkey}__".($useMatchIds ? "/$_->{hl_}" : '') : $_->{$fkey} } @{$ctx->[1]}),
		    ' ',
		    (map {ref($_) ? $_->{$fkey} : $_} @{$ctx->[2]}),
		   );
  return ("${hnum}: "
	  .wrap('',(' ' x length("$hnum")).'  ', $ctxstr)."\n"
	  .join('',
		map { wrap("\t+ ", ("\t  ".(' ' x length($_)).' '), "$_=\"$hit->{meta_}{$_}\"")."\n" }
		grep {$_ ne 'indices_' && defined($hit->{meta_}{$_})} sort keys %{$hit->{meta_}||{}})
	  #."\n"
	 );
}

##======================================================================
## API

## $str = $fmt->toString($hitList)
sub toString {
  my ($fmt,$hits) = @_;
  if ($hits->{counts_} && @{$hits->{counts_}}) {
    ##-- count-query: return tab-separated strings
    return join('', map {join("\t", @$_)."\n"} @{$hits->{counts_}});
  }
  elsif ($hits->{hits_} && @{$hits->{hits_}}) {
    ##-- usual case: retrieve hit strings
    my $useMatchIds = defined($fmt->{useMatchIds}) ? $fmt->{useMatchIds} : (grep {$_>0 && $_!=1} map {$_->{hl_}} map {@{$_->{ctx_}[1]}} @{$hits->{hits_}});
    return join("\n",
		map {
		  $fmt->hitString($hits->{hits_}[$_], $hits->{defaultField}, $_+$hits->{start}, $useMatchIds)
		} (0..$#{$hits->{hits_}})
	       );
  }
  ##-- unknown: return empty string
  return "(no hits)";
}

1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::Format::Text - human-readable text formatting for DDC hits

=head1 SYNOPSIS

 use DDC::Concordance;

 $hitList = DDC::Client::Distributed->new()->query('foo&&bar'); ##-- get some hits

 $fmt  = DDC::Format::Text->new(columns=>$ncols);
 $str = $fmt->toString($hitList);        ##-- conversion to string
 $fmt->toFile($hitList,$filename);       ##-- output to file
 $fmt->toFh($hitList,$fh);               ##-- output to filehandle

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

Class for formatting L<DDC::Hit|DDC::Hit> objects as plain text.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Text: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DDC::Format::Text inherits from L<DDC::Format|DDC::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Text: Constructors, etc.
=pod

=head2 Constructors, etc.

=over 4

=item new

 $fmt = $CLASS_OR_OBJ->new(%args);

Accepted keywords in %args:

   (
    start=>$previous_hit_num, ##-- pre-initial hit number (default=0)
    highlight=>[$pre,$post],  ##-- highlighting substrings
    columns=>$ncols,          ##-- for text wrapping [default=80]
   )

=item reset

 $fmt = $fmt->reset();

Resets the formatting object.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Format::Text: Helper functions
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
## DESCRIPTION: DDC::Format::Text: API
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

Copyright (C) 2006-2016 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
