package BBS::Universal::FileTransfer;
BEGIN { our $VERSION = '0.008'; }

sub filetransfer_initialize {
    my ($self) = @_;
    $self->{'debug'}->DEBUG(['Start FileTransfer Initialize']);
    $self->{'debug'}->DEBUG(['End FileTransfer Initialize']);
    return ($self);
} ## end sub filetransfer_initialize

sub files_type {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start File Type']);
    my @tmp = split(/\./, $file);
    my $ext = uc(pop(@tmp));
    my $sth = $self->{'dbh'}->prepare('SELECT type FROM file_types WHERE extension=?');
    $sth->execute($ext);
    my $name;
    if ($sth->rows > 0) {
        $name = $sth->fetchrow_array();
    }
    $sth->finish();
    $self->{'debug'}->DEBUG(['End File Type']);
    return ($ext, $name);
} ## end sub files_type

sub files_load_file {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start Files Load File']);
    my $filename = sprintf('%s.%s', $file, $self->{'USER'}->{'text_mode'});
    $self->{'CACHE'}->set(sprintf('SERVER %02d %s', $self->{'thread_number'}, 'CURRENT MENU FILE'), $filename);
    open(my $FILE, '<', $filename);
    my @text = <$FILE>;
    close($FILE);
    chomp(@text);
    $self->{'debug'}->DEBUG(['End Files Load File']);
    return (join("\n", @text));
} ## end sub files_load_file

sub files_list_summary {
    my ($self, $search) = @_;

    $self->{'debug'}->DEBUG(['Start Files List Summary']);
    my $sth;
    my $filter;
    if ($search) {
        $self->prompt('Search for (blank for all)');
        $filter = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
        $sth    = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE (filename LIKE ? OR title LIKE ?) AND category_id=? ORDER BY uploaded DESC');
        $sth->execute('%' . $filter . '%', '%' . $filter . '%', $self->{'USER'}->{'file_category'});
    } else {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=? ORDER BY uploaded DESC');
        $sth->execute($self->{'USER'}->{'file_category'});
    }
    my @files;
    my $max_filename = 10;
    my $max_title    = 20;
    if ($sth->rows > 0) {
        while (my $row = $sth->fetchrow_hashref()) {
            push(@files, $row);
            $max_filename = max(length($row->{'filename'}), $max_filename);
            $max_title    = max(length($row->{'title'}),    $max_title);
        }
        my $table = Text::SimpleTable->new($max_filename, $max_title);
        $table->row('FILENAME', 'TITLE');
        $table->hr();
        foreach my $record (@files) {
            $table->row($record->{'filename'}, $record->{'title'});
        }
        my $mode = $self->{'USER'}->{'text_mode'};
        if ($mode eq 'ANSI') {
            my $text = $table->boxes2('MAGENTA')->draw();
            while ($text =~ / (FILENAME|TITLE) /s) {
                my $ch  = $1;
                my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                $text =~ s/ $ch / $new /gs;
            }
            $self->output("\n$text");
        } elsif ($mode eq 'ATASCII') {
            $self->output("\n" . $self->color_border($table->boxes->draw(), 'MAGENTA'));
        } elsif ($mode eq 'PETSCII') {
            my $text = $table->boxes->draw();
            while ($text =~ / (FILENAME|TITLE) /s) {
                my $ch  = $1;
                my $new = '[% YELLOW %]' . $ch . '[% RESET %]';
                $text =~ s/ $ch / $new /gs;
            }
            $self->output("\n" . $self->color_border($text, 'PURPLE'));
        } else {
            $self->output("\n" . $table->draw());
        }
    } elsif ($search) {
        $self->output("\nSorry '$filter' not found");
    } else {
        $self->output("\nSorry, this file category is empty\n");
    }
    $self->output("\nPress a key to continue ...");
    $self->get_key(ECHO, BLOCKING);
    $self->{'debug'}->DEBUG(['End Files List Summary']);
    return (TRUE);
} ## end sub files_list_summary

