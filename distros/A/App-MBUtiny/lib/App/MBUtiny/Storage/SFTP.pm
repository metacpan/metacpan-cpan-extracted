package App::MBUtiny::Storage::SFTP; # $Id: SFTP.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Storage::SFTP - App::MBUtiny::Storage subclass for SFTP storage support

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

  <Host "foo">
    <SFTP>
        FixUP       on
        URL         sftp://user@example.com:22/path/to/backup/dir1
        URL         sftp://user@example.com:22/path/to/backup/dir2
        Set         key_path  /path/to/private/file.key
        Comment     SFTP storage said blah-blah-blah # Optional for collector
    </SFTP>

    # . . .

  </Host>

=head1 DESCRIPTION

App::MBUtiny::Storage subclass for SFTP storage support

B<NOTE!> For initialization SSH connection please run follow commands first:

    ssh-keygen -t rsa
    ssh-copy-id -i /path/to/private/file.pub user@example.com

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

=head2 sftp_storages

    my @list = $storage->sftp_storages;

Returns list of SFTP storage nodes

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
use Fcntl ':mode';
use URI;
use List::Util qw/uniq/;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MBUtiny::Util qw/ node2anode set2attr hide_password filesize /;

my $NET_SFTP_FOREIGN = 1; # Loaded!
my $NET_SFTP_FOREIGN_MESSAGE = "SFTP storage type is available";

eval { require Net::SFTP::Foreign; 1 } or do {
    $NET_SFTP_FOREIGN = 0;
    $NET_SFTP_FOREIGN_MESSAGE = "SFTP storage type is not available, Net::SFTP::Foreign is not installed or failed to load: $@";
};

use constant {
        STORAGE_SIGN => 'SFTP',
    };

