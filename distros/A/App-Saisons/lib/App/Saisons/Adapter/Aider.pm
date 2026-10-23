package App::Saisons::Adapter::Aider;
use strict;
use warnings;
use App::Saisons ();
use POSIX qw();
use App::Saisons::Launcher ();
sub new { bless {}, shift }
sub name      { 'Aider' }
sub tag       { "a Aid" }
sub tag_color { 'bold green' }
sub find_sessions {
    my ($self) = @_;
    my @search_dirs;
    if (my $env = $ENV{SAISONS_SEARCH_DIRS}) {
        @search_dirs = split /:/, $env;
    }
    else {
        my $home = $ENV{HOME};
        @search_dirs = grep { -d $_ }
            map { "$home/$_" } qw(projects dev src work code),
            '/projects';
    }
    my @history_files = _find_history_files(\@search_dirs, 1);
    my $home_file = "$ENV{HOME}/.aider.chat.history.md";
    push @history_files, $home_file if -f $home_file;
    my @sessions;
    for my $file (@history_files) {
        (my $cwd = $file) =~ s|/\.aider\.chat\.history\.md$||;
        push @sessions, _parse_history_file($file, $cwd, $self);
    }
    return @sessions;
}
sub _find_history_files {
    my ($roots, $maxdepth) = @_;
    my @result;
    my @queue = map { [$_, 0] } @$roots;
    while (my $item = shift @queue) {
        my ($dir, $depth) = @$item;
        opendir my $dh, $dir or next;
        for my $entry (readdir $dh) {
            next if $entry eq '.' || $entry eq '..';
            my $path = "$dir/$entry";
            if (-f $path && $entry eq '.aider.chat.history.md') {
                push @result, $path;
            }
            elsif (-d $path && !-l $path && $depth < $maxdepth) {
                push @queue, [$path, $depth + 1];
            }
        }
        closedir $dh;
    }
    return @result;
}
sub running {
    return ();
}
sub launch {
    my ($self, $sessions, $launcher) = @_;
    my %by_cwd;
    push @{ $by_cwd{$_->{cwd}} }, $_ for @$sessions;
    for my $cwd (keys %by_cwd) {
        my $cmd = "cd \Q$cwd\E && aider --restore-chat-history";
        App::Saisons::Launcher::launch_cmd($cmd, $cwd, $launcher, 'aider');
    }
}
sub delete_session {
    my ($self, $session) = @_;
    my $file = $session->{_file};
    open my $fh, '<:utf8', $file or return 0;
    my $content = do { local $/; <$fh> };
    close $fh;
    my $header = quotemeta($session->{_header});
    $content =~ s/^$header\n.*?(?=^# aider chat started at |\z)//ms;
    open $fh, '>', $file or return 0;
    print $fh $content;
    close $fh;
    return 1;
}
sub load_messages {
    my ($self, $session) = @_;
    my @messages;
    my $in_session = 0;
    open my $fh, '<:utf8', $session->{_file} or return @messages;
    while (my $line = <$fh>) {
        chomp $line;
        if ($line eq $session->{_header}) {
            $in_session = 1;
            next;
        }
        last if $in_session && $line =~ /^# aider chat started at /;
        next unless $in_session;
        if ($line =~ /^#### (.+)$/) {
            push @messages, { role => 'user', text => $1 };
        }
        elsif ($line =~ /^[^>#\s]/ && @messages && $messages[-1]{role} eq 'user') {
            push @messages, { role => 'assistant', text => $line };
        }
        elsif (@messages && $messages[-1]{role} eq 'assistant' && $line !~ /^>/) {
            $messages[-1]{text} .= "\n$line";
        }
    }
    close $fh;
    for my $m (@messages) {
        $m->{text} =~ s/\s+$//;
    }
    return @messages;
}
sub _parse_history_file {
    my ($file, $cwd, $adapter) = @_;
    my @sessions;
    open my $fh, '<:utf8', $file or return @sessions;
    my ($header, $date, $epoch, $title, @lines);
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^# aider chat started at (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})$/) {
            if ($header) {
                push @sessions, _make_session($header, $date, $epoch, $cwd, $file, \@lines, $adapter);
            }
            $date   = $1;
            $header = $line;
            $epoch  = _parse_epoch($date);
            @lines  = ();
            $title  = undef;
            next;
        }
        next unless $header;
        push @lines, $line;
        if (!$title && $line =~ /^#### (.+)$/) {
            $title = $1;
        }
    }
    close $fh;
    push @sessions, _make_session($header, $date, $epoch, $cwd, $file, \@lines, $adapter)
        if $header;
    return @sessions;
}
sub _make_session {
    my ($header, $date, $epoch, $cwd, $file, $lines, $adapter) = @_;
    my $cwd_sum = 0;
    $cwd_sum = ($cwd_sum * 31 + ord($_)) & 0xFFFFFFFF for split //, $cwd;
    my $id = sprintf('%08x-%04x-%04x-%04x-%012x',
        $cwd_sum,
        ($cwd_sum >> 16) & 0xFFFF,
        ($epoch >> 16)   & 0xFFFF,
        $epoch           & 0xFFFF,
        $epoch);
    my ($title) = grep { /^#### / } @$lines;
    $title = "(no messages)" unless $title;
    $title =~ s/^#### //;
    my $size = length(join "\n", @$lines);
    return {
        id       => $id,
        title    => $title,
        date     => $date,
        epoch    => $epoch,
        cwd      => $cwd,
        project  => $cwd,
        _file    => $file,
        _header  => $header,
        _size    => $size,
        _adapter => $adapter,
    };
}
sub _parse_epoch {
    my ($date) = @_;  
    return 0 unless $date =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/;
    return POSIX::mktime($6, $5, $4, $3, $2-1, $1-1900);
}
1;
