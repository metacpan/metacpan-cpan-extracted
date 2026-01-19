package Datafile::Array;

use strict;
use warnings;
use 5.014;
use Exporter 'import';
use Carp;

our @EXPORT_OK = qw(readarray writearray parse_csv_line);
our $VERSION   = '1.05';

sub _trim {
    my ($value, $do_trim) = @_;
    return $value unless $do_trim && defined $value;
    $value =~ s/^\s+|\s+$//g;
    return $value;
}

sub parse_csv_line {
    my ($line, $sep) = @_;
    $sep //= ',';
    my @fields;
    my $pos  = 0;
    my $len  = length( $line // '' );
    while ( $pos < $len ) {
        my $field = '';
        if ( substr( $line, $pos, 1 ) eq '"' ) {
            $pos++;
            my $start = $pos;
            while (1) {
                my $qpos = index( $line, '"', $pos );
                if ( $qpos == -1 ) {
                    $field .= substr( $line, $start );
                    $pos    = $len;
                    last;
                }
                $field .= substr( $line, $start, $qpos - $start );
                $pos    = $qpos + 1;
                if ( $pos < $len && substr( $line, $pos, 1 ) eq '"' ) {
                    $field .= '"';
                    $pos++;
                    $start = $pos;
                }
                else {
                    last;
                }
            }
        }
        else {
            my $spos = index( $line, $sep, $pos );
            $spos = $len if $spos == -1;
            $field = substr( $line, $pos, $spos - $pos );
            $pos   = $spos;
        }
        push @fields, $field;
        $pos++ if ( $pos < $len && substr( $line, $pos, 1 ) eq $sep );
    }
    return @fields;
}

sub readarray {
    my ( $filename, $data, $pafields, $opts ) = @_;
    $opts //= {};

    my $delim       = $opts->{delimiter}    // ';';
    my $key_fields  = $opts->{key_fields}   // 1;
    my $trim        = $opts->{trim_values}  // 1;
    my $comment     = $opts->{comment_char} // '#';
    my $skip_empty  = $opts->{skip_empty}   // 1;
    my $csv         = $opts->{csvquotes}    // 0;
    my $has_headers = $opts->{has_headers}  // 1;
    my $prefix      = $opts->{prefix}       // 0;
    my $search      = $opts->{search};
    my $verbose     = $opts->{verbose}      // 0;

    my @field_names;
    if ( ref $pafields eq 'ARRAY' ) {
        @field_names = @$pafields;
    }
    elsif ( defined $pafields ) {
        croak "datafile::array::readarray: 'fields' parameter must be an ARRAY reference";
    }
    if ( ref $data eq 'ARRAY' ) {
        @$data = ();
    }
    elsif ( ref $data eq 'HASH' ) {
        %$data = ();
    }
    else {
        croak "datafile::array::readarray: 'data' parameter must be an ARRAY or HASH reference";
    }

    my @messages = ();
    push @messages,
        "# readarray: fields=@field_names\n",
        "# opts: "
        . join( ", ", map { "$_=$opts->{$_}" } sort keys %$opts ) . "\n"
        if $verbose;

    my @compiled_patterns = ();
    if ( defined $search && ( ref $search || length $search ) ) {
        my @raw = ref $search eq 'ARRAY' ? @$search : ($search);
        for my $pat (@raw) {
            next unless defined $pat;
            my $regex = ref $pat eq 'Regexp' ? $pat : qr/\Q$pat\E/i;
            push @compiled_patterns, $regex;
        }
    }

    open( my $fh, '<:encoding(UTF-8)', $filename )
        or return ( 0, ["WARNING: cannot open '$filename': $!"] );

    my $record_count = 0;
    my $start_idx    = $prefix ? 1 : 0;
    my $delim_re     = qr/\Q$delim\E/;
    my $csvline      = '';

    my $header_done  = 0;
    $has_headers     = 1 if $prefix && $has_headers == 0;
    $header_done     = 1 if $has_headers == 0 && @field_names;

    while ( my $line = <$fh> ) {
        next if $line =~ /^\s*\Q$comment\E/;
        $line =~ s/[\r\n\s]+$//;

        my @fields;
        if ($csv) {
            $csvline .= "\n" if $csvline ne '';
            $csvline .= $line;
            my $count = () = $csvline =~ /\Q"\E/g;
            next
                unless $count % 2 == 0
                && ( $count == 0 || $csvline =~ /"[^"]*$/ );
            @fields = parse_csv_line( $csvline, $delim );
            $line   = $csvline;
            $csvline = '';
        }
        else {
            @fields = split $delim_re, $line, -1;
        }
        next if $skip_empty && $line eq '';

        unless ($header_done) {
            if ( $has_headers > 0 ) {
                if ( $has_headers == 1 || ( $prefix && substr( $line, 0, 1 ) eq 'H' ) )
                {
                    unless (@field_names) {
                        @field_names = map { _trim( $_, 1 ) }
                            @fields[ $start_idx .. $#fields ];
                        push @messages,
                            "- header fields: @field_names\n"
                            if $verbose;
                    }
                    $header_done = 1 if @field_names;
                }
                $has_headers--;
                next;
            }
            else {
                croak
"datafile::array::readarray: no field names provided and none found in file"
                    unless @field_names;
                $header_done = 1;
            }
        }
        next if @fields < $start_idx + @field_names;

        if (@compiled_patterns) {
            my $all_matched = 1;
            for my $regex (@compiled_patterns) {
                $all_matched = 0 unless $line =~ $regex;
                last unless $all_matched;
            }
            next unless $all_matched;
        }

        my %record;
        for my $i ( 0 .. $#field_names ) {
            my $val = $fields[ $start_idx + $i ] // '';
            $record{ $field_names[$i] } = _trim( $val, $trim );
        }

        if ( ref $data eq 'HASH' ) {
            my @key_parts = map { _trim( $fields[$_], $trim ) }
                ( 0 .. $key_fields - 1 );
            my $key = join( $delim, @key_parts );
            $data->{$key} = \%record;
        }
        else {
            push @$data, \%record;
        }

        $record_count++;
    }
    close $fh;
    croak
"datafile::array::readarray: no field names provided and none found in file"
        unless @field_names;

    if ( defined $pafields && @field_names && !@$pafields ) {
        @$pafields = @field_names;
        push @messages, "- return fields: @field_names\n" if $verbose;
    }

    push @messages,
        "- $record_count data records read from $filename\n"
        if $verbose;
    return ( $record_count, \@messages );
}

sub writearray {
    my ( $filename, $data, $pafields, $opts ) = @_;
    $opts //= {};

    my $delim        = $opts->{delimiter}    // ';';
    my $comment_char = $opts->{comment_char} // '#';
    my $header       = $opts->{header}       // 0;
    my $prefix       = $opts->{prefix}       // 0;
    my $backup       = $opts->{backup}       // 0;
    my $prot         = $opts->{prot}         // 0660;
    my $verbose      = $opts->{verbose}      // 0;

    my @field_names = ref $pafields eq 'ARRAY' ? @$pafields : ();
    unless (@field_names) {
        if (@$data) {
            my $first = ref($data) eq 'HASH' ? ( values %$data )[0] : $data->[0];
            @field_names = sort keys %$first;
        }
        else {
            @field_names = ();
        }
    }

    if ( ref $data ne 'ARRAY' && ref $data ne 'HASH' && !@field_names ) {
        if ( -f $filename ) {
            unlink($filename)
                or return ( 0, ["WARNING: unable to delete file $filename"] );
            return ( 1, ["SUCCESS: file $filename is deleted"] );
        }
        croak
"datafile::array::writearray: 'data' parameter must be an ARRAY or HASH reference";
    }

    my @messages = ();
    push @messages,
        "# writearray: fields=@field_names\n",
        "# opts: "
        . join( ", ", map { "$_=$opts->{$_}" } sort keys %$opts ) . "\n"
        if $verbose;

    my $tmp = "$filename.tmp";
    open( my $fh, '>:encoding(UTF-8):crlf', $tmp )
        or return ( 0, ["ERROR: cannot open '$tmp' for writing: $!"] );

    if ( my $comment = $opts->{comment} ) {
        my @lines = ref($comment) eq 'ARRAY' ? @$comment : split( /\n/, $comment );
        print $fh "$comment_char $_\n" for @lines;
        if ($verbose) { push @messages, "> $comment_char $_\n" for @lines }
    }

    my $prefix_hdr = $prefix ? 'H' . $delim : '';
    my $prefix_row = $prefix ? 'R' . $delim : '';

    if ( $header && @field_names ) {
        print $fh $prefix_hdr . join( $delim, @field_names ) . "\n";
        push @messages,
            "> " . $prefix_hdr . join( $delim, @field_names ) . "\n"
            if $verbose;
    }

    my $record_count = 0;
    my @records =
        ref($data) eq 'HASH' ? sort keys %$data : 0 .. $#$data;

    for my $key (@records) {
        my $rec = ref($data) eq 'HASH' ? $data->{$key} : $data->[$key];
        my @values = map { defined( $rec->{$_} ) ? $rec->{$_} : '' } @field_names;
        my $line   = $prefix_row . join( $delim, @values );
        print $fh $line . "\n"
            or return ( 0, ["ERROR: write error to '$tmp': $!"] );
        $record_count++;
    }
    print $fh "#EOF\n" if $comment_char eq '#';
    close $fh
        or return ( 0, ["ERROR: failed to close '$tmp': $!"] );

    if ($backup && -f $filename) {
        rename( $filename, $filename . '.bak' )
            or push @messages,
            "WARNING: backup to ${filename}.bak failed: $!";
    }
    rename( $tmp, $filename )
        or return ( 0, ["ERROR: failed to rename '$tmp' to '$filename': $!"] );
    chmod $prot, $filename;

    push @messages,
        "- renamed $tmp to $filename\n",
        "- $record_count data records written to $filename\n"
        if $verbose;
    return ( $record_count, \@messages );
}

1;

__END__

=head1 NAME

Datafile::Array - Pure-Perl utilities for reading and writing delimited data files

=head1 LICENSE

This module is free software.

You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SYNOPSIS

  use Datafile::Array qw(readarray writearray parse_csv_line);

  my @records;
  my @fields;

  my ($count, $msgs) = readarray('data.txt', \@records, \@fields, {
      delimiter    => ';',
      csvquotes    => 1,        # enable proper CSV quoted fields and multi-line
      has_headers  => 1,
      prefix       => 1,        # expect 'H' header and 'R' data lines
      trim_values  => 1,
      verbose      => 1,
  });

  # @records now contains array of hashes
  # @fields contains the detected or provided field names

  writearray('data.txt', \@records, \@fields, {
      header  => 1,
      prefix  => 1,
      backup  => 1,
      comment => 'Exported on ' . scalar localtime,
  });

=head1 DESCRIPTION

Lightweight pure-Perl module for reading and writing simple delimited data files.
Supports optional CSV-style quoted fields (including multi-line records), automatic or explicit headers,
prefix lines (H/R convention), search filtering, trimming, and safe atomic writes.

=head1 FUNCTIONS

=head2 readarray($filename, $data_ref, $fields_ref, \%options)

Loads delimited data into an array of hashes (or hash of hashes if using keys).

Returns two values:
  ($record_count, \@messages)

C<$record_count>  - number of data records read
C<\@messages>     - arrayref of informational/warning messages (especially when verbose => 1)

=head2 writearray($filename, $data_ref, $fields_ref, \%options)

Writes data back to file safely (using temporary file + rename).

Returns two values:
  ($record_count, \@messages)

On I/O error, returns C<(0, \@error_messages)> instead of dying.

=head2 parse_csv_line($line, [$delimiter = ','])

Standalone lightweight CSV line parser.

Parses a single line according to CSV rules:
- Handles quoted fields
- Escaped quotes via ""
- Fields containing delimiter, newlines, or quotes
- Lenient on unclosed quotes (treats rest as literal)

Returns array of fields.

Example:
  my @fields = parse_csv_line(q{hello,"world","say ""hi"""}, ',');
  # @fields = ('hello', 'world', 'say "hi"')

=head1 OPTIONS

=over 4

=item delimiter => ';' (default)

Field separator character.

=item csvquotes => 0 (default) | 1

Enable full CSV quoted-field parsing, including escaped quotes (""), fields containing delimiter/newlines,
and multi-line records.

=item has_headers => 1 (default)

Number of header lines to expect (or skip if prefix used). Set to 0 if no header.

=item prefix => 0 (default) | 1

Enable H/R prefix mode: first field of header line must be 'H', data lines 'R'.

=item key_fields => 1 (default)

Number of leading fields to use as composite key when loading into a hash.

=item trim_values => 1 (default)

Trim whitespace from all field values.

=item comment_char => '#' (default)

Character that marks comment lines (skipped).

=item skip_empty => 1 (default)

Skip blank lines.

=item search => undef (default)

String, regex, or arrayref of patterns. Only lines matching ALL patterns are processed.

=item verbose => 0 (default)

Include detailed progress messages in returned arrayref.

=item header => 0 (default) | 1 (writearray only)

Write header line (field names).

=item backup => 0 (default) | 1 (writearray only)

Rename existing file to .bak before overwriting.

=item prot => 0660 (default) (writearray only)

File permissions for new file (octal).

=item comment => undef (writearray only)

String or arrayref of comment lines to write at top.

=back
