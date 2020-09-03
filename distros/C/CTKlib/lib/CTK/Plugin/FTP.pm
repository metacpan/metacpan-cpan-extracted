package CTK::Plugin::FTP;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::FTP - FTP plugin

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "ftp",
        );

    $ctk->fetch_ftp(
        -url     => 'ftp://anonymous:anonymous@192.168.0.1/Public/test?Timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -mode    => "binary", # ascii / binary (default)
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -filter  => qr/\.tmp$/,
    );

    $ctk->store_ftp(
        -url     => 'ftp://anonymous:anonymous@192.168.0.1/Public/test?Timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -mode    => "binary", # ascii / binary (default)
        -dirsrc  => "/path/to/source/dir", # Source directory
        -filter  => qr/\.tmp$/,
    )

=head1 DESCRIPTION

FTP plugin

=head1 METHODS

=head2 fetch_ftp

    $ctk->fetch_ftp(
        -url     => 'ftp://anonymous:anonymous@192.168.0.1/Public/test?Timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -mode    => "binary", # ascii / binary (default)
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -files   => ['foo.tgz', 'bar.tgz', 'baz.tgz'],
    );

Download specified files from resource

    $ctk->fetch_ftp(
        -url     => 'ftp://anonymous:anonymous@192.168.0.1/Public/test?Timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -mode    => "binary", # ascii / binary (default)
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -filter  => qr/\.tmp$/,
    );

Download files from remote resource by regexp mask

=over 8

=item B<-url>

URL of resource.

For example:

    ftp://anonymous:anonymous@192.168.0.1/Public/test?timeout=30

Timeout=30 -- FTP atrtributes. See L<Net::FTP>

=item B<-dirout>, B<-out>, B<-dirdst>, B<-dst>, B<-target>

Specifies destination directory

Default: current directory

=item B<-filter>, B<-list>, B<-mask>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt /]

List of files

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-op>, B<-cmd>, B<-command>

Operation name. Allowed: copy, move

Default: copy

=item B<-uniq>, B<-unique>

Unique mode

Default: off

=item B<-mode>

Defines transferring mode. Supported ASCII or Binary mode

    -mode    => "binary", # ascii / binary (default)

Default: binary

=back

=head2 store_ftp

    $ctk->store_ftp(
        -url     => 'ftp://anonymous:anonymous@192.168.0.1/Public/test?Timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -mode    => "binary", # ascii / binary (default)
        -dirsrc  => "/path/to/source/dir", # Source directory
        -filter  => qr/\.tmp$/,
    )

Upload files from local directory to remote resource by regexp mask

=over 8

=item B<-url>

URL of resource.

For example:

    ftp://anonymous:anonymous@192.168.0.1/Public/test?Timeout=30

Timeout=30 -- FTP atrtributes. See L<Net::FTP>

=item B<-dirin>, B<-in>, B<-dirsrc>, B<-src>, B<-source>

Specifies source directory

Default: current directory

=item B<-filter>, B<-list>, B<-mask>, B<-files>, B<-regexp>, B<-glob>

    -list => [qw/ file1.zip file2.zip /]

List of files

    -file => "file1.zip"

Name of file

    -glob => "*.zip"

Glob pattern

    -regexp => qr/\.(zip|zip2)$/i

Regexp

Default: undef (all files)

=item B<-op>, B<-cmd>, B<-command>

Operation name. Allowed: copy, move

Default: copy

=item B<-uniq>, B<-unique>

Unique mode

Default: off

=item B<-mode>

Defines transferring mode. Supported ASCII or Binary mode

    -mode    => "binary", # ascii / binary (default)

Default: binary

=back

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<Net::FTP>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<Net::FTP>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2020 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use base qw/CTK::Plugin/;

use URI;
use Carp;
use File::Spec;
use File::Find;
use Cwd qw/getcwd abs_path/;
use CTK::Util qw/ :BASE /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Net::FTP;

use constant {
    DEFAULT_HOST        => "localhost",
    DEFAULT_USER        => "anonymous",
    DEFAULT_PASSWORD    => "anonymous\@example.com",
};

