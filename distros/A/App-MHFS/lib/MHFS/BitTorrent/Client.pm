package MHFS::BitTorrent::Client v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use MHFS::BitTorrent::Metainfo;
use MHFS::Process;

sub rtxmlrpc {
    my ($server, $params, $cb, $inputdata) = @_;
    my $process;
    my @cmd = ('rtxmlrpc', @$params, '--config-dir', $server->{settings}{'CFGDIR'} . '/.pyroscope/');
    print "$_ " foreach @cmd;
    print "\n";
    $process    = MHFS::Process->new_io_process($server->{evp}, \@cmd, sub {
        my ($output, $error) = @_;
        chomp $output;
        #say 'rtxmlrpc output: ' . $output;
        $cb->($output);
    }, $inputdata);

    if(! $process) {
        $cb->(undef);
    }

    return $process;
}

sub torrent_d_bytes_done {
    my ($server, $infohash, $callback) = @_;
    rtxmlrpc($server, ['d.bytes_done', $infohash ], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_d_size_bytes {
    my ($server, $infohash, $callback) = @_;
    rtxmlrpc($server, ['d.size_bytes', $infohash ],sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_load_verbose {
    my ($server, $filename, $callback) = @_;
    rtxmlrpc($server, ['load.verbose', '', $filename], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_load_raw_verbose {
    my ($server, $data, $callback) = @_;
    rtxmlrpc($server, ['load.raw_verbose', '', '@-'], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    }, $data);
}

sub torrent_d_directory_set {
    my ($server, $infohash, $directory, $callback) = @_;
    rtxmlrpc($server, ['d.directory.set', $infohash, $directory], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_d_start {
    my ($server, $infohash, $callback) = @_;
    rtxmlrpc($server, ['d.start', $infohash], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_d_delete_tied {
    my ($server, $infohash, $callback) = @_;
    rtxmlrpc($server, ['d.delete_tied', $infohash], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}


sub torrent_d_name {
    my ($server, $infohash, $callback) = @_;
    rtxmlrpc($server, ['d.name', $infohash], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_d_is_multi_file {
    my ($server, $infohash, $callback) = @_;
    rtxmlrpc($server, ['d.is_multi_file', $infohash], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}


sub torrent_set_priority {
    my ($server, $infohash, $priority, $callback) = @_;
    rtxmlrpc($server, ['f.multicall', $infohash, '', 'f.priority.set=' . $priority], sub {
    my ($output) = @_;
    if($output =~ /ERROR/) {
        $callback->(undef);
        return;
    }
    rtxmlrpc($server, ['d.update_priorities', $infohash], sub {
    if($output =~ /ERROR/) {
        $output = undef;
    }
    $callback->($output);
    })});
}


# lookup the findex for the file and then set the priority on it
# ENOTIMPLEMENTED
sub torrent_set_file_priority {
    my ($server, $infohash, $file, $priority, $callback) = @_;
    rtxmlrpc($server, ['f.multicall', $infohash, '', 'f.path='], sub {
    my ($output) = @_;
    if($output =~ /ERROR/) {
        $callback->(undef);
        return;
    }
    say "torrent_set_file_priority";
    say $output;
    die;

    $callback->($output);
    });
}

sub torrent_list_torrents {
    my ($server, $callback) = @_;
    rtxmlrpc($server, ['d.multicall2', '', 'default', 'd.name=', 'd.hash=', 'd.size_bytes=', 'd.bytes_done=', 'd.is_private='], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
    });
}

sub torrent_file_information {
    my ($server, $infohash, $name, $cb) = @_;
    rtxmlrpc($server, ['f.multicall', $infohash, '', 'f.path=', 'f.size_bytes='], sub {
    my ($output) = @_;
    if($output =~ /ERROR/) {
        $output = undef;
    }

    # pase the name and size arrays
    my %files;
    my @lines = split(/\n/, $output);
    while(1) {
        my $line = shift @lines;
        last if(!defined $line);
        if(substr($line, 0, 1) ne '[') {
            say "fail parse";
            $cb->(undef);
            return;
        }
        while(substr($line, -1) ne ']') {
            my $newline = shift @lines;
            if(!defined $newline) {
                say "fail parse";
                $cb->(undef);
                return;
            }
            $line .= $newline;
        }
        my ($file, $size) = $line =~ /^\[.(.+).,\s(\d+)\]$/;
        if((! defined $file) || (!defined $size)) {
            say "fail parse";
            $cb->(undef);
            return;
        }
        $files{$file} = {'size' => $size};
    }

    my @fkeys = (keys %files);
    if(@fkeys == 1) {
        my $key = $fkeys[0];
        torrent_d_is_multi_file($server, $infohash, sub {
        my ($res) = @_;
        if(! defined $res) {
            $cb->(undef);
        }
        if($res == 1) {
            %files = (   $name . '/' . $key => $files{$key});
        }
        $cb->(\%files);
        });
        return;
    }
    my %newfiles;
    foreach my $key (@fkeys) {
        $newfiles{$name . '/' . $key} = $files{$key};
    }
    $cb->(\%newfiles);
    });
}

sub torrent_start {
    my ($server, $torrentData, $saveto, $cb) = @_;
    my $torrent = MHFS::BitTorrent::Metainfo::Parse($torrentData);
    if(! $torrent) {
        $cb->{on_failure}->(); return;
    }
    my $asciihash = $torrent->InfohashAsHex();
    say 'infohash ' . $asciihash;

    # see if the hash is already in rtorrent
    torrent_d_bytes_done($server, $asciihash, sub {
    my ($bytes_done) = @_;
    if(! defined $bytes_done) {
        # load, set directory, and download it (race condition)
        # 02/05/2020 what race condition?
        torrent_load_raw_verbose($server, $$torrentData, sub {
        if(! defined $_[0]) { $cb->{on_failure}->(); return;}

        torrent_d_directory_set($server, $asciihash, $saveto, sub {
        if(! defined $_[0]) { $cb->{on_failure}->(); return;}

        torrent_d_start($server, $asciihash, sub {
        if(! defined $_[0]) { $cb->{on_failure}->(); return;}

        say 'starting ' . $asciihash;
        $cb->{on_success}->($asciihash);
        })})});
    }
    else {
        # set the priority and download
        torrent_set_priority($server, $asciihash, '1', sub {
        if(! defined $_[0]) { $cb->{on_failure}->(); return;}

        torrent_d_start($server, $asciihash, sub {
        if(! defined $_[0]) { $cb->{on_failure}->(); return;}

        say 'starting (existing) ' . $asciihash;
        $cb->{on_success}->($asciihash);
        })});
    }
    });
}

1;
