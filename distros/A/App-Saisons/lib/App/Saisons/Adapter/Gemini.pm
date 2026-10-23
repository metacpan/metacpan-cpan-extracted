package App::Saisons::Adapter::Gemini;
use strict;
use warnings;
use JSON::PP ();
use Time::Local ();
use App::Saisons ();
use App::Saisons::Launcher ();
sub new { bless {}, shift }
sub name      { 'Gemini' }
sub tag       { "\x{2726} Gem" }
sub tag_color { 'bold blue' }
sub find_sessions {
    my ($self) = @_;
    my $tmp = "$ENV{HOME}/.gemini/tmp";
    return () unless -d $tmp;
    my @sessions;
    opendir my $dh, $tmp or return ();
    for my $slug (readdir $dh) {
        next if $slug =~ /^\./;
        my $chats_dir = "$tmp/$slug/chats";
        next unless -d $chats_dir;
        opendir my $cdh, $chats_dir or next;
        for my $file (readdir $cdh) {
            next unless $file =~ /^session-.*\.jsonl$/;
            my $s = _parse_session("$chats_dir/$file", $self) or next;
            push @sessions, $s;
        }
        closedir $cdh;
    }
    closedir $dh;
    return @sessions;
}
sub running {
    return ();
}
sub launch {
    my ($self, $sessions, $launcher) = @_;
    for my $s (@$sessions) {
        my $cmd = "cd \Q$s->{cwd}\E && gemini --resume \Q$s->{id}\E";
        App::Saisons::Launcher::launch_cmd($cmd, $s->{cwd}, $launcher, $s->{title});
    }
}
sub delete_session {
    my ($self, $session) = @_;
    return unlink $session->{_file};
}
sub load_messages {
    my ($self, $session) = @_;
    my @messages;
    open my $fh, '<:utf8', $session->{_file} or return @messages;
    my $first = 1;
    while (my $line = <$fh>) {
        if ($first) { $first = 0; next }  
        my $obj  = eval { JSON::PP::decode_json($line) } or next;
        my $type = $obj->{type} // '';
        next unless $type eq 'user' || $type eq 'gemini';
        my $role = $type eq 'user' ? 'user' : 'assistant';
        my $text = $obj->{displayContent} // _extract_text($obj->{content});
        push @messages, { role => $role, text => $text } if length($text // '');
    }
    close $fh;
    return @messages;
}
sub _parse_session {
    my ($file, $adapter) = @_;
    open my $fh, '<:utf8', $file or return undef;
    my ($id, $title, $date_str, $epoch, $cwd);
    my $first = 1;
    while (my $line = <$fh>) {
        my $obj = eval { JSON::PP::decode_json($line) } or next;
        if ($first) {
            $first = 0;
            $id  = $obj->{sessionId} or return undef;
            $title = $obj->{summary} if $obj->{summary};
            if (my $ts = $obj->{startTime} // $obj->{lastUpdated}) {
                if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
                    $date_str = "$1-$2-$3T$4:$5:$6";
                    # not POSIX::tzset: it is unimplemented on Windows
                    $epoch = Time::Local::timegm($6, $5, $4, $3, $2 - 1, $1);
                }
            }
            $cwd = $ENV{HOME};
            if (ref $obj->{directories} eq 'ARRAY' && @{ $obj->{directories} }) {
                $cwd = $obj->{directories}[0];
            }
            next;
        }
        if (!$title && ($obj->{type} // '') eq 'user') {
            my $text = _extract_text($obj->{content});
            $title = $text if length($text // '');
            last;
        }
    }
    close $fh;
    return undef unless $id;
    $date_str //= '0000-00-00';
    $epoch    //= 0;
    $title    //= '(no title)';
    $cwd      //= $ENV{HOME};
    return {
        id       => $id,
        title    => $title,
        date     => $date_str,
        epoch    => $epoch,
        cwd      => $cwd,
        project  => $cwd,
        _file    => $file,
        _size    => (-s $file) // 0,
        _adapter => $adapter,
    };
}
sub _extract_text {
    my ($content) = @_;
    return '' unless defined $content;
    return $content unless ref $content;
    if (ref $content eq 'ARRAY') {
        return join '', map { ref $_ eq 'HASH' ? ($_->{text} // '') : '' } @$content;
    }
    return $content->{text} // '';
}
1;
