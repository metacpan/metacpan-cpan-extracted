use strict;
use warnings;
package Archive::Tar::Wrapper::IPC::Cmd;
# ABSTRACT: Archive-Tar-Wrapper minus IPC::Run, IO::Pty
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use File::Spec::Functions;
use File::Spec;
use File::Path;
use File::Copy;
use File::Find;
use File::Basename;
use IPC::Cmd qw(run);
use Cwd;

our $VERSION = "0.22";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        tar                  => undef,
        tmpdir               => undef,
        tar_read_options     => '',
        tar_write_options    => '',
        tar_gnu_read_options => [],
        dirs                 => 0,
        max_cmd_line_args    => 512,
        ramdisk              => undef,
        %options,
    };

    bless $self, $class;

    $self->{tar} = bin_find("tar") unless defined $self->{tar};
    $self->{tar} = bin_find("gtar") unless defined $self->{tar};

    if( ! defined $self->{tar} ) {
        LOGDIE "tar not found in PATH, please specify location";
    }

    if(defined $self->{ramdisk}) {
        my $rc = $self->ramdisk_mount( %{ $self->{ramdisk} } );
        if(!$rc) {
            LOGDIE "Mounting ramdisk failed";
        }
        $self->{tmpdir} = $self->{ramdisk}->{tmpdir};
    } else {
        $self->{tmpdir} = tempdir($self->{tmpdir} ? 
                                        (DIR => $self->{tmpdir}) : ());
    }

    $self->{tardir} = File::Spec->catfile($self->{tmpdir}, "tar");
    mkpath [$self->{tardir}], 0, 0755 or
        LOGDIE "Cannot mkpath $self->{tardir} ($!)";

    $self->{objdir} = tempdir();

    return $self;
}

###########################################
sub tardir {
###########################################
    my($self) = @_;

    return $self->{tardir};
}

###########################################
sub read {
###########################################
    my($self, $tarfile, @files) = @_;

    my $cwd = getcwd();

    unless(File::Spec::Functions::file_name_is_absolute($tarfile)) {
        $tarfile = File::Spec::Functions::rel2abs($tarfile, $cwd);
    }

    chdir $self->{tardir} or 
        LOGDIE "Cannot chdir to $self->{tardir}";

    my $compr_opt = "";
    $compr_opt = "z" if $self->is_compressed($tarfile);

    my $cmd = [$self->{tar}, "${compr_opt}x$self->{tar_read_options}",
               @{$self->{tar_gnu_read_options}},
               "-f", $tarfile, @files];

    DEBUG "Running @$cmd";

    my( $success, $error_message, $full_buf, $out, $err ) =
        run( command => $cmd, verbose => 0 );
    if(!$success) {
         ERROR "@$cmd failed: $err";
         chdir $cwd or LOGDIE "Cannot chdir to $cwd";
         return undef;
    }

    WARN $err if $err;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return 1;
}

###########################################
sub is_compressed {
###########################################
    my($self, $tarfile) = @_;

    return 1 if $tarfile =~ /\.t?gz$/i;

        # Sloppy check for gzip files
    open FILE, "<$tarfile" or die "Cannot open $tarfile";
    binmode FILE;
    my $read = sysread(FILE, my $two, 2, 0) or die "Cannot sysread";
    close FILE;
    return 1 if 
        ord(substr($two, 0, 1)) eq 0x1F and 
        ord(substr($two, 1, 1)) eq 0x8B;

    return 0;
}

###########################################
sub locate {
###########################################
    my($self, $rel_path) = @_;

    my $real_path = File::Spec->catfile($self->{tardir}, $rel_path);

    if(-e $real_path) {
        DEBUG "$real_path exists";
        return $real_path;
    }
    DEBUG "$real_path doesn't exist";

    WARN "$rel_path not found in tarball";
    return undef;
}

