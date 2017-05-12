##-*- Mode: CPerl -*-

##======================================================================
package DDC::XS::CQueryCompiler;
use strict;

## $query = $compiler->ParseQuery($str)
sub ParseQuery {
  return undef if (!$_[0]->ParseQuery_($_[1]));
  return $_[0]->getQuery();
}

##======================================================================
## Package aliases (backwards-compatibility)
package DDC::XS::QueryCompiler;
use strict;
our @ISA = qw(DDC::XS::CQueryCompiler);


1; ##-- be happy
