package App::MBUtiny::Storage::HTTP; # $Id: HTTP.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Storage::HTTP - App::MBUtiny::Storage subclass for HTTP storage support

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

  <Host "foo">
    <HTTP>
        FixUP   on
        URL     https://user:password@example.com/mbuserver/foo/dir1
        URL     https://user:password@example.com/mbuserver/foo/dir2
        Set     User-Agent TestServer/1.00
        Set     X-Test Foo Bar Baz
        Comment HTTP storage said blah-blah-blah # Optional for collector
    </HTTP>

    # . . .

  </Host>

=head1 DESCRIPTION

App::MBUtiny::Storage subclass for HTTP storage support

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

=head2 http_storages

    my @list = $storage->http_storages;

Returns list of HTTP storage nodes

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
use URI;
use List::Util qw/uniq/;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MBUtiny::Util qw/ node2anode set2attr hide_password filesize /;

use constant {
        STORAGE_SIGN => 'HTTP',
    };

sub init {
    my $self = shift;
    $self->maybe::next::method();
    $self->storage_status(STORAGE_SIGN, -1);
    my $usehttp = 0;

    my $http_nodes = dclone(node2anode(node($self->{host}, 'http')));
    #print explain($http_nodes), "\n";

    my %http_storages;
    foreach my $http_node (@$http_nodes) {
        my $urls = array($http_node, 'url') || [];
        my $attr = set2attr($http_node),
        my $timeout = uv2zero(value($http_node, 'timeout'));
        my $cmnt = value($http_node, 'comment') || "";
        foreach my $url (@$urls) {
            my $url_wop = hide_password($url, 2);
            $http_storages{$url} = {
                    url     => $url,
                    url_wop => $url_wop,
                    attr    => dclone($attr),
                    timeout => $timeout,
                    comment => join("\n", grep {$_} ($url_wop, $cmnt)),
                    fixup   => value($http_node, 'fixup') ? 1 : 0,
                };
            $usehttp++;
        }
    }
    $self->{http_storages} = [(values(%http_storages))];

    $self->storage_status(STORAGE_SIGN, $usehttp) if $usehttp;
    #print explain($self->{http_storages}), "\n";
    return $self;
}
sub http_storages {
    my $self = shift;
    my $storages = $self->{http_storages} || [];
    return @$storages;
}
sub test {
    my $self = shift;
    my %params = @_; $self->maybe::next::method(%params);
    my $sign = STORAGE_SIGN;
    return -1 if $self->storage_status($sign) <= 0; # SKIP

    my @test = ();
    foreach my $storage ($self->http_storages) {
        my $url = $storage->{url};
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};

        # Create object
        my $client = new App::MBUtiny::Storage::HTTP::Client(
            url     => $url, # Base URL
            timeout => $storage->{timeout}, # default: 180
            ($attr && isnt_void($attr)) ? (headers => $attr) : (),
        );
        unless ($client->status) {
            $self->storage_status($sign, 0);
            push @test, [0, $url_wop, sprintf("Can't connect to %s: %s", $url_wop, $client->error)];
            next;
        }

        # Check server
        unless ($client->check) {
            $self->storage_status($sign, 0);
            push @test, [0, $url_wop, sprintf("Server not running or not configured (%s): %s", $url_wop, $client->error)];
            next;
        }

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

    foreach my $storage ($self->http_storages) {
        my $url = $storage->{url};
        my $url_wop = $storage->{url_wop};
        my $comment = $storage->{comment} || "";
        my $attr = $storage->{attr};
        my $ostat = 1;

        # Create object
        my $client = new App::MBUtiny::Storage::HTTP::Client(
            url     => $url, # Base URL
            timeout => $storage->{timeout}, # default: 180
            ($attr && isnt_void($attr)) ? (headers => $attr) : (),
            no_check_redirect => 0,
        );
        unless ($client->status) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $client->error));
            $ostat = 0;
        }

        # Upload file
        if ($ostat) {
            $client->upload(file => $file, name => $name) or do {
                $self->error(join("\n", $client->transaction, $client->error));
                $ostat = 0;
            };
        }

        # Get file size
        if ($ostat) {
            my %info = $client->fileinfo(name => $name);
            unless ($client->status) {
                $self->error(join("\n", $client->transaction, $client->error));
                $ostat = 0;
            }
            my $dst_size = $info{size} || 0;
            unless ($src_size == $dst_size) {
                $self->error(sprintf("An error occurred while sending data to %s. Sizes are different: SRC=%d; DST=%d", $url_wop, $src_size, $dst_size));
                $ostat = 0;
            }
        }

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

    foreach my $storage ($self->http_storages) {
        my $url = $storage->{url};
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};

        # Create object
        my $client = new App::MBUtiny::Storage::HTTP::Client(
            url     => $url, # Base URL
            timeout => $storage->{timeout}, # default: 180
            ($attr && isnt_void($attr)) ? (headers => $attr) : (),
            no_check_redirect => 0,
        );
        unless ($client->status) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $client->error));
            next;
        }

        # Download file
        $client->download(file => $file, name => $name) or do {
            $self->error(join("\n", $client->transaction, $client->error));
            next;
        };
        my $src_size = 0;
        if (my $res = $client->res) {
            $src_size = $res->content_length || 0
        }
        my $dst_size = filesize($file) // 0;
        unless ($src_size == $dst_size) {
            $self->error(sprintf("An error occurred while fetching data from %s. Sizes are different: SRC=%d; DST=%d", $url_wop, $src_size, $dst_size));
            next;
        }

        # Validate
        unless ($self->validate($file)) { # FAIL validation!
            $self->error(sprintf("HTTP storage %s failed: file %s is not valid!", $url_wop, $file));
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

    foreach my $storage ($self->http_storages) {
        my $url = $storage->{url};
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};
        my $ostat = 1;

        # Create object
        my $client = new App::MBUtiny::Storage::HTTP::Client(
            url     => $url, # Base URL
            timeout => $storage->{timeout}, # default: 180
            ($attr && isnt_void($attr)) ? (headers => $attr) : (),
        );
        unless ($client->status) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $client->error));
            $ostat = 0;
        }

        # Get list
        my @ls = ();
        if ($ostat) {
            @ls = $client->filelist(host => $self->{name});
            unless ($client->status) {
                $self->error(join("\n", $client->transaction, $client->error));
                $ostat = 0;
            }
        }

        # Delete file
        if ($ostat && grep { $_ eq $name } @ls ) {
            $client->remove(name => $name) or do {
                $self->error(join("\n", $client->transaction, $client->error));
                $ostat = 0;
            };
        }

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
    foreach my $storage ($self->http_storages) {
        my $url = $storage->{url};
        my $url_wop = $storage->{url_wop};
        my $attr = $storage->{attr};
        my $ostat = 1;

        # Create object
        my $client = new App::MBUtiny::Storage::HTTP::Client(
            url     => $url, # Base URL
            timeout => $storage->{timeout}, # default: 180
            ($attr && isnt_void($attr)) ? (headers => $attr) : (),
        );
        unless ($client->status) {
            $self->error(sprintf("Can't connect to %s: %s", $url_wop, $client->error));
            $ostat = 0;
        }

        # Get list
        if ($ostat) {
            my @ls = $client->filelist(host => $self->{name});
            if ($client->status) {
                push @list, grep { defined($_) && length($_) } @ls;
            } else {
                $self->error(join("\n", $client->transaction, $client->error));
                $ostat = 0;
            }
        }
    }

    $self->{list}->{$sign} = [uniq(@list)];
    return 1;
}

