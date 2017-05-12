package Alvis::Utils;

require Exporter;
use strict;
use open ':utf8';
use File::Find;
use Cwd 'abs_path';
use Carp;

our @ISA = qw(Exporter);

#our @EXPORT    = qw(open_file get_files);
our @EXPORT_OK = qw( open_file get_files absolutize_path );
our $VERSION   = 0.01;

#############################################################################
# Opens file and returns its filehandle.
#
# open_file('my_file');
# open_file('file' =>'my_file', 'die' => '0', 'msg' => 'message');
#
# Returns undef if file openning fails and 'die' => '0'
#
sub open_file
{
    my %param = ('die' => 1);

    if (!defined($_[1])) {
        $param{'file'} = shift;
    } else {
        my %x = @_;
        %param = map {$_ => $x{$_}} keys %x;
    }

    my $filename = $param{'file'};
    croak "Filename to open is not defined" if (!defined($param{'file'}));

    $param{'msg'} = "Cannot open file '$filename'"
      if (!defined($param{'msg'}));

    my $is_failed = 0;
    local *FH;

    if ($filename =~ /\.bz2$/) {
        open(FH, "bzcat $filename |")
          or _open_file_failed(\$is_failed, %param);
    } elsif ($filename =~ /\.gz$/) {
        open(FH, "zcat $filename |")
          or _open_file_failed(\$is_failed, %param);
    } else {
        open(FH, $filename) or _open_file_failed(\$is_failed, %param);
    }

    return ($is_failed ? undef: *FH);
}

############################################################################
sub _open_file_failed
{
    my $is_failed = shift;
    my %param     = @_;
    croak "$param{'msg'}: $!" if ($param{'die'});
    $$is_failed = 1;
}

############################################################################
# Returns all files in given directory recursively.
sub get_files
{
    my ($in_dir, $filter) = @_;
    $in_dir = abs_path($in_dir);

    my @files;
    find(
        {
            wanted => sub {
                return unless (-f $File::Find::name);
                return if (defined($filter) && $File::Find::name !~ /$filter/);
                push @files, $File::Find::name;
            },
        },
        $in_dir
    );
    return @files;
}

############################################################################
# Returns absolute path for given relative path; or undef if
# path does not exist
sub absolutize_path
{
    my $path = shift;
    eval {$path = abs_path($path)};
    return -e $path ? $path : undef;
}

############################################################################
return 1;
