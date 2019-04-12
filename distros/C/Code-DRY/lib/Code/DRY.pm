package Code::DRY;

use 5.008000;
use strict;
use warnings;
use integer;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load( 'Code::DRY', $VERSION );

# Preloaded methods go here.

my @files;
our ( @fileoffsets, @file_lineoffsets );
my %filename2inode;

my $codetotal;
my $verbose = 0;

# reporting
# $minlength is the filter criterion for duplicates to report
# $units is currently either 'bytes' or 'lines'.
# $rDups point to an array with an entry for duplication
# The entry is an array with the following entries
#  [
#  0: filename,
#  1: offset of start of file,
#  2: line number of start,
#  3: line number of end,
#  4: offset of line start,
#  5: offset of line end,
#  6: offset start,
#  7: offset end
#  ]
my $default_callback = sub {
    my ( $minlength, $units, $rDups ) = @_;

    # show dupes
    my $copies               = scalar @{$rDups} - 1;
    my $myamountlines        = $rDups->[0]->[3] - $rDups->[0]->[2] + 1;
    my $myamountbytesclipped = $rDups->[0]->[5] - $rDups->[0]->[4] + 1;
    my $myamountbytes        = $rDups->[0]->[7] - $rDups->[0]->[6] + 1;
    my $lengthstring
        = $units eq 'bytes'
        ? "$myamountbytes (>= $minlength $units) and $myamountlines complete lines"
        : "$myamountlines (>= $minlength $units) and $myamountbytesclipped bytes reduced to complete lines";
    print "$copies duplicate(s) found with a length of $lengthstring:\n";

    my $cnt = 1;
    for my $dup ( @{$rDups} ) {
        print "$cnt.  File: $dup->[0] in lines $dup->[2]..$dup->[3] (offsets ",
            $dup->[4] - $dup->[1], "..", $dup->[5] - $dup->[1], ")\n";
        ++$cnt;
    }

    $cnt = 1;
    for my $dup ( @{$rDups} ) {
        if (0) {
            print
                "offsets: clipped $dup->[4]--$dup->[5], raw $dup->[6]--$dup->[7]\n";
            print "lineends at: ";
            for my $j ( $dup->[2] - 1 .. $dup->[3] ) {
                print $dup->[1]
                    + $file_lineoffsets[ offset2fileindex( $dup->[6] ) ]
                    ->[ $j - 1 ], ' ';
            }
        }
        print "=================\n";

        my $offsetLineEnd;
        if ( $units eq 'bytes' ) {

            # begin at start of line
            my $linenumber      = offset2line( $dup->[6] );
            my $fileindex       = offset2fileindex( $dup->[6] );
            my $file_lineoffset = $file_lineoffsets[$fileindex];
            my $offsetLineBegin
                = $linenumber <= 1
                ? $dup->[1]
                : $dup->[1] + $file_lineoffset->[ $linenumber - 2 ] + 1;
            $offsetLineEnd
                = $dup->[1]
                + $file_lineoffset->[ $dup->[3]
                + ( $dup->[5] == $dup->[7] ? 0 : 1 ) ];

            if (   $offsetLineBegin > $dup->[6]
                || $dup->[6] > $dup->[7]
                || $dup->[7] > $offsetLineEnd )
            {
                warn
                    "\n\ninternal error: $offsetLineBegin, $dup->[4], $dup->[5], $offsetLineEnd, line number $linenumber";
            }

            print get_concatenated_text($offsetLineBegin,
                $dup->[6] - $offsetLineBegin );
            print " ==>>" if ( $units eq 'bytes' );
        }

        print get_concatenated_text( $dup->[4], $dup->[5] - $dup->[4] + 1 );
        print "<<== " if ( $units eq 'bytes' );

        if ( $units eq 'bytes' ) {
            print get_concatenated_text(
                $dup->[7] + 1,
                $offsetLineEnd - $dup->[7]
            ) if ( $dup->[7] + 1 < $offsetLineEnd );
        }

        # end at end of line
        print "\n=================\n";
        ++$cnt;
        last;    # makes not much sense to repeat identical parts
    }
};