sub files_choices {
    my ($self, $record) = @_;

    while ($self->is_connected()) {
        my $view    = FALSE;
        my $mapping = {
            'TEXT' => '',
            'Z'    => { 'command' => 'BACK',        'color' => 'WHITE', 'access_level' => 'USER',         'text' => 'Return to File Menu' },
            'N'    => { 'command' => 'NEXT',        'color' => 'BLUE',  'access_level' => 'USER',         'text' => 'Next file' },
            'D'    => { 'command' => 'DOWNLOAD',    'color' => 'CYAN',  'access_level' => 'VETERAN',      'text' => 'Download file' },
            'R'    => { 'command' => 'REMOVE FILE', 'color' => 'RED',   'access_level' => 'JUNIOR SYSOP', 'text' => 'Remove file' },
        };
        if ($record->{'extension'} =~ /^(TXT|ASC|ATA|PET|VT|ANS|MD|INF|CDF|PL|PM|PY|C|CPP|H|SH|CSS|HTM|HTML|SHTML|JS|JAVA|XML|BAT)$/ && $self->check_access_level('VETERAN')) {
            $view = TRUE;
            $mapping->{'V'} = { 'command' => 'VIEW FILE', 'color' => 'CYAN', 'access_level' => 'VETERAN', 'text' => 'View file' };
        } ## end if ($record->{'extension'...})
        $self->show_choices($mapping);
        $self->prompt('Choose');
        my $key;
        do {
            $key = uc($self->get_key());
        } until ($key =~ /D|N|Z/ || ($key eq 'V' && $view) || ($key eq 'R' && $self->check_access_level('JUNION SYSOP')));
        $self->output($mapping->{$key}->{'command'} . "\n");
        if ($mapping->{$key}->{'command'} eq 'DOWNLOAD') {
            my $file = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $record->{'filename'};
            $mapping = {
                'B' => { 'command' => 'BACK',   'color' => 'WHITE',       'access_level' => 'USER',    'text' => 'Return to File Menu' },
                'Y' => { 'command' => 'YMODEM', 'color' => 'YELLOW',      'access_level' => 'VETERAN', 'text' => 'Download with the Ymodem protocol' },
                'X' => { 'command' => 'XMODEM', 'color' => 'BRIGHT BLUE', 'access_level' => 'VETERAN', 'text' => 'Download with the Xmodem protocol' },
                'Z' => { 'command' => 'ZMODEM', 'color' => 'GREEN',       'access_level' => 'VETERAN', 'text' => 'Download with the Zmodem protocol' },
            };
            $self->show_choices($mapping);
            $self->prompt('Choose');
            do {
                $key = uc($self->get_key());
            } until ($key =~ /B|X|Y|Z/);
            $self->output($mapping->{$key}->{'command'});
            if ($mapping->{$key}->{'command'} eq 'XMODEM') {
                system('sz', '--xmodem', '--quiet', '--binary', $file);
            } elsif ($mapping->{$key}->{'command'} eq 'YMODEM') {
                system('sz', '--ymodem', '--quiet', '--binary', $file);
            } elsif ($mapping->{$key}->{'command'} eq 'ZMODEM') {
                system('sz', '--zmodem', '--quiet', '--binary', '--resume', $file);
            } else {
                return (FALSE);
            }
            return (TRUE);
        } elsif ($mapping->{$key}->{'command'} eq 'VIEW FILE' && $self->check_access_level($mapping->{$key}->{'access_level'})) {
            my $file = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $record->{'filename'};
            open(my $VIEW, '<', $file);
            binmode($VIEW, ":encoding(UTF-8)");
            my $data;
            read($VIEW, $data, $record->{'file_size'}, 0);
            close($VIEW);
            $self->output('[% CLS %]' . $data . '[% RESET %]');
        } elsif ($mapping->{$key}->{'command'} eq 'REMOVE FILE' && $self->check_access_level($mapping->{$key}->{'access_level'})) {
            return (TRUE);
        } elsif ($mapping->{$key}->{'command'} eq 'NEXT') {
            return (TRUE);
        } elsif ($mapping->{$key}->{'command'} eq 'BACK') {
            return (FALSE);
        }
    } ## end while ($self->is_connected...)
} ## end sub files_choices

sub files_upload_choices {
    my ($self) = @_;
    my $ckey;

    $self->prompt('File Name? ');
    my $file = $self->get_line({ 'type' => FILENAME, 'max' => 255, 'default' => '' });
    my $ext  = uc($file =~ /\.(.*?)$/);

    $self->prompt('Title (Fiendly name)? ');
    my $title = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });

    $self->prompt('Description? ');
    my $description = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });

    my $file_category = $self->{'USER'}->{'file_category'};

    my $mapping = {
        'B' => { 'command' => 'BACK',   'color' => 'WHITE',       'access_level' => 'USER',    'text' => 'Return to File Menu' },
        'Y' => { 'command' => 'YMODEM', 'color' => 'YELLOW',      'access_level' => 'VETERAN', 'text' => 'Upload with the Ymodem protocol' },
        'X' => { 'command' => 'XMODEM', 'color' => 'BRIGHT BLUE', 'access_level' => 'VETERAN', 'text' => 'Upload with the Xmodem protocol' },
        'Z' => { 'command' => 'ZMODEM', 'color' => 'GREEN',       'access_level' => 'VETERAN', 'text' => 'Upload with the Zmodem protocol' },
    };
    $self->show_choices($mapping);
    $self->prompt('Choose');
    do {
        $ckey = uc($self->get_key());
    } until ($ckey =~ /B|X|Y|Z/);
    $self->output($mapping->{$ckey}->{'command'});
    if ($mapping->{$ckey}->{'command'} eq 'XMODEM') {
        if ($self->files_receive_file($file, XMODEM)) {
            my $filename = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
            my $size     = (-s $filename);
            my $sth      = $self->{'dbh'}->prepare('INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES (?,?,?,(SELECT id FROM file_types WHERE extension=?),?,?');
            $sth->execute($file_category, $file, $title, $ext, $description, $size);
            $sth->finish();
        } ## end if ($self->files_receive_file...)
    } elsif ($mapping->{$ckey}->{'command'} eq 'YMODEM') {
        if ($self->files_receive_file($file, YMODEM)) {
            my $filename = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
            my $size     = (-s $filename);
            my $sth      = $self->{'dbh'}->prepare('INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES (?,?,?,(SELECT id FROM file_types WHERE extension=?),?,?');
            $sth->execute($file_category, $file, $title, $ext, $description, $size);
            $sth->finish();
        } ## end if ($self->files_receive_file...)
    } elsif ($mapping->{$ckey}->{'command'} eq 'ZMODEM') {
        if ($self->files_receive_file($file, ZMODEM)) {
            my $filename = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
            my $size     = (-s $filename);
            my $sth      = $self->{'dbh'}->prepare('INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES (?,?,?,(SELECT id FROM file_types WHERE extension=?),?,?');
            $sth->execute($file_category, $file, $title, $ext, $description, $size);
            $sth->finish();
        } ## end if ($self->files_receive_file...)
    } else {
        return (FALSE);
    }
    if ($? == -1) {
        $self->{'debug'}->ERROR(["Could not execute rz:  $!"]);
    } elsif ($? & 127) {
        $self->{'debug'}->ERROR(["File Transfer Aborted:  $!"]);
    } else {
        $self->{'debug'}->DEBUG(['File Transfer Successful']);
    }
    return (TRUE);
} ## end sub files_upload_choices

