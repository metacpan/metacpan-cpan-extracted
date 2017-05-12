package BioUtil::Util;

use File::Path qw/remove_tree/;
use Time::HiRes qw/time/;

require Exporter;
@ISA    = (Exporter);
@EXPORT = qw(
    getopt

    file_list_from_argv
    get_file_list

    delete_string_elements_by_indexes
    delete_array_elements_by_indexes

    extract_parameters_from_string
    get_parameters_from_file

    get_list_from_file
    get_column_data

    read_json_file
    write_json_file

    run
    run_time
    readable_second

    check_positive_integer
    mean_and_stdev

    filename_prefix
    check_all_files_exist
    check_in_out_dir
    rm_and_mkdir

    get_paired_fq_gz_file_from_dir
    get_paired_fa_gz_file_from_dir

);

use vars qw($VERSION);

use 5.010_000;
use strict;
use warnings FATAL => 'all';

use Encode qw/ encode_utf8 /;
use File::Path qw(make_path remove_tree);
use File::Find;
use File::Basename;
use JSON;

=head1 NAME

BioUtil::Util - Utilities for operation on data or file

Some great modules like BioPerl provide many robust solutions. 
However, it is not easy to install for someone in some platforms.
And for some simple task scripts, a lite module may be a good choice.
So I reinvented some wheels and added some useful utilities into this module,
hoping it would be helpful.

=head1 VERSION

Version 2015.0228

=cut

our $VERSION = 2015.0228;

=head1 EXPORT
    getopt

    file_list_from_argv
    get_file_list

    delete_string_elements_by_indexes
    delete_array_elements_by_indexes

    extract_parameters_from_string
    get_parameters_from_file

    get_list_from_file
    get_column_data

    read_json_file
    write_json_file

    run
    run_time
    readable_second

    check_positive_integer
    mean_and_stdev
    
    filename_prefix
    check_all_files_exist
    check_in_out_dir 
    rm_and_mkdir

    get_paired_fq_gz_file_from_dir
    get_paired_fa_gz_file_from_dir

=head1 SYNOPSIS

  use BioUtil::Util;


=head1 SUBROUTINES/METHODS

=head2 getopt

getopt FOR ME

Example
    -a b -c t tt -d bb -dbtype asdfafd -test
    
    -a: b
    -c: ARRAY(0xee25e8)
    -d: bb
    -dbtype: asdfafd
    -infmt: fasta
    -test: 1

=cut

sub getopt {
    my ( $opts, $list ) = @_;
    return "\$opts should be ref of hash, and \$list should be ref of list\n"
        unless ref $opts eq ref {}
        and ref $list eq ref [];
    my ( $o, $opt ) = (undef) x 2;
    while (@$list) {
        $o = shift @$list;
        if ( $o =~ /^\-/ ) {
            $opt = $o;
            $$opts{$opt} = 'http:shenwei.me' unless exists $$opts{$opt};
        }
        else {
            if ( $$opts{$opt} ne 'http:shenwei.me' ) {
                $$opts{$opt} = [ $$opts{$opt} ]
                    if ref $$opts{$opt} ne ref [];
                push @{ $$opts{$opt} }, $o;
            }
            else {
                $$opts{$opt} = $o;
            }
        }
    }
    for ( keys %$opts ) { $$opts{$_} = 1 if $$opts{$_} eq 'http:shenwei.me'; }
    return $opts;
}

=head2 file_list_from_argv

Get file list from @ARGV. You should use this after parsing options!

When no arguments given, 'STDIN' will be added to 
the list, which could be further used by, e.g. FastaReader.

=cut

sub file_list_from_argv {
    my @files = ();
    for my $file (@_) {
        for my $f ( glob $file ) {
            push @files, $f;
        }
    }
    if ( @files == 0 ) {
        push @files, 'STDIN';
    }
    return @files;
}

=head2 get_file_list

Find files/directories with custom filter, 
max serach depth could be specified.

Example (searching perl scripts)

    my $dir   = "~";
    my $depth = 2;

    my $list = get_file_list(
        $dir,
        sub {
            if ( -d or /^\./i ) {  # ignore configuration file and folders
                return 0;
            }
            if (/\.pm/i or /\.pl/i) {
                return 1;
            }
            return 0;
        },
        $depth
    );
    print "$_\n" for @$list;

=cut