my $callback = $default_callback;

sub set_default_reporter {
    $callback = $default_callback;
}

sub set_reporter {
    ($callback) = @_;
}

sub clearData {
    @files            = undef;
    $codetotal        = undef;
    @fileoffsets      = ();
    @file_lineoffsets = ();

    __free_all();
}

sub report_dupes {
    my ( $minlength, $dups, $length, $matchentry ) = @_;

    my $units;
    if ( $minlength >= 0 ) {
        $units = 'lines';
    }
    else {
        $minlength = abs($minlength);
        $units     = 'bytes';
    }

    # get position info
    # and report via callback
    my @dups;
    for my $entry ( $matchentry .. $matchentry + $dups - 1 ) {
        my $offset_start = get_offset_at($entry);
        my $offset_end   = $offset_start + $length - 1;
        my $file_index   = offset2fileindex($offset_start);
        my $file_start
            = $file_index == 0 ? 0 : $fileoffsets[ $file_index - 1 ] + 1;

#print "$offset_start -> $offset_end => length ", $offset_end - $offset_start + 1, "\n";
        my ( $upLine, $downLine );
        offsetAndFileindex2line( $offset_start, $file_index, \$upLine );
        offsetAndFileindex2line( $offset_end, $file_index, undef,
            \$downLine );

        # in line mode clip to line start and line end
        my ( $offset_start_clipped, $offset_end_clipped );
        if ( $units eq 'lines' ) {
            $offset_start_clipped
                = $file_start
                + ( $upLine < 2
                ? 0
                : $file_lineoffsets[$file_index]->[ $upLine - 2 ] + 1 );
            $offset_end_clipped = $file_start
                + $file_lineoffsets[$file_index]->[ $downLine - 1 ];
        }
        else {
            $offset_start_clipped = $offset_start;
            $offset_end_clipped   = $offset_end;
        }
        push @dups,
            [
            offset2filename($offset_start), $file_start,
            $upLine,                        $downLine,
            $offset_start_clipped,          $offset_end_clipped,
            $offset_start,                  $offset_end
            ];
    }

    # sort by offset
    @dups = map { $_->[1] }
        sort { $a->[0] <=> $b->[0] } map { [ $_->[2], $_ ] } @dups;

    #print "\n";

    $callback->( $minlength, $units, \@dups );
}

# position to file and line number mapping
sub offset2filename {
    my $offset = shift;
    my $fi     = offset2fileindex($offset);
    if ( !defined $fi ) {
        return;
    }

    # support memory files
    if ( 'SCALAR' eq ref $files[$fi] ) {
        return "memfile$fi";
    }
    else {
        return $files[$fi];
    }
}

