package BBS::Universal::BBS_List;
BEGIN { our $VERSION = '0.002'; }

sub bbs_list_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start BBS List Initialize']);
    $self->{'debug'}->DEBUG(['End BBS List Initialize']);
    return ($self);
} ## end sub bbs_list_initialize

sub bbs_list_add {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start BBS List Add']);

    my $index    = 0;
    my $response = TRUE;
    $self->prompt('What is the BBS Name');
    my $bbs_name = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
    $self->{'debug'}->DEBUG(["  BBS NAme:  $bbs_name"]);
    $self->output("\n");
    if ($bbs_name ne '' && length($bbs_name) > 3) {
        $self->prompt('What is the Hostname');
        my $bbs_hostname = $self->get_line({ 'type' => HOST, 'max' => 255, 'default' => '' });
        $self->{'debug'}->DEBUG(["  BBS Hostname:  $bbs_hostname"]);
        $self->output("\n");
        if ($bbs_hostname ne '' && length($bbs_hostname) > 5) {
            $self->prompt('What is the Port number');
            my $bbs_port = $self->get_line({ 'type' => NUMERIC, 'max' => 5, 'default' => '' });
            $self->{'debug'}->DEBUG(["  BBS Port:  $bbs_port"]);
            $self->output("\n");
            if ($bbs_port ne '' && $bbs_port =~ /^\d+$/) {
                $self->{'debug'}->DEBUG(["  Adding BBS Entry"]);
                $self->output('Adding BBS Entry...');
                my $sth = $self->{'dbh'}->prepare('INSERT INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES (?,?,?,1)');
                $sth->execute($bbs_name, $bbs_hostname, $bbs_port);
                $sth->finish();
            } else {
                $response = FALSE;
            }
        } else {
            $response = FALSE;
        }
    } else {
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['End BBS List Add']);
    return ($response);
} ## end sub bbs_list_add

sub bbs_list {
    my $self   = shift;
    my $search = shift;

    $self->{'debug'}->DEBUG(['Start BBS List']);
    my $sth;
    my $string;
    my $mode = $self->{'USER'}->{'text_mode'};
    my $ch;
    if ($search) {
        $self->{'debug'}->DEBUG(['  Search BBS List']);
        $self->prompt('Please Enter The BBS To Search For');
        $string = $self->get_line({ 'type' => HOST, 'max' => 255, 'default' => '' });
        $self->{'debug'}->DEBUG(["  Search String:  $string"]);
        return (FALSE) unless (defined($string) && $string ne '');
        $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view WHERE bbs_name LIKE ? ORDER BY bbs_name');
        $sth->execute('%' . $string . '%');
        $self->output("\n\n");

        if ($mode eq 'ANSI') {
            $ch = '[% GREEN %]' . $string . '[% RESET %]';
            $self->output("[% B_BRIGHT YELLOW %][% BLACK %] Search BBS listing for [% RESET %] $ch\n\n");
        } elsif ($mode eq 'ATASCII') {
            $ch = $string;
            $self->output("Search BBS listing for $ch\n\n");
        } elsif ($mode eq 'PETSCII') {
            $ch = '[% GREEN %]' . $string . '[% RESET %]';
            $self->output("[% YELLOW %]Search BBS listing for[% RESET %] $ch\n\n");
        } else {
            $ch = $string;
            $self->output("Search BBS listing for '$string'\n\n");
        }
    } else {
        $self->{'debug'}->DEBUG(['  BBS List Full']);
        $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view ORDER BY bbs_name');
        $sth->execute();
        $self->output("\n\nShow full BBS list\n\n");
    } ## end else [ if ($search) ]
    $self->{'debug'}->DEBUG(['  BBS Listing - DB query complete']);
    my @listing;
    my ($name_size, $hostname_size, $poster_size) = (4, 14, 6);
    while (my $row = $sth->fetchrow_hashref()) {
        push(@listing, $row);
        $name_size     = max(length($row->{'bbs_name'}),     $name_size);
        $hostname_size = max(length($row->{'bbs_hostname'}), $hostname_size);
        $poster_size   = max(length($row->{'bbs_poster'}),   $poster_size);
    } ## end while (my $row = $sth->fetchrow_hashref...)
    $self->{'debug'}->DEBUGMAX(\@listing);
    if (scalar(@listing)) {
        my $table;
        if ($self->{'USER'}->{'max_columns'} > 40) {
            $table = Text::SimpleTable->new($name_size, $hostname_size, 5, $poster_size);
            $table->row('NAME', 'HOSTNAME/PHONE', 'PORT', 'POSTER');
            $table->hr();
            foreach my $line (@listing) {
                $table->row($line->{'bbs_name'}, $line->{'bbs_hostname'}, $line->{'bbs_port'}, $line->{'bbs_poster'});
            }
        } else {
            $table = Text::SimpleTable->new($name_size, $hostname_size);
            $table->row('NAME', 'HOSTNAME/PHONE');
            $table->hr();
            foreach my $line (@listing) {
                $table->row($line->{'bbs_name'}, $line->{'bbs_hostname'} . ':' . $line->{'bbs_port'});
            }
        } ## end else [ if ($self->{'USER'}->{...})]
        my $response;
        if ($mode eq 'ANSI') {
            $response = $table->boxes2('BRIGHT BLUE')->draw();
            while ($response =~ / (NAME|HOSTNAME.PHONE|PORT|POSTER) /) {
                my $ch  = $1;
                my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                $response =~ s/ $ch / $new /gs;
            }
        } elsif ($mode eq 'ATASCII') {
            $response = $self->color_border($table->boxes->draw(), '');
        } elsif ($mode eq 'PETSCII') {
            $response = $table->boxes->draw();
            while ($response =~ / (NAME|HOSTNAME.PHONE|PORT|POSTER) /) {
                my $ch  = $1;
                my $new = '[% YELLOW %]' . $ch . '[% WHITE %]';
                $response =~ s/ $ch / $new /gs;
            }
            $response = $self->color_border($response, 'BRIGHT BLUE');
        } else {
            $response = $table->draw();
        }
        $response =~ s/$string/$ch/gs if ($search);
        $self->output($response);
    } ## end if (scalar(@listing))
    $self->output("\n\nPress any key to continue\n");
    $self->get_key(SILENT, BLOCKING);
    $self->{'debug'}->DEBUG(['End BBS List']);
    return (TRUE);
} ## end sub bbs_list
1;
