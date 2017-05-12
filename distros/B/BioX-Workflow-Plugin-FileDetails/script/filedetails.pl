#!/usr/bin/env perl
package My::App::Options;
use Moose;

with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';
with 'MooseX::SimpleConfig';

has 'check_dir' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q(Directory to check for files.)
);

has 'print_dir' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0,
    documentation =>
        q(Create a directory for metadata, and write details to file self->check_dir/meta/file.meta Defaults to yes.)
);

has 'print_stdout' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 1,
    documentation => q(Print metadata to STDOUT. Default is yes.),
);

has 'line_count' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 1,
    documentation => 'q(Get a line count per file)',
    predicate     => 'has_line_count',
);

package My::App::Run;
use My::App::Options;
use File::Details;
use File::Find::Rule;
use File::Spec;
use Time::localtime;
use File::stat;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Number::Bytes::Human qw(format_bytes parse_bytes);

my $self = My::App::Options->new_with_options();

my @files = File::Find::Rule->file()->in( $self->check_dir );

if ( $self->print_dir ) {
    make_path( $self->check_dir . "/meta" );
}

my $human = Number::Bytes::Human->new(
    bs          => 1024,
    round_style => 'round',
    precision   => 2
);

print "# Directory\n\n";
print "## " . $self->check_dir . "\n\n";

print
    "|| File || MD5 || Size (bytes) || Size (human) || File Creation Time || Last access time || Last modify time ||\n";

foreach my $file (@files) {
    $file = File::Spec->rel2abs($file);
    my $basename = basename($file);
    my $details = File::Details->new($file);

    my ( $hash, $size, $ctime, $actime, $mtime ) = (
        $details->hash, $details->size,
        ctime( stat($file)->ctime ),
        ctime( stat($file)->atime ),
        ctime( stat($file)->mtime )
    );

    my $hsize = $human->format($size);

    my $info = <<EOF;
| $basename | $hash | $size | $hsize | $ctime | $actime | $mtime |
EOF

    if ( $self->has_line_count ) {
        my $line_count;
        if ( $file =~ m/\.gz$/ ) {
            $line_count = `zcat $file |wc -l`;
        }
        else {
            $line_count = `wc -l < $file`;
        }
        $info .= <<EOF;
 $line_count|
EOF
        $info .= "\n";

    }

    $DB::single = 2;
    if ( $self->print_stdout ) {
        print $info;
    }
    $DB::single = 2;

    if ( $self->print_dir ) {
        my $basename = fileparse($file);
        open( my $out, ">" . $self->check_dir . "/meta/$basename.meta" );
        print $out $info;
    }
}
