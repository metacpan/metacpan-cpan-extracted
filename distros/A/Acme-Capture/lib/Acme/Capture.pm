package Acme::Capture;
$Acme::Capture::VERSION = '0.01';
use strict;
use warnings;

use Exporter ();
use Capture::Tiny;

#--------------------------------------------------------------------------#
# create API subroutines and export them
# [do STDOUT flag, do STDERR flag, do merge flag, do tee flag]
#--------------------------------------------------------------------------#

my %api = (
  capture         => [1,1,0,0],
  capture_stdout  => [1,0,0,0],
  capture_stderr  => [0,1,0,0],
  capture_merged  => [1,1,1,0],
  tee             => [1,1,0,1],
  tee_stdout      => [1,0,0,1],
  tee_stderr      => [0,1,0,1],
  tee_merged      => [1,1,1,1],
);

for my $sub (keys %api) {
    my $args = join q{, }, @{$api{$sub}};
    eval "sub $sub(&;@) { unshift \@_, $args; goto \\&Capture::Tiny::_capture_tee; }"; ## no critic
}

{
    no warnings 'redefine';
    eval <<'EOT' or die "Can't redefine _relayer() ==> $@";
    sub Capture::Tiny::_relayer {
        my ($fh, $layers) = @_;

        my $unix_utf8_crlf = @$layers > 4
          && $layers->[0] eq 'unix'
          && $layers->[1] eq 'crlf'
          && $layers->[2] eq 'utf8'
          && $layers->[3] eq 'unix'
          && $layers->[4] eq 'encoding(utf8)' ? 1 : 0;

        if ($unix_utf8_crlf and $^O eq 'MSWin32') {
            binmode($fh, ':unix:encoding(utf8):crlf');
        }
        else {
            # _debug("# requested layers (@{$layers}) for @{[fileno $fh]}\n");
            my %seen = ( unix => 1, perlio => 1 ); # filter these out
            my @unique = grep { !$seen{$_}++ } @$layers;
            # _debug("# applying unique layers (@unique) to @{[fileno $fh]}\n");
            binmode($fh, join(":", ":raw", @unique));
        }
    };

    1;
EOT
}

our @ISA = qw/Exporter/;
our @EXPORT_OK = keys %api;
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

1;

__END__

=head1 NAME

Acme::Capture - Use Capture::Tiny with a different _relayer() method

=head1 SYNOPSIS

    use Acme::Capture qw(capture_merged);

    my $merged = capture_merged {
        print {*STDERR} "This is STDERR\n";
        print "==>[ABCDEFG]\n";
        system('dir C:\\');
        system('uvwxyz');
    };

    print "---------------------------\n";
    print "merged = $merged\n";
    print "\n";

=head1 AUTHOR

Klaus Eichner, January 2016

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Klaus Eichner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
