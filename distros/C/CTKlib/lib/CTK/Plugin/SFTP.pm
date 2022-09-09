package CTK::Plugin::SFTP;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::SFTP - SFTP plugin

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use CTK;
    my $ctk = CTK->new(
            plugins => "sftp",
        );

    $ctk->fetch_sftp(
        -url     => 'sftp://anonymous@192.168.0.1/Public/test?timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -filter  => qr/\.tmp$/,
    );

    $ctk->store_sftp(
        -url     => 'sftp://anonymous@192.168.0.1/Public/test?timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -dirsrc  => "/path/to/source/dir", # Source directory
        -filter  => qr/\.tmp$/,
    )

=head1 DESCRIPTION

SFTP plugin

B<NOTE!> For initialization SSH connection please run follow commands first:

    ssh-keygen -t rsa
    ssh-copy-id -i /path/to/private/file.pub user@example.com

=head1 METHODS

=head2 fetch_sftp

    $ctk->fetch_sftp(
        -url     => 'sftp://anonymous@192.168.0.1/Public/test?timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -files   => ['foo.tgz', 'bar.tgz', 'baz.tgz'],
    );

Download specified files from resource

    $ctk->fetch_sftp(
        -url     => 'sftp://anonymous@192.168.0.1/Public/test?timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -filter  => qr/\.tmp$/,
    );

Download files from remote resource by regexp mask

=over 8

=item B<-url>

URL of resource.

For example:

    sftp://anonymous@192.168.0.1/Public/test?timeout=30

timeout=30 -- SFTP atrtributes. See L<Net::SFTP::Foreign>

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

=back

=head2 store_sftp

    $ctk->store_sftp(
        -url     => 'sftp://anonymous@192.168.0.1/Public/test?timeout=30',
        -op      => "copy", # copy / move
        -uniq    => 1, # 0 -- off; 1 -- on
        -dirsrc  => "/path/to/source/dir", # Source directory
        -filter  => qr/\.tmp$/,
    )

Upload files from local directory to remote resource by regexp mask

=over 8

=item B<-url>

URL of resource.

For example:

    sftp://anonymous@192.168.0.1/Public/test?timeout=30

timeout=30 -- SFTP atrtributes. See L<Net::SFTP::Foreign>

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

=back

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<Net::SFTP::Foreign>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<Net::SFTP::Foreign>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.02';

use base qw/CTK::Plugin/;

use URI;
use Carp;
use File::Spec;
use File::Find;
use Cwd qw/getcwd abs_path/;
use Fcntl qw/:mode/;
use CTK::Util qw/ :BASE /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

my $NET_SFTP_FOREIGN = 1; # Loaded!
my $NET_SFTP_FOREIGN_MESSAGE = "Net::SFTP::Foreign is available";

eval { require Net::SFTP::Foreign; 1 } or do {
    $NET_SFTP_FOREIGN = 0;
    $NET_SFTP_FOREIGN_MESSAGE = "Net::SFTP::Foreign is not installed. Please install it: $@";
    $NET_SFTP_FOREIGN_MESSAGE .= "\nTry install:\n"
     . "  sudo cpan install Net::SFTP::Foreign\n"
     . "  apt install libnet-sftp-foreign-perl\n"
     . "  yum install perl-Net-SFTP-Foreign\n";
};