sub get_file_list {

    # filter is a subroutine to filter a file
    my ( $dir, $filter, $depth ) = @_;
    $dir =~ s/\/+/\//g;
    $dir =~ s/\/$//;

    $depth = 1 << 30 unless defined $depth;
    unless ( $depth =~ /^\d+$/ and $depth > 0 ) {
        warn "depth should be positive integer\n";
        return [];
    }

    # print "$dir\n";
    my $depth0 = $dir =~ tr/\//\//;

    my $files  = [];
    my $wanted = sub {
        return if /^\.+$/;
        return if $_ eq $dir;

        # check depth
        return if $File::Find::name =~ tr/\//\// - $depth0 > $depth;

        if ( &$filter($_) ) {
            push @$files, $File::Find::name;
        }
    };

    find( $wanted, ($dir) );

    return $files;
}

=head2 delete_string_elements_by_indexes

Delete string elements by indexes, it uses delete_array_elements_by_indexes

=cut

sub delete_string_elements_by_indexes {
    my ( $str, $ids ) = @_;
    my $t = '';
    unless ( ref $str eq ref \$t and ref $ids eq ref [] ) {
        die "both arguments should be array reference\n";
    }
    my @bytes = split //, $$str;
    return join "", @{ delete_array_elements_by_indexes( \@bytes, $ids ) };
}

=head2 delete_array_elements_by_indexes

Delete array elements by given indexes.

Example:

    @list = qw(a b c d e f);
    @idx = (1, 2, 4);
    $list2 = delete_array_elements_by_indexes(\@list, \@idx);
    print "@$list2\n"; # result: a, d, f

=cut

sub delete_array_elements_by_indexes {
    my ( $array, $ids ) = @_;
    unless ( ref $array eq ref [] and ref $ids eq ref [] ) {
        die "both arguments should be array reference\n";
    }
    my %omitted = map { $_ => 1 } @$ids;
    my @newarray = ();
    for my $i ( 0 .. ( scalar(@$array) - 1 ) ) {
        next if exists $omitted{$i};
        push @newarray, $$array[$i];
    }
    return \@newarray;
}

=head2 extract_parameters_from_string

Extract parameters from string.

The regular expression is 
    
    /([\w\d\_\-\.]+)\s*=\s*([^\=;]*)[\s;]*/

Example:

    # bad format, but could also be parsed
    # my $s = " s = b; a=test; b_c=12 3; a.b =; b
    # = asdf
    # sd; ads-f = 12313";

    # recommended
    my $s = "key1=abcde; key2=123; conf.a=file; conf.b=12; ";

    my $pa = extract_parameters_from_string($s);
    print "=$_:$$p{$_}=\n" for sort keys %$pa;

=cut

sub extract_parameters_from_string {
    my ($s) = @_;
    my $parameters = {};
    while ( $s =~ /([\w\d\_\-\.]+)\s*=\s*([^\=;]*)[\s;]*/gm ) {
        warn "$1 was defined more than once\n" if defined $$parameters{$1};
        $$parameters{$1} = $2;
    }
    return $parameters;
}

=head2 get_parameters_from_file

Get parameters from a file.
Comments start with # are allowed in file.

Example:
    
    my $pa = get_parameters_from_file("d.txt");
    print "$_: $$pa{$_}\n" for sort keys %$pa;

For a file with content:

    # cell phone 
    apple = 1 # note

    nokia = 2 #

output is:
    
    apple: 1
    nokia: 2

=cut

sub get_parameters_from_file {
    my ($file) = @_;
    my $parameters = {};
    open my $fh, $file or die "fail to open file $file\n";
    while (<$fh>) {
        s/^\s+|\s+$//g;
        next if $_ eq ''    # blank line
            or /^#/;        # annotation
        s/#.*//g;           # delete annotation

        next unless /([\w\d\_\-\.]+)\s*=\s*(.+)/;
        $$parameters{$1} = $2;
    }
    close $fh;
    return $parameters;
}

=head2 get_list_from_file

Get list from a file.
Comments start with # are allowed in file.

Example:
    
    my $list = get_list_from_file("d.txt");
    print "$_\n" for @$list;

For a file with content:

    # cell phone 
    apple # note

    nokia

output is:
    
    apple
    nokia

=cut

