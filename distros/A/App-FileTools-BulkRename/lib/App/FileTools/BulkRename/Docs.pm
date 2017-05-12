package App::FileTools::BulkRename::Docs;
# ABSTRACT: Self-Documentation Routines for brn

use strict;
use warnings;

BEGIN
  { our $VERSION = substr '$$Version: 0.07 $$', 11, -3; }

require Exporter;

use IO::Interactive qw(is_interactive);
use Pod::Text::Termcap ();
use Pod::Usage;

# Prettify usage output if its going to a terminal.
$Pod::Usage::ISA[0]='Pod::Text::Termcap' if is_interactive();


our @ISA = qw(Exporter);
our @EXPORT_OK=qw(usage help manpage readme);

sub usage
  { my $x = shift;

    pod2usage
      ( -exitval  => $x
      , -verbose  => 0
      );
  }

sub help
  {
    pod2usage
      ( -exitval  => 0
      , -verbose  => 1
      );
  }

sub manpage
  {
    pod2usage
      ( -exitval  => 0
      , -verbose  => 2
      );
  }

sub readme
  {
    pod2usage
      ( -exitval  => 0
      , -verbose  => 2
      );
  }


1;
