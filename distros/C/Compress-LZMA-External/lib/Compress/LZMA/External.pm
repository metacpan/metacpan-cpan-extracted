package Compress::LZMA::External;
use strict;
use warnings;
use File::Spec::Functions;
use File::Temp qw(tempfile);
use IO::File;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(compress_fast compress compress_best decompress);
our $VERSION   = '0.37';

sub compress_fast ($) {
    my $data = shift;
    return _call( $data, 'data.txt', 'lzma -c --fast -f' );
}

sub compress ($) {
    my $data = shift;
    return _call( $data, 'data.txt', 'lzma -c -f' );
}

sub compress_best ($) {
    my $data = shift;
    return _call( $data, 'data.txt', 'lzma -c --best -f' );
}

sub decompress ($) {
    my $data = shift;
    return _call( $data, 'data.txt.lzma', 'lzma -c -d -f' );
}

sub _call {
    my ( $in, $filename, $command ) = @_;
    my $dir  = File::Temp->newdir();
    my $path = catfile( $dir, $filename );
    my $fh   = IO::File->new("> $path") || die "Error opening $path: $!";
    $fh->print($in) || die "Error writing to $path: $!";
    $fh->close || die "Error closing $path: $!";
    $fh = IO::File->new("$command $path |") || die "Error opening lzma: $!";
    my $out;

    while ( !$fh->eof ) {
        $out .= <$fh>;
    }
    unlink($filename);
    return $out;
}

1;

__END__

=head1 NAME

Compress::LZMA::External - Compress and decompress using LZMA

=head1 SYNOPSIS

  use Compress::LZMA::External qw(compress decompress);
  my $compressed = compress($raw_data);
  my $decompressed = decompress($compressed_data);

  # you can also export these:
  my $compressed_fast = compress_fast($raw_data);
  my $compressed_best = compress_best($raw_data);

=head1 DESCRIPTION

The Lempel-Ziv-Markov chain-Algorithm (LZMA) is an data compression
algorithm. It compresses very well (better than gzip and bzip2),
compresses very slowly (much slower than bzip2) but decompresses
relatively quickly.

This module is an interface to the lzma command-line program,
available under Ubuntu with 'sudo apt-get install lzma'.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2008-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