sub init {
    my $self = shift;
    $self->maybe::next::method();
    $self->storage_status(STORAGE_SIGN, -1);
    my $usesftp = 0;

    my $sftp_nodes = dclone(node2anode(node($self->{host}, 'sftp')));
    #print explain($ftp_nodes), "\n";

    my %sftp_storages;
    foreach my $sftp_node (@$sftp_nodes) {
        my $urls = array($sftp_node, 'url') || [];
        my $gattr = set2attr($sftp_node),
        my $cmnt = value($sftp_node, 'comment') || "";
        foreach my $url (@$urls) {
            my $uri = new URI($url);
            my $url_wop = hide_password($url, 2);
            my $attr = dclone($gattr);
               $attr->{host} = $uri->host;
               $attr->{port} = $uri->port if $uri->port;
               $attr->{user} = $uri->user if $uri->user;
               $attr->{password} = $uri->password if $uri->password;
            $sftp_storages{$url} = {
                    url     => $url,
                    url_wop => $url_wop,
                    path    => $uri->path,
                    attr    => $attr,
                    comment => join("\n", grep {$_} ($url_wop, $cmnt)),
                    fixup   => value($sftp_node, 'fixup') ? 1 : 0,
                };
            $usesftp++;
        }
    }
    $self->{sftp_storages} = [(values(%sftp_storages))];

    $self->storage_status(STORAGE_SIGN, $usesftp) if $usesftp && $NET_SFTP_FOREIGN;
    #print explain($self->{sftp_storages}), "\n";
    return $self;
}
sub sftp_storages {
    my $self = shift;
    my $storages = $self->{sftp_storages} || [];
    return @$storages;
}
sub test {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    my $sign = STORAGE_SIGN;
    return $self->storage_status($sign)
        if is_void($self->sftp_storages()) && $self->storage_status($sign) <= 0; # SKIP
    unless ($NET_SFTP_FOREIGN) { # Not loaded
        $self->{test}->{$sign} = [[$NET_SFTP_FOREIGN_MESSAGE, -1]];
        return $self->storage_status($sign);
    }

    my @test = ();
    foreach my $storage ($self->sftp_storages) {
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};

        # Create object
        my $sftp = new Net::SFTP::Foreign(%$attr);
        if ($sftp->error) {
            $self->storage_status($sign, 0);
            push @test, [0, $url_wop, sprintf("Can't connect to %s: %s", $url_wop, $sftp->error)];
            next;
        }

        # Change dir
        if (my $path = $storage->{path}) {
            $sftp->setcwd($path) or do {
                $self->storage_status($sign, 0);
                push @test, [0, $url_wop, sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $sftp->error)];
                next;
            };
        }

        # Get pwd
        my $pwd = $sftp->cwd;
        if ($sftp->error) {
            $self->storage_status($sign, 0);
            push @test, [0, $url_wop, sprintf("Can't get cwd on %s: %s", $url_wop, $sftp->error)];
            next;
        }

        # Disconnect
        $sftp->disconnect;

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

    foreach my $storage ($self->sftp_storages) {
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};
        my $comment = $storage->{comment} || "";
        my $path = $storage->{path};
        my $ostat = 1;

        # Create object
        my $sftp = new Net::SFTP::Foreign(%$attr);
        if ($sftp->error) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $sftp->error));
            $ostat = 0;
        }

        # Change dir
        if ($ostat && length($path)) {
            $sftp->setcwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $sftp->error));
                $ostat = 0;
            };
        }

        # Put file
        if ($ostat) {
            $sftp->put($file, $name) or do {
                $self->error(sprintf("Can't put file %s to %s: %s", $name, $url_wop, $sftp->error));
                $ostat = 0;
            };
        }

        # Get file size
        if ($ostat) {
            my $ls = $sftp->ls(wanted => sub {
                my $foreign = shift;
                my $entry = shift;
                S_ISREG($entry->{a}->perm) && $entry->{filename} eq $name;
            });
            #print explain($ls), "\n";
            if ($sftp->error) {
                $self->error(sprintf("The ls failed: %s", $sftp->error));
                $ostat = 0;
            } elsif ($ls && is_array($ls)) {
                my $file = shift(@$ls);
                my $dst_size = $file->{a}->size || 0;
                unless ($src_size == $dst_size) {
                    $self->error(sprintf("An error occurred while sending data to %s. Sizes are different: SRC=%d; DST=%d", $url_wop, $src_size, $dst_size));
                    $ostat = 0;
                }
            }
        }

        # Disconnect
        $sftp->disconnect;

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

    foreach my $storage ($self->sftp_storages) {
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};
        my $path = $storage->{path};

        # Create object
        my $sftp = new Net::SFTP::Foreign(%$attr);
        if ($sftp->error) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $sftp->error));
            next;
        }

        # Change dir
        if (length($path)) {
            $sftp->setcwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $sftp->error));
                $sftp->disconnect;
                next;
            };
        }

        # Get file size
        my $src_size = 0;
        my $ls = $sftp->ls(wanted => sub {
            my $foreign = shift;
            my $entry = shift;
            S_ISREG($entry->{a}->perm) && $entry->{filename} eq $name;
        });
        if ($sftp->error) {
            $self->error(sprintf("The ls failed: %s", $sftp->error));
            $sftp->disconnect;
            next;
        } elsif ($ls && is_array($ls)) {
            my $file = shift(@$ls);
            $src_size = $file->{a}->size || 0;
        }

        # Get file
        $sftp->get($name, $file) or do {
            $self->error(sprintf("Can't get file %s from %s: %s", $name, $url_wop, $sftp->error));
            $sftp->disconnect;
            next;
        };

        # Check size
        my $dst_size = filesize($file) // 0;
        unless ($src_size == $dst_size) {
            $self->error(sprintf("An error occurred while sending data to %s. Sizes are different: SRC=%d; DST=%d", $url_wop, $src_size, $dst_size));
            $sftp->disconnect;
            next;
        }

        # Disconnect
        $sftp->disconnect;

        # Validate
        unless ($self->validate($file)) { # FAIL validation!
            $self->error(sprintf("SFTP storage %s failed: file %s is not valid!", $url_wop, $file));
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

    foreach my $storage ($self->sftp_storages) {
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};
        my $path = $storage->{path};
        my $ostat = 1;

        # Create object
        my $sftp = new Net::SFTP::Foreign(%$attr);
        if ($sftp->error) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $sftp->error));
            $ostat = 0;
        }

        # Change dir
        if ($ostat && length($path)) {
            $sftp->setcwd($path) or do {
                $self->error(sprintf("Can't change directory %s on %s: %s", $path, $url_wop, $sftp->error));
                $ostat = 0;
            };
        }

        # Delete file
        if ($ostat) {
            my $ls = $sftp->ls(wanted => sub {
                my $foreign = shift;
                my $entry = shift;
                S_ISREG($entry->{a}->perm) && $entry->{filename} eq $name;
            });
            #print explain($ls), "\n";
            if ($sftp->error) {
                $self->error(sprintf("The ls failed: %s", $sftp->error));
                $ostat = 0;
            } elsif ($ls && is_array($ls) && @$ls) {
                $sftp->remove($name) or do {
                    $self->error(sprintf("Can't delete file %s from %s: %s", $name, $url_wop, $sftp->error));
                    $ostat = 0;
                };
            }
        }

        # Disconnect
        $sftp->disconnect;

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
    foreach my $storage ($self->sftp_storages) {
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};
        my $path = $storage->{path};
        my $ostat = 1;

        # Create object
        my $sftp = new Net::SFTP::Foreign(%$attr);
        if ($sftp->error) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $sftp->error));
            $ostat = 0;
        }

        # Get file list
        if ($ostat) {
            my $ls = $sftp->ls($path, wanted => sub {
                my $foreign = shift;
                my $entry = shift;
                S_ISREG($entry->{a}->perm)
                #$entry->{filename} eq $name;
            });
            if ($sftp->error) {
                $self->error(sprintf("The ls failed: %s", $sftp->error));
                $ostat = 0;
            } elsif ($ls && is_array($ls)) {
                foreach (@$ls) {
                    my $f = $_->{filename};
                    push @list, $f if defined($f) && length($f);
                }
            }
        }

        # Disconnect
        $sftp->disconnect;
    }

    $self->{list}->{$sign} = [uniq(@list)];
    return 1;
}

1;

__END__