sub files_list_detailed {
    my ($self, $search) = @_;

    $self->{'debug'}->DEBUG(['Start Files List Detailed']);
    my $sth;
    my $filter;
    my $columns = $self->{'USER'}->{'max_columns'};
    if ($search) {
        $self->prompt('Search for');
        $filter = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
        $sth    = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE (filename LIKE ? OR title LIKE ?) AND category_id=? ORDER BY uploaded DESC');
        $sth->execute('%' . $filter . '%', '%' . $filter . '%', $self->{'USER'}->{'file_category'});
    } else {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=? ORDER BY uploaded DESC');
        $sth->execute($self->{'USER'}->{'file_category'});
    }
    my @files;
    if ($sth->rows > 0) {
        $self->{'debug'}->DEBUGMAX(\@files);
        my $table;
        my $mode = $self->{'USER'}->{'text_mode'};
        while (my $row = $sth->fetchrow_hashref()) {
            push(@files, $row);
        }
        $sth->finish();
        foreach my $record (@files) {
            if ($mode eq 'ANSI') {
                $self->output("\n" . '[% HORIZONTAL RULE GREEN %]' . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]       TITLE [% RESET %] ' . $record->{'title'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]    FILENAME [% RESET %] ' . $record->{'filename'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]   FILE SIZE [% RESET %] ' . format_number($record->{'file_size'}) . "\n");
                if ($record->{'prefer_nickname'}) {
                    $self->output('[% B_BLUE %][% BRIGHT WHITE %]    UPLOADER [% RESET %] ' . $record->{'nickname'} . "\n");
                } else {
                    $self->output('[% B_BLUE %][% BRIGHT WHITE %]    UPLOADER [% RESET %] ' . $record->{'fullname'} . "\n");
                }
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]   FILE TYPE [% RESET %] ' . $record->{'type'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]    UPLOADED [% RESET %] ' . $record->{'uploaded'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]      THUMBS [% RESET %] [% THUMBS UP SIGN %] ' . (0 + $record->{'thumbs_up'}) . '   [% THUMBS DOWN SIGN %] ' . (0 + $record->{'tumbs_down'}) . "\n");
                $self->output('[% HORIZONTAL RULE GREEN %]' . "\n");
            } else {
                $self->output("\n      TITLE: " . $record->{'title'} . "\n");
                $self->output('   FILENAME: ' . $record->{'filename'} . "\n");
                $self->output('  FILE SIZE: ' . format_number($record->{'file_size'}) . "\n");
                if ($record->{'prefer_nickname'}) {
                    $self->output('   UPLOADER: ' . $record->{'nickname'} . "\n");
                } else {
                    $self->output('   UPLOADER: ' . $record->{'fullname'} . "\n");
                }
                $self->output('  FILE TYPE: ' . $record->{'type'} . "\n");
                $self->output('   UPLOADED: ' . $record->{'uploaded'} . "\n");
                $self->output('  THUMBS UP: ' . (0 + $record->{'thumbs_up'}) . "\n");
                $self->output('THUMBS DOWN: ' . (0 + $record->{'thumbs_down'}) . "\n");
            } ## end else [ if ($mode eq 'ANSI') ]
            last unless ($self->files_choices($record));
        } ## end foreach my $record (@files)
    } elsif ($search) {
        $self->output("\nSorry '$filter' not found");
    } else {
        $self->output("\nSorry, this file category is empty\n");
    }
    $self->output("\nPress a key to continue ...");
    $self->get_key(ECHO, BLOCKING);
    $self->{'debug'}->DEBUG(['End Files List Detailed']);
    return (TRUE);
} ## end sub files_list_detailed

sub files_save_file {
    my ($self) = @_;
    $self->{'debug'}->DEBUG(['Start Save File']);
    $self->{'debug'}->DEBUG(['End Save File']);
    return (TRUE);
} ## end sub files_save_file

sub files_receive_file {
    my ($self, $file, $protocol) = @_;

    my $success = TRUE;
    $self->{'debug'}->DEBUG(['Start Receive File']);
    unless ($self->{'local_mode'}) {
        if ($protocol == YMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Ymodem"]);
            $success = $self->files_receive_file_ymodem($self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file);
        } elsif ($protocol == ZMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Zmodem"]);
            $success = $self->files_receive_file_zmodem($self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file);
        } else {    # Xmodem
            $success = $self->files_receive_file_xmodem($self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file);
            $self->{'debug'}->DEBUG(["Send file $file with Xmodem"]);
        }
    } else {
        $self->output("Upload not allowed in local mode\n");
    }
    $self->{'debug'}->DEBUG(['End Receive File']);
    return ($success);
} ## end sub files_receive_file