###########################################
sub add {
###########################################
    my($self, $rel_path, $path_or_stringref, $opts) = @_;
            
    if($opts) {
        if(!ref($opts) or ref($opts) ne 'HASH') {
            LOGDIE "Option parameter given to add() not a hashref.";
        }
    }

    my $perm    = $opts->{perm} if defined $opts->{perm};
    my $uid     = $opts->{uid} if defined $opts->{uid};
    my $gid     = $opts->{gid} if defined $opts->{gid};
    my $binmode = $opts->{binmode} if defined $opts->{binmode};

    my $target = File::Spec->catfile($self->{tardir}, $rel_path);
    my $target_dir = dirname($target);

    if( ! -d $target_dir ) {
        if( ref($path_or_stringref) ) {
            $self->add( dirname( $rel_path ), dirname( $target_dir ) );
        } else {
            $self->add( dirname( $rel_path ), dirname( $path_or_stringref ) );
        }
    }

    if(ref($path_or_stringref)) {
        open FILE, ">$target" or LOGDIE "Can't open $target ($!)";
        if(defined $binmode) {
            binmode FILE, $binmode;
        }
        print FILE $$path_or_stringref;
        close FILE;
    } elsif( -d $path_or_stringref ) {
          # perms will be fixed further down
        mkpath($target, 0, 0755) unless -d $target;
    } else {
        copy $path_or_stringref, $target or
            LOGDIE "Can't copy $path_or_stringref to $target ($!)";
    }

    if(defined $uid) {
        chown $uid, -1, $target or
            LOGDIE "Can't chown $target uid to $uid ($!)";
    }

    if(defined $gid) {
        chown -1, $gid, $target or
            LOGDIE "Can't chown $target gid to $gid ($!)";
    }

    if(defined $perm) {
        chmod $perm, $target or 
                LOGDIE "Can't chmod $target to $perm ($!)";
    }

    if(!defined $uid and 
       !defined $gid and 
       !defined $perm and
       !ref($path_or_stringref)) {
        perm_cp($path_or_stringref, $target) or
            LOGDIE "Can't perm_cp $path_or_stringref to $target ($!)";
    }

    1;
}

######################################
sub perm_cp {
######################################
    # Lifted from Ben Okopnik's
    # http://www.linuxgazette.com/issue87/misc/tips/cpmod.pl.txt

    my $perms = perm_get($_[0]);
    perm_set($_[1], $perms);
}

######################################
sub perm_get {
######################################
    my($filename) = @_;

    my @stats = (stat $filename)[2,4,5] or
        LOGDIE "Cannot stat $filename ($!)";

    return \@stats;
}

######################################
sub perm_set {
######################################
    my($filename, $perms) = @_;

    chown($perms->[1], $perms->[2], $filename) or
        LOGDIE "Cannot chown $filename ($!)";
    chmod($perms->[0] & 07777,    $filename) or
        LOGDIE "Cannot chmod $filename ($!)";
}

###########################################
sub remove {
###########################################
    my($self, $rel_path) = @_;

    my $target = File::Spec->catfile($self->{tardir}, $rel_path);

    rmtree($target) or LOGDIE "Can't rmtree $target ($!)";
}

###########################################
sub list_all {
###########################################
    my($self) = @_;

    my @entries = ();

    $self->list_reset();

    while(my $entry = $self->list_next()) {
        push @entries, $entry;
    }

    return \@entries;
}

###########################################
sub list_reset {
###########################################
    my($self) = @_;

    my $list_file = File::Spec->catfile($self->{objdir}, "list");
    open FILE, ">$list_file" or LOGDIE "Can't open $list_file";

    my $cwd = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir} ($!)";

    find(sub {
              my $entry = $File::Find::name;
              $entry =~ s#^\./##;
              my $type = (-d $_ ? "d" :
                          -l $_ ? "l" :
                                  "f"
                         );
              print FILE "$type $entry\n";
            }, ".");

    chdir $cwd or LOGDIE "Can't chdir to $cwd ($!)";

    close FILE;

    $self->offset(0);
}

###########################################
sub list_next {
###########################################
    my($self) = @_;

    my $offset = $self->offset();

    my $list_file = File::Spec->catfile($self->{objdir}, "list");
    open FILE, "<$list_file" or LOGDIE "Can't open $list_file";
    seek FILE, $offset, 0;

    { my $line = <FILE>;

      return undef unless defined $line;

      chomp $line;
      my($type, $entry) = split / /, $line, 2;
      redo if $type eq "d" and ! $self->{dirs};
      $self->offset(tell FILE);
      return [$entry, File::Spec->catfile($self->{tardir}, $entry), 
              $type];
    }
}

###########################################
sub offset {
###########################################
    my($self, $new_offset) = @_;

    my $offset_file = File::Spec->catfile($self->{objdir}, "offset");

    if(defined $new_offset) {
        open FILE, ">$offset_file" or LOGDIE "Can't open $offset_file";
        print FILE "$new_offset\n";
        close FILE;
    }

    open FILE, "<$offset_file" or LOGDIE "Can't open $offset_file (Did you call list_next() without a previous list_reset()?)";
    my $offset = <FILE>;
    chomp $offset;
    return $offset;
    close FILE;
}

