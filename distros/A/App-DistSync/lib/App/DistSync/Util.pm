package App::DistSync::Util;
use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

App::DistSync::Util - The App::DistSync utilities

=head1 SYNOPSIS

    use App::DistSync::Util;

=head1 DESCRIPTION

Exported utility functions

=head2 debug

    debug("Foo bar baz");
    debug("Foo %s baz", "bar");
    debug("Foo %s %s", "bar", "baz");

Show debug information to STDERR

=head2 fdelete

    my $status = fdelete( $file );

Deleting a file if it exists

=head2 manifind

    my $files_struct = manifind($dir); # { ... }

Read direactory and returns file structure

=head2 maniread

    my $mani_struct = maniread($file, skipflag); # { ... }

Read file as manifest and returns hash structure

=head2 maniwrite

    maniwrite($file, $mani_struct);

This function writes manifest structure to manifest file

=head2 qrreconstruct

    my $r = qrreconstruct('!!perl/regexp (?i-xsm:^\s*(error|fault|no))');
    # Translate to:
    #    qr/^\s*(error|fault|no)/i

Returns regular expression (QR) by perl/regexp string. YAML form of definition

    my $r = qrreconstruct('perl/regexp (?i-xsm:^\s*(error|fault|no))');
    # Translate to:
    #    qr/^\s*(error|fault|no)/i

Not-YAML form of definition

    my $r = qrreconstruct('regexp (?i-xsm:^\s*(error|fault|no))');
    # Translate to:
    #    qr/^\s*(error|fault|no)/i

Short form of definition

See also L<YAML::Type/regexp> of L<YAML::Types>

=head2 read_yaml

    my $yaml = read_yaml($yaml_file);

Read YAML file

=head2 slurp

    my $data = slurp($file, %args);
    my $data = slurp($file, { %args });
    slurp($file, { buffer => \my $data });
    my $data = slurp($file, { binmode => ":raw:utf8" });

Reads file $filename into a scalar

    my $data = slurp($file, { binmode => ":unix" });

Reads file in fast, unbuffered, raw mode

    my $data = slurp($file, { binmode => ":unix:encoding(UTF-8)" });

Reads file with UTF-8 encoding

By default it returns this scalar. Can optionally take these named arguments:

=over 4

=item binmode

Set the layers to read the file with. The default will be something sensible on your platform

=item block_size

Set the buffered block size in bytes, default to 1048576 bytes (1 MiB)

=item buffer

Pass a reference to a scalar to read the file into, instead of returning it by value.
This has performance benefits

=back

See also L</spew> to writing data to file

=head2 spew

    spew($file, $data, %args);
    spew($file, $data, { %args });
    spew($file, \$data, { %args });
    spew($file, \@data, { %args });
    spew($file, $data, { binmode => ":raw:utf8" });

Writes data to a file atomically. The only argument is C<binmode>, which is passed to
C<binmode()> on the handle used for writing.

Can optionally take these named arguments:

=over 4

=item append

This argument is a boolean option, defaulted to false (C<0>).
Setting this argument to true (C<1>) will cause the data to be be written at the end of the current file.
Internally this sets the sysopen mode flag C<O_APPEND>

=item binmode

Set the layers to write the file with. The default will be something sensible on your platform

=item locked

This argument is a boolean option, defaulted to false (C<0>).
Setting this argument to true (C<1>) will ensure an that existing file will not be overwritten

=item mode

This numeric argument sets the default mode of opening files to write.
By default this argument to C<(O_WRONLY | O_CREAT)>.
Please DO NOT set this argument unless really necessary!

=item perms

This argument sets the permissions of newly-created files.
This value is modified by your process's umask and defaults to 0666 (same as sysopen)

=back

See also L</slurp> to reading data from file

=head2 tms

    print tms();

This function returns current time and PID in format, for eg.:

    [Sat Dec  6 19:09:54 2025] [533052]

=head2 touch

    touch( "file" ) or die "Can't touch file";

Makes file exist, with current timestamp

See L<ExtUtils::Command>

=head2 write_yaml

    write_yaml($yaml_file, $yaml);

Write YAML file

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<LWP::Simple>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use Carp;

our $DEBUG //= !!$ENV{DISTSYNC_DEBUG};

use IO::File qw//;
use POSIX qw/ :fcntl_h  /;
use Fcntl qw/ O_WRONLY O_CREAT O_APPEND O_EXCL SEEK_END /;
use File::Spec;
use File::Find;
use File::Path;
use YAML::Tiny;

use base qw/Exporter/;
our @EXPORT = (qw/
        debug tms
    /);
our @EXPORT_OK = (qw/
        qrreconstruct
        touch slurp spew
        fdelete
        read_yaml write_yaml
        maniread manifind maniwrite
    /, @EXPORT);