sub files_receive_file_xmodem {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start files_receive_file_xmodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for XMODEM receive"]);
        return 0;
    }

    $self->output("\nStart sending your file via Xmodem\n");
    my $path = $file;
    my $FH;

    # Ensure directory exists
    if ($path =~ m{^(.+)/[^/]+$}) {
        my $dir = $1;
        unless (-d $dir) {
            File::Path::mkpath($dir);
        }
    } ## end if ($path =~ m{^(.+)/[^/]+$})

    unless (open $FH, '>:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file for writing $path: $!"]);
        return 0;
    }

    my $expected_blk   = 1;
    my $max_init_tries = 10;
    my $init_sent      = 0;

    # Request CRC mode by sending 'C' until sender responds with SOH/STX/EOT
    for (1 .. $max_init_tries) {
        last unless $self->is_connected();
        syswrite($sock, C_CHAR);
        $init_sent++;
        my $b = $self->_read_byte_timeout($sock, 10);
        if (defined $b && ($b eq SOH || $b eq STX || $b eq EOT || $b eq CAN)) {

            # put back the byte into variable for main loop
            $self->{'_xmodem_first'} = $b;
            last;
        } ## end if (defined $b && ($b ...))
    } ## end for (1 .. $max_init_tries)
    unless ($init_sent) {
        $self->{'debug'}->ERROR(["No response from sender to XMODEM init"]);
        close $FH;
        return 0;
    }

    my $success = 1;
  FILE_LOOP:
    while ($self->is_connected()) {

        # read first header byte
        my $hdr;
        if (defined $self->{'_xmodem_first'}) {
            $hdr = delete $self->{'_xmodem_first'};
        } else {
            $hdr = $self->_read_byte_timeout($sock, 60);
        }
        unless (defined $hdr) {
            $self->{'debug'}->ERROR(["Timeout waiting for XMODEM block header"]);
            $success = 0;
            last;
        }
        if ($hdr eq EOT) {
            # End of transmission
            syswrite($sock, ACK);
            last FILE_LOOP;
        } elsif ($hdr eq CAN) {
            $self->{'debug'}->ERROR(["Sender cancelled XMODEM transfer (CAN)"]);
            $success = 0;
            last FILE_LOOP;
        } elsif ($hdr eq SOH || $hdr eq STX) {
            my $block_size = ($hdr eq STX) ? 1024 : 128;

            # read blocknum and its complement
            my $blknum = $self->_read_byte_timeout($sock, 10);
            my $nblk   = $self->_read_byte_timeout($sock, 10);
            unless (defined $blknum && defined $nblk) {
                $self->{'debug'}->ERROR(["Timeout reading block number for XMODEM"]);
                $success = 0;
                last FILE_LOOP;
            }
            my $blknum_val = ord($blknum);
            my $nblk_val   = ord($nblk);

            # read data
            my $data = '';
            for (1 .. $block_size) {
                my $b = $self->_read_byte_timeout($sock, 10);
                unless (defined $b) {
                    $self->{'debug'}->ERROR(["Timeout reading XMODEM data block"]);
                    $success = 0;
                    last FILE_LOOP;
                }
                $data .= $b;
            } ## end for (1 .. $block_size)

            # read CRC16 (2 bytes)
            my $crc_hi = $self->_read_byte_timeout($sock, 10);
            my $crc_lo = $self->_read_byte_timeout($sock, 10);
            unless (defined $crc_hi && defined $crc_lo) {
                $self->{'debug'}->ERROR(["Timeout reading XMODEM CRC"]);
                $success = 0;
                last FILE_LOOP;
            }
            my $recv_crc = $crc_hi . $crc_lo;

            # validate block number
            if ((($blknum_val + ord($nblk)) & 0xFF) != 0xFF) {
                # invalid complement
                $self->{'debug'}->ERROR(["Invalid block number complement in XMODEM block"]);
                syswrite($sock, NAK);
                next;
            } ## end if ((($blknum_val + ord...)))
            if ($blknum_val == ($expected_blk & 0xFF)) {
                # verify CRC
                my $calc_crc = _crc16_bytes($data);
                if ($calc_crc eq $recv_crc) {
                    # write data (for XMODEM we don't have exact file size; write all and later trim if needed)
                    # strip trailing SUB (0x1A) only when they appear at the end if sender padded
                    # We'll write raw data; caller may handle size if needed.
                    print $FH $data;
                    syswrite($sock, ACK);
                    $expected_blk = ($expected_blk + 1) & 0xFF;
                } else {
                    $self->{'debug'}->ERROR(["CRC mismatch on XMODEM block $blknum_val"]);
                    syswrite($sock, NAK);
                    next;
                }
            } elsif ($blknum_val == (($expected_blk - 1) & 0xFF)) {
                # duplicate block (sender retransmitted) - ACK and ignore
                syswrite($sock, ACK);
                next;
            } else {
                # out of sequence
                $self->{'debug'}->ERROR(["Unexpected XMODEM block number $blknum_val (expected $expected_blk)"]);
                syswrite($sock, CAN x 2);
                $success = 0;
                last FILE_LOOP;
            } ## end else [ if ($blknum_val == ($expected_blk...))]
        } else {
            # unexpected byte - ignore/continue
            $self->{'debug'}->DEBUG(["Received unexpected byte during XMODEM receive: " . ord($hdr)]);
            next;
        } ## end else [ if ($hdr eq EOT) ]
    } ## end FILE_LOOP: while ($self->is_connected...)

    close $FH;
    $self->output("\nFile receive complete\n");
    $self->{'debug'}->DEBUG(['End files_receive_file_xmodem']);
    return $success;
} ## end sub files_receive_file_xmodem