###########################################
sub write {
###########################################
    my($self, $tarfile, $compress) = @_;

    my $cwd = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir} ($!)";

    unless(File::Spec::Functions::file_name_is_absolute($tarfile)) {
        $tarfile = File::Spec::Functions::rel2abs($tarfile, $cwd);
    }

    my $compr_opt = "";
    $compr_opt = "z" if $compress;

    opendir DIR, "." or LOGDIE "Cannot open $self->{tardir}";
    my @top_entries = grep { $_ !~ /^\.\.?$/ } readdir DIR;
    closedir DIR;

    my $cmd;

    if(@top_entries > $self->{max_cmd_line_args}) {
        my $filelist_file = $self->{tmpdir}."/file-list";
        open FLIST, ">$filelist_file" or 
            LOGDIE "Cannot open $filelist_file ($!)";
        for(@top_entries) {
            print FLIST "$_\n";
        }
        close FLIST;
        $cmd = [$self->{tar}, "${compr_opt}cf$self->{tar_write_options}", 
                $tarfile, "-T", $filelist_file];
    } else {
        $cmd = [$self->{tar}, "${compr_opt}cf$self->{tar_write_options}", 
                $tarfile, @top_entries];
    }


    DEBUG "Running @$cmd";
    my( $success, $error_message, $full_buf, $out, $err ) =
        run( command => $cmd, verbose => 0 );
    if(!$success) {
         ERROR "@$cmd failed: $err";
         chdir $cwd or LOGDIE "Cannot chdir to $cwd";
         return undef;
    }

    WARN $err if $err;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return 1;
}

###########################################
sub DESTROY {
###########################################
    my($self) = @_;

    $self->ramdisk_unmount() if defined  $self->{ramdisk};

    rmtree($self->{objdir}) if defined $self->{objdir};
    rmtree($self->{tmpdir}) if defined $self->{tmpdir};
}

######################################
sub bin_find {
######################################
    my($exe) = @_;

    my @paths = split /:/, $ENV{PATH};

    push @paths,
         "/usr/bin",
         "/bin",
         "/usr/sbin",
         "/opt/bin",
         "/ops/csw/bin",
         ;

    for my $path ( @paths ) {
        my $full = File::Spec->catfile($path, $exe);
            return $full if -x $full;
    }

    return undef;
}

###########################################
sub is_gnu {
###########################################
    my($self) = @_;

    open PIPE, "$self->{tar} --version |" or 
        return 0;

    my $output = join "\n", <PIPE>;
    close PIPE;

    return $output =~ /GNU/;
}

###########################################
sub ramdisk_mount {
###########################################
    my($self, %options) = @_;

      # mkdir -p /mnt/myramdisk
      # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

     $self->{mount}  = bin_find("mount") unless $self->{mount};
     $self->{umount} = bin_find("umount") unless $self->{umount};

     for (qw(mount umount)) {
         if(!defined $self->{$_}) {
             LOGWARN "No $_ command found in PATH";
             return undef;
         }
     }

     $self->{ramdisk} = { %options };
 
     $self->{ramdisk}->{size} = "100m" unless 
       defined $self->{ramdisk}->{size};
 
     if(! defined $self->{ramdisk}->{tmpdir}) {
         $self->{ramdisk}->{tmpdir} = tempdir( CLEANUP => 1 );
     }
 
     my @cmd = ($self->{mount}, 
                "-t", "tmpfs", "-o", "size=$self->{ramdisk}->{size}",
                "tmpfs", $self->{ramdisk}->{tmpdir});

     INFO "Mounting ramdisk: @cmd";
     my $rc = system( @cmd );
 
    if($rc) {
        LOGWARN "Mount command '@cmd' failed: $?";
        LOGWARN "Note that this only works on Linux and as root";
        return;
    }
 
    $self->{ramdisk}->{mounted} = 1;
 
    return 1;
}

###########################################
sub ramdisk_unmount {
###########################################
    my($self) = @_;

    return if !exists $self->{ramdisk}->{mounted};

    my @cmd = ($self->{umount}, $self->{ramdisk}->{tmpdir});

    INFO "Unmounting ramdisk: @cmd";

    my $rc = system( @cmd );
        
    if($rc) {
        LOGWARN "Unmount command '@cmd' failed: $?";
        return;
    }

    delete $self->{ramdisk};
    return 1;
}

1;

__END__
=pod

=head1 NAME

Archive::Tar::Wrapper::IPC::Cmd - L<Archive::Tar::Wrapper> minus IPC::Run, IO::Pty

=head1 VERSION

version 0.22

=head1 DESCRIPTION

Archive::Tar::Wrapper::IPC::Cmd is a fork of Michael Schilli's L<Archive::Tar::Wrapper>
Removed: IPC::Run, IO::Pty
Added:   IPC::Cmd
	
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Krzysztof Bieszczad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