__PACKAGE__->register_method(
    method    => "fetch_ftp",
    callback  => sub {
    my $self = shift;
    my ($url, $op, $uniq, $mode, $dirout, $filter) =
        read_attributes([
            ['URL', 'URI'],
            ['OP', 'OPER', 'OPERATION', 'CMD', 'COMMAND'],
            ['UNIQ', 'UNIQUE', 'DISTINCT'],
            ['MODE'],
            ['DIRDST', 'DSTDIR', 'DST', 'DEST', 'DIROUT', 'OUT', 'DESTINATION', 'TARGET'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILES'],
        ], @_);
    $self->error(""); # Cleanup first

    # Valid data
    my $uri;
    if (ref($url) && $url->isa("URI")) {
        $uri = $url->clone;
    } elsif ($url) {
        $uri = new URI($url);
    } else {
        $self->error("Incorrect URL or URI!");
        return;
    }
    $op ||= 'copy'; # copy / move
    $uniq = isTrueFlag($uniq); # on / off
    $dirout = _get_path($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $filter //= '';

    my (@inlist, $reg);
    if (ref($filter) eq 'ARRAY') { @inlist = @$filter } # array of files
    elsif (ref($filter) eq 'Regexp') { $reg = $filter } # Regexp
    elsif (length($filter)) { @inlist = ($filter) } # file
    my $count = 0;

    # Get connect data
    my %attrs = $uri->query_form; $uri->query_form({});
       $attrs{Host} = $uri->host // DEFAULT_HOST;
       $attrs{Port} = $uri->port if $uri->port;
    my $user = $uri->user // DEFAULT_USER;
    my $password = $uri->password // DEFAULT_PASSWORD;
    my $path = $uri->path // '';
    my $wop = sprintf("ftp://%s:******@%s", $user, $attrs{Host}) .
              ($attrs{Port} ? sprintf(":%d", $attrs{Port}) : '');

    # Create object
    my $ftp = Net::FTP->new(%attrs);
    unless ($ftp) {
        $self->error(sprintf("Can't connect to %s: %s", $wop, $@));
        return;
    }

    # Login
    $ftp->login($user, $password) or do {
        $self->error(sprintf("Can't login to %s: %s", $wop, $ftp->message));
        return;
    };

    # Change dir
    if (length($path)) {
        $ftp->cwd($path) or do {
            $self->error(sprintf("Can't change directory %s on %s: %s", $path, $wop, $ftp->message));
            $ftp->quit;
            return;
        };
        $wop .= $path =~ /^\// ? $path : sprintf("/%s", $path);
    }

    # Change mode
    $ftp->binary if !$mode || $mode =~ /^bin/i;

    # Get file list
    my @ls = $ftp->ls();

    # List processing
    foreach my $name (sort {$a cmp $b} @ls) {
        if ($reg) {
            next unless $name =~ $reg;
        } elsif (@inlist) {
            next unless grep {$_ eq $name} @inlist;
        }
        my $fs_remote = $ftp->size($name);  # Get remote file size
        next unless defined $fs_remote;
        my $file = File::Spec->catfile($dirout, $name);
        my $fs_local = $uniq ? _filesize($file) : 0; # Get local file size

        # Get file
        my $statget = 0;
        if ($uniq && (-e $file) && $fs_remote == $fs_local) {
            $statget = -1; # Skip! If uniq
        } else {
            $self->debug(sprintf("fetch \"%s\" \"%s\"", $wop, $file));
            if ($ftp->get($name, $file)) {
                $statget = 1;
                $fs_local = _filesize($file);
            } else {
                $self->error(sprintf("Can't get file %s to %s: %s", $name, $wop, $ftp->message));
                next;
            }
        }

        # Remove file
        if ($fs_remote == $fs_local) { # Ok
            $count++ if $statget == 1;
            if ($op =~ /^move/i) {
                $ftp->delete($name) or do {
                    $self->error(sprintf("Can't delete file %s from %s: %s", $name, $wop, $ftp->message));
                    next;
                };
            }
        } else { # Error
            $self->error(sprintf("Can't get file \"%s\". Size mismatch: Got: %d; Expected: %d", $name, $fs_remote, $fs_local));
        }
    }

    # Disconnect
    $ftp->quit;

    return $count;
});

__PACKAGE__->register_method(
    method    => "store_ftp",
    callback  => sub {
    my $self = shift;
    my ($url, $op, $uniq, $mode, $dirin, $filter) =
        read_attributes([
            ['URL', 'URI'],
            ['OP', 'OPER', 'OPERATION', 'CMD', 'COMMAND'],
            ['UNIQ', 'UNIQUE', 'DISTINCT'],
            ['MODE'],
            ['DIRSRC', 'SRCDIR', 'SRC', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILES', 'GLOB'],
        ], @_);
    $self->error(""); # Cleanup first

    # Valid data
    my $uri;
    if (ref($url) && $url->isa("URI")) {
        $uri = $url->clone;
    } elsif ($url) {
        $uri = new URI($url);
    } else {
        $self->error("Incorrect URL or URI!");
        return;
    }
    $op ||= 'copy'; # copy / move
    $uniq = isTrueFlag($uniq); # on / off
    $dirin = _get_path($dirin);
    unless (-e $dirin) {
        $self->error(sprintf("Source directory not found \"%s\"", $dirin));
        return;
    }
    $filter //= '';

    # Prepare filter (@list or $reg)
    my (@list, @inlist, $reg);
    if (ref($filter) eq 'ARRAY') { @list = @$filter } # array of globs
    elsif (ref($filter) eq 'Regexp') { $reg = $filter } # regexp
    elsif (length($filter)) { @list = ($filter) } # glob
    my $count = 0;

    # Get connect data
    my %attrs = $uri->query_form; $uri->query_form({});
       $attrs{Host} = $uri->host // DEFAULT_HOST;
       $attrs{Port} = $uri->port if $uri->port;
    my $user = $uri->user // DEFAULT_USER;
    my $password = $uri->password // DEFAULT_PASSWORD;
    my $path = $uri->path // '';
    my $wop = sprintf("ftp://%s:******@%s", $user, $attrs{Host}) .
              ($attrs{Port} ? sprintf(":%d", $attrs{Port}) : '');

    # Create object
    my $ftp = Net::FTP->new(%attrs);
    unless ($ftp) {
        $self->error(sprintf("Can't connect to %s: %s", $wop, $@));
        return;
    }

    # Login
    $ftp->login($user, $password) or do {
        $self->error(sprintf("Can't login to %s: %s", $wop, $ftp->message));
        return;
    };

    # Change dir
    if (length($path)) {
        $ftp->cwd($path) or do {
            $self->error(sprintf("Can't change directory %s on %s: %s", $path, $wop, $ftp->message));
            $ftp->quit;
            return;
        };
        $wop .= $path =~ /^\// ? $path : sprintf("/%s", $path);
    }

    # Change mode
    $ftp->binary if !$mode || $mode =~ /^bin/i;

    # Get file list
    my @ls = $uniq ? ($ftp->ls()) : ();
    my %found = ();
    foreach (@ls) {
        $found{$_} = 1;
    }

    # List processing
    find({ wanted => sub {
        return if -d;
        my $name = $_; # File name only
        my $file = $File::Find::name; # File (full path)
        my $dir = $File::Find::dir; # Directory
        return if $dir ne $dirin;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($reg) {
            return unless $name =~ $reg;
        } elsif (@inlist) {
            return unless grep {$_ eq $name} @inlist;
        } else {
            return if length $filter;
        }

        # Start!
        my ($fs_local, $fs_remote) = (0, 0);
        $fs_local = _filesize($name); # Get local file size
        $fs_remote = $uniq && $found{$name} ? ($ftp->size($name) || 0) : 0;  # Get remote file size

        # Put file
        my $statput = 0;
        if ($uniq && (-e $name) && $fs_remote == $fs_local) {
            $statput = -1; # Skip! If uniq
        } else {
            $self->debug(sprintf("store \"%s\" \"%s\"", $file, $wop));
            if ($ftp->put($file, $name)) {
                $statput = 1;
            } else {
                $self->error(sprintf("Can't put file %s to %s: %s", $name, $wop, $ftp->message));
                return;
            }
        }

        # Get file size if put is success
        if ($statput == 1) {
            my $rsz = $ftp->size($name);
            if (defined($rsz)) {
                $fs_remote = $rsz || 0;
            } else {
                $self->error(sprintf("The size() failed: %s", $ftp->message)) if $ftp->message;
            }
        }

        # Remove file
        if ($fs_remote == $fs_local) { # Ok
            $count++ if $statput == 1;
            if ($op =~ /^move/i) {
                unlink($name) or $self->error(sprintf("Can't delete file \"%s\": %s", $name, $!));
            }
        } else { # Error
            $self->error(sprintf("Can't put file \"%s\". Size mismatch: Got: %d; Expected: %d", $name, $fs_remote, $fs_local));
        }
    }}, $dirin);

    # Disconnect
    $ftp->quit;

    return $count;
});

sub _filesize {
    my $f = shift;
    my $filesize = 0;
    $filesize = (stat $f)[7] if -e $f;
    return $filesize // 0;
}

sub _expand_wildcards {
    my @wildcards = grep {defined && length} @_;
    return () unless @wildcards;
    my @g = map(/[*?]/o ? (glob($_)) : ($_), @wildcards);
    return () unless @g;
    return @g;
}

sub _get_path {
    my $d = shift;
    return getcwd() unless defined($d) && length($d);
    return abs_path($d) if -e $d and -l $d;
    return File::Spec->catdir(getcwd(), $d) unless File::Spec->file_name_is_absolute($d);
    return $d;
}

1;

__END__