sub files_receive_file_ymodem {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start files_receive_file_ymodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for YMODEM receive"]);
        return 0;
    }

    $self->output("\nStart sending your file via Ymodem\n");
    my $path = $file;

    # Ensure directory exists
    if ($path =~ m{^(.+)/[^/]+$}) {
        my $dir = $1;
        unless (-d $dir) {
            File::Path::mkpath($dir);
        }
    } ## end if ($path =~ m{^(.+)/[^/]+$})

    my $FH;
    unless (open $FH, '>:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file for writing $path: $!"]);
        return 0;
    }

    # Request CRC for YMODEM by sending 'C' to start
    my $tries   = 0;
    my $init_ok = 0;
    for (1 .. 10) {
        last unless $self->is_connected();
        syswrite($sock, C_CHAR);
        my $b = $self->_read_byte_timeout($sock, 10);
        if (defined $b) {
            # If we immediately get SOH/STX as response, proceed (put it back)
            if ($b eq SOH || $b eq STX || $b eq CAN) {
                $self->{'_ymodem_first'} = $b;
                $init_ok = 1;
                last;
            } else {
                # continue waiting for block 0
                $init_ok = 1;
                last;
            } ## end else [ if ($b eq SOH || $b eq...)]
        } ## end if (defined $b)
        $tries++;
    } ## end for (1 .. 10)
    unless ($init_ok) {
        $self->{'debug'}->ERROR(["No response from sender to YMODEM init"]);
        close $FH;
        return 0;
    }

    my $expected_blk  = 0;       # header block is block 0
    my $filesize      = undef;
    my $success       = 1;
    my $writing       = 0;
    my $bytes_written = 0;

  HEADER_LOOP:
    while ($self->is_connected()) {
        # read header/block
        my $hdr;
        if (defined $self->{'_ymodem_first'}) {
            $hdr = delete $self->{'_ymodem_first'};
        } else {
            $hdr = $self->_read_byte_timeout($sock, 60);
        }
        unless (defined $hdr) {
            $self->{'debug'}->ERROR(["Timeout waiting for YMODEM block header"]);
            $success = 0;
            last HEADER_LOOP;
        }
        if ($hdr eq CAN) {
            $self->{'debug'}->ERROR(["Sender cancelled YMODEM transfer (CAN)"]);
            $success = 0;
            last HEADER_LOOP;
        } elsif ($hdr eq EOT) {
            # Should not occur before data; but handle: ack and finish
            syswrite($sock, ACK);
            last HEADER_LOOP;
        } elsif ($hdr eq SOH || $hdr eq STX) {
            my $block_size = ($hdr eq STX) ? 1024 : 128;
            my $blknum     = $self->_read_byte_timeout($sock, 10);
            my $nblk       = $self->_read_byte_timeout($sock, 10);
            unless (defined $blknum && defined $nblk) {
                $self->{'debug'}->ERROR(["Timeout reading block number for YMODEM"]);
                $success = 0;
                last HEADER_LOOP;
            }
            my $blknum_val = ord($blknum);

            # read data
            my $data = '';
            for (1 .. $block_size) {
                my $b = $self->_read_byte_timeout($sock, 10);
                unless (defined $b) {
                    $self->{'debug'}->ERROR(["Timeout reading YMODEM data block"]);
                    $success = 0;
                    last HEADER_LOOP;
                }
                $data .= $b;
            } ## end for (1 .. $block_size)

            # read CRC16
            my $crc_hi = $self->_read_byte_timeout($sock, 10);
            my $crc_lo = $self->_read_byte_timeout($sock, 10);
            unless (defined $crc_hi && defined $crc_lo) {
                $self->{'debug'}->ERROR(["Timeout reading YMODEM CRC"]);
                $success = 0;
                last HEADER_LOOP;
            }
            my $recv_crc = $crc_hi . $crc_lo;
            my $calc_crc = _crc16_bytes($data);
            if ($calc_crc ne $recv_crc) {
                $self->{'debug'}->ERROR(["CRC mismatch on YMODEM block $blknum_val"]);
                syswrite($sock, NAK);
                next;
            }
            if ($blknum_val == $expected_blk) {
                if ($expected_blk == 0) {
                    # header block: filename\0size\0
                    my ($fname, $size_str) = split(/\0/, $data, 3);
                    if (defined $fname && $fname ne '') {
                        # parse size
                        if (defined $size_str && $size_str =~ /(\d+)/) {
                            $filesize = $1 + 0;
                        }

                        # we will use the provided $path (from caller). If needed, one could use $fname instead.
                        $writing = 1;

                        # ack header and request CRC for data blocks
                        syswrite($sock, ACK);
                        syswrite($sock, C_CHAR);
                        $expected_blk = 1;
                        next;
                    } else {
                        # empty filename => end of batch
                        syswrite($sock, ACK);
                        last HEADER_LOOP;
                    } ## end else [ if (defined $fname && ...)]
                } else {
                    # data block
                    if ($writing) {
                        # if filesize known, write only up to remaining bytes
                        if (defined $filesize) {
                            my $remaining = $filesize - $bytes_written;
                            if ($remaining <= 0) {
                                # already have enough data; ack and ignore
                            } else {
                                my $to_write = $data;
                                if (length($to_write) > $remaining) {
                                    $to_write = substr($to_write, 0, $remaining);
                                }
                                print $FH $to_write;
                                $bytes_written += length($to_write);
                            } ## end else [ if ($remaining <= 0) ]
                        } else {
                            print $FH $data;
                            $bytes_written += length($data);
                        }
                    } ## end if ($writing)
                    syswrite($sock, ACK);
                    $expected_blk = ($expected_blk + 1) & 0xFF;
                    next;
                } ## end else [ if ($expected_blk == 0)]
            } elsif ($blknum_val == (($expected_blk - 1) & 0xFF)) {
                # duplicate block - ack and continue
                syswrite($sock, ACK);
                next;
            } else {
                $self->{'debug'}->ERROR(["Unexpected YMODEM block number $blknum_val (expected $expected_blk)"]);
                syswrite($sock, CAN x 2);
                $success = 0;
                last HEADER_LOOP;
            } ## end else [ if ($blknum_val == $expected_blk)]
        } else {
            # unexpected byte - ignore and continue
            next;
        }
    } ## end HEADER_LOOP: while ($self->is_connected...)

    # After data blocks, expect EOT sequence from sender
    if ($success && $self->is_connected()) {
        my $got_eot = 0;
        for (1 .. 10) {
            my $b = $self->_read_byte_timeout($sock, 10);
            if (defined $b && $b eq EOT) {
                syswrite($sock, NAK);    # some receivers use NAK first; sender may resend EOT
                                         # wait for second EOT
                my $b2 = $self->_read_byte_timeout($sock, 10);
                if (defined $b2 && $b2 eq EOT) {
                    syswrite($sock, ACK);
                    $got_eot = 1;
                    last;
                } elsif (defined $b2 && $b2 eq ACK) {
                    $got_eot = 1;
                    last;
                } else {
                    # keep waiting
                    next;
                }
            } elsif (defined $b && $b eq CAN) {
                $self->{'debug'}->ERROR(["Sender cancelled after data (CAN)"]);
                $success = 0;
                last;
            }
        } ## end for (1 .. 10)
        unless ($got_eot) {
            $self->{'debug'}->ERROR(["No proper EOT sequence received for YMODEM"]);
            $success = 0;
        } else {
            # After EOT and ACK, sender will send an empty header block (block 0 with empty filename) to signal end of batch.
            # Read and ack it
            my $hdr = $self->_read_byte_timeout($sock, 10);
            if (defined $hdr && ($hdr eq SOH || $hdr eq STX)) {
                my $block_size = ($hdr eq STX) ? 1024 : 128;

                # read rest of block similar to above but we only need to ack it
                my $blknum = $self->_read_byte_timeout($sock, 10);
                my $nblk   = $self->_read_byte_timeout($sock, 10);
                for (1 .. $block_size) {
                    $self->_read_byte_timeout($sock, 10);
                }
                $self->_read_byte_timeout($sock, 10);
                $self->_read_byte_timeout($sock, 10);
                syswrite($sock, ACK);
            } ## end if (defined $hdr && ($hdr...))
        } ## end else
    } ## end if ($success && $self->...)

    close $FH;
    $self->output("\nFile receive complete\n");
    $self->{'debug'}->DEBUG(['End files_receive_file_ymodem']);
    return $success;
} ## end sub files_receive_file_ymodem

