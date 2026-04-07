package BBS::Universal::Messages;
BEGIN { our $VERSION = '0.003'; }

sub messages_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start Messages Initialize']);
    $self->{'debug'}->DEBUG(['End Messages Initialize']);
    return ($self);
} ## end sub messages_initialize

sub messages_forum_categories {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Messages Forum Categories']);
    my $command = '';
    my $id;
    my $sth      = $self->{'dbh'}->prepare('SELECT * FROM message_categories ORDER BY description');
    my $category = $self->{'USER'}->{'forum_category'};
    $sth->execute();    # $self->{'USER'}->{'forum_category'});
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Return to Forum Menu' },
    };
    my @menu_choices = @{ $self->{'MENU CHOICES'} };

    while (my $result = $sth->fetchrow_hashref()) {
        if ($self->check_access_level($result->{'access_level'})) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $result->{'name'},
                'id'           => $result->{'id'},
                'color'        => ($category == $result->{'id'}) ? 'GREEN' : 'WHITE',
                'access_level' => $result->{'access_level'},
                'text'         => $result->{'description'},
            };
        } ## end if ($self->check_access_level...)
    } ## end while (my $result = $sth->...)
    $sth->finish();
    $self->show_choices($mapping);
    $self->prompt('Choose Forum Category');
    my $key;
    do {
        $key = uc($self->get_key(SILENT, BLOCKING));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    if ($key eq chr(3)) {
        $command = 'DISCONNECT';
    } else {
        $id      = $mapping->{$key}->{'id'};
        $command = $mapping->{$key}->{'command'};
    }
    return ($command) if ($key eq 'Z');
    if ($self->is_connected() && $command ne 'DISCONNECT') {
        $self->output($command);
        $sth = $self->{'dbh'}->prepare('UPDATE users SET forum_category=? WHERE id=?');
        $sth->execute($id, $self->{'USER'}->{'id'});
        $sth->finish();
        $self->{'USER'}->{'forum_category'} = $id;
        $command = 'BACK';
    } ## end if ($self->is_connected...)
    $self->{'debug'}->DEBUG(['End Messages Forum Categories']);
    return ($command);
} ## end sub messages_forum_categories

