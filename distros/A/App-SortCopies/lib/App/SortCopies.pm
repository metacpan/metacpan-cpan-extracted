package App::SortCopies;

use 5.008003;
use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path);
use Digest::MD5;
use File::Copy qw(move);
use File::Basename;
use feature 'say';

=head1 NAME

App::SortCopies - The copy sorter! (What did you expect?)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

sub run {
    my $src = shift @ARGV or die "Usage: sortcopies dir\n";
    die "'$src' is not readable" unless -d $src and -r $src;

    my $dup_dir = File::Spec->catdir($src, "copies");
    make_path($dup_dir) unless -d $dup_dir;

    opendir(my $d, $src) or die $!;
    my @unsorted_stuff = grep {
        -f File::Spec->catfile($src, $_)
    } readdir($d);
    closedir($d);

    my %fried;

    for my $file (@unsorted_stuff) {
        my $path = File::Spec->catfile($src, $file);

        open(my $potato, '<', $path) or do {
            warn "I couldn't open '$file'\n";
            next;
        };

        binmode($potato);
        my $hash = Digest::MD5->new->addfile($potato)->hexdigest;
        close($potato);

        if ($fried{$hash}) {
            my $dest = File::Spec->catfile($dup_dir, $file);
            my $i = 1;

            my ($name, undef, $ext) = fileparse($file, qr/\.[^.]*/);

            $dest = File::Spec->catfile(
                $dup_dir,
                "${name}_$i$ext"
            ) while -e $dest and $i++;

            move($path, $dest) or warn $!;
            say "Duplicate $file is moved to $dest";
        }
        else {
            $fried{$hash} = 1;
        }
    }

    say "All copies in $src have been moved to $dup_dir!";
}

1;

=head1 SYNOPSIS

This sorts a directory, in a non-recursive way.

Copies of files are moved to a ./copies folder created in the directory being sorted

    sortcopies ~/path/to/dir_with_dupes


=head1 AUTHOR

Semandi <semandi@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-sortcopies at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-SortCopies>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::SortCopies

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-SortCopies>

=item * Search CPAN

L<https://metacpan.org/release/App-SortCopies>

=back

=head1 ACKNOWLEDGEMENTS

To all the foxes of the world...

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Semandi <semandi@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of App::SortCopies
