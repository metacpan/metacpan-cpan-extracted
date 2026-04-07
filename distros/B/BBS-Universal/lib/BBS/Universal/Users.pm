package BBS::Universal::Users;
BEGIN { our $VERSION = '0.004'; }

sub users_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Initialize']);
    $self->{'USER'}->{'mode'} = ASCII;
    $self->{'debug'}->DEBUG(['End Users Initialize']);
    return ($self);
} ## end sub users_initialize

sub users_change_access_level {
    my $self = shift;
    return (FALSE) if ($self->{'USER'}->{'username'} eq 'sysop');
    $self->{'debug'}->DEBUG(['Start Users Change Access Level']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    foreach my $result (keys %{ $self->{'access_levels'} }) {
        if (($self->{'access_levels'}->{$result} < $self->{'access_levels'}->{ $self->{'USER'}->{'access_level'} }) || $self->{'USER'}->{'access_level'} eq 'SYSOP') {
            $mapping->{ chr(65 + $self->{'access_levels'}->{$result}) } = {
                'command'      => $result,
                'color'        => 'WHITE',
                'access_level' => $self->{'USER'}->{'access_level'},
                'text'         => $result,
            };
        } ## end if (($self->{'access_levels'...}))
    } ## end foreach my $result (keys %{...})

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET date_format=? WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'date_format'} = $command;
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['End Users Change Access Level']);
    return (TRUE);
} ## end sub users_change_access_level

sub users_change_date_format {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Change Date Format']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    my $count = 1;
    foreach my $result ('YEAR/MONTH/DAY', 'MONTH/DAY/YEAR', 'DAY/MONTH/YEAR') {
        $mapping->{ chr(64 + $count) } = {
            'command'      => $result,
            'color'        => 'WHITE',
            'access_level' => 'USER',
            'text'         => $result,
        };
        $count++;
    } ## end foreach my $result ('YEAR/MONTH/DAY'...)

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET date_format=? WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'date_format'} = $command;
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['End Users Change Date Format']);
    return (TRUE);
} ## end sub users_change_date_format

sub users_change_baud_rate {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Change Baud Rate']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    my $count = 1;
    foreach my $result (qw(300 1200 2400 4800 9600 19200 FULL)) {
        $mapping->{ chr(64 + $count) } = {
            'command'      => $result,
            'color'        => 'WHITE',
            'access_level' => 'USER',
            'text'         => $result,
        };
        $count++;
    } ## end foreach my $result (qw(300 1200 2400 4800 9600 19200 FULL))

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET baud_rate=? WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'baud_rate'} = $command;
        $self->{'debug'}->DEBUG(["  Baud Rate:  $command"]);
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['End Users Change Baud Rate']);
    return (TRUE);
} ## end sub users_change_baud_rate

sub users_change_screen_size {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Change Screen Size']);
    $self->prompt("\nColumns");
    my $columns = 0 + $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'default' => $self->{'USER'}->{'max_columns'} });
    if ($columns >= 32 && $columns ne $self->{'USER'}->{'max_columns'} && $self->is_connected()) {
        $self->{'USER'}->{'max_columns'} = $columns;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET max_columns=? WHERE id=?');
        $sth->execute($columns, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Columns:  $columns"]);
    } ## end if ($columns >= 32 && ...)
    $self->prompt("\nRows");
    my $rows = 0 + $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'defult' => $self->{'USER'}->{'max_rows'} });
    if ($rows >= 25 && $rows ne $self->{'USER'}->{'max_rows'} && $self->is_connected()) {
        $self->{'USER'}->{'max_rows'} = $rows;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET max_rows=? WHERE id=?');
        $sth->execute($rows, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Rows:  $rows"]);
    } ## end if ($rows >= 25 && $rows...)
    $self->{'debug'}->DEBUG(['Start Users Change Screen Size']);
    return (TRUE);
} ## end sub users_change_screen_size