sub messages_list_messages {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Messages List Messages']);
    my $id;
    my $command;
    my $forum_category = $self->{'USER'}->{'forum_category'};
    my $sth            = $self->{'dbh'}->prepare('SELECT id,from_id,category,author_fullname,author_nickname,author_username,title,created FROM messages_view WHERE category=? ORDER BY created DESC');
    my @index;
    $sth->execute($forum_category);
    if ($sth->rows()) {
        while (my $record = $sth->fetchrow_hashref) {
            push(@index, $record);
        }
        $sth->finish();
        my $result;
        my $count = 0;
        do {
            $result = $index[$count];
            $sth    = $self->{'dbh'}->prepare('SELECT message FROM messages_view WHERE id=? ORDER BY created DESC');
            $sth->execute($result->{'id'});
            $result->{'message'} = $sth->fetchrow_array();
            $sth->finish();
            my $mode = $self->{'USER'}->{'text_mode'};
            if ($mode eq 'ANSI') {
                $self->output("[% CLS %][% HORIZONTAL RULE MAGENTA %][% B_MAGENTA %][% BLACK %]" . $self->pad_center('FORUM MESSAGE' . $self->{'USER'}->{'max_columns'}) . "[% RESET %]\n");
                $self->output('[% B_BRIGHT GREEN %][% BLACK %] CATEGORY [% RESET %] [% BOLD %][% GREEN %][% FORUM CATEGORY %][% RESET %]' . "\n");
                $self->output('[% BRIGHT WHITE %][% B_BLUE %]   Author [% RESET %] ');
                $self->output(($result->{'prefer_nickname'}) ? $result->{'author_nickname'} : $result->{'author_fullname'});
                $self->output(' (' . $result->{'author_username'} . ')' . "\n");
                $self->output('[% BRIGHT WHITE %][% B_BLUE %]    Title [% RESET %] ' . $result->{'title'} . "\n");
                $self->output('[% BRIGHT WHITE %][% B_BLUE %]  Created [% RESET %] ' . $self->users_get_date($result->{'created'}) . "\n\n");
                $self->output($result->{'message'}) if ($self->{'USER'}->{'read_message'});
                $self->output("\n[% HORIZONTAL RULE MAGENTA %]\n");
            } elsif ($mode eq 'PETSCII') {
                $self->output("[% CLS %][% GREEN %]== FORUM " . '=' x ($self->{'USER'}->{'max_columns'} - 7) . "[% RESET %]\n");
                $self->output('[% GREEN   %] CATEGORY [% RESET %] [% FORUM CATEGORY %]' . "\n");
                $self->output('[% YELLOW %]   Author [% RESET %] ');
                $self->output(($result->{'prefer_nickname'}) ? $result->{'author_nickname'} : $result->{'author_fullname'});
                $self->output(' (' . $result->{'author_username'} . ')' . "\n");
                $self->output('[% YELLOW %]    Title [% RESET %] ' . $result->{'title'} . "\n");
                $self->output('[% YELLOW %]  Created [% RESET %] ' . $self->users_get_date($result->{'created'}) . "\n\n");
                $self->output($result->{'message'}) if ($self->{'USER'}->{'read_message'});
                $self->output("\n[% GREEN %]" . '=' x $self->{'USER'}->{'max_columns'} . "[% RESET %]\n");
            } else {
                $self->output("[% CLS %]== FORUM " . '=' x ($self->{'USER'}->{'max_columns'} - 7) . "\n");
                $self->output(' CATEGORY > [% FORUM CATEGORY %]' . "\n");
                $self->output('  Author:  ');
                $self->output(($result->{'prefer_nickname'}) ? $result->{'nickname'} : $result->{'author_fullname'});
                $self->output(' (' . $result->{'author_username'} . ')' . "\n");
                $self->output('   Title:  ' . $result->{'title'} . "\n");
                $self->output(' Created:  ' . $self->users_get_date($result->{'created'}) . "\n\n");
                $self->output($result->{'message'}) if ($self->{'USER'}->{'read_message'});
                $self->output("\n" . '=' x $self->{'USER'}->{'max_columns'} . "\n");
            } ## end else [ if ($mode eq 'ANSI') ]
            my $mapping = {
                'Z' => { 'id' => $result->{'id'}, 'command' => 'BACK', 'color' => 'WHITE',       'access_level' => 'USER', 'text' => 'Return to the Forum Menu' },
                'N' => { 'id' => $result->{'id'}, 'command' => 'NEXT', 'color' => 'BRIGHT BLUE', 'access_level' => 'USER', 'text' => 'Next Message' },
            };
            if ($self->{'USER'}->{'post_message'}) {
                $mapping->{'R'} = { 'id' => $result->{'id'}, 'command' => 'REPLY', 'color' => 'BRIGHT GREEN', 'access_level' => 'USER', 'text' => 'Reply' };
            } ## end if ($self->{'USER'}->{...})
            if ($self->{'USER'}->{'remove_message'}) {
                $mapping->{'D'} = { 'id' => $result->{'id'}, 'command' => 'DELETE', 'color' => 'RED', 'access_level' => 'JUNIOR SYSOP', 'text' => 'Delete Message' };
            } ## end if ($self->{'USER'}->{...})
            $self->show_choices($mapping);
            $self->prompt('Choose');
            my $key;
            do {
                $key = uc($self->get_key(SILENT, FALSE));
            } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
            if ($key eq chr(3)) {
                $id      = undef;
                $command = 'DISCONNECT';
            } else {
                $id      = $mapping->{$key}->{'id'};
                $command = $mapping->{$key}->{'command'};
            }
            $self->output($command);
            if ($command eq 'REPLY') {
                my $message = $self->messages_edit_message('REPLY', $result);
                push(@index, $message);
                $count = 0;
            } elsif ($command eq 'DELETE') {
                $self->messages_delete_message($result);
                delete($index[$count]);
            } else {
                $count++;
            }
            unless ($self->{'local_mode'} || $self->{'sysop'} || $self->is_connected()) {
                $command = 'DISCONNECT';
            }
        } until ($count >= scalar(@index) || $command =~ /^(DISCONNECT|BACK)$/);
    } else {
		$self->output("\nNo messages\n\nPress any key\n");
		$self->get_key(SILENT, BLOCKING);
	} # end if ($sth->rows())
    $self->{'debug'}->DEBUG(['End Messages List Messages']);
    return (TRUE);
} ## end sub messages_list_messages

