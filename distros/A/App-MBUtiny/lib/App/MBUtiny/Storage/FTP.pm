package App::MBUtiny::Storage::FTP; # $Id: FTP.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Storage::FTP - App::MBUtiny::Storage subclass for FTP storage support

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

  <Host "foo">
    <FTP>
        #FixUP   on
        URL     ftp://user:password@example.com:21/path/to/backup/dir1
        URL     ftp://user:password@example.com:21/path/to/backup/dir2
        Set     Passive 1
        Set     Debug 1
        Comment FTP storage said blah-blah-blah # Optional for collector
    </FTP>

    # . . .

  </Host>

=head1 DESCRIPTION

App::MBUtiny::Storage subclass for FTP storage support

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

=head2 ftp_storages

    my @list = $storage->ftp_storages;

Returns list of FTP storage nodes

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
use Net::FTP;
use URI;
use List::Util qw/uniq/;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MBUtiny::Util qw/ node2anode set2attr hide_password filesize /;

use constant {
        STORAGE_SIGN => 'FTP',
    };

sub init {
    my $self = shift;
    $self->maybe::next::method();
    $self->storage_status(STORAGE_SIGN, -1);
    my $useftp = 0;

    my $ftp_nodes = dclone(node2anode(node($self->{host}, 'ftp')));
    #print explain($ftp_nodes), "\n";

    my %ftp_storages;
    foreach my $ftp_node (@$ftp_nodes) {
        my $urls = array($ftp_node, 'url') || [];
        my $attr = set2attr($ftp_node),
        my $cmnt = value($ftp_node, 'comment') || "";
        foreach my $url (@$urls) {
            my $url_wop = hide_password($url, 2);
            $ftp_storages{$url} = {
                    url     => $url,
                    url_wop => $url_wop,
                    attr    => $attr,
                    comment => join("\n", grep {$_} ($url_wop, $cmnt)),
                    fixup   => value($ftp_node, 'fixup') ? 1 : 0,
                };
            $useftp++;
        }
    }
    $self->{ftp_storages} = [(values(%ftp_storages))];

    $self->storage_status(STORAGE_SIGN, $useftp) if $useftp;
    #print explain($self->{ftp_storages}), "\n";
    return $self;
}
sub ftp_storages {
    my $self = shift;
    my $storages = $self->{ftp_storages} || [];
    return @$storages;
}

