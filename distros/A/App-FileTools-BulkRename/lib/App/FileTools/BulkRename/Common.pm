package App::FileTools::BulkRename::Common;
# ABSTRACT: Common routines needed by the BulkRename user functions
use strict;
use warnings;

BEGIN
  { our $VERSION = substr '$$Version: 0.07 $$', 11, -3;  }

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK=qw(modifiable);

use Contextual::Return;
use Scalar::Util qw(readonly);

# modifiable: return an lvalue which is the first of its input
# variables that is both defined, and modifiable.
sub modifiable : lvalue
  { my $m=-1;

    for my $i (0..$#_)
      {	($m = $i, last) if defined $_[$i] && !readonly $_[$i]; }
    $m >= 0 ? $_[$m] : $_;
  }

1;
