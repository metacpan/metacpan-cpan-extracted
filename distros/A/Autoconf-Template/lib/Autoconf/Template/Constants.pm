package Autoconf::Template::Constants;

use strict;
use warnings;

use parent qw(Exporter);

our $VERSION        = '2.1.0'; ## no critic (RequireInterpolation)
our $PROJECT        = 'autoconf-template-perl';         ## no critic (RequireInterpolation)
our $SHARE_DIR      = '/usr/local/share';         ## no critic (RequireInterpolation)
our $PERL5SHARE_DIR = '/usr/local/share/perl5/auto/share/dist/Autoconf-Template';   ## no critic (RequireInterpolation)

use Readonly;

# booleans
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

# chars
Readonly our $EMPTY => q{};
Readonly our $SPACE => q{ };
Readonly our $DASH  => q{-};
Readonly our $SLASH => q{/};
Readonly our $COMMA => q{,};
Readonly our $DOT   => q{.};

# paths
Readonly our $PROJECT_DIR   => "$SHARE_DIR/$PROJECT";
Readonly our $INCLUDE_PATH  => "$PERL5SHARE_DIR/templates";
Readonly our $TEMPLATES_DIR => "$PERL5SHARE_DIR/templates";
Readonly our $FILE_LIST     => "$PROJECT_DIR/file_list.json";

# other
Readonly our $MANIFEST_FILE => 'manifest.yaml';

Readonly our $COPYRIGHT => <<"END_OF_COPYRIGHT";
version $VERSION

Copyright (C) 2023 TBC Development Group, LLC
License GPLv2+: GNU GPL version 2 or later <https://gnu.org/licenses/gpl-2.0.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Rob Lauer <rlauer6\@comcast.net>
END_OF_COPYRIGHT

Readonly::Hash our %CONFIG_FILE_EXTENSIONS => (
  ini_files    => 'ini',
  config_files => 'cfg',
  json_files   => 'json',
  yaml_files   => 'yaml',
);

Readonly::Hash our %BOOLEAN_OPTIONS => (
  man_pages       => 'man-pages',
  create_missing  => 'create-missing',
  unit_tests      => 'unit-tests',
  html            => 'html',
  bash            => 'bash',
  version_numbers => 'add-version-numbers',
  pod_to_readme   => 'pod-to-readme',
);

Readonly::Hash our %SUBDIRS_BY_TYPE => (
  '.html' => 'src/main/html/htdocs',
  '.css'  => 'src/main/html/css',
  '.js'   => 'src/main/html/javascript',
  '.pm'   => 'src/main/perl/lib',
  '.pl'   => 'src/main/perl/bin',
  '.sh'   => 'src/main/bash/bin',
  '.cgi'  => 'src/main/perl/cgi-bin',
);

our %EXPORT_TAGS = (
  booleans => [
    qw(
      $TRUE
      $FALSE
    )
  ],
  chars => [
    qw(
      $EMPTY
      $SPACE
      $DASH
      $SLASH
      $COMMA
      $DOT
    )
  ],
  paths => [
    qw(
      $PROJECT_DIR
      $INCLUDE_PATH
      $SHARE_DIR
      $TEMPLATES_DIR
      $PERL5SHARE_DIR
    )
  ],
  vars => [
    qw(
      $PROJECT
      $FILE_LIST
      $MANIFEST_FILE
      $COPYRIGHT
      %CONFIG_FILE_EXTENSIONS
      %SUBDIRS_BY_TYPE
      %BOOLEAN_OPTIONS
    )
  ],
);

our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;

$EXPORT_TAGS{all} = [@EXPORT_OK];

1;
