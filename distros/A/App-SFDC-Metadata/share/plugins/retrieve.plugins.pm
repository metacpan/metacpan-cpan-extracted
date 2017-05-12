#!perl
package App::SFDC::Command::Retrieve;
use strict;
use warnings;
use 5.10.0;
use experimental qw(smartmatch);

sub _compressProfile {

  ## no critic

  return join "", grep {
    s/\r//g;                  # remove all CR characters
    s/\t/    /g;              # replace all tabs with 4 spaces
    if (/^\s/) {              # ignore the the xml root node
      s/\n//;                 # remove newlines
      s/^    (?=<(?!\/))/\n/; # insert newlines where appropriate
      s/^(    )+//;           # trim remaining whitespace
    }
    /\S/;
  } split /^/, shift;

  ## use critic
}

sub _retrieveTimeMetadataChanges {
  my ($path, $content) = @_;
  given ($path) {
    when (/\.profile|\.permissionset/) {
      # COMPRESS PROFILES
      $content = _compressProfile $content;
    }
  }
  return $content;
}

our @folders = (
    {type => 'Document', folder => 'unfiled$public'},
    {type => 'EmailTemplate', folder => 'unfiled$public'},
    {type => 'Report', folder => 'unfiled$public'},
);

1;
