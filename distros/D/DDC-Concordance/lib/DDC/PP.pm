#-*- Mode: CPerl -*-

## File: DDC::PP.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: pure-perl drop-in replacements for DDC::XS
##======================================================================

package DDC::PP;
use DDC::Concordance;
use strict;

use DDC::PP::Constants;
use DDC::PP::Object;
use DDC::PP::CQuery;
use DDC::PP::CQCount;
use DDC::PP::CQFilter;
use DDC::PP::CQueryOptions;

use DDC::PP::CQueryCompiler;

our @ISA = qw();
our $VERSION = $DDC::Concordance::VERSION;

##======================================================================
## Globals

our ($COMPILER);

##======================================================================
## Methods

## $CQuery = DDC::XS->parse($qstr)
##  + convenience wrapper
sub parse {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  $COMPILER = DDC::PP::CQueryCompiler->new() if (!$COMPILER);
  return $COMPILER->ParseQuery(@_);
}


1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::PP - pure-perl drop-in replacements for DDC::XS module

=head1 SYNOPSIS

 use DDC::PP;

 #... stuff happens ...

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

This package doesn't do anything but load the
pure-perl drop-in replacements for the L<DDC::XS|DDC::XS> modules.
See submodule documentation for details.

The code in this module is a pure-perl implementation of the original DDC C++ and XS code,
based on
L<DDC::XS|DDC::XS> v0.10 and L<DDC|http://sourceforge.net/projects/ddc-concordance/files/ddc-concordance/> v2.0.43.

Newer features of the C++ query parser and its XS interface may not be supported.
If you need to be 100% sure you're parsing queries exactly as the C++ DDC server does, use
the L<DDC::XS|DDC::XS> distribution linked to the appropriate version of the
underlying DDC C++ libraries.

If you would like to use the "real" C++ wrappers provided by L<DDC::XS|DDC::XS> when they are available
and use the pure-perl implementations as a fallback, see the L<DDC::Any|DDC::Any> module provided in
this distribution.

=cut

##======================================================================
## SUBMODULES
=pod

=head1 SUBMODULES

=over 4

=item L<DDC::PP::Constants|DDC::PP::Constants>

Pure-perl implementation of L<DDC::XS::Constants|DDC::XS::Constants>

=item L<DDC::PP::Object|DDC::PP::Object>

Pure-perl implementation of L<DDC::XS::Object|DDC::XS::Object>

=item L<DDC::PP::CQuery|DDC::PP::CQuery>

Pure-perl implementation of L<DDC::XS::CQuery|DDC::XS::CQuery>

=item L<DDC::PP::CQFilter|DDC::PP::CQFilter>

Pure-perl implementation of L<DDC::XS::CQFilter|DDC::XS::CQFilter>

=item L<DDC::PP::CQCount|DDC::PP::CQCount>

Pure-perl implementation of L<DDC::XS::CQCount|DDC::XS::CQCount>

=item L<DDC::PP::CQueryOptions|DDC::PP::CQueryOptions>

Pure-perl implementation of L<DDC::XS::CQueryOptions|DDC::XS::CQueryOptions>

=item L<DDC::PP::CQueryCompiler|DDC::PP::CQueryCompiler>

Pure-perl implementation of L<DDC::XS::CQueryCompiler|DDC::XS::CQueryCompiler>

=back

=cut

##======================================================================
## Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

DDC originally by Alexey Sokirko.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2016, Bryan Jurish.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
DDC::XS(3perl)

=cut
