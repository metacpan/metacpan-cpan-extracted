package Ace::RPC;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

use Carp 'croak';
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default.
@EXPORT = qw();

# Optional exports
@EXPORT_OK = qw(
	ACE_INVALID
	ACE_OUTOFCONTEXT
	ACE_SYNTAXERROR
	ACE_UNRECOGNIZED
	ACE_PARSE
);

$VERSION = '1.00';

sub AUTOLOAD {
  my $constname;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  my $val = constant($constname, 0);
  if ($! != 0) {
    if ($! =~ /Invalid/) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    }
    else {
      croak "Your vendor has not defined constant $constname";
    }
  }
  eval "sub $AUTOLOAD { $val }";
  goto &$AUTOLOAD;
}

bootstrap Ace::RPC $VERSION;

1;

__END__