sub test {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    my $sign = STORAGE_SIGN;
    return -1 if $self->storage_status($sign) <= 0; # SKIP

    my @test = ();
    foreach my $storage ($self->ftp_storages) {
        my $uri = new URI($storage->{url});
        my $url_wop = $storage->{url_wop};
        my $attr = dclone($storage->{attr});
        $attr->{Port} = $uri->port if $uri->port;

        # Create object
        my $ftp = new Net::FTP($uri->host, %$attr) or do {
            my $err = sprintf("Can't connect to %s: %s", $url_wop, $@);
            $self->storage_status($sign, 0);
            push @test, [0, $url_wop, $err];
            next;
        };

        # Login
        $ftp->login($uri->user || "anonymous", $uri->password || "anonymous\@example.com") or do {
            my $err = sprintf("Can't login to %s: %s", $url_wop, $ftp->message);
            $self->storage_status($sign, 0);
            push @test, [0, $url_wop, $err];
            next;
        };

        # Change dir (chdir + mkdir)
        my $path = $uri->path // ""; $path =~ s/^\///;
        if (length($path)) {
            $ftp->cwd($path) or do {
                my $dir = $ftp->mkdir($path, 1) or do {
                    my $err = sprintf("Can't create directory %s on %s: %s", $path, $url_wop, $ftp->message);
                    $self->storage_status($sign, 0);
                    push @test, [0, $url_wop, $err];
                    next;
                };
                $ftp->cwd($path) or do {
                    my $err = sprintf("Can't change directory %s on %s: %s", $dir, $url_wop, $ftp->message);
                    $self->storage_status($sign, 0);
                    push @test, [0, $url_wop, $err];
                    next;
                };
            };
        }

        # Quit
        $ftp->quit;
        push @test, [1, $url_wop];
    }

    $self->{test}->{$sign} = [@test];
    return 1;
}
sub put {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $status = 1;
    my $name = $params{name}; # File name only
    my $file = $params{file}; # Path to local file
    my $src_size = $params{size} || 0;

    foreach my $storage ($self->ftp_storages) {
        my $uri = new URI($storage->{url});
        my $url_wop = $storage->{url_wop};
        my $comment = $storage->{comment} || "";
        my $path = $uri->path // ""; $path =~ s/^\///;
        my $attr = dclone($storage->{attr});
        $attr->{Port} = $uri->port if $uri->port;
        my $ostat = 1;

        # Create object
        my $ftp = new Net::FTP($uri->host, %$attr) or do {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $@));
            $ostat = 0;
        };

        # Login
        if ($ostat) {
            $ftp->login($uri->user || "anonymous", $uri->password || "anonymous\@example.com") or do {
                $self->error(sprintf("Can't login to %s: %s", $url_wop, $ftp->message));
                $ostat = 0;
            };
        }

        # Change dir
        if ($ostat && length($path)) {
            $ftp->cwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $ftp->message));
                $ostat = 0;
            };
        }

        # Put file
        if ($ostat) {
            $ftp->binary;
            $ftp->put($file, $name) or do {
                $self->error(sprintf("Can't put file %s to %s: %s", $name, $url_wop, $ftp->message));
                $ostat = 0;
            };
        }

        # Get file size
        if ($ostat) {
            my $dst_size = $ftp->size($name) || 0;
            unless ($src_size == $dst_size) {
                $self->error(sprintf("An error occurred while sending data to %s. Sizes are different: SRC=%d; DST=%d", $url_wop, $src_size, $dst_size));
                $ostat = 0;
            }
        }

        # Quit
        $ftp->quit if $ftp;

        # Fixup!
        $self->fixup("put", $ostat, $comment) if $storage->{fixup};
        $status = 0 unless $ostat;
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

    foreach my $storage ($self->ftp_storages) {
        my $uri = new URI($storage->{url});
        my $url_wop = $storage->{url_wop};
        my $path = $uri->path // ""; $path =~ s/^\///;
        my $attr = dclone($storage->{attr});
        $attr->{Port} = $uri->port if $uri->port;

        # Create object
        my $ftp = new Net::FTP($uri->host, %$attr) or do {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $@));
            next;
        };

        # Login
        $ftp->login($uri->user || "anonymous", $uri->password || "anonymous\@example.com") or do {
            $self->error(sprintf("Can't login to %s: %s", $url_wop, $ftp->message));
            $ftp->quit if $ftp; # Quit
            next;
        };

        # Change dir
        if (length($path)) {
            $ftp->cwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $ftp->message));
                $ftp->quit if $ftp; # Quit
                next;
            };
        }

        # Get file size
        my $src_size = $ftp->size($name) || 0;

        # Get file
        $ftp->binary;
        $ftp->get($name, $file) or do {
            $self->error(sprintf("Can't get file %s from %s: %s", $name, $url_wop, $ftp->message));
            $ftp->quit if $ftp; # Quit
            next;
        };

        # Quit
        $ftp->quit if $ftp;

        # Check size
        my $dst_size = filesize($file) // 0;
        unless ($src_size == $dst_size) {
            $self->error(sprintf("An error occurred while fetching data from %s. Sizes are different: SRC=%d; DST=%d", $url_wop, $src_size, $dst_size));
            next;
        }

        # Validate
        unless ($self->validate($file)) { # FAIL validation!
            $self->error(sprintf("FTP storage %s failed: file %s is not valid!", $url_wop, $file));
            next
        }

        # Done!
        return $self->storage_status(STORAGE_SIGN, 1);
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

    foreach my $storage ($self->ftp_storages) {
        my $uri = new URI($storage->{url});
        my $url_wop = $storage->{url_wop};
        my $path = $uri->path // ""; $path =~ s/^\///;
        my $attr = dclone($storage->{attr});
        $attr->{Port} = $uri->port if $uri->port;
        my $ostat = 1;

        # Create object
        my $ftp = new Net::FTP($uri->host, %$attr) or do {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $@));
            $ostat = 0;
        };

        # Login
        if ($ostat) {
            $ftp->login($uri->user || "anonymous", $uri->password || "anonymous\@example.com") or do {
                $self->error(sprintf("Can't login to %s: %s", $storage->{url_wop}, $ftp->message));
                $ostat = 0;
            };
        }

        # Change dir
        if ($ostat && length($path)) {
            $ftp->cwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $ftp->message));
                $ostat = 0;
            };
        }

        # Get list
        my @ls = ();
        if ($ostat) {
            @ls = $ftp->ls();
        }

        # Delete file
        if ($ostat && grep { $_ eq $name } @ls ) {
            $ftp->delete($name) or do {
                $self->error(sprintf("Can't delete file %s from %s: %s", $name, $url_wop, $ftp->message));
                $ostat = 0;
            };
        }

        # Quit
        $ftp->quit if $ftp;

        # Fixup!
        $self->fixup("del", $name) if $storage->{fixup};
        $status = 0 unless $ostat;
    }
    $self->storage_status(STORAGE_SIGN, 0) unless $status;
}
sub list {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    return $self->storage_status(STORAGE_SIGN, -1) if $self->storage_status(STORAGE_SIGN) <= 0; # SKIP and set SKIP
    my $sign = STORAGE_SIGN;

    my @list = ();
    foreach my $storage ($self->ftp_storages) {
        my $uri = new URI($storage->{url});
        my $url_wop = $storage->{url_wop};
        my $path = $uri->path // ""; $path =~ s/^\///;
        my $attr = dclone($storage->{attr});
        $attr->{Port} = $uri->port if $uri->port;
        my $ostat = 1;

        # Create object
        my $ftp = new Net::FTP($uri->host, %$attr) or do {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $@));
            $ostat = 0;
        };

        # Login
        if ($ostat) {
            $ftp->login($uri->user || "anonymous", $uri->password || "anonymous\@example.com") or do {
                $self->error(sprintf("Can't login to %s: %s", $storage->{url_wop}, $ftp->message));
                $ostat = 0;
            };
        }

        # Change dir
        if ($ostat && length($path)) {
            $ftp->cwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $ftp->message));
                $ostat = 0;
            };
        }

        # Get list
        if ($ostat) {
            my @ls = $ftp->ls();
            push @list, grep { defined($_) && length($_) } @ls;
        }

        # Quit
        $ftp->quit if $ftp;
    }
    $self->{list}->{$sign} = [uniq(@list)];
    return 1;
}

1;

__END__