sub users_update_retro_systems {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Retro Systems']);
    $self->prompt("\nName your retro computers");
    my $retro = $self->get_line({ 'type' => STRING, 'max' => 65535, 'default' => $self->{'USER'}->{'retro_systems'} });
    if (length($retro) >= 5 && $retro ne $self->{'USER'}->{'retro_systems'} && $self->is_connected()) {
        $self->{'USER'}->{'retro_systems'} = $retro;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET retro_systems=? WHERE id=?');
        $sth->execute($retro, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Retro Systems:  $retro"]);
    } ## end if (length($retro) >= ...)
    $self->{'debug'}->DEBUG(['End Users Update Retro Systems']);
    return (TRUE);
} ## end sub users_update_retro_systems

sub users_update_email {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Email']);
    $self->prompt("\nEnter email address");
    my $email = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => $self->{'USER'}->{'email'} });
    if (length($email) > 5 && $email ne $self->{'USER'}->{'email'} && $self->is_connected()) {
        $self->{'USER'}->{'email'} = $email;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET email=? WHERE id=?');
        $sth->execute($email, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Email:  $email"]);
    } ## end if (length($email) > 5...)
    $self->{'debug'}->DEBUG(['End Users Update Email']);
    return (TRUE);
} ## end sub users_update_email

sub users_toggle_permission {
    my $self  = shift;
    my $field = shift;

    return (FALSE) if ($self->{'USER'}->{'username'} eq 'sysop');

    $self->{'debug'}->DEBUG(['Start Users Toggle Permission']);
    if (0 + $self->{'USER'}->{$field}) {
        $self->{'USER'}->{$field} = FALSE;
    } else {
        $self->{'USER'}->{$field} = TRUE;
    }
    my $sth = $self->{'dbh'}->prepare('UPDATE permissions SET ' . $field . '=? WHERE id=?');
    $sth->execute($self->{'USER'}->{$field}, $self->{'USER'}->{'id'});
    $self->{'dbh'}->commit;
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users Toggle Permission']);
    return (TRUE);
} ## end sub users_toggle_permission

sub users_update_location {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Location']);
    $self->prompt("\nEnter your location");
    my $location = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => $self->{'USER'}->{'location'} });
    if (length($location) >= 4 && $location ne $self->{'USER'}->{'location'} && $self->is_connected()) {
        $self->{'USER'}->{'location'} = $location;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET location=? WHERE id=?');
        $sth->execute($location, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Location:  $location"]);
    } ## end if (length($location) ...)
    $self->{'debug'}->DEBUG(['End Users Update Location']);
    return (TRUE);
} ## end sub users_update_location

sub users_update_accomplishments {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Accomplishments']);
    $self->prompt("\nEnter your accomplishments");
    my $accomplishments = $self->get_line({ 'type' => STRING, 'max' => 65535, 'default' => $self->{'USER'}->{'accomplishments'} });
    if (length($accomplishments) >= 4 && $accomplishments ne $self->{'USER'}->{'accomplishments'} && $self->is_connected()) {
        $self->{'USER'}->{'accomplishments'} = $accomplishments;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET accomplishments=? WHERE id=?');
        $sth->execute($accomplishments, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Accomplishments:  $accomplishments"]);
    } ## end if (length($accomplishments...))
    $self->{'debug'}->DEBUG(['End Users Update Accomplishments']);
    return (TRUE);
} ## end sub users_update_accomplishments

sub users_update_text_mode {
    my $self = shift;

    return (FALSE) if ($self->{'USER'}->{'username'} eq 'sysop');
    $self->{'debug'}->DEBUG(['Start Users Update Text Mode']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM text_modes ORDER BY text_mode');
    $sth->execute();
    my $count = 1;
    while (my $result = $sth->fetchrow_hashref()) {
        $mapping->{ chr(64 + $count) } = {
            'command'      => $result->{'text_mode'},
            'color'        => 'WHITE',
            'access_level' => 'USER',
            'text'         => $result->{'text_mode'},
        };
        $count++;
    } ## end while (my $result = $sth->...)
    $sth->finish();

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET text_mode=(SELECT id FROM text_modes WHERE text_mode=?) WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'text_mode'} = $command;
        $self->{'debug'}->DEBUG(["  Text Mode:  $command"]);
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['Start Users Update Text Mode']);
    return (TRUE);
} ## end sub users_update_text_mode