sub messages_edit_message {
    my $self        = shift;
    my $mode        = shift;
    my $old_message = (scalar(@_)) ? shift : undef;

    $self->{'debug'}->DEBUG(['Start Messages Edit Message']);
    my $message;
    if ($mode eq 'ADD') {
        $self->{'debug'}->DEBUG(['  Add Message']);
        $self->output("Add New Message\n");
        $message = $self->messages_text_editor();
        if (defined($message)) {
            $message->{'from_id'}  = $self->{'USER'}->{'id'};
            $message->{'category'} = $self->{'USER'}->{'forum_category'};
            my $sth = $self->{'dbh'}->prepare('INSERT INTO messages (category, from_id, title, message) VALUES (?, ?, ?, ?)');
            $sth->execute($message->{'category'}, $message->{'from_id'}, $message->{'title'}, $message->{'message'});
            $sth->finish();
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $self->output('[% GREEN %]Message Saved[% RESET %]');
            } else {
                $self->output('Message Saved');
            }
            $message->{'id'} = $sth->last_insert_id();
            sleep 1;
        } ## end if (defined($message))
    } elsif ($mode eq 'REPLY') {
        $self->output("  Edit Message\n");
        unless ($old_message->{'title'} =~ /^Re: /) {
            $old_message->{'title'} = 'Re: ' . $old_message->{'title'};
            $old_message->{'message'} =~ s/^(.*)/\> $1/g;
        }
        $self->output('-' x $self->{'USER'}->{'max_columns'} . "\n");
        $message = $self->messages_text_editor($old_message);
        if (defined($message)) {
            $message->{'from_id'}  = $self->{'USER'}->{'id'};
            $message->{'title'}    = $old_message->{'title'};
            $message->{'category'} = $self->{'USER'}->{'forum_category'};
            my $sth = $self->{'dbh'}->prepare('INSERT INTO messages (category, from_id, title, message) VALUES (?, ?, ?, ?)');
            $sth->execute($message->{'category'}, $message->{'from_id'}, $message->{'title'}, $message->{'message'});
            $sth->finish();
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $self->output('[% GREEN %]Message Saved[% RESET %]');
            } else {
                $self->output('Message Saved');
            }
            $message->{'id'} = $sth->last_insert_id();
            sleep 1;
        } ## end if (defined($message))
    } else {    # EDIT
        $self->output("  Edit Message\n");
        $self->output('-' x $self->{'USER'}->{'max_columns'} . "\n");
        $message = $self->messages_text_editor($old_message);
        if (defined($message)) {
            my $sth = $self->{'dbh'}->prepare('UPDATE messages SET message=? WHERE id=>');
            $sth->execute($message->{'message'}, $message->{'id'});
            $sth->finish();
            $message->{'id'} = $old_message->{'id'};
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $self->output('[% GREEN %]Message Saved[% RESET %]');
            } else {
                $self->output('Message Saved');
            }
            sleep 1;
        } ## end if (defined($message))
    } ## end else [ if ($mode eq 'ADD') ]
    $self->{'debug'}->DEBUG(['End Messages Edit Message']);
    return ($message);
} ## end sub messages_edit_message

