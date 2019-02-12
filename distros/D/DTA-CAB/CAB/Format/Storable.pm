## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::Storable.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser using Storable::freeze() & co.

package DTA::CAB::Format::Storable;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
use DTA::CAB::Token;
use DTA::CAB::Sentence;
use DTA::CAB::Document;
use Storable;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:sto|bin)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_) foreach (qw(sto bin));
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##---- Input
##     doc => $doc,                    ##-- buffered input document
##     raw => $bool,                   ##-- uses forceDocument() if false (default)
##
##     ##---- Output
##     #docbuf  => $obj,               ##-- an output object buffer (DTA::CAB::Document object)
##     netorder => $bool,              ##-- if true (default), then store in network order
##
##     ##---- INHERITED from DTA::CAB::Format
##     #utf8     => $bool,             ##-- n/a
##     #level    => $formatLevel,      ##-- sets output level: n/a
##     #outbuf   => $stringBuffer,     ##-- buffered output
##    )
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- input
		   #doc => undef,

		   ##-- output
		   #docbuf   => DTA::CAB::Document->new(),
		   netorder => 1,

		   ##-- i/o common
		   utf8 => undef, ##-- not applicable

		   ##-- user args
		   @_
		  }, ref($that)||$that);
  return $fmt;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  return qw(doc); #docbuf
}

##=============================================================================
## Methods: I/O: Generic
##==============================================================================

## $fmt = $fmt->close()
##  + deletes $fmt->{doc} if present

## @layers = $fmt->iolayers
sub iolayers {
  return (':raw');
}

##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromFh($fh)
sub fromFh {
  my ($fmt,$fh) = @_;
  $fmt->DTA::CAB::Format::fromFh($fh);
  $fmt->{doc} = Storable::retrieve_fd($fh)
    or $fmt->logconfess("fromFh(): Storable::retrieve_fd() failed: $!");
  return $fmt;
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##   + just returns buffered object in $fmt->{doc}
sub parseDocument {
  return $_[0]{raw} ? $_[0]{doc} : $_[0]->forceDocument( $_[0]{doc} );
}


##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + default returns text/plain
sub mimeType { return 'application/octet-stream'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.bin'; }


##--------------------------------------------------------------
## Methods: Output: output selection
##  + inherited

##--------------------------------------------------------------
## Methods: Output: Recommended API

## $fmt = $fmt->putRef($ref)
##  + wrapper for Storable::nstore_fd() rsp store_fd()
sub putRef {
  if ($_[0]{netorder}) {
    Storable::nstore_fd($_[1],$_[0]{fh})
	or $_[0]->logconfess("Storable::nstore_fd() failed for $_[1]: $!");
  } else {
    Storable::store_fd($_[1],$_[0]{fh})
	or $_[0]->logconfess("Storable::store_fd() failed for $_[1]: $!");
  }
  return $_[0];
}


## $fmt = $fmt->putToken($tok)
## $fmt = $fmt->putSentence($sent)
## $fmt = $fmt->putDocument($doc)
BEGIN {
  *putToken = \&putRef;
  *putSentence = \&putRef;
  *putDocument = \&putRef;
  *putData = \&putRef;
}

##==============================================================================
## Package Aliases
##==============================================================================
package DTA::CAB::Format::Freeze;
our @ISA = qw(DTA::CAB::Format::Storable);

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::Storable - Datum parser using Storable::freeze() & co.

=cut


##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::Storable;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = DTA::CAB::Format::Storable->new(%args);
 
 ##========================================================================
 ## Methods: Persistence
 
 @keys = $class_or_obj->noSaveKeys();
 
 ##========================================================================
 ## Methods: Input
 
 $fmt = $fmt->close();
 $fmt = $fmt->fromString($string);
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output
 
 $fmt = $fmt->flush();
 $str = $fmt->toString();
 
 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putDocument($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Storable: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::Storable
inherits from
L<DTA::CAB::Format|DTA::CAB::Format>.

=item Filenames

This module registers the filename regex:

 /\.(?i:sto|bin)$/

with L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Storable: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

Constructor.

%args, %$fmt:

 ##---- Input
 doc      => $doc,               ##-- buffered input document
 ##
 ##---- Output
 docbuf   => $obj,               ##-- an output object buffer (DTA::CAB::Document object)
 netorder => $bool,              ##-- if true (default), then store in network order
 ##
 ##---- INHERITED from DTA::CAB::Format
 #encoding => $encoding,         ##-- n/a
 #level    => $formatLevel,      ##-- sets Data::Dumper->Indent() option
 #outbuf   => $stringBuffer,     ##-- buffered output

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Storable: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Override: returns list of keys not to be saved.
This implementation just returns C<qw(doc)>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Storable: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item close

 $fmt = $fmt->close();

Override: close current input source, if any.

=item fromString

 $fmt = $fmt->fromString( $string);
 $fmt = $fmt->fromString(\$string)

Override: select input from string $string.

Requires perl 5.8 or better with PerlIO layer for "real" string I/O handles.

=item fromString_freeze

Like L</fromString>(), but uses Storable::thaw() internally.
This is actually a Bad Idea, since freeze() and thaw() do not
write headers compatible with store() and retrieve() ... annoying
but true.

=item parseDocument

 $doc = $fmt->parseDocument();

Just returns buffered object in $fmt-E<gt>{doc}

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Storable: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item flush

 $fmt = $fmt->flush();

Override: flush accumulated output

=item toString

 $str = $fmt->toString();
 $str = $fmt->toString($formatLevel=!$netorder)

Override: flush buffered output in $fmt-E<gt>{docbuf} to byte-string using Storable::nstore()
or Storable::store().  If $formatLevel is given and true, native-endian Storable::store()
will be used, otherwise (the default) network-order nstore() will be used.

=item toString_freeze

Like L</toString>(), but uses Storable::nfreeze() and Storable::freeze() internally.
See L</fromString_freeze> for some hints regarding why this is a Bad Idea.

=item toFh

 $fmt_or_undef = $fmt->toFh($fh,$formatLevel)

Override: dump buffered output to filehandle $fh.
Calls Storable::nstore() or Storable::store() as indicated by $formatLevel,
whose semantics are as for L</toString>().


=item putToken , putTokenRaw

 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putTokenRaw($tok);

Non-destructive / destructive token append.

=item putSentence , putSentenceRaw

 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putSentenceRaw($sent);

Non-destructive / destructive sentence append.

=item putDocument , putDocumentRaw

 $fmt = $fmt->putDocument($doc);
 $fmt = $fmt->putDocumentRaw($doc);

Non-destructive / destructive document append.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Storable: Package Aliases
=pod

=head2 Package Aliases

This module provides
a backwards-compatible
C<DTA::CAB::Format::Freeze> class
which is a trivial subclass of
C<DTA::CAB::Format::Storable>.

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Example
##======================================================================
=pod

=head1 EXAMPLE

No example file for this format is present, since the format
is determined by the perl C<Storable> module.  However,
the reference stored (rsp. retrieved) should be identical to that
in the example perl code in L<DTA::CAB::Format::Perl/EXAMPLE>.

=cut


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
