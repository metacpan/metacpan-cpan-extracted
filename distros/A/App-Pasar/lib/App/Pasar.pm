use v5.36;
package App::Pasar 0.02;
use Archive::Asar 0.02 ();
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt);

sub version() {
    say "pasar (" . __PACKAGE__ . ") " . __PACKAGE__->VERSION;
    exit;
}

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
              --version           output version information and exit

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
        'create|c'     => \my $opt_create,
        'list|l'       => \my $opt_list,
        'extract|x'    => \my $opt_extract,
        'unpacked|u=s' => \my $opt_unpacked,
        'help|h'       => sub (@) { usage 0 },
        'version'      => sub (@) { version },
    ) or usage 1;
    $opt_create || $opt_list || $opt_extract
        or die "$0: either --create, --list, or --extract must be given\n";

    @args or die "$0: no archive name\n";
    my $asarfile = shift @args;

    my $asar;
    if ($opt_create) {
        $asar = Archive::Asar->new_empty($asarfile);
        for my $arg (@args) {
            my @path = grep $_ ne '.', split m{[/\\]+}, $arg, -1;
            if (grep $_ eq '..', @path) {
                die "$0: can't embed paths containing '..': $arg\n";
            }
            $asar->ingest(\@path, $arg);
        }
        $asar->write_to_file($asarfile);
    }

    if ($opt_list) {
        $asar //= Archive::Asar->new_from_file($asarfile);
        print list($asar);
    }

    if ($opt_extract) {
        $asar //= Archive::Asar->new_from_file($asarfile);
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

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU General Public License|https://www.gnu.org/licenses/gpl-3.0.html>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
