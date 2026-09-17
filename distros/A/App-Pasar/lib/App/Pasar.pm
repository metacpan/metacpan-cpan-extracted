use v5.36;
package App::Pasar 0.01;
use Archive::Asar ();
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt);

sub usage($err) {
    print { $err ? \*STDERR : \*STDOUT } <<~"_EOT_";
        Usage: $0 OPTION... FILE [DIRECTORY]
        Extract data from Electron ASAR archive files.

          -l, --list              list contents of archive FILE
          -x, --extract           recursively extract contents of FILE to DIRECTORY
          -u DIR, --unpacked=DIR  read archive files marked "unpacked" from DIR
                                  instead; if DIR is the empty string, "unpacked"
                                  files are skipped instead
          -h, --help              display this help and exit

        Either -l/--list or -x/--extract must be given.
        _EOT_
    exit($err ? 1 : 0);
}

sub list($asar) {
    my sub esc($x, $harder) {
        $x =~ s{([/\\])}{\\$1}g if $harder;
        $x =~ s{([\x00-\x1f])}{ sprintf '\\x%02x', ord $1 }eg;
        $x
    }

    my sub get_node($path, $node) {
        for my $p (@$path) {
            $node = $node->{files}{$p} // return undef;
        }
        $node
    }

    my $index = $asar->index_raw;

    my $listing = '';
    my @stack = [];
    while (@stack) {
        my $path = pop @stack;
        my $node = get_node $path, $index;

        my $name = join '/', map esc($_, 1), @$path;
        if (exists $node->{link}) {
            $listing .= "LINK  $name -> " . esc($node->{link}, 0) . "\n";
        } elsif (exists $node->{files}) {
            push @stack, map [@$path, $_], sort { $b cmp $a } keys $node->{files}->%*;
            my $unpacked = $node->{unpacked} ? '  (unpacked)' : '';
            $listing .= "DIR   $name$unpacked\n" if @$path;
        } else {
            my $size = exists $node->{size} ? '  ' . (0 + $node->{size}) : '';
            my $unpacked = $node->{unpacked} ? '  (unpacked)' : '';
            $listing .= "FILE  $name$size$unpacked\n";
        }
    }

    $listing
}

sub main(@args) {
    GetOptionsFromArray(
        \@args,
        'list|l'       => \my $opt_list,
        'extract|x'    => \my $opt_extract,
        'unpacked|u=s' => \my $opt_unpacked,
        'help|h'       => sub (@) { usage 0 },
    ) or usage 1;
    $opt_list || $opt_extract or die "$0: either --list or --extract must be given\n";

    @args or die "$0: no input file\n";
    my $asarfile = shift @args;

    my $asar = Archive::Asar->new_from_file($asarfile);

    print list($asar) if $opt_list;

    if ($opt_extract) {
        my $outdir = @args ? shift @args : '.';
        my %opts;
        if (defined $opt_unpacked) {
            $opts{unpacked_dir} = length $opt_unpacked ? $opt_unpacked : undef;
        } elsif (-d "$asarfile.unpacked") {
            $opts{unpacked_dir} = "$asarfile.unpacked";
        }

        $asar->extract_to($outdir, \%opts);
    }
}

1
__END__

=encoding utf-8

=head1 NAME

App::Pasar - pasar internals

=head1 DESCRIPTION

No user serviceable parts inside.

=head1 SEE ALSO

L<pasar(1)>, L<Archive::Asar>

=begin :README

=head1 INSTALLATION

To install this script, run the following commands:

=for highlighter language=sh

    perl Makefile.PL
    make
    make test
    make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this script with the
perldoc command.

    perldoc pasar

You can also look for information at:

=over

=item *

MetaCPAN: L<https://metacpan.org/pod/pasar>

=item *

The source repository on Codeberg:
L<https://codeberg.org/mauke/App-Pasar>

=item *

The script's bug tracker: L<https://codeberg.org/mauke/App-Pasar/issues>

=back

=end :README

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU General Public License|https://www.gnu.org/licenses/gpl-3.0.html>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
