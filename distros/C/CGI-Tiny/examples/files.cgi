#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Path::Tiny;
use MIME::Types;
use Unicode::UTF8 qw(encode_utf8 decode_utf8);

cgi {
  my $cgi = $_;

  my $filename = $cgi->query_param('filename');
  unless (length $filename) {
    $cgi->set_response_status(404)->render(text => 'Not Found');
    exit;
  }

  # get files from public/ next to cgi-bin/
  my $public_dir = path(__FILE__)->realpath->parent->sibling('public');
  my $encoded_filename = encode_utf8 $filename;
  my $filepath = $public_dir->child($encoded_filename);

  # ensure file exists, is readable, and is not a directory
  unless (-r $filepath and !-d _) {
    $cgi->set_response_status(404)->render(text => 'Not Found');
    exit;
  }

  # ensure file path doesn't escape the public/ directory
  unless ($public_dir->subsumes($filepath->realpath)) {
    $cgi->set_response_status(404)->render(text => 'Not Found');
    exit;
  }

  my $basename = decode_utf8 $filepath->basename;
  my $mime = MIME::Types->new->mimeTypeOf($basename);
  $cgi->set_response_type($mime->type) if defined $mime;
  $cgi->set_response_disposition(attachment => $basename)->render(file => $filepath);
};
