package CTK::Plugin::File;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::File - File plugin

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "file",
        );

    my $n = $ctk->fcopy(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE].copy', # Format. Default: [FILE]
    );

    my $n = $ctk->fmove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE]', # Format. Default: [FILE]
    );

    my $n = $ctk->fremove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -glob   => "*.conf",
    );

    my $n = $ctk->fremove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -glob   => "*.conf",
    );

    my $n = $ctk->fsplit(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -lines  => 3,
        -format => '[FILE].part[PART]', # Format. Default: [FILE].part[PART]
    )

    my $n = $ctk->fjoin(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -outfile => "join.txt",
    );

=head1 DESCRIPTION

File plugin

=head1 METHODS

=over 8


=item B<fcopy>

    my $n = $ctk->fcopy(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE].copy', # Format. Default: [FILE]
    );

Copies files from the source directory to the destination directory
and returns how many files was copied

=over 8

=item B<-dirin>, B<-in>, B<-input>, B<-dirsrc>, , B<-src>

Specifies source directory

Default: current directory

=item B<-dirout>, B<-out>, B<-output>, B<-dirdst>, , B<-dst>

Specifies desination directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-file>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files or globs

    -glob => "file.*"

Glob pattern

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-format>, B<-callback>, B<-cb>

    -format => "[COUNT]_[FILE].copy.[TIME]"

Specifies format for output file

    -callback => sub {
        my $file_name = shift;
        my $file_number = shift;
        ...
        return $file_name;
    }

Callbacks allows you to modify the name of the output file manually

Default: "[FILE]"

=back

Replacing keys: FILE, COUNT, TIME

=item B<fjoin>

    my $n = $ctk->fjoin(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -outfile => "join.txt",
    );

Join group of files (by mask from source directory) to one big file (concatenate).
File writes to destination directory by output file name (fout)

    perl -MCTK::Command -e "fjoin(-mask=>qr/txt$/, -fout=>'foo.txt')" -- *

This is new features, added since CTK 1.18

=item B<fmove>

    my $n = $ctk->fmove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE]', # Format. Default: [FILE]
    );

Movies files from the source directory to the destination directory
and returns how many files was moved

Format of arguments see L</"fcopy">

=item B<fremove>

    my $n = $ctk->fremove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -glob   => "*.conf",
    );

Removing files from the source directory

Format of arguments see L</"fcopy">

=item B<fsplit>

    my $n = $ctk->fsplit(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -lines  => 3,
        -format => '[FILE].part[PART]', # Format. Default: [FILE].part[PART]
    )

Split group of files to parts

=over 8

=item B<-dirin>, B<-in>, B<-input>, B<-dirsrc>, , B<-src>

Specifies source directory

Default: current directory

=item B<-dirout>, B<-out>, B<-output>, B<-dirdst>, , B<-dst>

Specifies desination directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-file>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files or globs

    -glob => "file.*"

Glob pattern

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-limit>,B<-lines>,B<-rows>,B<-n>

    -lines => 5

Splits file by 5 lines

=item B<-format>, B<-callback>, B<-cb>

    -format => "[COUNT]_[FILE].copy[TIME].part[PART]"

Specifies format for output file

    -callback => sub {
        my $input_file_name = shift;
        my $input_file_number = shift;
        my $output_file_number = shift; # Part number
        ...
        return $file_name;
    }

Callbacks allows you to modify the name of the output file manually

Default: "[FILE].part[PART]"

=back

Replacing keys: FILE, COUNT, TIME, PART

=back

=head2 REPLACING KEYS

=over 8

=item B<FILE>

Path and filename

=item B<FILENAME>

Filename only

=item B<FILEEXT>

File extension only

=item B<COUNT>

Current number of file in sequence (for fcopy and fmove methods)

For fsplit method please use perl mask %i

=item B<TIME>

Current time value (unix-time format, time())

=back


=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<File::Find>, L<File::Copy>, L<Cwd>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/CTK::Plugin/;

use CTK::Util qw/ :API :FORMAT :FILE /;
use Carp;
use File::Find;
use Cwd qw/getcwd/;
use File::Copy;
use Fcntl qw/ :flock /;
use Symbol;

use constant BUFFER_SIZE => 32 * 1024; # 32kB

__PACKAGE__->register_method(
    method    => "fcopy",
    callback  => \&_cpmv
);

__PACKAGE__->register_method(
    method    => "fmove",
    callback  => sub { &_cpmv(@_, '-X_CTK_PLUGIN_OP' => 'move') }
);

__PACKAGE__->register_method(
    method    => "fremove",
    callback  => sub { &_cpmv(@_, '-X_CTK_PLUGIN_OP' => 'remove') }
);