# CRC16-CCITT (XMODEM) calculation
sub _crc16_bytes {
    my ($data) = @_;
    my $crc = 0x0000;
    foreach my $ch (split //, $data) {
        $crc ^= (ord($ch) << 8);
        for (1 .. 8) {
            if ($crc & 0x8000) {
                $crc = (($crc << 1) & 0xFFFF) ^ 0x1021;
            } else {
                $crc = ($crc << 1) & 0xFFFF;
            }
        } ## end for (1 .. 8)
    } ## end foreach my $ch (split //, $data)
    return chr(($crc >> 8) & 0xFF) . chr($crc & 0xFF);
} ## end sub _crc16_bytes

# Read a single byte from socket with timeout (seconds)
sub _read_byte_timeout {
    my ($self, $sock, $timeout) = @_;
    $timeout ||= 10;
    my $rin = '';
    my $rout;
    my $fileno = fileno($sock);
    return undef unless defined $fileno && $fileno >= 0;
    vec($rin, $fileno, 1) = 1;
    my $nfound = select($rout = $rin, undef, undef, $timeout);

    if ($nfound > 0) {
        my $buf = '';
        my $r   = sysread($sock, $buf, 1);
        return undef unless defined $r && $r == 1;
        return $buf;
    } ## end if ($nfound > 0)
    return undef;
} ## end sub _read_byte_timeout

# Send a single XMODEM/YMODEM block (128 or 1024) using CRC16
sub _send_block {
    my ($self, $sock, $blknum, $data, $block_size) = @_;
    $block_size ||= 128;
    my $hdr = ($block_size == 1024) ? STX : SOH;
    $data .= chr(0x1A) x ($block_size - length($data));    # pad with SUB
    my $blk = $hdr . chr($blknum & 0xFF) . chr((~$blknum) & 0xFF) . $data;
    $blk .= _crc16_bytes($data);
    my $written = 0;
    my $len     = length($blk);

    while ($written < $len && $self->is_connected()) {
        my $rv = syswrite($sock, substr($blk, $written), $len - $written);
        unless (defined $rv) {
            return 0;
        }
        $written += $rv;
    } ## end while ($written < $len &&...)
    return 1;
} ## end sub _send_block

