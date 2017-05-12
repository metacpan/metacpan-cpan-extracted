package App::FileTools::BulkRename::Errors;
# ABSTRACT: Error values and routines for BulkRename

use strict;
use warnings;
BEGIN
  { our
      $VERSION = substr '$$Version: 0.07 $$', 11, -3;
  }

require Exporter;

our @ISA = qw(Exporter);

use enum qw
  ( :BulkRename_Error_
    None
    Help
    Docs
    Info
    General=16
    NoSuchFile
    BadConfigFile
    BadPreset
    NotImplemented
    NotAllowedInPresets
  );

# Export all Enums defined above.
our @EXPORT = grep {m/^BulkRename_Error_/}
  keys %App::FileTools::BulkRename::Errors::;


1;
