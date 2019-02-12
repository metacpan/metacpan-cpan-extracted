## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Document.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic API for whole documents passed to/from DTA::CAB::Analyzer

package DTA::CAB::Document;
use DTA::CAB::Datum;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Datum);

##==============================================================================
## Constructors etc.
##==============================================================================

## $doc = CLASS_OR_OBJ->new(\@sentences,%args)
##  + object structure: HASH
##    {
##     body => \@sentences,  ##-- DTA::CAB::Sentence objects
##     types => \%text2tok,  ##-- maps token text type-wise to Token objects (optional)
##     ##
##     ##-- special attributes
##     #noTypeKeys => \@keys, ##-- token keys which should not be mapped to/from types (default='_xmlnod')
##     ##
##     ##-- dta-tokwrap attributes
##     xmlbase => $base,
##    }
sub new {
  return bless({
		body => ($#_>=1 ? $_[1] : []),
		#noTypeKeys => [qw(_xmlnod)],
		@_[2..$#_],
	       }, ref($_[0])||$_[0]);
}

##==============================================================================
## Methods: ???
##==============================================================================

## $n = $doc->nTokens()
sub nTokens {
  my $ntoks = 0;
  $ntoks += scalar(@{$_->{tokens}}) foreach (@{$_[0]->{body}});
  return $ntoks;
}

## $n = $doc->nChars()
##  + total number of token text characters
sub nChars {
  my $nchars = 0;
  $nchars += length($_->{text}) foreach (map {@{$_->{tokens}}} @{$_[0]->{body}});
  return $nchars;
}

## \%types = $doc->types()
##  + get hash \%types = ($typeText => $typeToken, ...) mapping token text to
##    basic token objects (with only 'text' key defined)
##  + just returns cached $doc->{types} if defined
##  + otherwise computes & caches in $doc->{types}
sub types {
  return $_[0]{types} if ($_[0]{types});
  return $_[0]->getTypes();
}

## \%types = $doc->getTypes()
##  + (re-)computes hash \%types = ($typeText => $typeToken, ...) mapping token text to
##    token objects (with all but @{$doc->{noTypeKeys}} keys)
sub getTypes {
  my $doc = shift;
  my $types = $doc->{types} = {};
  my @nokeys = @{$doc->{noTypeKeys}||[qw(moot dmoot)]};
  my ($typ);
  foreach (map {@{$_->{tokens}}} @{$doc->{body}}) {
    next if (exists($types->{$_->{text}}));
    $typ = $types->{$_->{text}} = {%$_};
    delete(@$typ{@nokeys});
  }
  return $types;
}

## \%types = $doc->getTextTypes()
##  + (re-)computes hash \%types = ($typeText => {text=>$typeText}, ...) mapping token text to
##    basic token objects (with only 'text' key defined)
sub getTextTypes {
  my $doc = shift;
  my $types = $doc->{types} = {};
  my ($typ);
  foreach (map {@{$_->{tokens}}} @{$doc->{body}}) {
    next if (exists($types->{$_->{text}}));
    $typ = $types->{$_->{text}} = {text=>$_->{text}};
  }
  return $types;
}

## \%types = $doc->extendTypes(\%types,@keys)
##  + extends \%types with token keys @keys
sub extendTypes {
  my ($doc,$types,@keys) = @_;
  $types = $doc->types() if (!defined($types));
  my ($tok);
  foreach $tok (map {@{$_->{tokens}}} @{$doc->{body}}) {
    $types->{$tok->{text}}{$_} = Storable::dclone($tok->{$_}) foreach (@keys);
  }
  return $types;
}

## $doc = $doc->expandTypes()
## $doc = $doc->expandTypes(\%types)
## $doc = $doc->expandTypes(\@keys,\%types)
## $doc = $doc->expandTypes(\@keys,\%types,\%opts)
##  + expands \%types (default=$doc->{types}) map into tokens
##  + clobbers all keys
sub expandTypes {
  return $_[0]->expandTypeKeys(@_[1,2]) if (@_>2);
  my ($doc,$types) = @_;
  $types = $doc->{types} if (!$types);
  return $doc if (!$types); ##-- no {types} key
  my ($typ);
  foreach (map {@{$_->{tokens}}} @{$doc->{body}}) {
    $typ = $types->{$_->{text}};
    @$_{keys %$typ} = values %$typ;
  }
  return $doc;
}

## $doc = $doc->expandTypeKeys(\@typeKeys)
## $doc = $doc->expandTypeKeys(\@typeKeys,\%types)
## $doc = $doc->expandTypeKeys(\@typeKeys,\%types,\%opts)
##  + expands \%types (default=$doc->{types}) map into tokens
##  + only keys in \@typeKeys are expanded
sub expandTypeKeys {
  my ($doc,$keys,$types) = @_;
  $types = $doc->{types} if (!$types);
  return $doc if (!$types || !$keys || !@$keys); ##-- no {types} key, or no keys to expand
  my ($typ,$tok);
  foreach $tok (map {@{$_->{tokens}}} @{$doc->{body}}) {
    $typ = $types->{$tok->{text}};
    @$tok{@$keys} = @$typ{@$keys};
    #$tok{$_}=$typ->{$_} foreach (grep {defined($typ->{$_})} @$keys); ##-- don't put undef keys into tok in the first place
    #delete(@$tok{grep {!defined($tok->{$_})} @$keys}); ##-- ... or remove undef keys from tok after the fact
    ## + both of these undef-pruners are kind of useless here, since undef values sometimes come back via 'map'
    ##   e.g. in (...map {$_ ? @$_ : qw()} @$w{qw(tokpp toka mlatin)}...) as used in Analyzer::Moot code
    ## + this should really be something for e.g. analyzeClean(), but that now means something else
  }
  return $doc;
}

## $doc = $doc->clearTypes()
##  + clears {types} cache
sub clearTypes {
  delete $_[0]{types};
  return $_[0];
}

##==============================================================================
## I/O wrappers

##--------------------------------------------------------------
## I/O wrappers: input

## $doc = CLASS_OR_OBJECT->fromDocument($doc)
sub fromDocument {
  if (ref($_[0]) && UNIVERSAL::isa($_[0],__PACKAGE__)) {
    %{$_[0]} = %{$_[1]};
    return $_[0];
  }
  return $_[1];
}

## $doc = CLASS_OR_OBJECT->fromFile($filename_or_fh,%fmt_options)
sub fromFile {
  my $fmt = DTA::CAB::Format->newReader(file=>$_[1],@_[2..$#_])
    or $_[0]->logconfess("fromFile(): could not create format for '$_[1]': $!");
  my $doc = $fmt->parseFile($_[1])
    or $_[0]->logconfess("fromFile(): could not pase file '$_[1]': $!");
  return $_[0]->fromDocument($doc);
}

## $doc = CLASS_OR_OBJECT->fromFh($fh,%fmt_options)
sub fromFh {
  my $fmt = DTA::CAB::Format->newReader(@_[2..$#_])
    or $_[0]->logconfess("fromFh(): could not create format for filehandle $_[1]: $!");
  my $doc = $fmt->parseFh($_[1])
    or $_[0]->logconfess("fromFile(): could not pase filehandle $_[1]: $!");
  return $_[0]->fromDocument($doc);
}

## $doc = CLASS_OR_OBJECT->fromString( $str,%fmt_options)
## $doc = CLASS_OR_OBJECT->fromString(\$str,%fmt_options)
sub fromString {
  my $fmt = DTA::CAB::Format->newReader(@_[2..$#_])
    or $_[0]->logconfess("fromFh(): could not create format: $!");
  my $doc = $fmt->parseString($_[1])
    or $_[0]->logconfess("fromFile(): could not pase string: $!");
  return $_[0]->fromDocument($doc);
}

##--------------------------------------------------------------
## I/O wrappers: output

## $doc = CLASS_OR_OBJECT->toFormat($fmt)
sub toFormat {
  my $fmt = $_[1];
  $fmt->putDocumentRaw($_[0])
    or $_[0]->logconfess("toFormat(): ", ref($fmt), "->putDocumentRaw() failed: $!");
  $fmt->flush()
    or $_[0]->logconfess("toFormat(): ", ref($fmt), "->flush() failed: $!");
  return $_[0];
}

## $doc = CLASS_OR_OBJECT->toFile($filename_or_fh,%fmt_options)
sub toFile {
  my $fmt = DTA::CAB::Format->newWriter(file=>$_[1],@_[2..$#_])
    or $_[0]->logconfess("toFile(): could not create format for '$_[1]': $!");
  $fmt->toFile($_[1])
    or $_[0]->logconfess("toFile(): ", ref($fmt), "->toFile() failed for '$_[1]': $!");
  return $_[0]->toFormat($fmt);
}

## $doc = CLASS_OR_OBJECT->toFh($fh,%fmt_options)
sub toFh {
  my $fmt = DTA::CAB::Format->newWriter(@_[2..$#_])
    or $_[0]->logconfess("toFh(): could not create format for '$_[1]': $!");
  $fmt->toFh($_[1])
    or $_[0]->logconfess("toFh(): ", ref($fmt), "->toFh() failed for '$_[1]': $!");
  return $_[0]->toFormat($fmt);
}

## \$str = CLASS_OR_OBJECT->toString(\$str,%fmt_options)
##  $str = CLASS_OR_OBJECT->toString( $str,%fmt_options)
sub toString {
  my $fmt = DTA::CAB::Format->newWriter(@_[2..$#_])
    or $_[0]->logconfess("toString(): could not create format for '$_[1]': $!");
  $fmt->toString($_[1])
    or $_[0]->logconfess("toString(): ", ref($fmt), "->toString() failed for '$_[1]': $!");
  $_[0]->toFormat($fmt) or return undef;
  return $_[1];
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl & edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Document - generic API for whole documents passed to/from DTA::CAB::Analyzer

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Document;
 
 $doc = CLASS_OR_OBJ->new(\@sentences,%args);
 $n = $doc->nTokens();

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Document: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Document inherits from
L<DTA::CAB::Datum|DTA::CAB::Datum>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Document: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $doc = CLASS_OR_OBJ->new(\@sentences,%args);

%args, %$doc:

 body => \@sentences,  ##-- DTA::CAB::Sentence objects

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Document: Methods: ???
=pod

=head2 Methods

=over 4

=item nTokens

 $n = $doc->nTokens();

Returns number of tokens in the document.

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

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


=cut