1;

package App::MBUtiny::Storage::HTTP::Client;

use vars qw/ $VERSION /;
$VERSION = '1.00';

use Fcntl qw/ :flock /;
use File::Basename;
use CTK::ConfGenUtil;
use CTK::Util qw/ trim /;

use base qw/ WWW::MLite::Client /;

use constant {
        CONTENT_TYPE    => "application/octet-stream",
    };

sub new {
    my $class = shift;
    my %params = @_;
    $params{ua_opts}        ||= { agent => "MBUtiny/$VERSION" };
    $params{content_type}   ||= CONTENT_TYPE;
    $params{no_check_redirect} //= 1;
    return $class->SUPER::new(%params);
}
sub check {
    my $self = shift;
    $self->request("HEAD");
    return $self->status;
}
sub filelist {
    my $self = shift;
    my %args = @_;
    my $string_ret = $self->request(GET => $self->_merge_path_query($args{path}, $args{host})) || "";
    my @array_ret  = map {$_ = trim($_)} split /\s*\n+\s*/, $string_ret;
    return wantarray ? @array_ret : $string_ret;
}
sub upload {
    my $self = shift;
    my %args = @_;
    my $file = $args{file} || ''; # File for uploading! /path/to/file.tar.gz
    my $name = $args{name} || basename($file); # File name! file.tar.gz
    my $path = $args{path} ? sprintf("%s/%s", $args{path}, $name) : $name; # Path for request: /foo/bar
    $self->request(PUT => $self->_merge_path_query($path), sub {
        my $req = shift; # HTTP::Request object
        $req->header('Content-Type', CONTENT_TYPE);
        if (-e $file and -f $file) {
            my $size = (-s $file) || 0;
            return 0 unless $size;
            #my $sizef = $size;
            my $fh;
            $req->content(sub {
                unless ($fh) {
                    open($fh, "<", $file) or do {
                        $self->error(sprintf("Can't open file %s to read: %s", $file, $!));
                        return "";
                    };
                    binmode($fh);
                }
                my $buf = "";
                if (my $n = read($fh, $buf, 1024)) {
                    #$sizef -= $n;
                    #printf STDERR ">>> sizef=%d; n=%d\n", $sizef, $n;
                    return $buf;
                }
                close($fh);
                return "";
            });
            return $size;
        }
        return 0;
    });
    return $self->status;
}
sub fileinfo {
    my $self = shift;
    my %args = @_;
    my $name = $args{name}; # File name! file.tar.gz
    unless ($name) {
        $self->error("The file name (name attribute) not specified!");
        return ();
    }
    my $path = $args{path} ? sprintf("%s/%s", $args{path}, $name) : $name; # Path for request: /foo/bar
    $self->request(HEAD => $self->_merge_path_query($path));
    return () unless $self->status;
    my %ret = ();
    my $res = $self->res;
    if ($res) {
        $ret{code}          = $res->code || 0;
        $ret{message}       = $res->message || '';
        $ret{size}          = $res->content_length || 0;
        $ret{content_type}  = $res->content_type || '';
    }
    return %ret;
}
sub download {
    my $self = shift;
    my %args = @_;
    my $file = $args{file} || ''; # File for downloading! /path/to/file.tar.gz
    my $name = $args{name} || basename($file); # File name! file.tar.gz
    my $path = $args{path} ? sprintf("%s/%s", $args{path}, $name) : $name; # Path for request: /foo/bar

    my $fh;
    my $expected_length;
    my $bytes_received = 0;
    $self->request(GET => $self->_merge_path_query($path), undef, sub {
        my($chunk, $res) = @_;
        #$bytes_received += length($chunk);
        unless (defined $expected_length) {
            $expected_length = $res->content_length || 0;
            open($fh, ">", $file) or do {
                $self->error(sprintf("Can't open file %s to write: %s", $file, $!));
                return;
            };
            flock($fh, LOCK_EX) or do {
                $self->error(stprintf("Can't lock file %s: %s", $file, $!));
                return;
            };
            binmode($fh);
        }
        if ($expected_length && $fh) {
            #printf STDERR "%d%% - ", 100 * $bytes_received / $expected_length;
            print $fh $chunk;
        }

        #print STDERR "$bytes_received bytes received\n";
        # XXX Should really do something with the chunk itself
        # print $chunk;
    });
    close($fh) if $fh;
    return $self->status;
}
sub remove {
    my $self = shift;
    my %args = @_;
    my $name = $args{name}; # File name! file.tar.gz
    unless ($name) {
        $self->error("The file name (name attribute) not specified!");
        return $self->status(0);
    }
    my $path = $args{path} ? sprintf("%s/%s", $args{path}, $name) : $name; # Path for request: /foo/bar
    $self->request(DELETE => $self->_merge_path_query($path));
    return $self->status;
}

sub _merge_path_query {
    my $self = shift;
    my $path = shift;
    my $host = shift;
    my $uri = $self->{uri}->clone;
    my $path_orig = $uri->path;
    $uri->path(sprintf("%s/%s", $path_orig, $path)) if $path;
    $uri->query_form(host => $host) if $host;
    return $uri->path_query;
}

1;

__END__
