package App::Saisons::Launcher;
use strict;
use warnings;
sub launch_cmd {
    my ($cmd, $cwd, $launcher, $title) = @_;
    $title //= 'saisons';
    if ($launcher eq 'tmux') {
        system('tmux', 'new-window', '-c', $cwd, $cmd);
    }
    elsif ($launcher eq 'screen') {
        system('screen', '-X', 'screen', '-t', substr($title, 0, 20),
               'bash', '-c', "$cmd; exec bash");
    }
    elsif ($launcher eq 'gnome-terminal') {
        system('gnome-terminal', '--tab', "--working-directory=$cwd",
               '--', 'bash', '--login', '-c', $cmd);
    }
    elsif ($launcher eq 'iterm') {
        my $escaped = _applescript_quote($cmd);
        system('osascript', '-e', qq{tell application "iTerm2"\ntell current window\ncreate tab with default profile\ntell current session of current tab\nwrite text $escaped\nend tell\nend tell\nend tell});
    }
    elsif ($launcher eq 'terminal-app') {
        my $escaped = _applescript_quote($cmd);
        system('osascript', '-e', qq{tell application "Terminal"\ndo script $escaped\nactivate\nend tell});
    }
    else {
        system('bash', '-c', $cmd);
    }
}
sub _applescript_quote {
    my ($str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/"/\\"/g;
    return qq{"$str"};
}
1;
