package CTK::Command; # $Id: Command.pm 267 2019-05-21 08:23:33Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Command - Utilities to extend common UNIX commands

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    perl -MCTK::Command -e crlf -- build/conf
    perl -MCTK::Command -e fsplit -- 3 src "file.txt" dst "[FILE].[PART]"
    perl -MCTK::Command -e fjoin -- src "file.*" dst join.txt

=head1 DESCRIPTION

Utilities to extend common UNIX commands

The module is used to extend common UNIX commands. In all cases the
functions work from @ARGV rather than taking arguments. This makes
them easier to deal with in Makefiles. Call them like this:

    perl -MCTK::Command -e some_command -- some files to work on

All filenames with * and ? will be glob expanded

=head1 FUNCTIONS

Shared functions

=head2 crlf

    perl -MCTK::Command -e crlf -- build/conf

Converts DOS and OS/2 linefeeds to Unix style recursively.

Original see in package L<ExtUtils::Command/"dos2unix">

=head2 fsplit

    perl -MCTK::Command -e fsplit -- 3 src "file.txt" dst "[FILE].[PART]"

Split file to parts

Arguments (in order):

=over 8

=item lines

How many lines

=item dirsrc

Source direcoty

=item file

File name or glob-mask

=item dirdst

Destination directory for parted files

=item format

Format

=back

See L<CTK::Plugin::File/"fsplit">

=head2 fjoin

perl -MCTK::Command -e fjoin -- src "file.*" dst join.txt

Joins files to one big file

Arguments (in order):

=over 8

=item dirsrc

Source direcoty

=item mask

File names as glob-mask

=item dirdst

Destination directory for result file

=item fileout

Name of output file

=back

See L<CTK::Plugin::File/"fjoin">

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin::File>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw($VERSION @EXPORT);
$VERSION = 1.03;

use base qw /Exporter/;
@EXPORT = qw(
        fsplit fjoin crlf
    );

use CTK;
use CTK::Util qw/file_lf_normalize/;
use File::Find;
use File::Spec;

# Original in package ExtUtils::Command
sub _expand_wildcards { @ARGV = map(/[*?]/o ? glob($_) : $_, @ARGV) }

sub fsplit {
    my $lines   = shift(@ARGV) // 0;
    my $src     = shift(@ARGV) // "";
    my $file    = shift(@ARGV) // "";
    my $dst     = shift(@ARGV) // "";
    my $format  = shift(@ARGV);
    return 0 unless $lines;
    return 0 unless length($src) && -e $src;
    return 0 unless length($file);
    return 0 unless length($dst);

    my $ctk = new CTK(plugins => "file");
    unless ($ctk->status) {
        die $ctk->error;
    }
    $ctk->fsplit(
        -dirsrc => $src,
        -dirdst => $dst,
        -file   => $file,
        -lines  => $lines,
        -format => $format,
    ) or do {
        die $ctk->error if $ctk->error;
        die("File not found");
    };
    return 1;
}
sub fjoin {
    my $src     = shift(@ARGV) // "";
    my $mask    = shift(@ARGV) // "";
    my $dst     = shift(@ARGV) // "";
    my $file    = shift(@ARGV) // "";
    return 0 unless length($src) && -e $src;
    my $ctk = new CTK(plugins => "file");
    unless ($ctk->status) {
        die $ctk->error;
    }
    $ctk->fjoin(
        -dirsrc => $src,
        -dirdst => $dst,
        -mask   => $mask,
        -fileout => $file,
    ) or do {
        die $ctk->error if $ctk->error;
        die("File not found");
    };
    return 1;
}
sub crlf {
    _expand_wildcards();
    find({ wanted => sub {
        return if -d;
        return if -z _;
        return unless -w _;
        return unless -r _;
        return unless -T _;
        my $orig = $_;
        my $dir = $File::Find::dir;
        my $file = File::Spec->catfile($dir, $orig);
        my (@fromstat) = stat $orig;
        print "Normalizing the linefeeds in file $file... ";
        file_lf_normalize($orig) or do {
            print STDERR "Can't create file $orig: $!\n";
            return
        };
        my $perm = $fromstat[2] || 0;
        $perm &= 07777;
        eval { chmod $perm, $orig; };
        if ($@) {
            print STDERR $@, "\n"
        } else {
            print "ok\n";
        }
    }}, @ARGV);
}

1;

__END__
