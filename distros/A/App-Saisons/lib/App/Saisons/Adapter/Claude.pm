package App::Saisons::Adapter::Claude;
use strict;
use warnings;
use App::Saisons ();
use JSON::PP;
use POSIX qw();
use Time::Local qw();
use App::Saisons::Launcher ();
sub new { bless {}, shift }
sub name      { 'Claude Code' }
sub tag       { "\x{2736} Cld" }
sub tag_color { 'bold red' }
sub find_sessions {
    my ($self) = @_;
    my $projects_dir = "$ENV{HOME}/.claude/projects";
    my %running_names;
    my $sessions_dir = "$ENV{HOME}/.claude/sessions";
    if (opendir my $sdh, $sessions_dir) {
        while (my $f = readdir $sdh) {
            next unless $f =~ /^\d+\.json$/;
            open my $fh, '<', "$sessions_dir/$f" or next;
            my $json = do { local $/; <$fh> };
            close $fh;
            my $obj = eval { decode_json($json) } or next;
            next unless $obj->{sessionId} && $obj->{name};
            $running_names{ $obj->{sessionId} } = $obj->{name};
        }
        closedir $sdh;
    }
    my %by_id;
    opendir my $dh, $projects_dir or return ();
    for my $project (sort readdir $dh) {
        next if $project =~ /^\./;
        my $dir = "$projects_dir/$project";
        next unless -d $dir;
        opendir my $pdh, $dir or next;
        for my $file (sort readdir $pdh) {
            next unless $file =~ /^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$/;
            my $id = $1;
            my ($title, $date, $epoch, $cwd, $first_msg) = _extract_meta("$dir/$file");
            $cwd //= _derive_path($project);
            $title //= $running_names{$id} // $first_msg // '(no title)';
            my $size = -s "$dir/$file" // 0;
            my $session_dir = "$dir/$id";
            my $candidate = {
                id       => $id,
                project  => $project,
                cwd      => $cwd,
                title    => $title,
                date     => $date,
                epoch    => $epoch,
                _file    => "$dir/$file",
                _dir     => (-d $session_dir ? $session_dir : undef),
                _size    => $size,
                _adapter => $self,
            };
            # Deduplicate: keep the copy with the larger file (more content).
            # Duplicates arise when Claude writes back to the old project dir
            # after a move_session. The moved copy has the full conversation;
            # the leftover is tiny (only metadata records, no cwd).
            if (!exists $by_id{$id} || $size > $by_id{$id}{_size}) {
                $by_id{$id} = $candidate;
            }
        }
        closedir $pdh;
    }
    closedir $dh;
    return values %by_id;
}
sub running {
    my ($self) = @_;
    my %running;
    my $sessions_dir = "$ENV{HOME}/.claude/sessions";
    opendir my $sdh, $sessions_dir or return %running;
    while (my $f = readdir $sdh) {
        next unless $f =~ /^\d+\.json$/;
        open my $fh, '<', "$sessions_dir/$f" or next;
        my $json = do { local $/; <$fh> };
        close $fh;
        my $obj = eval { decode_json($json) } or next;
        my $pid = $obj->{pid}       or next;
        my $sid = $obj->{sessionId} or next;
        next unless kill(0, $pid);
        $running{$sid} = 1;
    }
    closedir $sdh;
    return %running;
}
sub launch {
    my ($self, $sessions, $launcher) = @_;
    for my $s (@$sessions) {
        my $cmd = "cd \Q$s->{cwd}\E && claude --resume \Q$s->{id}\E";
        App::Saisons::Launcher::launch_cmd($cmd, $s->{cwd}, $launcher, $s->{title});
    }
}
sub delete_session {
    my ($self, $session) = @_;
    return unlink $session->{_file};
}
sub move_session {
    my ($self, $session, $new_cwd) = @_;
    my $projects_dir = "$ENV{HOME}/.claude/projects";
    my $old_cwd      = $session->{cwd};
    my $old_file     = $session->{_file};
    (my $new_project = $new_cwd) =~ s|/|-|g;
    $new_project =~ s/^-//;  
    $new_project = "-$new_project";
    my $new_dir  = "$projects_dir/$new_project";
    my $new_file = "$new_dir/$session->{id}.jsonl";
    unless (-d $new_dir) {
        mkdir $new_dir or return (0, "Cannot create $new_dir: $!");
    }
    open my $in,  '<', $old_file or return (0, "Cannot read $old_file: $!");
    open my $out, '>', $new_file or return (0, "Cannot write $new_file: $!");
    my $old_quoted = quotemeta($old_cwd);
    while (my $line = <$in>) {
        $line =~ s/"cwd":"$old_quoted"/"cwd":"$new_cwd"/g;
        print $out $line;
    }
    close $in;
    close $out;
    unlink $old_file;
    my $old_dir = "$projects_dir/$session->{project}";
    opendir my $dh, $old_dir or return (1, '');
    my @remaining = grep { !/^\./ } readdir $dh;
    closedir $dh;
    rmdir $old_dir unless @remaining;
    $session->{cwd}     = $new_cwd;
    $session->{project} = $new_project;
    $session->{_file}   = $new_file;
    return (1, '');
}
sub load_messages {
    my ($self, $session) = @_;
    my @messages;
    open my $fh, '<', $session->{_file} or return @messages;
    while (<$fh>) {
        next unless /"role":"(user|assistant)"/;
        my $role = $1;
        my $obj  = eval { decode_json($_) } or next;
        my $content = $obj->{message}{content} // next;
        my $text = '';
        if (!ref $content) {
            $text = $content;
        }
        elsif (ref $content eq 'ARRAY') {
            for my $block (@$content) {
                next unless ref $block eq 'HASH' && ($block->{type} // '') eq 'text';
                $text .= $block->{text};
            }
        }
        next unless length $text;
        push @messages, { role => $role, text => $text };
    }
    close $fh;
    return @messages;
}
sub _extract_meta {
    my ($file) = @_;
    my ($title, $date, $epoch, $cwd, $first_msg) = (undef, '0000-00-00', 0, undef, undef);
    print STDERR "\033[2KLoading $file ...\r";
    open my $fh, '<:utf8', $file or return ($title, $date, $epoch, $cwd);
    while (<$fh>) {
        $title = $1 if !defined $title && /"aiTitle":"([^"]+)"/;
        $cwd   = $1 if !$cwd && /"cwd":"([^"]+)"/;
        if (!$first_msg && /"role":"user"/) {
            my $obj = eval { decode_json($_) } or next;
            my $c   = $obj->{message}{content};
            my $txt = ref $c eq 'ARRAY' ? ($c->[0]{text} // '') : ($c // '');
            next if $txt =~ /^This session is being continued from a previous conversation/;
            ($first_msg) = split /\n/, $txt if length $txt;
        }
        if (/"timestamp":"(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $ts = "$1T$2:$3:$4";
            if ($ts gt $date) {
                $date  = $ts;
                $epoch = Time::Local::timegm($4, $3, $2,
                    substr($1,8,2), substr($1,5,2)-1, substr($1,0,4)-1900);
            }
        }
    }
    close $fh;
    print STDERR "\033[2K\r";
    return ($title, $date, $epoch, $cwd, $first_msg);
}
sub _derive_path {
    my ($project) = @_;
    return $project;
}
1;