__PACKAGE__->register_method(
    method    => "fetch_sftp",
    callback  => sub {
    my $self = shift;
    my ($url, $op, $uniq, $dirout, $filter) =
        read_attributes([
            ['URL', 'URI'],
            ['OP', 'OPER', 'OPERATION', 'CMD', 'COMMAND'],
            ['UNIQ', 'UNIQUE', 'DISTINCT'],
            ['DIRDST', 'DSTDIR', 'DST', 'DEST', 'DIROUT', 'OUT', 'DESTINATION', 'TARGET'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILE', 'FILES'],
        ], @_);
    unless ($NET_SFTP_FOREIGN) {
        $self->error($NET_SFTP_FOREIGN_MESSAGE);
        return;
    }
    $self->error(""); # Cleanup first

    # Valid data
    my $uri;
    if (ref($url) && $url->isa("URI")) {
        $uri = $url->clone;
    } elsif ($url) {
        $uri = URI->new($url);
    } else {
        $self->error("Incorrect URL or URI!");
        return;
    }
    $op ||= 'copy'; # copy / move
    $uniq = isTrueFlag($uniq); # on / off
    $dirout = _get_path($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return;
    }
    $filter //= '';

    my (@inlist, $reg);
    if (ref($filter) eq 'ARRAY') { @inlist = @$filter } # array of files
    elsif (ref($filter) eq 'Regexp') { $reg = $filter } # Regexp
    elsif (length($filter)) { @inlist = ($filter) } # file
    my $count = 0;

    # Get connect data
    my %attrs = $uri->query_form; $uri->query_form({});
       $attrs{host} = $uri->host;
       $attrs{port} = $uri->port if $uri->port;
       $attrs{user} = $uri->user if $uri->user;
       $attrs{password} = $uri->password if $uri->password;
    my $path = $uri->path // '';
    my $wop = "sftp://" .
              ($attrs{user} ? sprintf("%s@", $attrs{user}) : '') .
              ($attrs{host} || 'localhost') .
              ($attrs{port} ? sprintf(":%d", $attrs{port}) : '');

    # Create object
    my $sftp = Net::SFTP::Foreign->new(%attrs);
    if ($sftp->error) {
        $self->error(sprintf("Can't connect to %s: %s", $wop, $sftp->error));
        return;
    }

    # Get file list
    my %found = (); # filename => size
    my $ls = $sftp->ls($path, wanted => sub {
        my $foreign = shift;
        my $entry = shift;
        return unless S_ISREG($entry->{a}->perm);
        $found{ $entry->{filename} } = $entry->{a}->size || 0;
        return 1;
    });
    if ($sftp->error) {
        $self->error(sprintf("The ls failed: %s", $sftp->error));
        $sftp->disconnect;
        return;
    }

    # Change dir
    if (length($path)) {
        $sftp->setcwd($path) or do {
            $self->error(sprintf("Can't change directory %s on %s: %s", $path, $wop, $sftp->error));
            $sftp->disconnect;
            return;
        };
        $wop .= $path =~ /^\// ? $path : sprintf("/%s", $path);
    }

    # List processing
    foreach my $name (sort {$a cmp $b} keys %found) {
        if ($reg) {
            next unless $name =~ $reg;
        } elsif (@inlist) {
            next unless grep {$_ eq $name} @inlist;
        }
        my $file = File::Spec->catfile($dirout, $name);
        my $fs_remote = $found{$name} || 0;  # Get remote file size
        my $fs_local = $uniq ? _filesize($file) : 0; # Get local file size

        # Get file
        my $statget = 0;
        if ($uniq && (-e $file) && $fs_remote == $fs_local) {
            $statget = -1; # Skip! If uniq
        } else {
            $self->debug(sprintf("fetch \"%s\" \"%s\"", $wop, $file));
            if ($sftp->get($name, $file)) {
                $statget = 1;
                $fs_local = _filesize($file);
            } else {
                $self->error(sprintf("Can't get file %s to %s: %s", $name, $wop, $sftp->error));
                next;
            }
        }

        # Remove file
        if ($fs_remote == $fs_local) { # Ok
            $count++ if $statget == 1;
            if ($op =~ /^move/i) {
                $sftp->remove($name) or do {
                    $self->error(sprintf("Can't delete file %s from %s: %s", $name, $wop, $sftp->error));
                    next;
                };
            }
        } else { # Error
            $self->error(sprintf("Can't get file \"%s\". Size mismatch: Got: %d; Expected: %d", $name, $fs_remote, $fs_local));
        }
    }

    # Disconnect
    $sftp->disconnect;

    return $count;
});

__PACKAGE__->register_method(
    method    => "store_sftp",
    callback  => sub {
    my $self = shift;
    my ($url, $op, $uniq, $dirin, $filter) =
        read_attributes([
            ['URL', 'URI'],
            ['OP', 'OPER', 'OPERATION', 'CMD', 'COMMAND'],
            ['UNIQ', 'UNIQUE', 'DISTINCT'],
            ['DIRSRC', 'SRCDIR', 'SRC', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILES', 'GLOB'],
        ], @_);
    unless ($NET_SFTP_FOREIGN) {
        $self->error($NET_SFTP_FOREIGN_MESSAGE);
        return;
    }
    $self->error(""); # Cleanup first

    # Valid data
    my $uri;
    if (ref($url) && $url->isa("URI")) {
        $uri = $url->clone;
    } elsif ($url) {
        $uri = URI->new($url);
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
       $attrs{host} = $uri->host;
       $attrs{port} = $uri->port if $uri->port;
       $attrs{user} = $uri->user if $uri->user;
       $attrs{password} = $uri->password if $uri->password;
    my $path = $uri->path // '';
    my $wop = "sftp://" .
              ($attrs{user} ? sprintf("%s@", $attrs{user}) : '') .
              ($attrs{host} || 'localhost') .
              ($attrs{port} ? sprintf(":%d", $attrs{port}) : '');

    # Create object
    my $sftp = Net::SFTP::Foreign->new(%attrs);
    if ($sftp->error) {
        $self->error(sprintf("Can't connect to %s: %s", $wop, $sftp->error));
        return;
    }

    # Get file list
    my %found = (); # filename => size
    if ($uniq) {
        my $ls = $sftp->ls($path, wanted => sub {
            my $foreign = shift;
            my $entry = shift;
            return unless S_ISREG($entry->{a}->perm);
            $found{ $entry->{filename} } = $entry->{a}->size || 0;
            return 1;
        });
        if ($sftp->error) {
            $self->error(sprintf("The ls failed: %s", $sftp->error));
            $sftp->disconnect;
            return;
        }
    }

    # Change dir
    if (length($path)) {
        $sftp->setcwd($path) or do {
            $self->error(sprintf("Can't change directory %s on %s: %s", $path, $wop, $sftp->error));
            $sftp->disconnect;
            return;
        };
        $wop .= $path =~ /^\// ? $path : sprintf("/%s", $path);
    }

    # List processing
    my $top = length($dirin) ? $dirin : getcwd();
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
        #printf "#%d Dir: %s; Name: %s; File: %s\n", $count, $dir, $name, $file;
        my ($fs_local, $fs_remote) = (0, 0);
        $fs_local = _filesize($name); # Get local file size
        $fs_remote = $uniq && exists($found{$name}) ? ($found{$name} || 0) : 0;  # Get remote file size

        # Put file
        my $statput = 0;
        if ($uniq && (-e $name) && $fs_remote == $fs_local) {
            $statput = -1; # Skip! If uniq
        } else {
            $self->debug(sprintf("store \"%s\" \"%s\"", $file, $wop));
            if ($sftp->put($file, $name)) {
                $statput = 1;
            } else {
                $self->error(sprintf("Can't put file %s to %s: %s", $name, $wop, $sftp->error));
                return;
            }
        }

        # Get file size if put is success
        if ($statput == 1) {
            if (my $rstat = $sftp->stat($name)) {
                $fs_remote = $rstat->size || 0;
            } else {
                $self->error(sprintf("The stat() failed: %s", $sftp->error)) if $sftp->error;
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
    $sftp->disconnect;

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
