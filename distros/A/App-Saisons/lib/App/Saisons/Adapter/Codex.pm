package App::Saisons::Adapter::Codex;
use strict;
use warnings;
use App::Saisons ();
use JSON::PP ();
use POSIX qw();
use App::Saisons::Launcher ();
sub new { bless {}, shift }
sub name      { 'Codex' }
sub tag       { "\x{2601} Cdx" }
sub tag_color { 'bold cyan' }
sub find_sessions {
    my ($self) = @_;
    my $root = $ENV{CODEX_HOME} // "$ENV{HOME}/.codex";
    my $sessions_dir = "$root/sessions";
    return () unless -d $sessions_dir;
    my @files = _find_session_files($sessions_dir);
    my @sessions;
    for my $file (@files) {
        my $s = _parse_session($file, $self) or next;
        push @sessions, $s;
    }
    return @sessions;
}
sub running {
    return ();
}
sub launch {
    my ($self, $sessions, $launcher) = @_;
    for my $s (@$sessions) {
        my $cmd = "cd \Q$s->{cwd}\E && codex resume \Q$s->{_file}\E";
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
    while (my $line = <$fh>) {
        my $obj     = eval { JSON::PP::decode_json($line) } or next;
        my $type    = $obj->{type}    // '';
        my $payload = $obj->{payload} // {};
        if ($type eq 'event_msg' && ($payload->{type} // '') eq 'user_message') {
            my $text = $payload->{message} // '';
            push @messages, { role => 'user', text => $text } if length $text;
        }
        elsif ($type eq 'response_item' && ($payload->{role} // '') eq 'assistant') {
            my $text = _extract_text($payload->{content});
            push @messages, { role => 'assistant', text => $text } if length $text;
        }
    }
    close $fh;
    return @messages;
}
sub _find_session_files {
    my ($root) = @_;
    my @files;
    opendir my $dh, $root or return @files;
    for my $year (sort readdir $dh) {
        next unless $year =~ /^\d{4}$/;
        my $ydir = "$root/$year";
        opendir my $mdh, $ydir or next;
        for my $month (sort readdir $mdh) {
            next unless $month =~ /^\d{2}$/;
            my $mdir = "$ydir/$month";
            opendir my $ddh, $mdir or next;
            for my $day (sort readdir $ddh) {
                next unless $day =~ /^\d{2}$/;
                my $ddir = "$mdir/$day";
                opendir my $fdh, $ddir or next;
                for my $file (sort readdir $fdh) {
                    next unless $file =~ /^rollout-.*\.jsonl$/;
                    push @files, "$ddir/$file";
                }
                closedir $fdh;
            }
            closedir $ddh;
        }
        closedir $mdh;
    }
    closedir $dh;
    my $archived = "$root/archived_sessions";
    if (-d $archived) {
        opendir my $adh, $archived or return @files;
        for my $file (sort readdir $adh) {
            next unless $file =~ /^rollout-.*\.jsonl$/;
            push @files, "$archived/$file";
        }
        closedir $adh;
    }
    return @files;
}
sub _parse_session {
    my ($file, $adapter) = @_;
    open my $fh, '<:utf8', $file or return undef;
    my ($id, $cwd, $title);
    while (my $line = <$fh>) {
        my $obj = eval { JSON::PP::decode_json($line) } or next;
        my $type    = $obj->{type}    // '';
        my $payload = $obj->{payload} // {};
        if ($type eq 'session_meta') {
            $id  //= $payload->{id};
            $cwd //= $payload->{cwd};
        }
        elsif ($type eq 'event_msg' && ($payload->{type} // '') eq 'user_message') {
            $title //= $payload->{message};
        }
        last if $id && $cwd && $title;
    }
    close $fh;
    return undef unless $id;
    $cwd   //= $ENV{HOME};
    $title //= '(no title)';
    my ($date_str, $epoch) = ('0000-00-00', 0);
    if ($file =~ /rollout-(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})/) {
        $date_str = "$1-$2-$3T$4:$5:$6";
        $epoch    = POSIX::mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
    }
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
    return join '', map { ref $_ eq 'HASH' && ($_->{type}//'') eq 'text' ? $_->{text} : '' }
                    ref $content eq 'ARRAY' ? @$content : ();
}
1;