sub users_load {
    my $self     = shift;
    my $username = shift;
    my $password = shift;

    $self->{'debug'}->DEBUG(['Start Users Load']);
    my $sth;
    if ($self->{'sysop'}) {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE username=?');
        $sth->execute($username);
    } else {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE username=? AND password=SHA2(?,512)');
        $sth->execute($username, $password);
    }
    my $results  = $sth->fetchrow_hashref();
    my $response = FALSE;
    if (defined($results)) {
        $self->{'USER'} = $results;
        delete($self->{'USER'}->{'password'});
        foreach my $field (    # For numeric values
            qw(
            show_email
            prefer_nickname
            view_files
            upload_files
            download_files
            remove_files
            read_message
            post_message
            remove_message
            play_fortunes
            banned
            sysop
            )
        ) {
            $self->{'USER'}->{$field} = 0 + $self->{'USER'}->{$field};
        } ## end foreach my $field (  qw( show_email...))
        $response = TRUE;
    } ## end if (defined($results))
    $self->{'debug'}->DEBUG(['End Users Load']);
    return ($response);
} ## end sub users_load

sub users_get_date {
    my $self     = shift;
    my $old_date = shift;

    $self->{'debug'}->DEBUG(['Start User Get Date']);
    my $response;
    if ($old_date =~ / /) {
        my $time;
        ($old_date, $time) = split(/ /, $old_date);
        my ($year, $month, $day) = split(/-/, $old_date);
        my $date = $self->{'USER'}->{'date_format'};
        $date =~ s/YEAR/$year/;
        $date =~ s/MONTH/$month/;
        $date =~ s/DAY/$day/;
        $response = "$date $time";
    } else {
        my ($year, $month, $day) = split(/-/, $old_date);
        my $date = $self->{'USER'}->{'date_format'};
        $date =~ s/YEAR/$year/;
        $date =~ s/MONTH/$month/;
        $date =~ s/DAY/$day/;
        $response = $date;
    } ## end else [ if ($old_date =~ / /) ]
    $self->{'debug'}->DEBUG(['End User Get Date']);
    return ($response);
} ## end sub users_get_date

