package Datafile::Hash;

use strict;
use warnings;
use 5.014;
use Exporter 'import';
use Carp;

our @EXPORT_OK  = qw(readhash writehash);
our $VERSION    = '1.05';

sub _trim { $_[0] =~ s/^\s+|\s+$//gr if defined $_[0] && $_[1] }

sub readhash {
    my ( $filename, $data, $opts ) = @_;
    $opts //= {};

    my $delim        = $opts->{delimiter}    // '=';
    my $skip_empty   = $opts->{skip_empty}   // 1;
    my $skip_headers = $opts->{skip_headers} // 0;
    my $key_fields   = $opts->{key_fields}   // 1;
    my $comment_char = $opts->{comment_char} // '#';
    my $search       = $opts->{search};
    my $verbose      = $opts->{verbose}      // 0;
    my $group_mode   = $opts->{group}        // 2;
    my $ini_mode = ( $delim eq '=' || $delim eq ':' ) ? 1 : 0;

    my @messages = ();
    if ($verbose) {
        push @messages, "# readhash: delimiter='$delim', key_fields=$key_fields\n";
        push @messages,
            "# opts: " . join( ", ", map { "$_=$opts->{$_}" } sort keys %$opts ) . "\n";
    }

    my @compiled_patterns = ();
    if ( defined $search && ( ref $search || length $search ) ) {
        my @raw = ref $search eq 'ARRAY' ? @$search : ($search);
        for my $pat (@raw) {
            next unless defined $pat;
            my $regex = ref $pat eq 'Regexp' ? $pat : qr/\Q$pat\E/i;
            push @compiled_patterns, $regex;
        }
    }
    croak
"datafile::hash::readhash: second argument (\$data) must be a HASH reference"
        unless ref $data eq 'HASH';

    open my $fh, '<:encoding(UTF-8)', $filename
        or return ( 0, ["WARNING: cannot open '$filename': $!"] );
    %$data = ();

    my $entry_count   = 0;
    my $current_path  = [];
    my %structured    = ();
    my %groups_seen   = ();

    while ( my $line = <$fh> ) {
        next if $line =~ /^\s*\Q$comment_char\E/;
        if ( $skip_headers > 0 ) {
            $skip_headers--;
            next;
        }
        $line =~ s/[\r\n\s]+$//;
        next if $skip_empty && $line eq '';

        if (@compiled_patterns) {
            my $all_matched = 1;
            for my $regex (@compiled_patterns) {
                $all_matched = 0 unless $line =~ $regex;
                last unless $all_matched;
            }
            next unless $all_matched;
        }

        if ( $line =~ /^\[\s*(.+?)\s*\]$/ ) {
            my $section = _trim( $1, 1 );
            @$current_path = split /\./, $section;

            my $path = '';
            for my $part (@$current_path) {
                $path = $path ? "$path.$part" : $part;
                $groups_seen{$path}++;
            }
            push @messages, "- entering section [$section]\n" if $verbose;
            next;
        }

        unless ($ini_mode) {
            my @fields = split /\Q${delim}\E/, $line, -1;
            next if @fields < $key_fields + 1;

            my $key   = join $delim, @fields[ 0 .. $key_fields - 1 ];
            my $value = join $delim, @fields[ $key_fields .. $#fields ];
            $data->{$key} = $value;
        }
        else {
            if ( $key_fields > 1 ) {
                push @messages,
                    "- warning: ignoring key_fields = $key_fields in INI mode\n";
                $key_fields = 1;
            }
            my @fields = split /\Q$delim\E/, $line, 2;
            next if @fields < 2;
            my $key   = join $delim, map { _trim( $_, 1 ) } @fields[ 0 .. $key_fields - 1 ];
            my $value = join $delim,
                map { _trim( $_, 1 ) } @fields[ $key_fields .. $#fields ];

            if ( $delim eq '=' ) {
                $value =~ s/^"(.*)"$/$1/;
                $value =~ s/\\"/"/g;
            }
            my $ref = \%structured;
            $ref = $data if ( $group_mode == 2 );
            $ref = ( $ref->{$_} //= {} ) for @$current_path;
            $ref->{$key} = $value;
        }
        $entry_count++;
    }
    close $fh;

    if ( $ini_mode && $group_mode != 2 ) {
        my $flatten;
        $flatten = sub {
            my ( $hash, $prefix ) = @_;
            for my $k ( sort keys %$hash ) {
                my $v = $hash->{$k};
                my $full =
                    ( $group_mode == 1 && $prefix ne '' ) ? "$prefix.$k" : $k;
                if ( ref $v eq 'HASH' ) {
                    $flatten->( $v, $full );
                }
                else {
                    $data->{ $group_mode == 0 ? $k : $full } = $v;
                }
            }
        };
        $flatten->( \%structured, '' );
    }

    if ( $verbose && $ini_mode ) {
        push @messages, "- groups: " . join( ',', sort keys %groups_seen ) . "\n";
    }
    push @messages, "- $entry_count data records read from $filename\n"
        if $verbose;

    return ( $entry_count, \@messages, \%groups_seen );
}

sub writehash {
    my ( $filename, $hash, $opts ) = @_;
    $opts //= {};

    my $delim        = $opts->{delimiter}    // '=';
    my $comment_char = $opts->{comment_char} // '#';
    my $prot         = $opts->{prot}         // 0660;
    my $backup       = $opts->{backup}       // 0;
    my $verbose      = $opts->{verbose}      // 0;
    my $ini_mode     = ( $delim eq '=' || $delim eq ':' ) ? 1 : 0;

    unless ( $hash && ref $hash eq 'HASH' && keys %$hash ) {
        if ( -f $filename ) {
            unlink($filename)
                or return ( 0,
                ["ERROR: file $filename could not be deleted $!"] );
            return ( 1, ["SUCCESS: file $filename was deleted.\n"] );
        }
        croak
"datafile::hash::writehash: second argument (\$data) must be a HASH reference"
    }

    my $tmp = "$filename.tmp";
    my @messages = ();
    if ($verbose) {
        push @messages, "# writehash: delimiter='$delim'\n";
        push @messages,
            "# opts: " . join( ", ", map { "$_=$opts->{$_}" } sort keys %$opts ) . "\n";
    }

    open my $fh, '>:encoding(UTF-8):crlf', $tmp
        or return ( 0, ["ERROR: cannot open '$tmp' for writing: $!"] );

    if ( my $comment = $opts->{comment} ) {
        my @lines = ref $comment eq 'ARRAY' ? @$comment : split /\n/, $comment;
        print $fh "$comment_char $_\n" for @lines;
        if ($verbose) { push @messages, "> $comment_char $_\n" for @lines; }
    }

    my $entry_count = 0;

    unless ($ini_mode) {
        for my $k ( keys %$hash ) {
            my $v = $hash->{$k};
            print $fh "$k$delim$v\n";
            $entry_count++;
        }
    }
    else {
        my $first_section   = 1;
        my %data            = %$hash;
        my $has_real_nested = grep { ref $data{$_} eq 'HASH' } keys %data;

        if ( !$has_real_nested && grep /\./, keys %data ) {
            my %nested;
            while ( my ( $k, $v ) = each %data ) {
                my @p = split /\./, $k;
                my $r = \%nested;
                $r = ( $r->{$_} //= {} ) for @p[ 0 .. $#p - 1 ];
                $r->{ $p[-1] } = $v;
            }
            %data            = %nested;
            $has_real_nested = 1;
        }

        my %global_data;
        for my $k ( keys %data ) {
            next if ref $data{$k} eq 'HASH';
            $global_data{$k} = delete $data{$k};
        }
        my $write_section;
        $write_section = sub {
            my ( $cur, $path ) = @_;
            my $name = @$path ? join( '.', @$path ) : '';

            print $fh "\n" unless ($first_section);
            $first_section = 0;
            if ( $name ne '' ) {
                print $fh "[$name]\n";
                push @messages, "> [$name]\n" if $verbose;
            }

            my $maxsize = 0;
            for my $k ( sort grep { !ref $cur->{$_} } keys %$cur ) {
                $maxsize = length($k) if length($k) > $maxsize;
            }
            for my $k ( sort grep { !ref $cur->{$_} } keys %$cur ) {
                my $v = $cur->{$k};
                my $needs_quoting =
                    ( $v =~ /[#"'\r\n]/ || $v =~ /^\s+|\s+$/ || $v eq '' );
                if ( $delim eq '=' && $needs_quoting ) {
                    $v =~ s/"/\\"/g;
                    $v = qq("$v");
                }
                my $line = sprintf "%-*s %s %s", $maxsize, $k, $delim, $v;
                print $fh "$line\n";
                $entry_count++;
            }

            for my $sub ( sort grep { ref $cur->{$_} eq 'HASH' } keys %$cur ) {
                $write_section->( $cur->{$sub}, [ @$path, $sub ] );
            }
        };

        if ( keys %global_data ) {
            $write_section->( \%global_data, [] );
        }
        for my $top ( sort keys %data ) {
            $write_section->( $data{$top}, [$top] );
        }
    }
    print $fh "#EOF\n" if $comment_char eq '#';
    close $fh
        or return ( 0, ["ERROR: failed to close '$tmp': $!"] );

    if ( $backup && -f $filename ) {
        rename( $filename, $filename . '.bak' )
            or push @messages,
            "WARNING: backup to ${filename}.bak failed: $!";
    }
    rename( $tmp, $filename )
        or return ( 0, ["ERROR: failed to rename '$tmp' to '$filename': $!"] );
    chmod $prot, $filename;

    push @messages, "- $entry_count entries written to $filename\n"
        if $verbose;
    return ( $entry_count, \@messages );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Datafile::Hash - Pure-Perl utilities for datafiles and INI-style config files with multi-level sections

=head1 LICENSE

This module is free software.

You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SYNOPSIS

  use Datafile::Hash qw(readhash writehash);

  my %config;

  readhash('config.ini', \%config, {
      delimiter => '=',      # INI mode
      group     => 2,        # nested hashes (default)
      verbose   => 1,
  });

  # $config{section}{subsection}{key} = 'value'

  # Flat key-value file example
  readhash('settings.txt', \%config, {
      delimiter => '=',      # still INI mode
      group     => 0,        # flat hash, ignore sections
  });

  writehash('config.ini', \%config, {
      backup  => 1,
      comment => ['Auto-generated - do not edit manually', scalar localtime],
  });

=head1 DESCRIPTION

Lightweight pure-Perl module for reading and writing key-value data files,
including full INI-style files with multi-level sections.
Supports flat files, dotted-key notation, or true nested hashes.
Safe atomic writes and consistent error handling.

=head1 FUNCTIONS

=head2 readhash($filename, $hash_ref, \%options)

Loads key-value data into a hash reference.

Returns:
  ($entry_count, \@messages, \%groups_seen)

C<$entry_count>    - number of key-value pairs read
C<\@messages>      - informational/warning messages
C<\%groups_seen>   - hashref of section names encountered (only in INI mode)

=head2 writehash($filename, $hash_ref, \%options)

Writes hash data back to file.

Returns:
  ($entry_count, \@messages)

On I/O error returns C<(0, \@error_messages)>.

=head1 OPTIONS

=over 4

=item delimiter => '=' (default)

Key-value separator. If '=' or ':' → full INI mode with sections and quoting.
Any other delimiter → flat key-value mode (no sections).

=item group => 2 (default)

How to handle sections:
  0 - ignore sections, flat hash
  1 - dotted keys (section.sub.key)
  2 - nested hashes (recommended for INI)

=item key_fields => 1 (default)

Number of leading fields to use as key (only used in flat mode).

Ignored in INI mode (forced to 1).

=item skip_empty => 1 (default)

Skip blank lines.

=item skip_headers => 0 (default)

Number of leading lines to skip (e.g., BOM or banner).

=item comment_char => '#' (default)

Character marking comment lines.

=item search => undef (default)

String, regex, or arrayref — only matching lines are processed.

=item verbose => 0 (default)

Include detailed messages in return arrayref.

=item backup => 0 (default) | 1 (writehash only)

Rename existing file to .bak.

=item comment => undef (writehash only)

String or arrayref of comment lines to write at top.

=item prot => 0660 (default) (writehash only)

File permissions (octal) for new file.

=back

INI mode automatically handles:
- Section headers [section.subsection]
- Quoted values with escaped quotes (\")
- Proper value quoting on write when needed (contains special chars, newlines, leading/trailing space, or empty)
