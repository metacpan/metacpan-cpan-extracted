package ClarID::Tools::Command::qrcode;
use strict;
use warnings;
use feature 'say';
use Moo;
use MooX::Options
  auto_help        => 1,
  auto_version     => 1,
  usage            => 'USAGE',
  config_from_hash => {};
use Types::Standard qw(Enum Str);
use Text::CSV_XS;
use File::Path       qw(make_path);
use Carp             qw(croak);
# Tell App::Cmd this is a command
use App::Cmd::Setup -command;
use namespace::autoclean;

# CLI options
# NB: Invalid parameter values (e.g., --format=foo) trigger App::Cmd usage/help
# This hides the detailed Types::Standard error  
# Fix by overriding usage_error/options_usage  
option 'action' => (
  is       => 'ro',
  format   => 's',
  isa      => Enum[qw/encode decode/],
  required => 1,
  doc      => 'encode | decode',
);

option 'input' => (
  is       => 'ro',
  format   => 's',
  isa      => Str,
  required => 1,
  doc      => 'CSV file (encode) or directory of PNGs, or single PNG file (decode)',
);

option 'column' => (
  is     => 'ro',
  format => 's',
  isa    => Str,
  doc    => 'Column name to read (defaults to clar_id or stub_id, encode only)',
);

option 'outdir' => (
  is      => 'ro',
  format  => 's',
  isa     => Str,
  default => sub { 'qrcodes' },
  doc     => 'Where to write PNGs (encode only)',
);

option 'outfile' => (
  is      => 'ro',
  format  => 's',
  isa     => Str,
  default => sub { 'decoded.csv' },
  doc     => 'Where to write CSV (decode directory mode only)',
);

option 'sep' => (
  is      => 'ro',
  format  => 's',
  isa     => Str,
  default => sub { ',' },
  doc     => 'CSV separator',
);

option 'size' => (
  is      => 'ro',
  format  => 'i',
  isa     => Str,
  default => sub { 3 },
  doc     => 'module size for qrencode (-s flag)',
);

sub execute {
    my $self = shift;
    if ($self->action eq 'encode') {
        $self->_run_encode;
    } else {
        $self->_run_decode;
    }
}

sub _run_encode {
    my $self = shift;

    # Check for qrencode
    system("which qrencode >/dev/null 2>&1") == 0
        or croak "ERROR: 'qrencode' not found in PATH";

    # Prepare output directory
    unless (-d $self->outdir) {
        make_path($self->outdir)
            or croak "ERROR: cannot create directory '$self->{outdir}'";
    }

    # Open CSV file
    my $csv = Text::CSV_XS->new({ sep_char => $self->sep, binary => 1, auto_diag => 1 });
    open my $fh, '<', $self->input
        or croak "ERROR: Cannot open '$self->input': $!";

    # Read header
    my $hdr_ref = $csv->getline($fh)
        or croak "ERROR: CSV is empty";
    my @hdr = @$hdr_ref;
    my %idx = map { $hdr[$_] => $_ } 0..$#hdr;

    # Determine column
    my $col = $self->column
        || (exists $idx{clar_id} ? 'clar_id'
        : exists $idx{stub_id}  ? 'stub_id'
        : croak "ERROR: No --column and neither clar_id nor stub_id in header");
    croak "ERROR: Column '$col' not found" unless exists $idx{$col};

    say "Encoding column '$col' into PNG files in directory '$self->{outdir}'";

    # Process rows
    while (my $row = $csv->getline($fh)) {
        my $val = $row->[$idx{$col}] // '';
        next unless length $val;
        (my $safe = $val) =~ s/[^A-Za-z0-9_-]/_/g;
        my $png = "$self->{outdir}/$safe.png";
        system("qrencode", "-s", $self->size, "-o", $png, $val) == 0
            or warn "WARNING: qrencode failed for value '$val'" and next;
        say "  - $val -> $png";
    }
    close $fh;
}

sub _run_decode {
    my $self = shift;

    # Check for zbarimg
    system("which zbarimg >/dev/null 2>&1") == 0
        or croak "ERROR: 'zbarimg' not found in PATH";

    # Single-file decode mode
    if (-f $self->input && $self->input =~ /\.png$/i) {
        my $file = $self->input;
        chomp(my $decoded = qx(zbarimg --raw "$file" 2>/dev/null));
        die "ERROR: no QR code found in '$file'\n" unless length $decoded;
        say $decoded;
        return 1;
    }

    # Directory decode mode
    my $col_name = $self->column || 'clar_id';
    opendir my $dh, $self->input
        or croak "ERROR: Cannot open directory '$self->input': $!";
    my @files = grep { /\.png$/i } readdir $dh;
    closedir $dh;

    open my $out, '>', $self->outfile
        or croak "ERROR: Cannot write to '$self->outfile': $!";
    print $out "$col_name\n";

    for my $f (@files) {
        my $path = "$self->{input}/$f";
        chomp(my $decoded = qx(zbarimg --raw "$path" 2>/dev/null));
        next unless length $decoded;
        $decoded =~ s/\r?\n//g;
        print $out "$decoded\n";
    }
    close $out;
    say "Decoded CSV written to '$self->{outfile}'";
}

1;
