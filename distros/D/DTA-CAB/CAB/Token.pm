## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Token.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic API for tokens passed to/from DTA::CAB::Analyzer

package DTA::CAB::Token;
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

## $tok = CLASS_OR_OBJ->new($text)
## $tok = CLASS_OR_OBJ->new($text,%args)
## $tok = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH
##    {
##     ##-- Required Attributes
##     text   => $raw_text,     ##-- raw token text
##     ##
##     ##-- Optional Attributes
##     _attrs => \%attrs,       ##-- scalar attributes ($key=>$val, e.g. for xml pass-through)
##     _dtrs  => \@dtrs,        ##-- structural daughters (DTA::CAB::Datum objects, e.g. for xml pass-through)
##     $key   => $value,        ##-- perl-level structure (e.g. analyzer output)
##     ##
##     ##-- DTA::CAB Attributes (post-analysis)
##     #loc   => {off=>$offset, len=>$len}, ##-- parsed & passed through by some formats
##     #xlit  => $a_xlit,       ##-- analysis output by DTA::CAB::Analyzer::Transliterator
##     #morph => $a_morph,      ##-- analysis output by DTA::CAB::Analyzer::Morph subclass for literal morphology lookup
##     #safe  => $a_safe,       ##-- analysis output by DTA::CAB::Analyzer::MorphSafe (?)
##     #rw    => $a_rw,         ##-- analysis output by DTA::CAB::Analyzer::Rewrite subclass for rewrite lookup
##    }
sub new {
  return bless({
		((@_ < 2 || @_ % 2 != 0)
		 ? @_[1..$#_]
		 : (text=>$_[1],@_[2..$#_]))
	       },
	       ref($_[0]) || $_[0]);
}

##==============================================================================
## Methods: Formatting : OBSOLETE!
##==============================================================================


1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl & edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Token - generic API for tokens passed to/from DTA::CAB::Analyzer

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Token;
 
 $tok = CLASS_OR_OBJ->new($text);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Token: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Token inherits from
L<DTA::CAB::Datum>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Token: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $tok = CLASS_OR_OBJ->new($text);
 $tok = CLASS_OR_OBJ->new($text,%args)
 $tok = CLASS_OR_OBJ->new(%args)

Constructor.

%args, %$tok:

 ##-- Required Attributes
 text => $raw_text,      ##-- raw token text
 ##
 ##-- Post-Analysis Attributes (?)
 #xlit  => $a_xlit,     ##-- analysis output by DTA::CAB::Analyzer::Transliterator
 #morph => $a_morph,    ##-- analysis output by DTA::CAB::Analyzer::Morph subclass for literal morphology lookup
 #safe  => $a_safe,     ##-- analysis output by DTA::CAB::Analyzer::MorphSafe (?)
 #rw    => $a_rw,       ##-- analysis output by DTA::CAB::Analyzer::Rewrite subclass for rewrite lookup
 #...                   ##-- (maybe more)

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