sub messages_delete_message {
    my $self    = shift;
    my $message = shift;

    $self->{'debug'}->DEBUG(['Start Messages Delete Message']);
    my $response = FALSE;
    $self->output("\n\nReally Delete This Message?  ");
    if ($self->decision() && defined($message)) {
        my $sth = $self->{'dbh'}->prepare('UPDATE messages SET hidden=TRUE WHERE id=?');
        $sth->execute($message->{'id'});
        $sth->finish();
        $response = TRUE;
    } ## end if ($self->decision() ...)
    $self->{'debug'}->DEBUG(['End Messages Delete Message']);
    return ($response);
} ## end sub messages_delete_message

sub messages_text_editor {
    my $self    = shift;
    my $message = (scalar(@_)) ? shift : undef;

    $self->{'debug'}->DEBUG(['Start Messages Text Editor']);
    my $title = '';
    my $text  = '';
    if ($self->{'local_mode'} || $self->is_connected()) {
        if (defined($message)) {
            $title = $message->{'title'};
            $text  = $message->{'message'};
            $self->prompt('Message');
            $text = $self->messages_text_edit($title, $text);
        } else {
            $self->prompt('Title');
            $title = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
            return (undef) unless (defined($title) && $title ne '');
            $self->prompt('Message');
            $text = $self->messages_text_edit($title);
        } ## end else [ if (defined($message))]
        if (defined($text) && defined($title)) {
            $self->{'debug'}->DEBUG(['End Messages Text Editor']);
            return (
                {
                    'title'   => $title,
                    'message' => $text,
                }
            );
        } ## end if (defined($text) && ...)
    } ## end if ($self->{'local_mode'...})
    $self->{'debug'}->DEBUG(['  Abort', 'End Messages Text Editor']);
    return (undef);
} ## end sub messages_text_editor