# file index is 0 based
sub offset2fileindex {
    my $offset = shift;
    my ( $l, $r ) = ( 0, $#fileoffsets );
    return if ( !defined $offset );
    return 0 if ( 0 == $r );

    my $file = int( ( $r + $l ) / 2 );
    while ( $l < $r ) {

   #print "m=$file, l=$l, r=$r, fileoffset=$fileoffsets[$file] >= $offset?\n";

        return $file
            if (
            (   ( $file > 0 && $fileoffsets[ $file - 1 ] < $offset )
                || $file == 0
            )
            && $offset <= $fileoffsets[$file]
            );

        if ( $file > 0 && $fileoffsets[ $file - 1 ] >= $offset ) {
            $r = $file;
            $file = int( ( $r + $l ) / 2 );
        }
        else {
            $l = $file;
            $file = int( ( $r + $l + 1 ) / 2 );
        }
    }

    return undef;
}

#line number is 1 based
sub offsetAndFileindex2line {
    my ( $offset, $fileindex, $rRoundedUp_line, $rRoundedDown_line ) = @_;
    return if ( !defined $offset );
    return if ( !defined $fileindex );

    my $base = $fileindex == 0 ? 0 : $fileoffsets[ $fileindex - 1 ] + 1;
    $offset -= $base;

    my $lineoffsets = $file_lineoffsets[$fileindex];
    my ( $l, $r ) = ( 0, $#{$lineoffsets} );
    if ( 0 == $r ) {
        if ( defined($rRoundedUp_line) ) {
            ${$rRoundedUp_line} = 0;
        }
        if ( defined($rRoundedDown_line) ) {
            ${$rRoundedDown_line} = 0;
        }
        return 0;
    }

    my $line = int( ( $r + $l ) / 2 );

    while ( $l < $r ) {
        if ((   ( $line > 0 && $lineoffsets->[ $line - 1 ] < $offset )
                || $line == 0
            )
            && $offset <= $lineoffsets->[$line]
            )
        {
            if ( defined($rRoundedDown_line) ) {
                ${$rRoundedDown_line}
                    = $line == 0 ? $line + 1
                    : ( $offset == ( $lineoffsets->[$line] ) ? $line + 1
                    : $line );
            }
            if ( defined($rRoundedUp_line) ) {
                ${$rRoundedUp_line}
                    = $offset
                    == ( $line == 0 ? 0 : $lineoffsets->[ $line - 1 ] + 1 )
                    ? $line + 1
                    : $line + 2;
            }
            return $line + 1;
        }

        if ( $line > 0 && $lineoffsets->[ $line - 1 ] >= $offset ) {
            $r = $line;
            $line = int( ( $r + $l ) / 2 );
        }
        else {
            $l = $line;
            $line = int( ( $r + $l + 1 ) / 2 );
        }
    }
    return;
}

# line number is 1 based
sub offset2line {
    my ( $offset, $rRoundedUp_line, $rRoundedDown_line ) = @_;
    my $fileindex = offset2fileindex($offset);
    return offsetAndFileindex2line( $offset, $fileindex, $rRoundedUp_line,
        $rRoundedDown_line );
}

sub get_line_offsets_of_fileindex {
    my $fileindex = shift;
    return $file_lineoffsets[$fileindex];
}

sub get_concatenated_text {
    return if (!defined $codetotal);
    my ( $start, $length ) = @_;
    return substr( $codetotal, $start, $length );
}

sub enter_files {
    (my $rfiles) = @_;

    # reset all info
    @fileoffsets = @file_lineoffsets = ();
    %filename2inode = ();
    $codetotal = '';

    my $here = 0;
    for my $file (@{$rfiles}) {
        next if (!defined $file || $file eq '');
        # check metadata
        my @statresult = stat($file);
        if (0 < $#statresult) {
            my $inode = $statresult[1]; # inode
            if (exists $filename2inode{$inode}) {
                $file = undef;
                next; # avoid hard and symbolic links
            }
	    $filename2inode{$inode} = undef; # inode
        }
        # preprocess files content
        if (-z $file) {
            $file = undef;
            next;    # skip empty files
	}

        my ( $code, @lineoffsets ) = __get_text($file);
        if ($code eq '') {
            $file = undef;
            next;    # skip empty files
	}

        # we need the length of $code
        $codetotal .= $code;
        push @fileoffsets, ( length $codetotal ) - 1;

        # save line offsets per file
        push @file_lineoffsets, [@lineoffsets];
        ++$here;
    }
    @{$rfiles} = grep { defined $_ } @{$rfiles};
    return $here;
}

sub find_duplicates_in {
    ( my $minlength, my $ignoreContentFilter, @files ) = @_;
    enter_files(\@files);

    # enter codestring
    build_suffixarray_and_lcp($codetotal) == 0
        or die "Error building suffix array:$!\n";
    warn "analysing content of ", length $codetotal, " bytes out of ",
        scalar @files, " files...\n" if ($verbose);
    clip_lcp_to_fileboundaries( \@fileoffsets );
    reduce_lcp_to_nonoverlapping_lengths();
    set_lcp_to_zero_for_shadowed_substrings();

    my $n = get_size();

    my $cnt = 0;

    my @ranks;
    my $absminlength = abs($minlength);

    my $last_lcp = 0;
    @ranks = sort { get_len_at($b) <=> get_len_at($a) } grep {

# filter out when the lcp for this index is smaller than our requested minimal length
        my $lcp;    # length of match
        my $res = ( $lcp = get_len_at($_) )
            >= $absminlength;    # works for bytes and lines

        $res = $res && $lcp != $last_lcp;

        # ignore filter
        my $off;
        if ( $res && defined $ignoreContentFilter ) {
	    my $text = get_concatenated_text( $off = get_offset_at($_), $lcp );
            $res = $text !~ m{$ignoreContentFilter}xms;
        }

        if ( $res && 0 <= $minlength )
        {                        # minimal length is specified in line units
            my $off = get_offset_at($_);

            # include complete lines
            my ( $upLine, $downLine );
            my $startLine = offset2line( $off, \$upLine );
            my $endLine = offset2line( $off + $lcp - 1, undef, \$downLine );
            my $includesCompleteLines = $downLine - $upLine + 1;

            # positive minlength is interpreted as lines
            $res = $includesCompleteLines >= $minlength;
        }

        if (1) {
            $last_lcp = $lcp;
        }

#print "index $_ with lcp ", get_len_at($_), " and offset ", get_offset_at($_), " is ", $res ? "accepted\n" : "filtered out\n";
#print "index $_ with lcp ", get_len_at($_), " and offset ", get_offset_at($_), " is accepted\n" if $res;
#print "index $_ with lcp ", get_len_at($_), " and offset ", get_offset_at($_), " is filtered out\n" if !$res;
        $res;
    } ( 1 .. $n - 1 );

    warn "ranking array created with ", scalar @ranks, " entries\n" if ($verbose);

    my $res = '';
    # now report the remaining duplicates
    for my $matchentry (@ranks) {

        # how many duplicates?
        my $count_dups = 2;
        my $lcp        = get_len_at($matchentry);    # length of match
        while ( $lcp == get_len_at( $matchentry + $count_dups - 1 ) ) {
            ++$count_dups;
        }

        report_dupes( $minlength, $count_dups, $lcp, $matchentry - 1 );
    }
    $codetotal = undef; # release memory
    return $res;
}

use File::Find ();

sub scan_directories {
    my ( $minlength, $ignoreContentFilter, $regexAccept, $regexIgnore, @dirs )
        = @_;
    my @filepaths;

    if ( !defined $regexIgnore ) {
        $regexIgnore = qr{\.bak$|~$|\.swp$|\.bup$}xmsi;
    }
    if ( defined $regexAccept && ref $regexAccept ne 'Regexp' ) {
        $regexAccept = qr{$regexAccept}xms;
    }
    if ( ref $regexIgnore ne 'Regexp' ) {
        $regexIgnore = qr{$regexIgnore}xms;
    }
    if ( defined $ignoreContentFilter
        && ref $ignoreContentFilter ne 'Regexp' )
    {
        $ignoreContentFilter = qr{$ignoreContentFilter}xms;
    }
    if ( 1 == scalar @dirs && !-d $dirs[0] ) {

        # enable globs
        @dirs = <$dirs[0]>;
    }
    @dirs = grep { -e $_ && -d $_ } @dirs;
    if ( 0 == scalar @dirs ) {
        print "no valid directories given!\n";
        return;
    }

    File::Find::find(
        sub {
            #if ( -f $_ && -s $_
            if ( -s $_
                && ( !defined($regexAccept) || $_ =~ m{$regexAccept} ) )
            {
                if ( $_ =~ m{$regexIgnore} ) {
                } else {
                    push @filepaths, $File::Find::name;
                }
            }
        },
        @dirs
    );
    if ( 0 == scalar @filepaths ) {
        print "no files found for start dir(s) ", ( join ',', @dirs ),
            " with accept filter $regexAccept and ignore filter $regexIgnore!\n";
        return;
    }

    find_duplicates_in( $minlength, $ignoreContentFilter, @filepaths );
}

sub __get_text {
    my $file     = shift;
    my $contents = '';
    my @lineoffsets;
    open my $infile, '<', $file or die "cannot open file $file: $!\n";
    while (<$infile>) {
        $contents .= $_;
        push @lineoffsets, length($contents) - 1;
    }
    return ( $contents, @lineoffsets );
}

1;
__END__

=encoding Latin-1

=head1 NAME

Code::DRY - Cut-and-Paste-Detector for Perl code 

=head1 SYNOPSIS

  use Code::DRY;

  # high level usage: scan some directories for Perl code
  # and let the module report duplicates sorted
  # by length of duplicates. Minimum length are 4 lines, 
  # and all filters are set to undef.
  #
  Code::DRY::scan_directories(4, undef, undef, undef, @dirs);

  or

  # mid level usage: let the function report duplicates
  # from a list of files. The ignore filter is set to undef.
  # This time the minimum length is set to 40 bytes.
  Code::DRY::find_duplicates_in(-40, undef, @files);

  or

  # low level usage: analyse the raw data yourself
  # built the suffix and lcp array
  Code::DRY::build_suffixarray_and_lcp($longstringwithcode);
  # avoid matches crossing file boundaries
  Code::DRY::clip_lcp_to_fileboundaries(\@Code::DRY::fileoffsets);
  # avoid matches overlapping into each other
  Code::DRY::reduce_lcp_to_nonoverlapping_lengths();
  # avoid matches that are included in longer matches
  Code::DRY::set_lcp_to_zero_for_shadowed_substrings();
  # then iterate through the lcp array via get_len_at(index)
  # and through the suffix/offset array via get_offset_at(index)

=head1 DESCRIPTION

The module's main purpose is to report repeated text fragments (typically Perl code)
that could be considered for isolation and/or abstraction in order to
reduce multiple copies of the same code (aka cut and paste code).

Code duplicates may occur in the same line, file or directory.

The ad hoc approach to compare every item against every other item
leads to computing times growing exponentially with the amount of code,
which is not useful for anything but the smallest code bases.

So a efficient data structure is needed. 

This module can create the suffix array and the longest common prefix array
for a string of 8-bit characters. These data structures can be used to
search for repetitions of substrings in O(n) time.

The current strategy is to concatenate code from all files into one
string and then use the suffix array and its companion,
the longest-common-prefix (lcp) array on this string.


=head3 Example:

Instead of real Perl code I use the string 'mississippi' for simplicity.
A B<suffix> is a partial string of an input string, which ends at the end of the input string.
A B<prefix> is a partial string of an input string, which starts at the start of the input string.
The B<suffix array> of a string is a list of offsets (each one for a suffix),
which is sorted lexicographically by suffix:

    #  offset suffix
    ================
    0  10:    i
    1   7:    ippi
    2   4:    issippi
    3   1:    ississippi
    4   0:    mississippi
    5   9:    pi
    6   8:    ppi
    7   6:    sippi
    8   3:    sissippi
    9   5:    ssippi
    10  2:    ssissippi

The other structure needed is the B<longest common prefix array> (lcp).
It contains the maximal length of the prefixes for this entry shared with the previous 
entry from the suffix array. For this example it looks like this:


    #  offset lcp  (common prefixes shown in ())
    =====================
    0  10:    0    ()
    1   7:    1    (i)
    2   4:    1    (i)
    3   1:    4    (issi) overlap!
    3         3    (iss)  corrected non overlapping prefixes
    4   0:    0    ()
    5   9:    0    ()
    6   8:    1    (p)
    7   6:    0    ()
    8   3:    2    (si)
    9   5:    1    (s)
    10  2:    3    (ssi)

The standard lcp array may contain overlapping prefixes, but 
for our purposes we need only non overlapping prefixes lengths.
The same overlap may occur for prefixes that extend from the end of 
one source file to the start of the next file when we use 
concatenated content of source files.
The limiting with respect to internal overlaps and 
file crossing prefix lengths is done by two respective functions afterwards.

If we sort the so obtained lcp values in descending order we get

    #  offset lcp  (prefix shown in ())
    ===================================
    3   1:    3    (iss) now corrected to non overlapping prefixes
    10  2:    3    (ssi)
    8   3:    2    (si)
    1   7:    1    (i)
    2   4:    1    (i)
    6   8:    1    (p)
    9   5:    1    (s)
    0  10:    0    ()
    4   0:    0    ()
    5   9:    0    ()
    7   6:    0    ()

The first entry shows the longest repetition in the given string.
Not all entries are of interest since smaller copies are contained in the longest match.
After removing all 'shadowed' repetitions, the next entry can be reported.
Finally the lcp values are too small to be of any interest.


Currently this is experimental code.

The most appropriate mailing list on which to discuss this module would be
perl-qa.  See L<http://lists.perl.org/list/perl-qa.html>.

=head1 REQUIREMENTS & OPTIONAL MODULES

=head2 REQUIREMENTS

=over

=item * The ability to compile XS extensions.

This means a working C compiler, a linker, a C<make> program etc. If you built perl
from source you will have these already and they will be used automatically.
If your perl was built in some other way, for example you may have installed
it using your Operating System's packaging mechanism, you will need to ensure
that the appropriate tools are installed.

=item * Module C<File::Find>

This is a core module now for a while.

=back

=head2 OPTIONAL MODULES

=over

=item * L<Test::More>

Required if you want to run Code::DRY's own tests.

=item * L<Test::Output>

Optional if you want to run Code::DRY's own tests.

=back


=head1 SUBROUTINES


=head2 C<scan_directories($minlength, $ignoreContent, $regexAccept, $regexIgnore, @array_of_pathnames_of_directories)>

Scans the given directories in C<@array_of_pathnames_of_directories> recursively for file names 
matching the regexp C<$regexAccept>, if it is defined.
If those file names also do B<not> match against the regexp C<$regexIgnore> 
(unless C<$regexIgnore> is undefined) they are included in the analysis.

If C<$regexAccept> and C<$regexIgnore> both are C<undef>, all file names will be considered for analysis.

If either of C<$regexAccept> and C<$regexIgnore> is not a ref of type 'Regexp', 
it is expected to be a pattern string that will be converted into a regexp with C<qr{}xms>.

The parameter C<$ignoreContent> can be used to avoid duplication reports for content matching this regex.
If C<$ignoreContent> is not a ref of type 'Regexp', it is expected to be a pattern string that 
will be converted into a regexp with C<qr{}xms>.

The parameter C<$minlength> is interpreted in units of lines when being positive.
Otherwise its absolute value is interpreted in units of bytes.

All repetitions with a minimum length of C<$minlength> will be reported by the C<report> callback function.


=head2 C<find_duplicates_in($minlength, $ignoreContent, @array_of_pathnames_of_files)>

Reads files for the given file names composing a long string, which is then analysed for repetitions.

The parameter C<$minlength> is interpreted in units of lines when being positive.
Otherwise its absolute value is interpreted in units of bytes.

The parameter C<$ignoreContent> can be used to avoid duplication reports for content matching this regex.
If C<$ignoreContent> is not a ref of type 'Regexp', it is expected to be a pattern string that 
will be converted into a regexp with C<qr{}xms>.

All repetitions with a minimum length of C<$minlength> will be reported by the C<report> callback function.


=head2 C<set_reporter(sub{ CODE BLOCK })>

Set custom code to report duplicates of a code fragment. The callback is invoked with 
position information for the copies found during analysis.

The supplied code has to accept two scalars and an array reference. 

The first parameter is the required minimum length of duplicates to be reported.

The second parameter contains a string describing the units for minimum length ('lines' or 'bytes').

The referenced array (third parameter) contains one entry with an anonymous array reference for each copy found.
Copies are reported in the order of the processing of the files and then in the order of positions.
Each copy is represented by this position information as an array entry:

=over

=item 1. filename

=item 2. line number at start of copy (starting with 1). This is the line number of the first line completely contained in the copy.

=item 3. line number at end of copy. This is the line number of the last line completely contained in the copy.

=item 4. offset from start of file at start of copy (starting with 0) clipped to the next completely contained line.

=item 5. offset from start of file at end of copy clipped to the last completely contained line.

=item 6. offset from start of file at start of copy (starting with 0) (used in 'bytes' mode)

=item 7. offset from start of file at end of copy (used in 'bytes' mode)

=back


The default reporter is like this:

    XXX insert code when stable


=head2 C<set_default_reporter>

Resets the reporter callback function to the default shown above.


=head2 C<report_dupes($minlength, $copies, $length, $index_in_suffix_and_lcp_array)>

This function builds a data structure with position information for the duplication copies 
described by the input parameters. The entries in the suffix array from 
C<$index_in_suffix_and_lcp_array> to C<$index_in_suffix_and_lcp_array + $copies -1>
will give the offsets in the string where the copies start. Each has a length of 
C<$length> characters. With these values file names and line numbers are retrieved and 
stored in the structure.
Then the reporter callback function is called with the minimum length of this scan C<$minlength> and this structure.
See also function L<set_reporter()>.


=head2 C<enter_files($ref_to_array_of_pathnames_of_files)>

Reads the files given by the pathnames. Any files with length zero are skipped (and removed from the filename array).
Offset arrays for file and line end positions are built.
The content of all files is concatenated. Currently the content must not be valid Perl (but this
might change when parsing gets involved in a future release).


=head2 C<build_suffixarray_and_lcp($textstring_to_analyse)>

The XS routine calls the sais-lite function to construct the suffix and longest common 
prefix arrays for the complete string to analyse.


=head2 C<clip_lcp_to_fileboundaries(@array_with_endoffset_positions_of_files)>

The XS routine limits lcp values that cross files according to given file end positions.
The accumulated end positions have to be sorted in ascending order.
Internally a binary search is done in order to find the right file end position.
C<@Code::DRY::fileoffsets> contain the needed offset when C<enter_files> has been used before.


=head2 C<reduce_lcp_to_nonoverlapping_lengths>

The XS routine limits lcp values that overlap with the preceeding entry. 
This is necessary to avoid overlap of the reported duplicates.

=head2 C<offset2fileindex($offset)>

This function uses binary search to get the index of the respective file entry for this offset.

=head2 C<offset2filename($offset)>

This function uses binary search to get the index of the respective file entry for this offset.
It returns the filename for this entry.

=head2 C<offset2line($offset)>

This function uses binary search to get the index of the respective file entry for this offset.
Then it again uses binary search to get the max offset of the respective line and
returns the line number for this entry.

=head2 C<offsetAndFileindex2line($offset, $fileindex, \$nextcompleteLine, \$lastcompleteLine)>

This function uses binary search to get the max offset of the respective line belonging 
to file C<$fileindex> and returns the line number for this entry. 

If the third parameter is defined, it is expected to be a reference to a scalar. It will be
set to the line number of the next line unless C<$offset> points to the start of a line. 
Then it will be set to the current line number.

If the fourth parameter is defined, it is expected to be a reference to a scalar. It will be
set to the line number of the previous line unless C<$offset> points to the end of a line
or there is no previous line. Then it will be set to the current line number.

=head2 C<clearData>

This function clears all resources that were used for a scan.

=head2 C<get_len_at($index)>

This XS function returns the lcp value at index C<$index> or ~0, if the index is out of range.

=head2 C<get_offset_at($index)>

This XS function returns the offset value from the suffix array at index C<$index> or ~0, if the index is out of range.

=head2 C<get_isa_at($offset)>

This XS function returns the index number from the suffix array where the C<$offset> is found or ~0, if the offset is out of range.

=head2 C<set_lcp_to_zero_for_shadowed_substrings($index)>

This XS function sets all prefix lengths to zero for those entries where the suffix is contained in another longer (or more leftward) suffix.

=head2 C<get_concatenated_text($offset, $length)>

This function returns the given text portion of the internal concatenated string at offset C<$offset> with a length of C<$length>.

=head2 C<get_line_offsets_of_fileindex($fileindex)>

This function returns the array reference of the line end offsets for the file at index C<$fileindex>.

=head2 C<get_next_ranked_index> not yet implemented

This XS function returns the next index number of the sorted lcp values or ~0, if there are no more entries left.

=head2 C<reset_rank_iterator> not yet implemented

This XS function resets the iterator of the sorted lcp values.

=head2 C<get_size>

This XS function returns the size of string (in 8-bit characters) used by the C<build_suffixarray_and_lcp> function.

=head2 C<get_lcp>

This XS function returns a reference of a copy of the lcp array from the C<build_suffixarray_and_lcp> function.

=head2 C<get_sa>

This XS function returns a reference of a copy of the suffix array from the C<build_suffixarray_and_lcp> function.

=head2 C<__get_text>

Internal function

=head2 C<__free_all>

Internal function



=head1 DIAGNOSTICS

=head2 Output messages

Duplicates are reported (as per default reporter) in the following format:

	1 duplicate(s) found with a length of 8 (>= 2 lines) and 78 bytes reduced to complete lines:
	1.  File: t/00_lowlevel.t in lines 57..64 (offsets 1467..1544)
	2.  File: t/00_lowlevel.t in lines 74..81 (offsets 1865..1942)
	=================
	...<duplicated content>
	=================


=head2 Error messages

This module can die with the following error messages:

=over

=item * "cannot open file $file: $!\n";

The opening of a file for read access failed.

=item * "Error building suffix array:$!\n"

The XS code could not allocate enough memory for the combined file content.

=back

=head1 BUGS AND LIMITATIONS

Probably some, it is new code :-).

Currently the underlying XS code operates with 8-bit characters only.
With Perl source code that seems to work on most texts.

The full extent of masking out submatches has not yet beem implemented.

To report bugs, go to
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Code-DRYE<gt>
or send mail to E<lt>bug-Code-DRY#rt.cpan.orgE<gt>


=head1 EXPORTED SYMBOLS

None by default.

=head1 ACKNOWLEDGEMENTS

Thanks to Yuta Mori for providing the C code for the construction of the suffix array
(sais-lite) and to Johannes Fischer for extending it with the efficient
generation of lcp values. I am grateful that both authors provided their work as open
source.

Some code and ideas cribbed from:

Ovid's blog L<http://blogs.perl.org/users/ovid/2012/12/finding-duplicate-code-in-perl.html>

=head1 SEE ALSO

=over

=item * Suffix array construction algorithm: G. Nong, S. Zhang, and W. H. Chan. 'Linear suffix array construction by almost pure induced-sorting', In Proc. DCC, pages 193--202. IEEE Press, 2009

=item * LCP construction algorithm: Johannes Fischer, 'Inducing the LCP-Array' L<http://arxiv.org/abs/1101.3448>

=item * C code: Yuta Mori, sais-lite 2.4.1 at L<http://sites.google.com/site/yuta256/sais>

=item * C code: Johannes Fischer, sais-lite-lcp-master at L<https://github.com/elventear/sais-lite-lcp>

=item * Perl code: Ovid, blog at L<http://blogs.perl.org/users/ovid/2012/12/finding-duplicate-code-in-perl.html>, code at L<https://gist.github.com/Ovid/4231878#file-find_duplicate_code-pl>

=item * Theory: Dan Gusfield, 'Algorithms on String, Trees, and Sequences', Cambridge University Press, 1999, ISBN 978-0521670357

=back

=head1 AUTHOR

Heiko Eiﬂfeldt, E<lt>hexcoder@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014,2019 by hexcoder

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

For files salcpis.[ch] from the sais-lite-lcp-master package:

=over

=item Copyright (c) 2008-2010 Yuta Mori All Rights Reserved.

=item Copyright (c) 2011 Johannes Fischer All Rights Reserved.

=back


=cut