sub users_list {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users List']);
    my $sth = $self->{'dbh'}->prepare(
        q{
              SELECT username,
                     fullname,
                     nickname,
                     accomplishments,
                     retro_systems,
                     birthday,
                     prefer_nickname,
                     location
                FROM users_view
               WHERE banned=FALSE
            ORDER BY username;
        }
    );
    $sth->execute();
    my $columns = $self->{'USER'}->{'max_columns'};
    my $table;
    if ($columns <= 40) {    # Username and Fullname
        $table = Text::SimpleTable->new(10, 36);
        $table->row('USERNAME', 'FULLNAME');
    } elsif ($columns <= 64) {    # Username, Nickname and Fullname
        $table = Text::SimpleTable->new(10, 20, 32);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME');
    } elsif ($columns <= 80) {    # Username, Nickname, Fullname and Location
        $table = Text::SimpleTable->new(10, 20, 32, 32);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION');
    } elsif ($columns <= 132) {    # Username, Nickname, Fullname, Location, Retro Systems
        $table = Text::SimpleTable->new(10, 20, 30, 30, 40);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS');
    } else {                       # Username, Nickname, Fullname, Location, Retro Systems, Birthday and Accomplishments
        $table = Text::SimpleTable->new(10, 20, 32, 32, 40, 5, 100);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS', 'BDAY', 'ACCOMPLISHMENTS');
    }
    while (my $results = $sth->fetchrow_hashref()) {
        $table->hr;
        my $preferred = ($results->{'prefer_nickname'}) ? $results->{'nickname'} : $results->{'fullname'};
        if ($columns <= 40) {    # Username and Fullname
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-36s', $preferred));
        } elsif ($columns <= 64) {    # Username, Nickname and Fullname
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-32s', $preferred));
        } elsif ($columns <= 80) {    # Username, Nickname, Fullname and Location
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-32s', $preferred), sprintf('%-32s', $results->{'location'}));
        } elsif ($columns <= 132) {    # Username, Nickname, Fullname, Location, Retro Systems
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-30s', $preferred), sprintf('%-30s', $results->{'location'}), sprintf('%-40s', $results->{'retro_systems'}));
        } else {                       # Username, Nickname, Fullname, Location, Retro Systems, Birthday and Accomplishments
            my ($year, $month, $day) = split('-', $results->{'birthday'});
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-32s', $preferred), sprintf('%-32s', $results->{'location'}), sprintf('%-40s', $results->{'retro_systems'}), sprintf('%02d/%02d', $month, $day), sprintf('%-100s', $results->{'accomplishments'}));
        }
    } ## end while (my $results = $sth...)
    $sth->finish;
    my $text;
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $text = $table->boxes2('GREEN')->draw();
        foreach my $orig ('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS', 'BDAY', 'ACCOMPLISHMENTS') {
            my $ch = '[% BRIGHT YELLOW %]' . $orig . '[% RESET %]';
            $text =~ s/$orig/$ch/gs;
        }
    } elsif ($mode eq 'ATASCII') {
        $text = $self->color_border($table->boxes->draw(), '');
    } elsif ($mode eq 'PETSCII') {
        $text = $table->boxes->draw();
        foreach my $orig ('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS', 'BDAY', 'ACCOMPLISHMENTS') {
            my $ch = '[% YELLOW %]' . $orig . '[% RESET %]';
            $text =~ s/$orig/$ch/gs;
        }
        $text = $self->color_border($text, 'GREEN');
    } else {
        $text = $table->draw();
    }
    $self->{'debug'}->DEBUG(['End Users List']);
    return ($text);
} ## end sub users_list

sub users_add {
    my $self          = shift;
    my $user_template = shift;

    $self->{'debug'}->DEBUG(['Start Users Add']);
    $self->{'debug'}->DEBUGMAX([$user_template]);
    $self->{'dbh'}->begin_work;
    my $sth = $self->{'dbh'}->prepare(
        q{
            INSERT INTO users (
                username,
                given,
                family,
                nickname,
                email,
                accomplishments,
                retro_systems,
                birthday,
                location,
                baud_rate,
                text_mode,
                password)
              VALUES (?,?,?,?,?,?,?,DATE(?),?,?,(SELECT text_modes.id FROM text_modes WHERE text_modes.text_mode=?),SHA2(?,512))
        }
    );
    $sth->execute($user_template->{'username'}, $user_template->{'given'}, $user_template->{'family'}, $user_template->{'nickname'}, $user_template->{'email'}, $user_template->{'accomplishments'}, $user_template->{'retro_systems'}, $user_template->{'birthday'}, $user_template->{'location'}, $user_template->{'baud_rate'}, $user_template->{'text_mode'}, $user_template->{'password'},);
    $sth->finish;
    $sth = $self->{'dbh'}->prepare(
        q{
            INSERT INTO permissions (
                id,
                prefer_nickname,
                view_files,
                upload_files,
                download_files,
                remove_files,
                read_message,
                show_email,
                post_message,
                remove_message,
                sysop,
                play_fortunes,
                timeout)
              VALUES (LAST_INSERT_ID(),?,?,?,?,?,?,?,?,?,?,?,?,?);
        }
    );
    $sth->execute($user_template->{'prefer_nickname'}, $user_template->{'view_files'}, $user_template->{'upload_files'}, $user_template->{'download_files'}, $user_template->{'remove_files'}, $user_template->{'read_message'}, $user_template->{'show_email'}, $user_template->{'post_message'}, $user_template->{'remove_message'}, $user_template->{'sysop'}, $user_template->{'play_fortunes'}, $user_template->{'timeout'},);
    my $response;

    if ($self->{'dbh'}->err) {
        $self->{'dbh'}->rollback;
        $sth->finish();
        $response = FALSE;
    } else {
        $self->{'dbh'}->commit;
        $sth->finish();
        $response = TRUE;
    }
    $self->{'debug'}->DEBUG(['End Users Add']);
    return ($response);
} ## end sub users_add