__PACKAGE__->register_method(
    method    => "fsplit",
    callback  => sub {
    my $self = shift;
    my ($dirin, $dirout, $listmsk, $limit, $format) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','GLOB','GLOBS','FILE','FILES', 'REGEXP'],
                ['LIMIT','STRINGS','ROWS','MAX','ROWMAX','N','LIM','LINES'],
                ['FORMAT','CALLBACK','CB'],
            ],@_) if defined $_[0];

    $dirin //= getcwd();
    $dirin = File::Spec->catdir(getcwd(), $dirin) unless File::Spec->file_name_is_absolute($dirin);
    $dirout //= getcwd();
    $dirout = File::Spec->catdir(getcwd(), $dirout) unless File::Spec->file_name_is_absolute($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $listmsk //= '';
    $limit ||= 0;
    $format //= '[FILE].part[PART]';
    my $count = 0;
    my @list;
    my $cond;

    if (ref($listmsk) eq 'ARRAY') { # array of globs
        @list = @$listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        $cond = $listmsk;
    } else { # glob
        @list = ($listmsk);
    }
    my $top = length($dirin) ? $dirin : getcwd();
    my @inlist;
    find({ wanted => sub {
        return if -d;
        return if -B;
        return if -z;
        my $name = $_;
        my $file = $File::Find::name;
        my $dir = $File::Find::dir;
        return if $dir ne $top;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($cond) {
            return unless $name =~ $cond;
        } elsif(@inlist) {
            return unless grep {$_ eq $name} @inlist;
        }

        # Start splitting!
        $count++;
        open FIN, "<", $name or do {
            $self->error(sprintf("Can't open file \"%s\" for spliting: %s", $file, $!));
            $count--;
            return;
        };
            my $fpart = 0; # Parts
            my $fline = $limit; # Line
            open FOUT, ">-";
            while (<FIN>) { # chomp
                if ($fline >= $limit) { # is limit
                    $fline = 1;
                    $fpart++;
                    my $dst_f = ref($format) eq 'CODE'
                        ? $format->($name, $count, $fpart)
                        : dformat($format,{
                            FILE  => $name,
                            COUNT => $count,
                            TIME  => time(),
                            PART  => $fpart,
                        });
                    next unless defined($dst_f) && length($dst_f);
                    my $dst = File::Spec->catfile($dirout, $dst_f);
                    close FOUT;
                    open FOUT, ">", $dst or do {
                        $self->error(sprintf("Can't open file \"%s\" for writing: %s", $dst, $!));
                        next;
                    }
                } else {
                    $fline++;
                }
                print FOUT;
            }
            close FOUT;
        close FIN or do {
            $self->error(sprintf("Can't close file \"%s\" after spliting: %s", $file, $!));
            return;
        };

    }}, $top);

    return $count; # Number of files
});