# XMODEM send (CRC mode preferred)
# Returns true on success, false on failure
sub files_send_xmodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_send_xmodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for XMODEM send"]);
        return 0;
    }
    $self->output("\nStart Xmodem download\n");
    my $path = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
    my $FH;
    unless (open $FH, '<:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file $path: $!"]);
        return 0;
    }

    # Wait for receiver request: 'C' (CRC) or NAK (checksum)
    my $init_char = _read_byte_timeout($sock, 60);
    unless (defined $init_char) {
        $self->{'debug'}->ERROR(["Timeout waiting for receiver to start XMODEM"]);
        close $FH;
        return 0;
    }

    my $use_crc = ($init_char eq C_CHAR);

    # we will always use CRC16 blocks

    my $blockno        = 1;
    my $success        = 1;
    my $retries_global = 0;
    my $eof            = 0;
    my $max_retries    = 10;

    while ($self->is_connected()) {
        my $data;
        my $n = read($FH, $data, 128);
        if (defined $n && $n > 0) {
            # send block
            my $send_ok  = 0;
            my $attempts = 0;
            while ($attempts < $max_retries && $self->is_connected()) {
                $attempts++;
                unless ($self->_send_block($sock, $blockno, $data, 128)) {
                    $self->{'debug'}->ERROR(["Failed write while sending XMODEM block $blockno"]);
                    $success = 0;
                    last;
                }
                my $resp = $self->_read_byte_timeout($sock, 10);
                unless (defined $resp) {
                    $self->{'debug'}->DEBUG(["No response for block $blockno, retry $attempts"]);
                    next;
                }
                if ($resp eq ACK) {
                    $send_ok = 1;
                    last;
                } elsif ($resp eq NAK) {
                    next;    # retransmit
                } elsif ($resp eq CAN) {
                    $self->{'debug'}->ERROR(["Received CAN during XMODEM send"]);
                    $success = 0;
                    last;
                } else {
                    # unexpected byte, retry
                    next;
                }
            } ## end while ($attempts < $max_retries...)
            unless ($send_ok) { $success = 0; last; }
            $blockno = ($blockno + 1) % 256;
        } else {
            # EOF reached
            $eof = 1;
            last;
        } ## end else [ if (defined $n && $n >...)]
    } ## end while ($self->is_connected...)

    if ($success) {
        # send EOT and wait for ACK
        my $sent = 0;
        for (1 .. 10) {
            syswrite($sock, EOT);
            my $r = $self->_read_byte_timeout($sock, 10);
            if (defined $r && $r eq ACK) { $sent = 1; last; }
        }
        unless ($sent) {
            $self->{'debug'}->ERROR(["No ACK for EOT in XMODEM send"]);
            $success = 0;
        } else {
            $self->{'debug'}->DEBUG(['XMODEM send completed']);
        }
    } ## end if ($success)

    close $FH;
    $self->output("\nFile download complete\n");
    $self->{'debug'}->DEBUG(['End files_send_xmodem']);
    return $success;
} ## end sub files_send_xmodem

# YMODEM send (simple implementation):
# - Send initial 128-byte header block with filename\0size\0
# - Then send data in 1024-byte STX blocks with CRC16
# Returns true on success, false otherwise
sub files_send_ymodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_send_ymodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for YMODEM send"]);
        return 0;
    }

    $self->output("\nStart Ymodem download\n");
    my $path = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
    my $FH;
    unless (open $FH, '<:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file $path: $!"]);
        return 0;
    }
    my $size = -s $path;
    $size = 0 unless defined $size;

    # Wait for initial 'C' (CRC) from receiver
    my $init_char = $self->_read_byte_timeout($sock, 60);
    unless (defined $init_char) {
        $self->{'debug'}->ERROR(["Timeout waiting for receiver to start YMODEM"]);
        close $FH;
        return 0;
    }

    # prepare header block (block 0)
    my $header = $file . "\0" . $size . " ";
    $header .= "\0" x (128 - length($header));

    # send header block and expect ACK then 'C'
    unless ($self->_send_block($sock, 0, $header, 128)) {
        $self->{'debug'}->ERROR(["Failed to send YMODEM header block"]);
        close $FH;
        return 0;
    }
    my $r1 = $self->_read_byte_timeout($sock, 10);
    my $r2 = $self->_read_byte_timeout($sock, 10);

    # r1 should be ACK and r2 should be 'C' to begin 1k transfer (some receivers differ)
    unless (defined $r1 && $r1 eq ACK) {
        $self->{'debug'}->ERROR(["No ACK after YMODEM header"]);
        close $FH;
        return 0;
    }

    # Send data blocks in 1K (1024) with STX header
    my $blockno = 1;
    my $success = 1;
    while ($self->is_connected()) {
        my $data;
        my $n = read($FH, $data, 1024);
        if (defined $n && $n > 0) {
            # send 1k block
            my $attempts = 0;
            my $sent_ok  = 0;
            while ($attempts < 10 && $self->is_connected()) {
                $attempts++;
                unless ($self->_send_block($sock, $blockno, $data, 1024)) {
                    $self->{'debug'}->ERROR(["Failed write while sending YMODEM block $blockno"]);
                    $success = 0;
                    last;
                }
                my $resp = $self->_read_byte_timeout($sock, 10);
                if (defined $resp && $resp eq ACK) { $sent_ok = 1; last; }
                if (defined $resp && $resp eq NAK) { next; }
                if (defined $resp && $resp eq CAN) { $self->{'debug'}->ERROR(["Received CAN during YMODEM send"]); $success = 0; last; }

                # else retry
            } ## end while ($attempts < 10 && ...)
            last unless $sent_ok && $success;
            $blockno = ($blockno + 1) % 256;
        } else {
            last;    # EOF
        }
    } ## end while ($self->is_connected...)

    if ($success) {
        # End-of-file sequence: send EOT and expect ACK, then send an empty header block (block 0 with filename "")
        my $sent = 0;
        for (1 .. 10) {
            syswrite($sock, EOT);
            my $r = _read_byte_timeout($sock, 10);
            if (defined $r && $r eq NAK) {
                # some receivers expect NAK then ACK, repeat
                next;
            } elsif (defined $r && $r eq ACK) {
                $sent = 1;
                last;
            }
        } ## end for (1 .. 10)
        unless ($sent) {
            $self->{'debug'}->ERROR(["No ACK for EOT in YMODEM send"]);
            $success = 0;
        } else {
            # Send final empty header (indicates end of batch)
            my $empty_header = "\0" x 128;
            unless (_send_block($sock, 0, $empty_header, 128)) {
                $self->{'debug'}->ERROR(["Failed to send final empty YMODEM header"]);
                $success = 0;
            } else {
                my $r = _read_byte_timeout($sock, 10);    # expect ACK
                unless (defined $r && $r eq ACK) {
                    $self->{'debug'}->ERROR(["No ACK after final YMODEM header"]);
                    $success = 0;
                }
            } ## end else
        } ## end else
    } ## end if ($success)

    close $FH;
    $self->output("\nFile download complete\n");
    $self->{'debug'}->DEBUG(['End files_send_ymodem']);
    return $success;
} ## end sub files_send_ymodem

