package DDC::XS;

use 5.008004;
use strict;
use warnings;
use Carp;
use AutoLoader;
use Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.19';

require XSLoader;
XSLoader::load('DDC::XS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

##======================================================================
## Includes

require DDC::XS::Object;         ##-- global wrappers
require DDC::XS::Constants;      ##-- sets up DDC::XS::EXPORTS etc.
require DDC::XS::CQueryCompiler;
#require DDC::XS::CQuery;
#require DDC::XS::CQCount;
require DDC::XS::CQFilter;
require DDC::XS::CQueryOptions;

##======================================================================
## Globals

our ($COMPILER);

##======================================================================
## Methods

## $CQuery = DDC::XS->parse($qstr)
##  + convenience wrapper
sub parse {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  $COMPILER = DDC::XS::CQueryCompiler->new() if (!$COMPILER);
  return $COMPILER->ParseQuery(@_);
}



1; ##-- be happy

__END__

# Below is stub documentation for your module. You'd better edit it!

=pod

=head1 NAME

DDC::XS - XS interface to DDC C++ libraries

=head1 SYNOPSIS

  use DDC::XS;
 
  $CQuery = DDC::XS->parse($query_string);  ##-- uses global compiler $DDC::XS::COMPILER

=head1 DESCRIPTION

The DDC::XS module provides a perl interface to various libddc* C++ libraries
for corpus indexing and search.

=head1 CLASS METHODS

=head2 parse

 $CQuery = DDC::XS->parse($query_string);

Parses a DDC query string and returns a DDC::XS::CQuery object,
using a global DDC::XS::CQueryCompiler object C<$DDC::XS::COMPILER>.

=head1 SEE ALSO

perl(1),
DDC::XS::Constants(3perl),
DDC::XS::Object(3perl),
DDC::XS::CQuery(3perl),
DDC::XS::CQCount(3perl),
DDC::XS::CQFilter(3perl),
DDC::XS::CQueryOptions(3perl),
DDC::XS::CQueryCompiler(3perl).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
