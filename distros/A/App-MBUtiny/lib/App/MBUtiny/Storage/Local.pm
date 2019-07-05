package App::MBUtiny::Storage::Local; # $Id: Local.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Storage::Local - App::MBUtiny::Storage subclass for local storage support

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

  <Host "foo">
    <Local>
        #FixUP   on
        Localdir /path/to/foo/storage
        Localdir /path/to/bar/storage
        Comment  Local storage said blah-blah-blah # Optional for collector
    </Local>

    # . . .

  </Host>

=head1 DESCRIPTION

App::MBUtiny::Storage subclass for local storage support

=head2 del

Removes the specified file.
This is backend method of L<App::MBUtiny::Storage/del>

=head2 get

Gets the backup file from storage and saves it to specified path.
This is backend method of L<App::MBUtiny::Storage/get>

=head2 init

The method performs initialization of storage.
This is backend method of L<App::MBUtiny::Storage/init>

=head2 list

Gets backup file list on storage.
This is backend method of L<App::MBUtiny::Storage/list>

=head2 local_storages

    my @list = $storage->local_storages;

Returns list of local storage nodes

=head2 put

Sends backup file to storage.
This is backend method of L<App::MBUtiny::Storage/put>

=head2 test

Storage testing.
This is backend method of L<App::MBUtiny::Storage/test>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MBUtiny::Storage>

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

use Storable qw/dclone/;
use File::Spec;
use File::Copy qw/copy/;
use List::Util qw/uniq/;

use App::MBUtiny::Util qw/ filesize node2anode /;

use CTK::Util qw/ preparedir getlist /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use constant {
        STORAGE_SIGN => 'Local',
    };

sub init {
    my $self = shift;
    $self->maybe::next::method();
    $self->storage_status(STORAGE_SIGN, -1);

    my $uselocal = 0;
    my $local_nodes = dclone(node2anode(node($self->{host}, 'local')));
    $self->{local_nodes} = $local_nodes;
    my %local_dirs;
    foreach my $local_node (@$local_nodes) {
        my $localdirs = array($local_node, 'localdir') || [];
        foreach my $dir (@$localdirs) {
            if ((-e $dir) && (-d $dir or -l $dir)) {
                $local_dirs{$dir} = 1;
            } else {
                if (preparedir($dir)) {
                    $local_dirs{$dir} = 1;
                }
            }
            $uselocal++ if $local_dirs{$dir};
        }
    }
    $self->{local_dirs} = [(keys(%local_dirs))];

    $self->storage_status(STORAGE_SIGN, $uselocal) if $uselocal;
    #print explain($self->{local_dirs}), "\n";

    return $self;
}
sub local_storages {
    my $self = shift;
    my $storages = $self->{local_nodes} || [];
    return @$storages;
}
sub test {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    my $sign = STORAGE_SIGN;
    return -1 if $self->storage_status($sign) <= 0; # SKIP
    my $dirs = $self->{local_dirs};
    my @test = ();
    foreach my $dir (@$dirs) {
        if (-e $dir) {
            push @test, [1, $dir];
        } else {
            $self->storage_status($sign, 0);
            push @test, [0, $dir, "Directory \"$dir\" not found"];
        }
    }
    $self->{test}->{$sign} = [@test];
    return 1;
}
sub put {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $status = 1;
    my $name = $params{name};
    my $file = $params{file};

    my $local_nodes = $self->{local_nodes};
    foreach my $local_node (@$local_nodes) {
        my $ostat = 1;
        my $localdirs = array($local_node, 'localdir') || [];
        my @dirs = ();
        foreach my $dir (@$localdirs) {
            my $dst = File::Spec->catfile($dir, $name);
            if (copy($file, $dst)) {
                $params{size} ||= 0;
                my $size = filesize($file) // 0;
                if ($size == $params{size}) {
                    push @dirs, $dir;
                } else {
                    $self->error(sprintf("Copy \"%s\" to \"%s\" failed: size is different", $name, $dir, $!));
                    $ostat = 0;
                    $status = 0;
                }
            } else {
                $self->error(sprintf("Copy \"%s\" to \"%s\" failed: %s", $name, $dir, $!));
                $ostat = 0;
                $status = 0;
            };
        }
        my $storages_comment = @dirs ? join("; ", @dirs) : "No real local storages";
        my $comment = join("\n", grep {$_} ($storages_comment, value($local_node, 'comment')));
        $self->fixup("put", $ostat, $comment) if value($local_node, 'fixup'); # Fixup!
    }
    $self->storage_status(STORAGE_SIGN, 0) unless $status;
}
sub get {
    my $self = shift;
    my %params = @_;
    if ($self->storage_status(STORAGE_SIGN) <= 0) { # SKIP and set SKIP
        $self->maybe::next::method(%params);
        return $self->storage_status(STORAGE_SIGN, -1);
    }
    my $name = $params{name}; # archive name
    my $file = $params{file}; # destination archive file path

    foreach my $local_node ($self->local_storages) {
        my $localdirs = array($local_node, 'localdir') || [];
        foreach my $dir (@$localdirs) {
            my $src = File::Spec->catfile($dir, $name);
            my $src_size = filesize($src) // 0;
            if (copy($src, $file)) {
                my $dst_size = filesize($file) // 0;
                if ($src_size == $dst_size) {
                    unless ($self->validate($file)) { # FAIL validation!
                        $self->error(sprintf("Local storage dir %s failed: file %s is not valid!", $dir, $file));
                        next;
                    }
                    return $self->storage_status(STORAGE_SIGN, 1); # Done!
                } else {
                    $self->error(sprintf("Copy \"%s\" to \"%s\" failed: size is different", $src, $file, $!));
                }
            } else {
                $self->error(sprintf("Copy \"%s\" to \"%s\" failed: %s", $src, $file, $!));
            };
        }
    }
    $self->storage_status(STORAGE_SIGN, 0);
    $self->maybe::next::method(%params);
}
sub del {
    my $self = shift;
    my $name = shift;
    $self->maybe::next::method($name);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $status = 1;
    my $local_nodes = $self->{local_nodes};
    foreach my $local_node (@$local_nodes) {
        my $localdirs = array($local_node, 'localdir') || [];
        my @dirs = ();
        foreach my $dir (@$localdirs) {
            my $file = File::Spec->catfile($dir, $name);
            next unless -e $file;
            if (unlink($file)) {
                if (-e $file) {
                    $self->error(sprintf("Unlink \"%s\" failed", $file));
                    $status = 0;
                }
            } else {
                $self->error(sprintf("Unlink \"%s\" failed: %s", $file, $!));
                $status = 0;
            }
        }
        $self->fixup("del", $name) if value($local_node, 'fixup'); # Fixup!
    }
    $self->storage_status(STORAGE_SIGN, 0) unless $status;
}
sub list {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $sign = STORAGE_SIGN;
    my $dirs = $self->{local_dirs};
    my @list = ();
    foreach my $dir (@$dirs) {
        if (-e $dir) {
            my $l = getlist($dir) || [];
            push @list, @$l;
        }
    }
    $self->{list}->{$sign} = [uniq(@list)];
    return 1;
}

1;

__END__