sub users_delete {
    my $self = shift;
    my $id   = shift;

    $self->{'debug'}->DEBUG(['Start Users Delete']);
    if ($id == 1) {
        $self->{'debug'}->ERROR(['  Attempt to delete SysOp user']);
        return (FALSE);
    }
    $self->{'debug'}->WARNING(["  Delete user $id"]);
    $self->{'dbh'}->begin_work();
    my $sth = $self->{'dbh'}->prepare('DELETE FROM permissions WHERE id=?');
    $sth->execute($id);
    if ($self->{'dbh'}->err) {
        $self->{'debug'}->ERROR([$self->{'dbh'}->errstr]);
        $self->{'dbh'}->rollback();
        $sth->finish();
        $self->{'debug'}->DEBUG(['   End Users Delete']);
        return (FALSE);
    } else {
        $sth->finish();
        $sth = $self->{'dbh'}->prepare('DELETE FROM users WHERE id=?');
        $sth->execute($id);
        if ($self->{'dbh'}->err) {
            $self->{'debug'}->ERROR([$self->{'dbh'}->errstr]);
            $self->{'dbh'}->rollback();
            $sth->finish();
            $self->{'debug'}->DEBUG(['   End Users Delete']);
            return (FALSE);
        } else {
            $self->{'dbh'}->commit();
            $sth->finish();
            $self->{'debug'}->DEBUG(['   End Users Delete']);
            return (TRUE);
        } ## end else [ if ($self->{'dbh'}->err)]
    } ## end else [ if ($self->{'dbh'}->err)]
    $self->{'debug'}->DEBUG(['End Users Delete']);
} ## end sub users_delete

sub users_file_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users File Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT description FROM file_categories WHERE id=?');
    $sth->execute($self->{'USER'}->{'file_category'});
    my ($category) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users File Category']);
    if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        $category = $self->news_title_colorize($category);
    }
    return ($category);
} ## end sub users_file_category

sub users_forum_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Forum Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT description FROM message_categories WHERE id=?');
    $sth->execute($self->{'USER'}->{'forum_category'});
    my ($category) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users Forum Category']);
    return ($category);
} ## end sub users_forum_category

sub users_rss_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users RSS Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT title FROM rss_feed_categories WHERE id=?');
    $sth->execute($self->{'USER'}->{'rss_category'});
    my ($category) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users RSS Category']);
    return ($category);
} ## end sub users_rss_category

sub users_find {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start Users Find']);
    $self->{'debug'}->DEBUG(['End Users Find']);
    return (TRUE);
} ## end sub users_find

sub users_count {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Count']);
    my $sth = $self->{'dbh'}->prepare('SELECT COUNT(*) FROM users');
    $sth->execute();
    my ($count) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users Count']);
    return ($count);
} ## end sub users_count