use constant {
    QRTYPES => {
        ''  => sub { qr{$_[0]} },
        x   => sub { qr{$_[0]}x },
        i   => sub { qr{$_[0]}i },
        s   => sub { qr{$_[0]}s },
        m   => sub { qr{$_[0]}m },
        ix  => sub { qr{$_[0]}ix },
        sx  => sub { qr{$_[0]}sx },
        mx  => sub { qr{$_[0]}mx },
        si  => sub { qr{$_[0]}si },
        mi  => sub { qr{$_[0]}mi },
        ms  => sub { qr{$_[0]}sm },
        six => sub { qr{$_[0]}six },
        mix => sub { qr{$_[0]}mix },
        msx => sub { qr{$_[0]}msx },
        msi => sub { qr{$_[0]}msi },
        msix => sub { qr{$_[0]}msix },
    },
};

sub debug {
    return unless $DEBUG;
    my $txt = (scalar(@_) == 1) ? shift(@_) : sprintf(shift(@_), @_);
    warn $txt, "\n";
    return 1;
}
sub tms { sprintf "[%s] [%d]", scalar(localtime(time())), $$ }
sub qrreconstruct { # See app/paysrelay
    # Returns regular expression (QR)
    # Gets from YAML::Type::regexp of YAML::Types
    # To input:
    #    !!perl/regexp (?i-xsm:^\s*(error|fault|no))
    # Translate to:
    #    qr/^\s*(error|fault|no)/i
    my $v = shift;
    return undef unless defined $v;
    return $v unless $v =~ /^\s*\!{0,2}(perl\/)?regexp\s*/i;
    $v =~ s/\s*\!{0,2}(perl\/)?regexp\s*//i;
    return qr{$v} unless $v =~ /^\(\?([\^\-uxism]*):(.*)\)\z/s;
    my ($flags, $re) = ($1, $2);
    $flags =~ s/-.*//; # remove all after '-'
    $flags =~ s/^\^//; # remove start-symbol
    $flags =~ tr/u//d; # remove u modifier
    my $sub = QRTYPES->{$flags} || sub { qr{$_[0]} };
    return $sub->($re);
}
sub slurp {
    my $file = shift // '';
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    return unless length($file) && -r $file;
    my $cleanup = 1;
    # Open filehandle
    my $fh;
    if (ref($file)) {
        $fh = $file;
        $cleanup = 0; # Disable closing filehandle for passed filehandle
    } else {
        $fh = IO::File->new($file, "r");
        unless (defined $fh) {
            carp qq/Can't open file "$file": $!/;
            return;
        }
    }
    # Set binmode layer
    my $bm = $args->{binmode} // ':raw'; # read in :raw by default
    $fh->binmode($bm);
    # Set buffer
    my $buf;
    my $buf_ref = $args->{buffer} // \$buf;
     ${$buf_ref} = ''; # Set empty string to buffer
    my $blk_size = $args->{block_size} || 1024 * 1024; # Set block size (1 MiB)
    # Read whole file
    my ($pos, $ret) = (0, 0);
    while ($ret = $fh->read(${$buf_ref}, $blk_size, $pos)) {
        $pos += $ret if defined $ret;
    }
    unless (defined $ret) {
        carp qq/Can't read from file "$file": $!/;
        return;
    }
    # Close filehandle
    $fh->close if $cleanup; # automatically closes the file
    # Return content if no buffer specified
    return if defined $args->{buffer};
    return ${$buf_ref};
}
sub spew {
    my $file = shift // '';
    my $data = shift // '';
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $cleanup = 1;
    # Get binmode layer, mode and perms
    my $bm = $args->{binmode} // ':raw'; # read in :raw by default
    my $perms = $args->{perms} // 0666; # set file permissions
    my $mode = $args->{mode} // O_WRONLY | O_CREAT;
       $mode |= O_APPEND if $args->{append};
       $mode |= O_EXCL if $args->{locked};
    # Open filehandle
    my $fh;
    if (ref($file)) {
        $fh = $file;
        $cleanup = 0; # Disable closing filehandle for passed filehandle
    } else {
        $fh = IO::File->new($file, $mode, $perms);
        unless (defined $fh) {
            carp qq/Can't open file "$file": $!/;
            return;
        }
    }
    # Set binmode layer
    $fh->binmode($bm);
    # Set buffer
    my $buf;
    my $buf_ref = \$buf;
    if (ref($data) eq 'SCALAR') {
        $buf_ref = $data;
    } elsif (ref($data) eq 'ARRAY') {
        ${$buf_ref} = join '', @$data;
    } else {
        $buf_ref = \$data;
    }
    # Seek, print, truncate and close
    $fh->seek(0, SEEK_END) if $args->{append}; # SEEK_END == 2
    $fh->print(${$buf_ref}) or return;
    $fh->truncate($fh->tell) if $cleanup;
    $fh->close if $cleanup;
    return 1;
}
sub touch {
    my $fn  = shift // '';
    return 0 unless length($fn);
    my $t = time;
    my $ostat = open my $fh, '>>', $fn;
    unless ($ostat) {
        printf STDERR "Can't touch file \"%s\": %s\n", $fn, $!;
        return 0;
    }
    close $fh if $ostat;
    utime($t, $t, $fn);
    return 1;
}
sub fdelete {
    my $file = shift;
    return 0 unless defined $file && -e $file;
    unless (unlink($file)) {
        printf STDERR "Can't delete file \"%s\": %s\n", $file, $!;
        return 0;
    }
    return 1;
}
sub read_yaml {
    my $file = shift;
    return [] unless defined $file;
    return [] unless (-e $file) && -r $file;
    my $yaml = YAML::Tiny->new;
    my $data = $yaml->read($file);
    return [] unless $data;
    return $data;
}
sub write_yaml {
    my $file = shift;
    my $data = shift;
    return 0 unless defined $file;
    return 0 unless defined $data;
    my $yaml = YAML::Tiny->new($data);
    $yaml->write($file);
    return 1;
}
sub maniread { # Reading data from MANEFEST, MIRRORS and MANEFEST.* files
    # Original see Ext::Utils::maniread
    my $mfile = shift;
    my $skipflag = shift;

    my $read = {};
    return $read unless defined($mfile) && (-e $mfile) && (-r $mfile) && (-s $mfile);
    my $fh;
    unless (open $fh, "<", $mfile){
        printf STDERR "Can't open file \"%s\": %s\n", $mfile, $!;
        return $read;
    }
    local $_;
    while (<$fh>){
        chomp;
        next if /^\s*#/;
        my($file, $args);

        if ($skipflag && $_ =~ /^\s*\!\!perl\/regexp\s*/i) { # Working in SkipMode
            #s/\r//;
            #$_ =~ qr{^\s*\!\!perl\/regexp\s*(?:(?:'([^\\']*(?:\\.[^\\']*)*)')|([^#\s]\S*))?(?:(?:\s*)|(?:\s+(.*?)\s*))$};
            #$args = $3;
            #my $file = $2;
            #if ( defined($1) ) {
            #    $file = $1;
            #    $file =~ s/\\(['\\])/$1/g;
            #}
            unless (($file, $args) = /^'(\\[\\']|.+)+'\s*(.*)/) {
                ($file, $args) = /^(^\s*\!\!perl\/regexp\s*\S+)\s*(.*)/;
            }
        } else {
            # filename may contain spaces if enclosed in ''
            # (in which case, \\ and \' are escapes)
            if (($file, $args) = /^'(\\[\\']|.+)+'\s*(.*)/) {
                $file =~ s/\\([\\'])/$1/g;
            } else {
                ($file, $args) = /^(\S+)\s*(.*)/;
            }
        }
        next unless $file;
        $read->{$file} = [defined $args ? split(/\s+/,$args) : ""];
    }
    close $fh;
    return $read;
}
sub manifind {
    my $dir = shift;
    carp("Can't specified directory") && return {} unless defined($dir) && -e $dir;

    my $found = {};
    my $base = File::Spec->canonpath($dir);
    #my ($volume,$sdirs,$sfile) = File::Spec->splitpath( $base );

    my $wanted = sub {
        my $path = File::Spec->canonpath($_);
        my $name = File::Spec->abs2rel( $path, $base );
        my $fdir = File::Spec->canonpath($File::Find::dir);
        return if -d $_;

        my $key = join("/", File::Spec->splitdir(File::Spec->catfile($name)));
        $found->{$key} = {
                mtime   => (stat($_))[9] || 0,
                size    => (-s $_) || 0,
                dir     => $fdir,
                path    => $path,
                file    => File::Spec->abs2rel( $path, $fdir ),
            };
    };

    # We have to use "$File::Find::dir/$_" in preprocess, because
    # $File::Find::name is unavailable.
    # Also, it's okay to use / here, because MANIFEST files use Unix-style
    # paths.
    find({
            wanted      => $wanted,
            no_chdir    => 1,
        }, $dir);

    return $found;
}
sub maniwrite {
    my $file = shift;
    my $mani = shift;
    carp("Can't specified file") && return 0 unless defined($file);
    carp("Can't specified manifest-hash") && return 0 unless defined($mani) && ref($mani) eq 'HASH';
    my $file_bak = $file.".bak";

    rename $file, $file_bak;
    my $fh;

    unless (open $fh, ">", $file){
        printf STDERR "Can't open file \"%s\": %s\n", $file, $!;
        rename $file_bak, $file;
        return 0;
    }

    # Stamp
    print  $fh "###########################################\n";
    printf $fh "# File created at %s\n", scalar(localtime(time()));
    print  $fh "# Please, do NOT edit this file directly!!\n";
    print  $fh "###########################################\n\n";

    foreach my $f (sort { lc $a cmp lc $b } keys %$mani) {
        my $d = $mani->{$f};
        my $text = sprintf("%s\t%s\t%s",
                $d->{mtime} || 0,
                $d->{size} || 0,
                $d->{mtime} ? scalar(localtime($d->{mtime})) : 'UNKNOWN',
            );
        my $tabs = (8 - (length($f)+1)/8);
        $tabs = 1 if $tabs < 1;
        $tabs = 0 unless $text;
        if ($f =~ /\s/) {
            $f =~ s/([\\'])/\\$1/g;
            $f = "'$f'";
        }
        print $fh $f, "\t" x $tabs, $text, "\n";
    }
    close $fh;

    unlink $file_bak;

    return 1;
}

1;

__END__