__PACKAGE__->register_method(
    method    => "fjoin",
    callback  => sub {
    my $self = shift;
    my ($dirin, $dirout, $listmsk, $fileout) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','GLOB','GLOBS','FILE','FILES', 'REGEXP'],
                ['FILEOUT','FILEDST','OUTFILE','DSTFILE'],
            ],@_) if defined $_[0];

    $dirin //= getcwd();
    $dirin = File::Spec->catdir(getcwd(), $dirin) unless File::Spec->file_name_is_absolute($dirin);
    $dirout //= getcwd();
    $dirout = File::Spec->catdir(getcwd(), $dirout) unless File::Spec->file_name_is_absolute($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $listmsk //= '';
    $fileout //= '';
    unless (length($fileout)) {
        $self->error("Incorrect file out for files joining");
        return 0;
    }

    # Name of the FileOut building
    $fileout = File::Spec->catfile($dirout, $fileout) unless File::Spec->file_name_is_absolute($fileout);
    my $fh_out = gensym;
    if (open($fh_out, ">", $fileout)) {
        if (flock($fh_out, LOCK_EX)) {
            unless (binmode($fh_out)) {
                $self->error(sprintf("Can't call binmode() for file \"%s\" to writing: %s,%s"), $fileout, $!, $^E);
                close($fh_out) or $self->error(sprintf("Can't close file \"%s\" before writing: %s"), $fileout, $!);
                return 0;
            }
        } else {
            $self->error(sprintf("Can't lock [%d] file \"%s\" to writing: %s"), LOCK_SH, $fileout, $!);
            close($fh_out) or $self->error(sprintf("Can't close file \"%s\" before writing: %s"), $fileout, $!);
            return 0;
        }
    } else {
        $self->error(sprintf("Can't open file \"%s\" to writing: %s"), $fileout, $!);
        return 0;
    }

    my $count = 0;
    my @list;
    my $cond;

    if (ref($listmsk) eq 'ARRAY') { # array of globs
        @list = @$listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        $cond = $listmsk;
    } else { # glob
        @list = ($listmsk);
    }
    my $top = length($dirin) ? $dirin : getcwd();
    my @inlist;
    find({
        preprocess => sub { sort {$a cmp $b} @_ },
        wanted => sub {
        return if -d;
        return if -B;
        return if -z;
        my $name = $_;
        my $file = $File::Find::name;
        my $dir = $File::Find::dir;
        return if $dir ne $top;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($cond) {
            return unless $name =~ $cond;
        } elsif(@inlist) {
            return unless grep {$_ eq $name} @inlist;
        }

        # Start Joining!
        $count++;
        my $fh_in = gensym;
        if (open($fh_in, "<", $name)) {
            if (flock($fh_in, LOCK_SH)) {
                unless (binmode($fh_in)) {
                    $self->error(sprintf("Can't call binmode() for file \"%s\" to reading: %s,%s"), $file, $!, $^E);
                    close($fh_in) or $self->error(sprintf("Can't close file \"%s\" before reading: %s"), $file, $!);
                    $count--;
                    return;
                }
                while (1) {
                    my $buf;
                    my ($r, $w);
                    $r = sysread($fh_in, $buf, BUFFER_SIZE);
                    last unless $r;
                    $w = syswrite($fh_out, $buf, $r) or last;
                }
                close($fh_in) or $self->error(sprintf("Can't close file \"%s\" after reading: %s"), $file, $!);
            } else {
                close($fh_in) or $self->error(sprintf("Can't close file \"%s\" before reading: %s"), $file, $!);
                $self->error(sprintf("Can't lock [%d] file \"%s\" to reading: %s"), LOCK_SH, $file, $!);
            }
        } else {
            $self->error(sprintf("Can't open file \"%s\" to reading: %s"), $file, $!);
            $count--;
        }
    }}, $top);

    close($fh_out) or $self->error(sprintf("Can't close file \"%s\" after writing: %s"), $fileout, $!);
    unlink($fileout) if defined($fileout) && (-e $fileout) && (-z $fileout);

    return $count; # Number of files
});

sub _cpmv {
    my $self = shift;
    my ($dirin, $dirout, $listmsk, $format, $op) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','GLOB','GLOBS','FILE','FILES', 'REGEXP'],
                ['FORMAT','CALLBACK','CB'],
                'X_CTK_PLUGIN_OP'
            ],@_) if defined $_[0];
    $op ||= "copy";
    $dirin //= getcwd();
    $dirin = File::Spec->catdir(getcwd(), $dirin) unless File::Spec->file_name_is_absolute($dirin);
    $dirout //= getcwd();
    $dirout = File::Spec->catdir(getcwd(), $dirout) unless File::Spec->file_name_is_absolute($dirout);
    unless (($op eq "remove") || -e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $listmsk //= '';
    $format //= '[FILE]';
    my $count = 0;
    my @list;
    my $cond;

    if (ref($listmsk) eq 'ARRAY') { # array of globs
        @list = @$listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        $cond = $listmsk;
    } else { # glob
        @list = ($listmsk);
    }
    my $top = length($dirin) ? $dirin : getcwd();
    my @inlist;
    find({ wanted => sub {
        return if -d;
        my $name = $_;
        my $file = $File::Find::name;
        my $dir = $File::Find::dir;
        return if $dir ne $top;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($cond) {
            return unless $name =~ $cond;
        } elsif(@inlist) {
            return unless grep {$_ eq $name} @inlist;
        }
        if ($op eq 'remove') {
            $count++;
            unlink($name) or do {
                $self->error(sprintf("Can't remove file \"%s\": %s", $file, $!));
                $count--;
            };
            return;
        }
        my $dst_f = ref($format) eq 'CODE'
            ? $format->($name, ++$count)
            : dformat($format,{
                FILE  => $name,
                COUNT => ++$count,
                TIME  => time(),
            });
        unless (defined($dst_f) && length($dst_f)) {
            $count--;
            return;
        }
        my $dst = File::Spec->catfile($dirout, $dst_f);
        if ($op eq 'move') {
            move($name, $dst) or do {
                $self->error(sprintf("Move \"%s\" to \"%s\" failed: %s", $file, $dst, $!));
                $count--;
            };
        } else { # copy
            copy($name, $dst) or do {
                $self->error(sprintf("Copy \"%s\" to \"%s\" failed: %s", $file, $dst, $!));
                $count--;
            };
        }

    }}, $top);

    return $count; # Number of files
}

sub _expand_wildcards {
    my @wildcards = grep {defined && length} @_;
    return () unless @wildcards;
    my @g = map(/[*?]/o ? (glob($_)) : ($_), @wildcards);
    return () unless @g;
    return @g;
}

1;

__END__