sub get_list_from_file {
    my ($file) = @_;
    open my $fh, "<", $file or die "fail to open file $file\n";
    my @list = ();
    while (<$fh>) {
        s/\r?\n//g;
        s/^\s+|\s+$//g;
        next if $_ eq ''    # blank line
            or /^#/;        # annotation
        s/#.*//g;           # delete annotation

        push @list, $_;
    }
    close $fh;
    return \@list;
}

=head2 get_column_data

Get one column of a file.

Example:

    my $list = get_column_data("d.txt", 2);
    print "$_\n" for @$list;

=cut

sub get_column_data {
    my ( $file, $column, $delimiter ) = @_;
    unless ( $column =~ /^(\d+)$/ and $column > 0 ) {
        warn "column number ($column) should be positive integer\n";
        $column = 1;
    }
    $delimiter = "\t" unless defined $delimiter;

    open my $fh, "<", $file or die "failed to open file: $file\n";
    my @linedata = ();
    my @data     = ();
    my $n        = 0;
    while (<$fh>) {
        s/\r?\n//;
        next if /^\s*#/;
        @linedata = split /$delimiter/, $_;
        $n = scalar @linedata;
        next unless $n > 0;

        if ( $column > $n ) {
            die
                "number of columns of this line ($n) is less than given column number ($column)\n$_";
        }

        push @data, $linedata[ $column - 1 ];
    }
    close $fh;

    return \@data;
}

=head2 read_json_file

Read json file and decode it into a hash ref.

Example:

    my $hashref = read_json_file($file);

=cut

sub read_json_file {
    my ($file) = @_;
    open my $fh, "<:encoding(utf8)", $file
        or die "fail to open json file: $file\n";
    my $text;
    while (<$fh>) {
        s/\s*#+.*\r?\n?//g;    # remove annotation
        $text .= $1 if / *(.+)/;
    }
    close $fh;
    my $hash = decode_json($text);
    return $hash;
}

=head2 write_json_file

Write a hash ref into a file.

Example:
    
    my $hashref = { "a" => 1, "b" => 2 };
    write_json_file($hashref, $file);

=cut

sub write_json_file {
    my ( $hash, $file ) = @_;
    my $json = JSON->new->allow_nonref;
    my $text = $json->pretty->encode($hash);
    $text = encode_utf8($text);
    open my $fh2, ">:encoding(utf8)", $file
        or die "fail to open json file: $file\n";
    print $fh2 $text;
    close $fh2;
}

=head2 run

Run a command

Example:
    
    my $fail = run($cmd);
    die "failed to run:$cmd\n" if $fail;

=cut

sub run {
    my ($cmd) = @_;
    system($cmd);

    if ( $? == -1 ) {
        die "[ERROR] fail to run: $cmd. Command ("
            . ( split /\s+/, $cmd )[0]
            . ") not found\n";
    }
    elsif ( $? & 127 ) {
        printf STDERR "[ERROR] command died with signal %d, %s coredump\n",
            ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
    }
    else {
        # 0, ok
    }
    return $?;
}

=head2 run_time

Run a subroutine with given arguments N times, and return the mean and stdev
of time.

Example:
    
    my $read_by_record = sub {
        my ($file) = @_;
        my $next_seq = FastaReader($file);
        while ( my $fa = &$next_seq() ) {
            my ( $header, $seq ) = @$fa;
            # print ">$header\n$seq\n";
        }
    };
    
    my ($mean, $stdev) = run_time( 8, $read_by_record, $file );
    printf STDERR "\n## Compute time: %0.03f ± %0.03f s\n\n", $mean, $stdev;

=cut

sub run_time {
    my ( $n, $sub, @args ) = @_;
    die "first argument should be positive integer"
        unless $n =~ /^\d+$/ and $n > 0;

    my $t0 = 0;
    my @ts = ();
    for ( 1 .. $n ) {
        $t0 = time;
        &$sub(@args);    # call $sub
        push @ts, time - $t0;
    }

    return mean_and_stdev( \@ts );
}

=head2 readable_second

readable_second

Example:
    
    print readable_second(11312314),"\n"; # 130 day 22 hour 18 min 34 sec

=cut

