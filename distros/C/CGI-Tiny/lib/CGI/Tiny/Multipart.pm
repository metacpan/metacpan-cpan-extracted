package CGI::Tiny::Multipart;
# ABSTRACT: Tiny multipart/form-data form parser

# This file is part of CGI::Tiny which is released under:
#   The Artistic License 2.0 (GPL Compatible)
# See the documentation for CGI::Tiny for full license details.

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '1.003';

our @EXPORT_OK = qw(extract_multipart_boundary parse_multipart_form_data);

use constant DEFAULT_REQUEST_BODY_BUFFER => 262144;

sub extract_multipart_boundary {
  my ($content_type) = @_;
  my ($boundary_quoted, $boundary_unquoted) = $content_type =~ m/;\s*boundary\s*=\s*(?:"((?:\\[\\"]|[^"])+)"|([^";]+))/i;
  $boundary_quoted =~ s/\\([\\"])/$1/g if defined $boundary_quoted;
  return defined $boundary_quoted ? $boundary_quoted : $boundary_unquoted;
}

sub parse_multipart_form_data {
  my ($input, $length, $boundary, $options) = @_;
  $options ||= {};
  my $input_is_scalar = ref $input eq 'SCALAR';
  binmode $input unless $input_is_scalar;
  my $remaining = 0 + ($length || 0);
  my $next_boundary = "\r\n--$boundary\r\n";
  my $end_boundary = "\r\n--$boundary--";
  my $buffer_size = 0 + ($options->{buffer_size} || DEFAULT_REQUEST_BODY_BUFFER);
  my $buffer = "\r\n";
  my (%state, @parts, $current);
  READER: while ($remaining > 0) {
    if ($input_is_scalar) {
      $buffer .= substr $$input, 0, $remaining;
      $remaining = 0;
    } else {
      my $chunk = $remaining < $buffer_size ? $remaining : $buffer_size;
      last unless my $read = read $input, $buffer, $chunk, length $buffer;
      $remaining -= $read;
    }

    unless ($state{parsing_headers} or $state{parsing_body}) {
      my $next_pos = index $buffer, $next_boundary;
      my $end_pos = index $buffer, $end_boundary;
      if ($next_pos >= 0 and ($end_pos < 0 or $end_pos > $next_pos)) {
        substr $buffer, 0, $next_pos + length($next_boundary), '';
        $state{parsing_headers} = 1;
        push @parts, $current = {headers => {}, name => undef, filename => undef, size => 0};
      } elsif ($end_pos >= 0) {
        $state{done} = 1;
        last; # end of multipart data
      } else {
        next; # read more to find start of multipart data
      }
    }

    while (length $buffer) {
      if ($state{parsing_headers}) {
        while ((my $pos = index $buffer, "\r\n") >= 0) {
          if ($pos == 0) { # end of headers
            $state{parsing_headers} = 0;
            $state{parsing_body} = 1;
            $state{parsed_optional_crlf} = 0;
            last;
          }

          my $header = substr $buffer, 0, $pos + 2, '';
          my ($name, $value) = split /\s*:\s*/, $header, 2;
          return undef unless defined $value;
          $value =~ s/\s*\z//;

          $current->{headers}{lc $name} = $value;
          if (lc $name eq 'content-disposition') {
            while ($value =~ m/;\s*([^=\s]+)\s*=\s*(?:"((?:\\[\\"]|[^"])*)"|([^";]*))/ig) {
              my ($field_name, $field_quoted, $field_unquoted) = ($1, $2, $3);
              next unless lc $field_name eq 'name' or lc $field_name eq 'filename';
              $field_quoted =~ s/\\([\\"])/$1/g if defined $field_quoted;
              $current->{lc $field_name} = defined $field_quoted ? $field_quoted : $field_unquoted;
            }
          }
        }
        next READER if $state{parsing_headers}; # read more to find end of headers
      } else {
        my $append = '';
        my $next_pos = index $buffer, $next_boundary;
        my $end_pos = index $buffer, $end_boundary;
        if ($next_pos >= 0 and ($end_pos < 0 or $end_pos > $next_pos)) {
          if (!$state{parsed_optional_crlf} and $next_pos >= 2) {
            substr $buffer, 0, 2, '';
            $next_pos -= 2;
            $state{parsed_optional_crlf} = 1;
          }
          $append = substr $buffer, 0, $next_pos, '';
          substr $buffer, 0, length($next_boundary), '';
          $state{parsing_body} = 0;
          $state{parsing_headers} = 1;
        } elsif ($end_pos >= 0) {
          if (!$state{parsed_optional_crlf} and $end_pos >= 2) {
            substr $buffer, 0, 2, '';
            $end_pos -= 2;
            $state{parsed_optional_crlf} = 1;
          }
          $append = substr $buffer, 0, $end_pos; # no replacement, we're done here
          $state{parsing_body} = 0;
          $state{done} = 1;
        } elsif (length($buffer) > length($next_boundary) + 2) {
          if (!$state{parsed_optional_crlf}) {
            substr $buffer, 0, 2, '';
            $state{parsed_optional_crlf} = 1;
          }
          $append = substr $buffer, 0, length($buffer) - length($next_boundary), '';
        }

        $current->{size} += length $append;
        unless (defined $current->{filename} and $options->{discard_files}) {
          if ($options->{parse_as_files} or (defined $current->{filename} and !defined $options->{parse_as_files})) {
            my $is_eof = !$state{parsing_body};
            if (defined $options->{on_file_buffer}) {
              $options->{on_file_buffer}->($append, my $dummy = $current, $is_eof);
            } else {
              # create temp file even if empty
              unless (defined $current->{file}) {
                require File::Temp;
                $current->{file} = File::Temp->new(@{$options->{tempfile_args} || []});
                binmode $current->{file};
              }
              print {$current->{file}} $append;
              if ($is_eof) { # finalize temp file
                $current->{file}->flush;
                seek $current->{file}, 0, 0;
              }
            }
          } else {
            $current->{content} = '' unless defined $current->{content};
            $current->{content} .= $append;
          }
        }

        last READER if $state{done};         # end of multipart data
        next READER if $state{parsing_body}; # read more to find end of part

        # new part started
        push @parts, $current = {headers => {}, name => undef, filename => undef, size => 0};
      }
    }
  }
  return undef unless $state{done};

  return \@parts;
}

1;
