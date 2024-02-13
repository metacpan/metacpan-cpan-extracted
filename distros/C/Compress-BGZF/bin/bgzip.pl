#!/usr/bin/perl

use 5.010001;
use strict;
use warnings;
use autodie;

use Carp;
use Getopt::Long qw/:config bundling no_auto_abbrev no_ignore_case/;
use Compress::BGZF::Reader;
use Compress::BGZF::Writer;
use List::Util qw/any/;
use Pod::Usage;

our $VERSION = 0.002;
use constant PROGRAM => 'bgzip.pl';

use constant BUFFER_SIZE => 1024**2;

my $offset      = 0;
my $use_stdout  = 0;
my $force       = 0;
my $gen_index   = 0;
my $decompress  = 0;
my $reindex     = 0;
my $remove_src  = 0;
my $comp_level  = 5;
my $return_size;
my $fn_index;

GetOptions(
    'b|offset=i'         => \$offset,
    'd|decompress'       => \$decompress,
    'c|stdout'           => \$use_stdout,
    'f|force'            => \$force,
    'i|index'            => \$gen_index,
    'r|reindex'          => \$reindex,
    'I|index-name=s'     => \$fn_index,
    'l|compress-level=i' => \$comp_level,
    's|size=i'           => \$return_size,
    'R|remove-src'       => \$remove_src,
    'h|help'             => sub{ pod2usage(-verbose => 2, -exitval => 0); },
    'v|version'          => sub{ say 'This is ',PROGRAM,' v', $VERSION; exit },
);

my $fn_in = $ARGV[0];

# check that input parameters are compatible
$decompress = 1 if ($offset || $return_size);
my $is_write = ($decompress || $reindex) ? 0 : 1;
$use_stdout = 1 if ($is_write && ! defined $fn_in); 

die "reading compressed data from STDIN not supported"
. " - please supply input filename"
    if (! $is_write && ! defined $fn_in);

die "index filename required if compressing to STDOUT"
    if ($gen_index && $use_stdout && ! $fn_index);

my $fh_in;
if (defined $fn_in) {
    open $fh_in, '<', $fn_in or die "Error reading file: $!";
}
else {
    $fh_in = \*STDIN;
}
binmode $fh_in;

if ($is_write) {

    my $fn_out = $use_stdout ? undef : $fn_in . '.gz';
    check_exists($fn_out);
    my $writer = Compress::BGZF::Writer->new($fn_out);
    $writer->set_write_eof(1);
    $writer->set_level($comp_level);

    my $buf;
    while (read $fh_in, $buf, BUFFER_SIZE) {
        $writer->add_data($buf);
    }

    $writer->finalize();

    if ($gen_index) {
        my $fn_index = $fn_index ? $fn_index : "$fn_in.gz.gzi";
        check_exists($fn_index);
        $writer->write_index( $fn_index );
    }

    unlink $fn_in if (defined $fn_in && $remove_src);

}

else {

    my $reader = Compress::BGZF::Reader->new($fn_in);
    
    if ($reindex) {

        $reader->rebuild_index;
        my $fn_index = $fn_index ? $fn_index : "$fn_in.gzi";
        check_exists($fn_index);
        $reader->write_index( $fn_index );

    }

    else {

        my $fh_out;
        my $unlink = 0;
        if ($offset || $return_size || $use_stdout) {
            $fh_out = \*STDOUT;
        }
        else {
            my $fn_out = $fn_in;
            $fn_out =~ s/\.gz// or die "Unexpected file extension (not .gz)\n";
            die "output filename will clobber input filename"
                if ($fn_out eq $fn_in);
            check_exists( $fn_out );
            open $fh_out, '>', $fn_out
                or die "Failed to open file for writing: $!\n";
        }
        binmode $fh_out;

        $reader->move_to( $offset, 0 );
        if ($return_size) {
            my $buff = $reader->read_data( $return_size );
            print {$fh_out} $buff;
            exit;
        }
        else {
            my $buff;
            print {$fh_out} $buff while ( $buff = $reader->read_data( BUFFER_SIZE ) );
        }

    }
            
} 

close $fh_in;
exit;

sub check_exists {

    my ($fn) = @_;
    return if ($force || ! defined $fn || ! -e $fn);
    local $| = 1;
    print STDERR "$fn already exists; overwrite (y/N)? ";
    chomp (my $char = <STDIN>);
    return if ($char =~ /^y(es)?$/i);
    warn "not overwriting\n";
    exit;

}