sub messages_text_edit {
    my $self  = shift;
    my $title = (scalar(@_)) ? shift : undef;
    my $text  = (scalar(@_)) ? shift : undef;

    $self->{'debug'}->DEBUG(['Start Messages Text Edit']);
    my $columns   = $self->{'USER'}->{'max_columns'};
    my $text_mode = $self->{'USER'}->{'text_mode'};
    my @lines;
    if (defined($text) && $text ne '') {
        @lines = split(/\n$/, $text . "\n");
    }
    my $save   = FALSE;
    my $cancel = FALSE;
    do {
        my $counter = 0;
        if ($text_mode eq 'ANSI') {
            $self->output('[% CLS %][% HORIZONTAL RULE BRIGHT GREEN %][% RESET %]' . "\n");
            $self->output('[% CYAN %]Subject[% RESET %]:  ' . $title . "\n");
            $self->output('[% BRIGHT GREEN %]' . '-' x $columns . '[% RESET %]' . "\n");
            $self->output("Type a command on a line by itself\n");
            $self->output('  :[% YELLOW %]S[% RESET %] = Save and exit' . "\n");
            $self->output('  :[% RED %]Q[% RESET %] = Cancel, do not save' . "\n");
            $self->output('  :[% BRIGHT BLUE %]E[% RESET %] = Edit a specific line number (:E5 edits line 5)' . "\n");
            $self->output('[% HORIZONTAL RULE BRIGHT GREEN %][% RESET %]' . "\n");
        } elsif ($text_mode eq 'PETSCII') {
            $self->output('[% CLEAR %][% LIGHT GREEN %]' . '=' x $columns . "\n");
            $self->output('[% CYAN %]Subject[% WHITE %]:  ' . $title . "\n");
            $self->output('[% LIGHT GREEN %]' . '-' x $columns . "\n");
            $self->output('[% WHITE %]Type a command on a line by itself' . "\n");
            $self->output('  :[% YELLOW %]S[% WHITE %] = Save and exit' . "\n");
            $self->output('  :[% RED %]Q[% WHITE %] = Cancel, do not save' . "\n");
            $self->output('  :[% BLUE %]E[% WHITE %] = Edit a specific line number (:E5 edits line 5)' . "\n");
            $self->output('=' x $columns . "\n");
        } elsif ($text_mode eq 'ATASCII') {
            $self->output('[% CLEAR %]' . '=' x $columns . "\n");
            $self->output("Subject:  $title\n");
            $self->output('-' x $columns . "\n");
            $self->output("Type a command on a line by itself\n");
            $self->output("  :S = Save and exit\n");
            $self->output("  :Q = Cancel, do not save\n");
            $self->output("  :E = Edit a specific line number (:E5 edits line 5)\n");
            $self->output('=' x $columns . "\n");
        } else {    # ASCII
            $self->output('[% CLEAR %]' . '=' x $columns . "\n");
            $self->output("Subject:  $title\n");
            $self->output('-' x $columns . "\n");
            $self->output("Type a command on a line by itself\n");
            $self->output("  :S = Save and exit\n");
            $self->output("  :Q = Cancel, do not save\n");
            $self->output("  :E = Edit a specific line number (:E5 edits line 5)\n");
            $self->output('=' x $columns . "\n");
        } ## end else [ if ($text_mode eq 'ANSI')]

        foreach my $line (@lines) {
            if ($text_mode eq 'ANSI') {
                $self->output(sprintf('%s%03d%s %s', '[% CYAN %]', ($counter + 1), '[% RESET %]', $line) . "\n");
            } else {
                $self->output(sprintf('%03d %s', ($counter + 1), $line) . "\n");
            }
            $counter++;
        } ## end foreach my $line (@lines)
        my $menu = FALSE;
        do {
            if ($text_mode eq 'ANSI') {
                $self->output(sprintf('%s%03d%s ', '[% CYAN %]', ($counter + 1), '[% RESET %]'));
            } elsif ($text_mode eq 'PETSCII') {
                $self->output(sprintf('%s%03d%s ', '[% CYAN %]', ($counter + 1), '[% WHITE %]'));
            } else {
                $self->output(sprintf('%03d ', ($counter + 1)));
            }
            $text = $self->get_line({ 'type' => STRING, 'max' => $self->{'USER'}->{'max_columns'}, 'default' => '' });

            if ($text =~ /^\:(.)(.*)/i) {    # Process command
                my $command = uc($1);
                if ($command eq 'E') {
                    my $line_number = $2;
                    if ($line_number > 0) {
                        if ($text_mode eq 'ANSI') {
                            $self->output("\n" . sprintf('%s%03d%s ', '[% CYAN %]', $line_number, '[% RESET %]'));
                        } elsif ($text_mode eq 'PETSCII') {
                            $self->output(sprintf('%s%03d%s ', '[% CYAN %]', $line_number, '[% WHITE %]'));
                        } else {
                            $self->output("\n" . sprintf('%03d ', $line_number));
                        }
                        my $line = $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'default' => $self->{'USER'}->{'max_columns'}, $lines[$line_number - 1] });
                        $lines[$line_number - 1] = $line;
                    } ## end if ($line_number > 0)
                    $menu = TRUE;
                } elsif ($command eq 'S') {
                    $save = TRUE;
                } elsif ($command eq 'Q') {
                    $cancel = TRUE;
                }
            } else {
                chomp($text);
                push(@lines, $text);
                $counter++;
            }
        } until ($menu || $save || $cancel || !$self->is_connected());
    } until ($save || $cancel || !$self->is_connected());
    if ($save) {
        $text = join("\n", @lines);
    } else {
        undef($text);
    }
    $self->{'debug'}->DEBUG(['End Messages Text Edit']);
    return ($text);
} ## end sub messages_text_edit
1;