# files_send_file: route to appropriate pure-perl sender (X/Y) or Z stub
sub files_send_file {
    my ($self, $file, $protocol) = @_;

    my $success = TRUE;
    $self->{'debug'}->DEBUG(['Start Send File']);
    unless ($self->{'local_mode'}) {    # No file transfer in local mode
        if ($protocol == YMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Ymodem (Perl)"]);
            $success = $self->files_send_ymodem($file);
        } elsif ($protocol == ZMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Zmodem (stub)"]);
            $success = $self->files_send_zmodem($file);
        } else {    # Xmodem assumed
            $self->{'debug'}->DEBUG(["Send file $file with Xmodem (Perl)"]);
            $success = $self->files_send_xmodem($file);
        }
        chdir $self->{'CONF'}->{'BBS ROOT'};
    } else {
        $self->output("Download not allowed in local mode\n");
        $success = 0;
    }
    $self->{'debug'}->DEBUG(['End Send File']);
    return ($success);
} ## end sub files_send_file

sub _run_on_socket {
    my ($self, $cmd, $args, $cwd) = @_;
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket"]);
        return 0;
    }
    my $fileno = fileno($sock);
    unless (defined $fileno && $fileno >= 0) {
        $self->{'debug'}->ERROR(["Invalid client socket fileno"]);
        return 0;
    }

    my $pid = fork();
    if (!defined $pid) {
        $self->{'debug'}->ERROR(["fork failed: $!"]);
        return 0;
    }

    if ($pid == 0) {
        # child: attach socket to STDIN/STDOUT/STDERR and exec the command
        # ensure we don't run any parent cleanup handlers
        local $SIG{CHLD} = 'DEFAULT';

        # Duplicate socket fd onto STDIN/STDOUT/STDERR
        open(STDIN,  '<&', $fileno) or POSIX::_exit(1);
        open(STDOUT, '>&', $fileno) or POSIX::_exit(1);
        open(STDERR, '>&', $fileno) or POSIX::_exit(1);
        binmode(STDIN);
        binmode(STDOUT);
        binmode(STDERR);
        if ($cwd) {
            chdir $cwd or POSIX::_exit(1);
        }

        # exec (this replaces the child)
        exec $cmd, @{ $args // [] };

        # if exec fails
        POSIX::_exit(1);
    } ## end if ($pid == 0)

    # parent: wait for child, return success based on exit status
    waitpid($pid, 0);
    my $status = $?;    # full status
    if ($status == -1) {
        $self->{'debug'}->ERROR(["Failed to waitpid for $cmd: $!"]);
        return 0;
    }
    my $exitcode = ($status >> 8) & 0xFF;
    if ($exitcode != 0) {
        $self->{'debug'}->DEBUG(["$cmd exited with code $exitcode"]);
    }
    return $exitcode == 0 ? 1 : 0;
} ## end sub _run_on_socket

sub files_send_zmodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_send_zmodem (using lrzsz)']);

    # Require lrzsz (sz) to be installed on the system.
    # sz will write to the socket (which we've dup'd to STDOUT in child).
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for ZMODEM send"]);
        return 0;
    }

    $self->output("\nStart Zmodem file download\n");

    # full path to file on server
    my $path = $file;
    unless (-e $path) {
        $self->{'debug'}->ERROR(["File not found for ZMODEM send: $path"]);
        return 0;
    }

    # Use sz --zmodem --binary --quiet --resume <file>
    # note: --resume is helpful if client requests resume. Adjust flags per your lrzsz version.
    my @args = ('--zmodem', '--binary', '--quiet', '--resume', $path);

    my $ok = $self->_run_on_socket('sz', \@args);
    $self->output("\nFile download complete\n");
    $self->{'debug'}->DEBUG(['End files_send_zmodem (using lrzsz)']);
    return $ok;
} ## end sub files_send_zmodem

sub files_receive_file_zmodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_receive_file_zmodem (using lrzsz)']);

    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for ZMODEM receive"]);
        return 0;
    }

    $self->output("\nStart Zmodem file upload\n");

    # When rz receives files it writes them into the current working directory.
    # Use the destination directory from config (same place other uploads are stored).
    my $dest_dir = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'};

    # ensure directory exists
    unless (-d $dest_dir) {
        File::Path::mkpath($dest_dir);
        if ($@) {
            $self->{'debug'}->ERROR(["Failed to create dest dir $dest_dir: $@"]);
            return 0;
        }
    } ## end unless (-d $dest_dir)

    # We will chdir in the child before exec so the received file lands in $dest_dir.
    # Use rz --binary --quiet. Depending on lrzsz version you may want --overwrite or --keep
    my @args = ('--binary', '--overwrite', '--quiet');

    my $ok = $self->_run_on_socket('rz', \@args, $dest_dir);

    $self->output("\nFile upload complete\n");
    $self->{'debug'}->DEBUG(['End files_receive_file_zmodem (using lrzsz)']);
    return $ok;
} ## end sub files_receive_file_zmodem
1;