sub users_info {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Info']);
    my $table;
    my $text  = '';
    my $width = 1;

    foreach my $field (keys %{ $self->{'USER'} }) {
        $width = max($width, length($self->{'USER'}->{$field}));
    }

    my $columns = $self->{'USER'}->{'max_columns'};
    $self->{'debug'}->DEBUG(["  $columns Columns"]);
    if ($columns <= 40) {
        $table = sprintf('%-15s=%-25s', 'FIELD', 'VALUE') . "\n";
        $table .= '-' x $self->{'USER'}->{'max_columns'} . "\n";
        $table .= sprintf('%-15s=%-25s', 'ACCOUNT NUMBER',  $self->{'USER'}->{'id'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'USERNAME',        $self->{'USER'}->{'username'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'FULL NAME',       $self->{'USER'}->{'fullname'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'NICKNAME',        $self->{'USER'}->{'nickname'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'EMAIL',           $self->{'USER'}->{'email'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'DATE FORMAT',     $self->{'USER'}->{'date_format'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'SCREEN',          $self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'BIRTHDAY',        $self->users_get_date($self->{'USER'}->{'birthday'})) . "\n";
        $table .= sprintf('%-15s=%-25s', 'LOCATION',        $self->{'USER'}->{'location'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'BAUD RATE',       $self->{'USER'}->{'baud_rate'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'LAST LOGIN',      $self->{'USER'}->{'login_time'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'LAST LOGOUT',     $self->{'USER'}->{'logout_time'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'TEXT MODE',       $self->{'USER'}->{'text_mode'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'IDLE TIMEOUT',    $self->{'USER'}->{'timeout'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'SHOW EMAIL',      $self->yes_no($self->{'USER'}->{'show_email'},      FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'PREFER NICKNAME', $self->yes_no($self->{'USER'}->{'prefer_nickname'}, FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'VIEW FILES',      $self->yes_no($self->{'USER'}->{'view_files'},      FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'UPLOAD FILES',    $self->yes_no($self->{'USER'}->{'upload_files'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'DOWNLOAD FILES',  $self->yes_no($self->{'USER'}->{'download_files'},  FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'REMOVE FILES',    $self->yes_no($self->{'USER'}->{'remove_files'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'READ MESSAGES',   $self->yes_no($self->{'USER'}->{'read_message'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'POST MESSAGES',   $self->yes_no($self->{'USER'}->{'post_message'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'REMOVE MESSAGES', $self->yes_no($self->{'USER'}->{'remove_message'},  FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'PLAY FORTUNES',   $self->yes_no($self->{'USER'}->{'play_fortunes'},   FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'ACCESS LEVEL',    $self->{'USER'}->{'access_level'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'RETRO SYSTEMS',   $self->{'USER'}->{'retro_systems'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'ACCOMPLISHMENTS', $self->{'USER'}->{'accomplishments'}) . "\n";
    } elsif ((($width + 22) * 2) <= $columns) {
        $table = Text::SimpleTable->new(15, $width, 15, $width);
        $table->row('FIELD', 'VALUE', 'FIELD', 'VALUE');
        $table->hr();
        $table->row('ACCOUNT NUMBER',  $self->{'USER'}->{'id'},                                    'USERNAME',        $self->{'USER'}->{'username'});
        $table->row('FULLNAME',        $self->{'USER'}->{'fullname'},                              'NICKNAME',        $self->{'USER'}->{'nickname'});
        $table->row('EMAIL',           $self->{'USER'}->{'email'},                                 'SCREEN',          $self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'});
        $table->row('BIRTHDAY',        $self->users_get_date($self->{'USER'}->{'birthday'}),       'LOCATION',        $self->{'USER'}->{'location'});
        $table->row('BAUD RATE',       $self->{'USER'}->{'baud_rate'},                             'LAST LOGIN',      $self->users_get_date($self->{'USER'}->{'login_time'}));
        $table->row('DATE FORMAT',     $self->{'USER'}->{'date_format'},                           'LAST LOGOUT',     $self->users_get_date($self->{'USER'}->{'logout_time'}));
        $table->row('IDLE TIMEOUT',    $self->{'USER'}->{'timeout'},                               'TEXT MODE',       $self->{'USER'}->{'text_mode'});
        $table->row('PREFER NICKNAME', $self->yes_no($self->{'USER'}->{'prefer_nickname'}, FALSE), 'VIEW FILES',      $self->yes_no($self->{'USER'}->{'view_files'}, FALSE));
        $table->row('UPLOAD FILES',    $self->yes_no($self->{'USER'}->{'upload_files'}, FALSE),    'DOWNLOAD FILES',  $self->yes_no($self->{'USER'}->{'download_files'}, FALSE));
        $table->row('REMOVE FILES',    $self->yes_no($self->{'USER'}->{'remove_files'}, FALSE),    'READ MESSAGES',   $self->yes_no($self->{'USER'}->{'read_message'}, FALSE));
        $table->row('POST MESSAGES',   $self->yes_no($self->{'USER'}->{'post_message'}, FALSE),    'REMOVE MESSAGES', $self->yes_no($self->{'USER'}->{'remove_message'}, FALSE));
        $table->row('SHOW EMAIL',      $self->yes_no($self->{'USER'}->{'show_email'}, FALSE),      'ACCESS LEVEL',    $self->{'USER'}->{'access_level'});
		$table->row('PLAY FORTUNES',   $self->yes_no($self->{'USER'}->{'play_fortunes'}, FALSE),   'ACCOMPLISHMENTS', $self->{'USER'}->{'accomplishments'});
		$table->row('RETRO SYSTEMS',   $self->{'USER'}->{'retro_systems'},'','');
    } else {
        $width = min($width + 7, $self->{'USER'}->{'max_columns'} - 7);
        $table = Text::SimpleTable->new(15, $width);
        $table->row('FIELD', 'VALUE');
        $table->hr();
        $table->row('ACCOUNT NUMBER',  $self->{'USER'}->{'id'});
        $table->row('USERNAME',        $self->{'USER'}->{'username'});
        $table->row('FULLNAME',        $self->{'USER'}->{'fullname'});
        $table->row('NICKNAME',        $self->{'USER'}->{'nickname'});
        $table->row('EMAIL',           $self->{'USER'}->{'email'});
        $table->row('DATE FORMAT',     $self->{'USER'}->{'date_format'});
        $table->row('SCREEN',          $self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'});
        $table->row('BIRTHDAY',        $self->users_get_date($self->{'USER'}->{'birthday'}));
        $table->row('LOCATION',        $self->{'USER'}->{'location'});
        $table->row('BAUD RATE',       $self->{'USER'}->{'baud_rate'});
        $table->row('LAST LOGIN',      $self->{'USER'}->{'login_time'});
        $table->row('LAST LOGOUT',     $self->{'USER'}->{'logout_time'});
        $table->row('TEXT MODE',       $self->{'USER'}->{'text_mode'});
        $table->row('IDLE TIMEOUT',    $self->{'USER'}->{'timeout'});
        $table->row('SHOW EMAIL',      $self->yes_no($self->{'USER'}->{'show_email'},      FALSE));
        $table->row('PREFER NICKNAME', $self->yes_no($self->{'USER'}->{'prefer_nickname'}, FALSE));
        $table->row('VIEW FILES',      $self->yes_no($self->{'USER'}->{'view_files'},      FALSE));
        $table->row('UPLOAD FILES',    $self->yes_no($self->{'USER'}->{'upload_files'},    FALSE));
        $table->row('DOWNLOAD FILES',  $self->yes_no($self->{'USER'}->{'download_files'},  FALSE));
        $table->row('REMOVE FILES',    $self->yes_no($self->{'USER'}->{'remove_files'},    FALSE));
        $table->row('READ MESSAGES',   $self->yes_no($self->{'USER'}->{'read_message'},    FALSE));
        $table->row('POST MESSAGES',   $self->yes_no($self->{'USER'}->{'post_message'},    FALSE));
        $table->row('REMOVE MESSAGES', $self->yes_no($self->{'USER'}->{'remove_message'},  FALSE));
        $table->row('PLAY FORTUNES',   $self->yes_no($self->{'USER'}->{'play_fortunes'},   FALSE));
        $table->row('ACCESS LEVEL',    $self->{'USER'}->{'access_level'});
        $table->row('RETRO SYSTEMS',   $self->{'USER'}->{'retro_systems'});
        $table->row('ACCOMPLISHMENTS', $self->{'USER'}->{'accomplishments'});
    } ## end else [ if ($columns <= 40) ]

    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ATASCII') {
        $text = $self->color_border($table->boxes->draw(), 'WHITE');
    } elsif ($mode eq 'ANSI') {
        $text = $table->boxes2('RGB 0,90,190')->draw();
        my $no    = colored(['red'],           'NO');
        my $yes   = colored(['green'],         'YES');
        my $field = colored(['bright_yellow'], 'FIELD');
        my $va    = colored(['bright_yellow'], 'VALUE');
        $text =~ s/ FIELD / $field /gs;
        $text =~ s/ VALUE / $va /gs;
        $text =~ s/ NO / $no /gs;
        $text =~ s/ YES / $yes /gs;

        foreach $field ('PLAY FORTUNES', 'ACCESS LEVEL', 'SUFFIX', 'ACCOUNT NUMBER', 'USERNAME', 'FULLNAME', 'SCREEN', 'BIRTHDAY', 'LOCATION', 'BAUD RATE', 'LAST LOGIN', 'LAST LOGOUT', 'TEXT MODE', 'IDLE TIMEOUT', 'RETRO SYSTEMS', 'ACCOMPLISHMENTS', 'SHOW EMAIL', 'PREFER NICKNAME', 'VIEW FILES', 'UPLOAD FILES', 'DOWNLOAD FILES', 'REMOVE FILES', 'READ MESSAGES', 'POST MESSAGES', 'REMOVE MESSAGES', 'EMAIL', 'NICKNAME', 'DATE FORMAT') {
            my $ch = colored(['yellow'], $field);
            $text =~ s/$field/$ch/gs;
        }
    } elsif ($mode eq 'PETSCII') {
        $text = $table->boxes->draw();
        my $no    = '[% RED %]NO[% RESET %]';
        my $yes   = '[% GREEN %]YES[% RESET %]';
        my $field = '[% YELLOW %]FIELD[% RESET %]';
        my $va    = '[% YELLOW %]VALUE[% RESET %]';
        $text =~ s/ FIELD / $field /gs;
        $text =~ s/ VALUE / $va /gs;
        $text =~ s/ NO / $no /gs;
        $text =~ s/ YES / $yes /gs;

        foreach $field ('PLAY FORTUNES', 'ACCESS LEVEL', 'SUFFIX', 'ACCOUNT NUMBER', 'USERNAME', 'FULLNAME', 'SCREEN', 'BIRTHDAY', 'LOCATION', 'BAUD RATE', 'LAST LOGIN', 'LAST LOGOUT', 'TEXT MODE', 'IDLE TIMEOUT', 'RETRO SYSTEMS', 'ACCOMPLISHMENTS', 'SHOW EMAIL', 'PREFER NICKNAME', 'VIEW FILES', 'UPLOAD FILES', 'DOWNLOAD FILES', 'REMOVE FILES', 'READ MESSAGES', 'POST MESSAGES', 'REMOVE MESSAGES', 'EMAIL', 'NICKNAME', 'DATE FORMAT') {
            my $ch = '[% BROWN %]' . $field . '[% RESET %]';
            $text =~ s/$field/$ch/gs;
        }
        $text = $self->color_border($text, 'BLUE');
    } else {
        $text = $table->draw();
    }
    $self->{'debug'}->DEBUG(['End Users Info']);
    return ($text);
} ## end sub users_info
1;