sub readable_second ($) {
    my ($seconds) = @_;
    return "Positive integer need." unless $seconds =~ /^\d+$/;

    my $time            = "";
    my $has_bigger_unit = 0;

    my $days = $seconds / 86400;
    if ( $days >= 1 ) {
        $time .= ( int $days ) . " day ";
        $has_bigger_unit = 1;
    }
    $seconds = $seconds % 86400;

    my $hours = $seconds / 3600;
    if ( $hours >= 1 ) {
        $time .= ( int $hours ) . " hour ";
        $has_bigger_unit = 1;
    }
    elsif ($has_bigger_unit) { $time .= 0 . " hour "; }
    $seconds = $seconds % 3600;

    my $minutes = $seconds / 60;
    if ( $minutes >= 1 ) {
        $time .= ( int $minutes ) . " min ";
        $has_bigger_unit = 1;
    }
    elsif ($has_bigger_unit) { $time .= 0 . " min "; }
    $seconds = $seconds % 60;

    $time .= $seconds . " sec";
    return $time;
}

=head2 check_positive_integer

Check Positive Integer

Example:
    
    check_positive_integer(1);

=cut

sub check_positive_integer {
    my ($n) = @_;
    die "positive integer needed ($n given)"
        unless $n =~ /^\d+$/ and $n != 0;
}

=head2 mean_and_stdev

return mean and stdev of a list

Example:
    my @list = qq/1 2 3/;
    mean_and_stdev(\@list);

=cut
sub mean_and_stdev($) {
    my ($list) = @_;
    return ( 0, 0 ) if @$list == 0;
    my $sum = 0;
    $sum += $_ for @$list;
    my $sum_square = 0;
    $sum_square += $_ * $_ for @$list;
    my $mean     = $sum / @$list;
    my $variance = $sum_square / @$list - $mean * $mean;
    my $std      = sqrt $variance;
    return ( $mean, $std );
}

=head2 filename_prefix

Get filename prefix

Example:
    
    filename_prefix("test.fa"); # "test"
    filename_prefix("tmp");     # "tmp"

=cut

sub filename_prefix {
    my ($file) = @_;
    if ( $file =~ /(.+)\..+?$/ ) {
        return $1;
    }
    else {
        return $file;
    }
}

=head2 check_all_files_exist

    Check whether all files existed.

=cut

sub check_all_files_exist {
    my $flag = 1;
    for (@_) {
        if ( not -e $_ ) {
            return 0;
        }
    }
    return 1;
}

=head2 check_in_out_dir

Check in and $fh2 directory.

Example:
    
    check_in_out_dir("~/dir", "~/dir.out");

=cut

sub check_in_out_dir {
    my ( $in, $out ) = @_;
    die "dir $in not found."
        unless -e $in;

    die "$in is not a directory.\n"
        unless -d $in;

    $in =~ s/\/$//;
    $out =~ s/\/$//;
    die "out dir shoud be different from in dir!\n"
        if $in eq $out;
}

=head2 rm_and_mkdir

Make a directory, remove it firstly if it exists.

Example:
    
    rm_and_mkdir("out")

=cut

sub rm_and_mkdir {
    my ($dir) = @_;
    if ( -e $dir ) {
        remove_tree($dir) or die "fail to remove: $dir\n";
    }
    mkdir $dir or die "fail to mkdir: $dir\n";
}

=head2 get_paired_fq_gz_file_from_dir

Example:

    # .
    # ├── test_1.fq.gz
    # └── test_2.fq.gz
    for my $pe ( get_paired_fq_gz_file_from_dir($indir) ) {
        # test_1.fq.gz, test_1.fq.gz, test
        my ( $fqfile1, $fqfile2, $id ) = @$pe;

    }

=cut

sub get_paired_fq_gz_file_from_dir {
    my ($dir) = @_;
    my @files;
    for ( sort glob "$dir/*_1.fq.gz" ) {
        /\/?([^\/]+)_1.fq.gz/;
        my $id = $1;
        next unless -e "$dir/${id}_2.fq.gz";
        push @files, [ "$dir/${id}_1.fq.gz", "$dir/${id}_2.fq.gz", "$dir/${id}", $id ];
    }
    return @files;
}

sub get_paired_fa_gz_file_from_dir {
    my ($dir) = @_;
    my @files;
    for ( sort glob "$dir/*_1.fa.gz" ) {
        /\/?([^\/]+)_1.fa.gz/;
        my $id = $1;
        next unless -e "$dir/${id}_2.fa.gz";
        push @files, [ "$dir/${id}_1.fa.gz", "$dir/${id}_2.fa.gz", "$dir/${id}", $id ];
    }
    return @files;
}

1;
