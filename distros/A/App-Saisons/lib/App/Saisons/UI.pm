package App::Saisons::UI;

use strict;
use warnings;
use utf8;
use POSIX qw();
use App::Saisons;
use Term::ANSIColor qw(colored color);
use JSON::PP ();
use Encode qw(decode);
use Time::Local ();

my $STATE_FILE = "$ENV{HOME}/.config/saisons/state.json";
use constant RESET => color('reset');
sub _col_yellow  { color('yellow') }
sub _col_cyan    { color('cyan') }
sub _col_green   { color('green') }
sub _col_white   { color('white') }
sub _col_boldgrn { color('bold green') }
# background-only bars (256-color): column colors stay readable on top
sub _col_sel        { "\e[48;5;23m" }   # dark teal
sub _col_active     { "\e[48;5;24m" }   # muted steel blue
sub _col_active_sel { "\e[48;5;30m" }   # brighter teal
sub _str_bold    { colored($_[0], 'bold') }
sub _str_dim     { colored($_[0], 'faint') }
sub _str_boldyel { colored($_[0], 'bold yellow') }
sub _str_boldcyn { colored($_[0], 'bold cyan') }
sub _str_boldgrn { colored($_[0], 'bold green') }
sub _str_boldred { colored($_[0], 'bold red') }
sub new { bless {}, shift }
sub _load_state {
    open my $fh, '<', $STATE_FILE or return {};
    my $json = do { local $/; <$fh> };
    close $fh;
    eval { JSON::PP::decode_json($json) } // {};
}
sub _save_state {
    my ($state) = @_;
    (my $dir = $STATE_FILE) =~ s|/[^/]+$||;
    mkdir $dir unless -d $dir;
    open my $fh, '>', $STATE_FILE or return;
    print $fh JSON::PP::encode_json($state);
    close $fh;
}
use constant REFRESH_RUNNING_EVERY => 5;   # seconds between ● marker refreshes
sub _refresh_running {
    my ($sessions, $running) = @_;
    my %seen;
    %$running = ();
    for my $s (@$sessions) {
        next if $seen{ref $s->{_adapter}}++;
        %$running = (%$running, $s->{_adapter}->running);
    }
}
my ($OLD_TERM, $ROWS, $COLS);
my $RESIZED = 0;
my $CASE_SENSITIVE = 0;
sub _qr {
    my ($q) = @_;
    return eval { $CASE_SENSITIVE ? qr/(\Q$q\E)/ : qr/(\Q$q\E)/i };
}
sub _set_term_title {
    my ($title) = @_;
    return unless -t STDOUT;
    print "\033]2;$title\007";
}
sub _init_term {
    binmode STDOUT, ':utf8';
    STDOUT->autoflush(1);
    _set_term_title('SAISONS');
    my $tty = \*STDIN;
    $OLD_TERM = POSIX::Termios->new;
    $OLD_TERM->getattr(fileno($tty));
    my $raw = POSIX::Termios->new;
    $raw->getattr(fileno($tty));
    $raw->setlflag($raw->getlflag & ~(POSIX::ECHO | POSIX::ICANON));
    $raw->setcc(POSIX::VMIN, 1);   
    $raw->setcc(POSIX::VTIME, 0);  
    $raw->setattr(fileno($tty), POSIX::TCSANOW);
}
sub _restore_term {
    $OLD_TERM->setattr(fileno(\*STDIN), POSIX::TCSANOW) if $OLD_TERM;
    _set_term_title('');
}
sub _term_size {
    my $s = `stty size 2>/dev/null`;
    return ($s =~ /^(\d+)\s+(\d+)/) ? ($1, $2) : (40, 120);
}
sub _check_resize {
    my ($rows, $cols) = _term_size();
    # a size change reflows/wraps the old frame, so a home-and-overwrite
    # redraw is not enough; wipe the screen before rendering
    print "\033[2J" if defined $ROWS && ($rows != $ROWS || $cols != $COLS);
    ($ROWS, $COLS) = ($rows, $cols);
}
sub _input_pending {
    my ($timeout) = @_;
    return 1 if $RESIZED;
    my $rin = '';
    vec($rin, fileno(STDIN), 1) = 1;
    return (select($rin, undef, undef, $timeout) || 0) > 0;
}
sub _read_key {
    # wait in select() so SIGWINCH interrupts us; a blocked sysread would
    # be restarted (SA_RESTART) and the resize would go unnoticed
    my ($deadline) = @_;
    while (1) {
        if ($RESIZED) { $RESIZED = 0; return 'RESIZE' }
        return 'TICK' if defined $deadline && time >= $deadline;
        last if _input_pending(0.5);
    }
    my $c = '';
    my $n = sysread STDIN, $c, 1;
    return 'EOF' unless $n;   # closed/hung-up stdin must not busy-loop
    if ($c eq "\033") {
        my $rin = '';
        vec($rin, fileno(STDIN), 1) = 1;
        return 'ESC' unless select($rin, undef, undef, 0.05);
        my $c2 = '';
        sysread STDIN, $c2, 1;
        return "ALT_$c2" if $c2 =~ /^[a-zA-Z]$/;   # ESC+letter = Alt+letter
        if ($c2 eq '[') {
            my $c3 = '';
            sysread STDIN, $c3, 1;
            return 'UP'    if $c3 eq 'A';
            return 'DOWN'  if $c3 eq 'B';
            return 'RIGHT' if $c3 eq 'C';
            return 'LEFT'  if $c3 eq 'D';
            if ($c3 =~ /[0-9]/) {
                my $c4 = ''; sysread STDIN, $c4, 1;
                return 'PGUP'   if $c3 eq '5';
                return 'PGDN'   if $c3 eq '6';
                return 'END'    if $c3 eq '4';
                return 'DELETE' if $c3 eq '3';
                if ($c3 eq '1') {
                    if ($c4 eq ';') {
                        my $c5 = ''; sysread STDIN, $c5, 1;
                        my $c6 = ''; sysread STDIN, $c6, 1;
                        return 'SHIFT_UP'   if $c5 eq '2' && $c6 eq 'A';
                        return 'SHIFT_DOWN' if $c5 eq '2' && $c6 eq 'B';
                        return 'IGNORE';
                    }
                    return 'HOME';
                }
                return 'IGNORE';
            }
            return 'IGNORE';
        }
        return 'ESC';
    }
    return $c;
}
sub _clamp_list {
    my ($entries, $cursor, $offset, $visible) = @_;
    my $n = scalar @$entries;
    $cursor = 0      if $cursor < 0;
    $cursor = $n - 1 if $cursor >= $n && $n;
    $cursor++ while $cursor < $n - 1 && $entries->[$cursor] && $entries->[$cursor]{type} ne 'session';
    $cursor-- while $cursor > 0      && $entries->[$cursor] && $entries->[$cursor]{type} ne 'session';
    if ($n <= $visible) {
        $offset = 0;
    } else {
        my $max = $n - $visible;
        $offset = $max if $offset > $max;
        $offset = $cursor                if $cursor < $offset;
        $offset = $cursor - $visible + 1 if $cursor >= $offset + $visible;
        $offset = 0 if $offset < 0;
    }
    return ($cursor, $offset);
}
sub _move_cursor {
    my ($entries, $cursor, $step) = @_;
    my $n = scalar @$entries;
    $cursor += $step;
    if ($step > 0) {
        $cursor++ while $cursor < $n - 1 && $entries->[$cursor] && $entries->[$cursor]{type} ne 'session';
    } else {
        $cursor-- while $cursor > 0 && $entries->[$cursor] && $entries->[$cursor]{type} ne 'session';
    }
    return $cursor;
}
sub interactive_select {
    my ($self, $sessions, $running) = @_;
    $running //= {};
    my $state   = _load_state();
    my %sel_ids = map { $_ => 1 } @{ $state->{selected} // [] };
    my $group_by = $state->{grouped} // '';           # '', 'path' or 'agent'
    $group_by = 'path' if $group_by eq '1';           # legacy boolean state
    $group_by = ''     if $group_by eq '0';
    my $cursor  = 0;
    my $offset      = 0;
    my $filter      = '';
    my $fulltext    = '';
    my ($ft_sig, @ft_hits, $ft_match);   # cached full-text results; the scan reads every session file
    my @sort_cols = qw(selected running agent date size session path title);
    my $sort_idx  = 3;
    my $sort_rev  = 1;
    my $sort_mode = 0;
    _init_term();
    local $SIG{INT}   = sub { _restore_term(); print "\033[?25h\033[0m\n"; STDOUT->flush(); exit 0 };
    local $SIG{WINCH} = sub { $RESIZED = 1 };
    print "\033[?25l";  
    my @result;
    my $next_refresh = time + REFRESH_RUNNING_EVERY;
    while (1) {
        _check_resize();
        my @filtered = grep { ref $_ eq 'HASH' } @$sessions;
        if ($filter) {
            my $re = _qr($filter) // qr/(?!)/;
            @filtered = grep {
                $_->{title} =~ $re || $_->{cwd} =~ $re || $_->{date} =~ $re
            } @filtered;
        }
        if ($fulltext) {
            my $sig = "$filter\0$fulltext\0$CASE_SENSITIVE";
            unless (defined $ft_sig && $ft_sig eq $sig) {
                @ft_hits  = _fulltext_filter(\@filtered, $fulltext);
                $ft_match = _match_map(@ft_hits);
                $ft_sig   = $sig;
            }
            _apply_match_rows(\@ft_hits, $ft_match);
            @filtered = @ft_hits;
        } else {
            undef $ft_sig;
            delete $_->{_match} for @filtered;
        }
        my $visible_sessions = \@filtered;
        my $sort_col = $sort_cols[$sort_idx];
        my @entries = _build_entries($visible_sessions, $running, \%sel_ids, $group_by, $sort_col, $sort_rev);
        my $n       = scalar @entries;
        my $visible = $ROWS - 3 - 1;
        ($cursor, $offset) = _clamp_list(\@entries, $cursor, $offset, $visible);
        _render(\@entries, $cursor, $offset, $visible, \%sel_ids, $group_by, $running, $filter, $fulltext, $sort_col, $sort_rev, $sort_mode);
        my $key = _read_key($next_refresh);
        if ($key eq 'UP' || $key eq 'k') {
            if ($sort_mode && $key eq 'UP') { $sort_rev = 0; $cursor = 0; $offset = 0 }
            else { $cursor = _move_cursor(\@entries, $cursor, -1) }
        }
        elsif ($key eq 'DOWN' || $key eq 'j') {
            if ($sort_mode && $key eq 'DOWN') { $sort_rev = 1; $cursor = 0; $offset = 0 }
            else { $cursor = _move_cursor(\@entries, $cursor, +1) }
        }
        elsif ($key eq 'PGUP')       { $cursor -= $visible;     $offset -= $visible }
        elsif ($key eq 'PGDN')       { $cursor += $visible;     $offset += $visible }
        elsif ($key eq 'SHIFT_UP')   { $cursor -= int($visible/2); $offset -= int($visible/2) }
        elsif ($key eq 'SHIFT_DOWN') { $cursor += int($visible/2); $offset += int($visible/2) }
        elsif ($key eq 'HOME' || $key eq 'g') { $cursor = 0; $offset = 0 }
        elsif ($key eq 'END'  || $key eq 'G') { $cursor = $n - 1 }
        elsif ($key eq ' ') {
            my $e = $entries[$cursor];
            if ($e && $e->{type} eq 'session') {
                my $id = $e->{session}{id};
                $sel_ids{$id} ? delete $sel_ids{$id} : ($sel_ids{$id} = 1);
            }
        }
        elsif ($key eq "\n" || $key eq "\r") {
            if ($sort_mode) { $sort_mode = 0; next }
            # resolve against the visible list: a filter or search must hide
            # selections made outside it from bulk actions
            my @to_open = _selected_sessions(\%sel_ids, \@filtered);
            unless (@to_open) {
                my $e = $entries[$cursor];
                push @to_open, $e->{session} if $e && $e->{type} eq 'session';
            }
            if (@to_open) {
                my @already_running = grep { $running->{ $_->{id} } } @to_open;
                if (@already_running) {
                    my $ans = _confirm(scalar(@already_running) . " session(s) already running. Open anyway? [y/N] ");
                    next unless $ans =~ /^y/i;
                }
                _save_state({ selected => [map { $_->{id} } @to_open], grouped => $group_by });
                @result = @to_open;
                last;
            }
        }
        elsif ($key eq 'a') {
            $sel_ids{$_->{session}{id}} = 1 for grep { $_->{type} eq 'session' } @entries;
        }
        elsif ($key eq 'A' || $key eq 'c') {
            %sel_ids = ();
        }
        elsif ($key eq 's') {
            $sort_mode = !$sort_mode;
        }
        elsif ($key eq 'S') {
            $sort_rev = !$sort_rev;
            $cursor = 0; $offset = 0;
        }
        elsif ($key eq 'LEFT' || $key eq 'RIGHT') {
            if ($sort_mode) {
                my $step = $key eq 'RIGHT' ? 1 : -1;
                my $idx  = $sort_idx;
                do { $idx += $step }
                    while $idx >= 0 && $idx < @sort_cols && $group_by eq 'path' && $sort_cols[$idx] eq 'path';
                if ($idx >= 0 && $idx < @sort_cols) {
                    $sort_idx = $idx;
                    $cursor = 0; $offset = 0;
                }
            }
        }
        elsif ($key eq 't') {
            $group_by = $group_by eq ''     ? 'path'
                      : $group_by eq 'path' ? 'agent'
                      :                       '';
            $cursor = 0; $offset = 0;
        }
        elsif ($key eq "\x0c") {  # Ctrl+L: force full repaint
            print "\033[2J";
        }
        elsif ($key eq 'r' || $key eq 'TICK') {
            _refresh_running($sessions, $running);
            $next_refresh = time + REFRESH_RUNNING_EVERY;
        }
        elsif ($key eq 'v') {
            my $e = $entries[$cursor];
            if ($e && $e->{type} eq 'session') {
                _restore_term(); print "\033[?25h";
                _peek($e->{session});
                _init_term(); print "\033[?25l";
            }
        }
        elsif ($key eq 'd' || $key eq 'DELETE') {
            my @to_del = _selected_sessions(\%sel_ids, \@filtered);
            unless (@to_del) {
                my $e = $entries[$cursor];
                push @to_del, $e->{session} if $e && $e->{type} eq 'session';
            }
            if (@to_del) {
                _do_delete(\@to_del, $sessions, \%sel_ids);
                undef $ft_sig;
                $cursor = 0; $offset = 0;
            }
        }
        elsif ($key eq 'm') {
            my @to_move = _selected_sessions(\%sel_ids, \@filtered);
            if (@to_move) {
                my @already_running = grep { $running->{ $_->{id} } } @to_move;
                if (@already_running) {
                    my $ans = _confirm(scalar(@already_running) . " session(s) are currently running. Moving a running session may corrupt it. Proceed? [y/N] ");
                    next unless $ans =~ /^y/i;
                }
                _restore_term(); print "\033[?25h";
                _do_move(\@to_move, $sessions, \%sel_ids);
                undef $ft_sig;
                $cursor = 0; $offset = 0;
                _init_term(); print "\033[?25l";
            }
        }
        elsif ($key eq '/' || $key eq '?') {
            my $is_fulltext = $key eq '?';
            my $prompt      = $is_fulltext
                ? colored('?search: ', 'bold yellow')
                : colored('/filter: ', 'bold cyan');
            my $query = $is_fulltext ? $fulltext : $filter;
            my @pv_stack;   # [query, [hits]] per typed prefix: extending a substring
                            # search can only narrow, so each scan starts from the
                            # previous prefix's hits, and backspace pops for free
            my $draw_prompt = sub {
                print "\033[${ROWS};1H\033[K";
                my $flag = $CASE_SENSITIVE ? colored(' [case sensitive]', 'bold yellow') : '';
                my $hint = ' (M-C=toggle case ENTER=' . ($is_fulltext ? 'search' : 'apply') . ' ESC=cancel)';
                print $prompt . colored($query, 'bold white') . $flag . colored($hint, 'faint');
                STDOUT->flush();
            };
            my ($cur2, $off2) = (0, 0);
            my $q_dirty = 0;   # true while query edits may still be in flight
            while (1) {
                my @f2 = grep { ref $_ eq 'HASH' } @$sessions;
                if (!$is_fulltext && $query) {
                    my $re = _qr($query) // qr/(?!)/;
                    @f2 = grep { $_->{title} =~ $re || $_->{cwd} =~ $re || $_->{date} =~ $re } @f2;
                } elsif ($is_fulltext && $query) {
                    pop @pv_stack while @pv_stack && index($query, $pv_stack[-1][0]) != 0;
                    if (@pv_stack && $pv_stack[-1][0] eq $query) {
                        _apply_match_rows($pv_stack[-1][1], $pv_stack[-1][2]);
                        @f2 = @{ $pv_stack[-1][1] };
                        $q_dirty = 0;
                    } elsif ($q_dirty && _input_pending(0.25)) {
                        # more typing on the way: keep the stale preview, scan on pause
                        if (@pv_stack) {
                            _apply_match_rows($pv_stack[-1][1], $pv_stack[-1][2]);
                            @f2 = @{ $pv_stack[-1][1] };
                        }
                    } else {
                        my $base = @pv_stack ? $pv_stack[-1][1] : \@f2;
                        my @hits = _fulltext_filter($base, $query);
                        push @pv_stack, [$query, [@hits], _match_map(@hits)];
                        @f2 = @hits;
                        $q_dirty = 0;
                    }
                }
                _check_resize();
                my $sort_col = $sort_cols[$sort_idx];
                my @e2   = _build_entries(\@f2, $running, \%sel_ids, $group_by, $sort_col, $sort_rev);
                my $vis2 = $ROWS - 3 - 1;
                ($cur2, $off2) = _clamp_list(\@e2, $cur2, $off2, $vis2);
                _render(\@e2, $cur2, $off2, $vis2, \%sel_ids, $group_by, $running,
                    ($is_fulltext ? $filter : $query),
                    ($is_fulltext ? $query  : $fulltext),
                    $sort_col, $sort_rev, 0);
                $draw_prompt->();
                my $ch = _read_key();
                if ($ch eq "\n" || $ch eq "\r") {
                    if ($is_fulltext) {
                        $fulltext = $query;
                        # hand the preview's hits to the main loop's cache, so
                        # applying the search doesn't rescan (preview ignores
                        # $filter, so only when none is active)
                        if (!$filter && @pv_stack && $pv_stack[-1][0] eq $query) {
                            $ft_sig   = "\0$query\0$CASE_SENSITIVE";
                            @ft_hits  = @{ $pv_stack[-1][1] };
                            $ft_match = $pv_stack[-1][2];
                        }
                    } else {
                        $filter = $query;
                    }
                    # the preview ignores the other active restriction, so the
                    # selection only carries over when there is none
                    my $other = $is_fulltext ? $filter : $fulltext;
                    ($cursor, $offset) = $other ? (0, 0) : ($cur2, $off2);
                    last;
                } elsif ($ch eq 'ESC' || $ch eq 'EOF') {
                    last;
                } elsif ($ch eq 'UP') {
                    $cur2 = _move_cursor(\@e2, $cur2, -1);
                } elsif ($ch eq 'DOWN') {
                    $cur2 = _move_cursor(\@e2, $cur2, +1);
                } elsif ($ch eq 'ALT_c' || $ch eq 'ALT_C' || $ch eq "\t") {
                    # case toggle can widen or narrow matches: rescan from scratch
                    $CASE_SENSITIVE = !$CASE_SENSITIVE;
                    @pv_stack = ();
                    $draw_prompt->();
                } elsif ($ch eq 'BACKSPACE' || $ch eq "\x7f" || $ch eq "\x08") {
                    $query = substr($query, 0, -1) if length($query);
                    $cur2 = 0; $off2 = 0; $q_dirty = 1;
                    $draw_prompt->();   # echo before the (possibly slow) rescan
                } elsif (length($ch) == 1 && $ch ge ' ') {
                    $query .= $ch;
                    $cur2 = 0; $off2 = 0; $q_dirty = 1;
                    $draw_prompt->();
                }
            }
        }
        elsif ($key eq 'ESC') {
            if ($sort_mode) {
                $sort_mode = 0;
            } elsif ($filter || $fulltext) {
                $filter = ''; $fulltext = '';
                $cursor = 0; $offset = 0;
            } else {
                _save_state({ selected => [keys %sel_ids], grouped => $group_by });
                last;
            }
        }
        elsif ($key eq 'q' || $key eq 'EOF') {
            _save_state({ selected => [keys %sel_ids], grouped => $group_by });
            last;
        }
    }
    _restore_term();
    print "\033[?25h\033[2J\033[H\033[0m";  
    STDOUT->flush();
    return @result;
}
sub _selected_sessions {
    my ($sel_ids, $sessions) = @_;
    my %by_id = map { $_->{id} => $_ } @$sessions;
    return map { $by_id{$_} } grep { $by_id{$_} } keys %$sel_ids;
}
my %SORT_CMP = (
    selected => sub { ($_[1]{_sel}  // 0) <=> ($_[0]{_sel}  // 0) },
    running  => sub { ($_[1]{_run}  // 0) <=> ($_[0]{_run}  // 0) },
    agent    => sub { _adapter_tag($_[0]{_adapter}, 1) cmp _adapter_tag($_[1]{_adapter}, 1) },
    date     => sub { $_[0]{date}          cmp $_[1]{date}          },
    size     => sub { ($_[0]{_size} // 0) <=> ($_[1]{_size} // 0)  },
    session  => sub { $_[0]{id}            cmp $_[1]{id}            },
    path     => sub { $_[0]{cwd}           cmp $_[1]{cwd}           },
    title    => sub { lc($_[0]{title})     cmp lc($_[1]{title})     },
);
sub _sorted {
    my ($sessions, $sort_col, $sort_rev, $sel_ids, $running) = @_;
    my $cmp = $SORT_CMP{$sort_col} // $SORT_CMP{date};
    my @ann = map { { %$_, _sel => $sel_ids->{$_->{id}} ? 1 : 0,
                           _run => $running->{$_->{id}} ? 1 : 0 } } @$sessions;
    my @sorted = sort { $cmp->($a, $b) } @ann;
    @sorted = reverse @sorted if $sort_rev;
    return @sorted;
}
sub _build_entries {
    my ($sessions, $running, $sel_ids, $group_by, $sort_col, $sort_rev) = @_;
    $sort_col //= 'date';
    my @valid = grep { ref $_ eq 'HASH' } @$sessions;
    if ($group_by) {
        my $group_key = $group_by eq 'agent'
            ? sub { _short_class(ref $_[0]{_adapter}) }
            : sub { $_[0]{cwd} };
        my %by_dir;
        push @{ $by_dir{$group_key->($_)} }, $_ for @valid;
        my %sorted_dir;
        for my $dir (keys %by_dir) {
            $sorted_dir{$dir} = [ _sorted($by_dir{$dir}, $sort_col, $sort_rev, $sel_ids, $running) ];
        }
        my $dir_cmp = $SORT_CMP{$sort_col} // $SORT_CMP{date};
        my @dirs = sort {
            my $ann_a = { %{$sorted_dir{$a}[0]}, _sel => $sel_ids->{$sorted_dir{$a}[0]{id}} ? 1 : 0,
                                                 _run => $running->{$sorted_dir{$a}[0]{id}} ? 1 : 0 };
            my $ann_b = { %{$sorted_dir{$b}[0]}, _sel => $sel_ids->{$sorted_dir{$b}[0]{id}} ? 1 : 0,
                                                 _run => $running->{$sorted_dir{$b}[0]{id}} ? 1 : 0 };
            $dir_cmp->($ann_a, $ann_b) || $a cmp $b
        } keys %sorted_dir;
        @dirs = reverse @dirs if $sort_rev;
        my @entries;
        for my $dir (@dirs) {
            push @entries, { type => 'header', label => $dir };
            push @entries, _entry_rows(@{ $sorted_dir{$dir} });
        }
        return @entries;
    }
    return _entry_rows(_sorted(\@valid, $sort_col, $sort_rev, $sel_ids, $running));
}
sub _entry_rows {
    return map {
        my $s = $_;
        ({ type => 'session', session => $s },
         map { { %$_, type => 'match' } } @{ $s->{_match} // [] });
    } @_;
}
sub _truncate_path {
    my ($path, $width) = @_;
    return sprintf "%-${width}s", length($path) > $width
        ? '...' . substr($path, -($width - 3))
        : $path;
}
use constant MAX_MATCH_LINES => 3;
sub _search_content {
    my ($session, $query) = @_;
    my ($title, $cwd, $q) = $CASE_SENSITIVE
        ? ($session->{title}, $session->{cwd}, $query)
        : (lc $session->{title}, lc $session->{cwd}, lc $query);
    return {} if index($title, $q) >= 0;
    return {} if index($cwd,   $q) >= 0;
    my $re = _qr($query) or return undef;
    my @files;
    push @files, $session->{_file} if $session->{_file} && -f $session->{_file};
    if (my $dir = $session->{_dir}) {
        push @files, _find_jsonl_files($dir);
    }
    @files = sort { ((stat($b))[9] // 0) <=> ((stat($a))[9] // 0) } @files;
    my @rows;
    my $found = 0;
    for my $file (@files) {
        last if $found >= MAX_MATCH_LINES;
        open my $fh, '<', $file or next;
        my @lines;
        while (my $l = <$fh>) {
            no warnings 'utf8';
            push @lines, decode('UTF-8', $l, Encode::FB_DEFAULT);
        }
        close $fh;
        my @hits;
        for (my $i = $#lines; $i >= 0; $i--) {
            next unless $lines[$i] =~ $re;
            push @hits, $i;
            last if $found + @hits >= MAX_MATCH_LINES;
        }
        next unless @hits;
        $found += @hits;
        my %is_hit = map { $_ => 1 } @hits;
        my @blocks;
        for my $i (@hits) {
            my ($lo, $hi) = ($i - 1, $i + 1);
            $lo = 0       if $lo < 0;
            $hi = $#lines if $hi > $#lines;
            if (@blocks && $hi >= $blocks[-1][0] - 1) {
                $blocks[-1][0] = $lo if $lo < $blocks[-1][0];
            } else {
                push @blocks, [$lo, $hi];
            }
        }
        for my $b (@blocks) {
            push @rows, { gap => 1 } if @rows;
            for my $i ($b->[0] .. $b->[1]) {
                if ($is_hit{$i} && $lines[$i] =~ $re) {
                    my ($ms, $me) = ($-[0], $+[0]);
                    push @rows, { matched => 1, time => _line_time($lines[$i]),
                                  text => _match_snippet($lines[$i], $ms, $me) };
                } else {
                    push @rows, { matched => 0, time => _line_time($lines[$i]),
                                  text => _ctx_snippet($lines[$i]) };
                }
            }
        }
    }
    return @rows ? { rows => \@rows } : undef;
}
sub _clean_snippet {
    my ($snip) = @_;
    $snip =~ s/\\u([0-9a-fA-F]{4})/chr(hex($1))/ge;
    $snip =~ s/\\[ntr]/ /g;
    $snip =~ s/\\(["\\\/])/$1/g;
    $snip =~ s/[\x00-\x1f]/ /g;
    $snip =~ s/\s+/ /g;
    $snip =~ s/^\s+|\s+$//g;
    return $snip;
}
sub _match_snippet {
    my ($line, $mstart, $mend) = @_;
    chomp $line;
    my $start = $mstart - 30;
    $start = 0 if $start < 0;
    my $len  = ($mend - $start) + 100;
    my $snip = _clean_snippet(substr($line, $start, $len));
    $snip = "\x{2026}$snip" if $start > 0;
    $snip .= "\x{2026}"     if $start + $len < length($line);
    return $snip;
}
sub _ctx_snippet {
    my ($line) = @_;
    my $text = $line;
    for my $f (qw(text content message)) {
        if ($line =~ /"$f"\s*:\s*"((?:[^"\\]|\\.)+)"/) { $text = $1; last }
    }
    $text = _clean_snippet($text);
    $text = substr($text, 0, 130) . "\x{2026}" if length($text) > 130;
    return $text;
}
sub _line_time {
    my ($line) = @_;
    if ($line =~ /"(?:timestamp|startTime|createdAt|time|date)"\s*:\s*"([^"]+)"/) {
        my $t = $1;
        if ($t =~ /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?(Z|[+-]\d{2}:?\d{2})?/) {
            my ($Y, $M, $D, $h, $m, $s, $tz) = ($1, $2, $3, $4, $5, $6 // 0, $7 // '');
            my $epoch = eval {
                $tz eq 'Z' ? Time::Local::timegm($s, $m, $h, $D, $M - 1, $Y)
                           : Time::Local::timelocal($s, $m, $h, $D, $M - 1, $Y)
            };
            return POSIX::strftime('%Y-%m-%d %H:%M', localtime($epoch)) if defined $epoch;
            return "$Y-$M-$D $h:$m";
        }
        return substr($t, 0, 16);
    }
    if ($line =~ /"(?:timestamp|time|created(?:At)?)"\s*:\s*(\d{10,13})(?:\.\d+)?/) {
        my $e = $1;
        $e = int($e / 1000) if length($e) > 11;
        return POSIX::strftime('%Y-%m-%d %H:%M', localtime($e));
    }
    return '';
}
sub _apply_match_rows {
    # cached hit lists share session hashes with later scans, which overwrite
    # or delete _match; re-apply the rows that belong to the cached query
    my ($sessions, $map) = @_;
    for my $s (@$sessions) {
        my $rows = $map->{$s->{id}};
        if ($rows) { $s->{_match} = $rows } else { delete $s->{_match} }
    }
}
sub _match_map {
    my (@hits) = @_;
    return { map { $_->{id} => $_->{_match} } grep { $_->{_match} } @hits };
}
sub _fulltext_filter {
    my ($sessions, $query) = @_;
    return grep {
        my $m = _search_content($_, $query);
        if ($m && $m->{rows}) { $_->{_match} = $m->{rows} }
        else                  { delete $_->{_match} }
        $m;
    } @$sessions;
}
sub _find_jsonl_files {
    my ($dir) = @_;
    my @files;
    return @files unless -d $dir;
    opendir my $dh, $dir or return @files;
    for my $entry (readdir $dh) {
        next if $entry =~ /^\./;
        my $path = "$dir/$entry";
        if (-d $path) {
            push @files, _find_jsonl_files($path);
        } elsif ($path =~ /\.jsonl$/) {
            push @files, $path;
        }
    }
    closedir $dh;
    return @files;
}
sub _banner {
    my ($cols) = @_;
    my @letters = split //, "\x{FF33}\x{FF21}\x{FF29}\x{FF33}\x{FF2F}\x{FF2E}\x{FF33}";
    my @colors  = ('bold red', 'bold yellow', 'bold green', 'bold cyan', 'bold blue', 'bold magenta', 'bold red');
    my $title   = join '', map { colored($letters[$_], $colors[$_]) } 0..$#letters;
    my $author      = 'v' . App::Saisons::version_string() . "  by Nicolas Mendoza  \x{00a9} 2026";
    my $title_vis   = scalar @letters * 2;  
    my $pad         = $cols - $title_vis - length($author);
    $pad = 2 if $pad < 2;
    my $art_str = $title . _str_dim(' ' x $pad . $author) . "\033[K\n";
    return $art_str;
}
sub _render {
    my ($entries, $cursor, $offset, $visible, $sel_ids, $group_by, $running, $filter, $fulltext, $sort_col, $sort_rev, $sort_mode) = @_;
    $sort_col //= 'date';
    my $hide_path = $group_by eq 'path';
    my $sort_hl = $sort_mode ? 'bold black on_yellow' : 'bold yellow';
    my $sort_arrow = $sort_rev ? "\x{2193}" : "\x{2191}";  
    my $n    = scalar @$entries;
    my $cols = $COLS;
    my $banner = _banner($cols);
    my $banner_lines = 1;
    my $rel_w    = 8;   
    my $size_w   = 6;   
    my $id_w     = 8;
    my $tag_w    = 4;
    my $prefix_w = 4;   # ✔ and ● are each 2 terminal columns wide
    my $sep_w    = 1;
    my $has_sb   = $n > $visible ? 1 : 0;
    my $usable   = $COLS - $has_sb;
    my $path_w = 0;
    unless ($hide_path) {
        my $max_path = 0;
        for my $e (@$entries) {
            next unless $e->{type} eq 'session';
            my $len = length($e->{session}{cwd});
            $max_path = $len if $len > $max_path;
        }
        $path_w = $max_path > 40 ? 40 : $max_path < 20 ? 20 : $max_path;
    }
    my $fixed   = $prefix_w + 1 + $tag_w + $sep_w + $rel_w + $sep_w + $size_w + $sep_w + $id_w + $sep_w
                + ($path_w ? $path_w + $sep_w : 0);
    my $title_w = $usable - $fixed;
    $title_w = 10 if $title_w < 10;
    my $frame = "\033[H";
    $frame .= $banner;
    my @sb_char;
    if ($has_sb) {
        my $bar_height = int($visible * $visible / $n) || 1;
        my $bar_top    = int($offset  * $visible / $n);
        for my $r (0 .. $visible - 1) {
            $sb_char[$r] = ($r >= $bar_top && $r < $bar_top + $bar_height) ? '#' : '|';
        }
    }
    my $hdr_col = sub {
        my ($key, $label, $w) = @_;
        if ($sort_col eq $key) {
            return colored("$label$sort_arrow", $sort_hl) . ' ' x ($w - length($label) - 1);
        }
        return sprintf "%-${w}s", $label;
    };
    my $sel_mark_hdr = $sort_col eq 'selected' ? colored("\x{2714}", $sort_hl) : "\x{2714}";
    my $run_mark_hdr = $sort_col eq 'running'  ? colored("\x{25cf}", $sort_hl) : "\x{25cf}";
    my $hdr = $hide_path
        ? sprintf("%s %s   %s%s %s %s %s",
            $sel_mark_hdr, $run_mark_hdr,
            $hdr_col->('agent',   'Agt',     $tag_w),
            $hdr_col->('date',    'When',    $rel_w),
            $hdr_col->('size',    'Size',    $size_w),
            $hdr_col->('session', 'Session', $id_w),
            $hdr_col->('title',   'Title',   $title_w))
        : sprintf("%s %s   %s%s %s %s %s %s",
            $sel_mark_hdr, $run_mark_hdr,
            $hdr_col->('agent',   'Agt',     $tag_w),
            $hdr_col->('date',    'When',    $rel_w),
            $hdr_col->('size',    'Size',    $size_w),
            $hdr_col->('session', 'Session', $id_w),
            $hdr_col->('path',    'Path',    $path_w),
            $hdr_col->('title',   'Title',   $title_w));
    $frame .= _str_bold($hdr) . "\n";
    $frame .= _str_dim('-' x ($usable - 1)) . "\n";
    my $end = $offset + $visible - 1;
    $end = $n - 1 if $end >= $n;
    for my $i ($offset .. $end) {
        my $entry     = $entries->[$i];
        my $active    = $i == $cursor;
        my $row_idx   = $i - $offset;
        my $sb        = $sb_char[$row_idx] // '';
        if ($entry->{type} eq 'header') {
            my $line = sprintf " %-*s", $usable - 2, $entry->{label};
            $frame .= ($active
                ? color('reverse') . _str_boldyel($line) . RESET
                : _str_boldyel($line)) . "\n";
            next;
        }
        if ($entry->{type} eq 'match') {
            if ($entry->{gap}) {
                $frame .= '     ' . _str_dim("\x{22ee}") . "\033[K\n";
                next;
            }
            my $time = sprintf '%-16s', ($entry->{time} // '');
            my $maxw = $usable - 25;
            $maxw = 10 if $maxw < 10;
            my $text = substr($entry->{text} // '', 0, $maxw);
            if ($entry->{matched}) {
                if ($fulltext) {
                    my $re = _qr($fulltext);
                    $text =~ s/$re/colored($1, 'black on_yellow')/ge if $re;
                }
                $frame .= '     ' . _str_dim("\x{21b3} $time  ")
                       . _col_white . $text . RESET . "\033[K\n";
            } else {
                $frame .= '     ' . color('faint') . "\x{2502} $time  " . $text
                       . RESET . "\033[K\n";
            }
            next;
        }
        my $session    = $entry->{session};
        my $is_sel     = $sel_ids->{ $session->{id} };
        my $is_running = $running->{  $session->{id} };
        my $no_title   = ($session->{title} // '') eq '(no title)';
        my $sel_mark       = $is_sel     ? "\x{2714}" : ' ';   # ✔ = 2 cols; absent = 2 spaces
        my $running_bullet = $is_running ? "\x{25cf}" : ' ';   # ● = 2 cols; absent = 2 spaces
        my $tag   = _adapter_tag($session->{_adapter}, 0);
        my $when  = sprintf "%-${rel_w}s",   _rel_time($session->{epoch});
        my $size  = sprintf "%-${size_w}s",  _fmt_size($session->{_size} // 0);
        my $id    = sprintf "%-${id_w}s",    substr($session->{id}, 0, $id_w);
        my $raw_title = substr($session->{title}, 0, $title_w);
        my $raw_path  = $hide_path ? '' : _truncate_path($session->{cwd}, $path_w);
        if ($filter) {
            my $re = _qr($filter) // qr/(?!)/;
            $raw_title =~ s/$re/colored($1, 'bold reverse')/ge;
            $raw_path  =~ s/$re/colored($1, 'bold reverse')/ge unless $hide_path;
        }
        my $title = sprintf "%-${title_w}s", $raw_title;
        my $bg = $active && $is_sel ? _col_active_sel
               : $active            ? _col_active
               : $is_sel            ? _col_sel
               :                      '';
        my $row = $sel_mark . ' '
             . ($is_running ? _col_boldgrn . $running_bullet . RESET : ' ') . ' '
             . $tag . RESET . ' '
             . _col_yellow . $when . ' '
             . _col_cyan   . $size . ' '
             . _col_cyan   . $id   . ' '
             . ($hide_path ? '' : _col_green . $raw_path . ' ')
             . ($no_title ? color('faint') : _col_white) . $title
             . RESET;
        if ($bg) {
            # keep the column colors and re-arm the bar after every reset
            $row =~ s/\e\[0m/\e[0m$bg/g;
            $row = $bg . $row . RESET;
        }
        $frame .= $row . "\n";
    }
    my $rows_drawn = ($end >= $offset) ? ($end - $offset + 1) : 0;
    $frame .= "\033[K\n" x ($visible - $rows_drawn) if $rows_drawn < $visible;
    if ($has_sb) {
        my $sb_col = $COLS;  
        for my $r (0 .. $visible - 1) {
            my $screen_row = $banner_lines + 2 + 1 + $r;  
            $frame .= "\033[${screen_row};${sb_col}H"
                   . _str_dim($sb_char[$r] // '|');
        }
    }
    my $nsel        = scalar keys %$sel_ids;
    my $toggle_mode = $group_by eq ''     ? 'by path'
                    : $group_by eq 'path' ? 'by agent'
                    :                       'flat';
    my $pct         = $n > $visible ? sprintf(' %d%%', int(($offset + $visible/2) / $n * 100)) : '';
    my $footer = $sort_mode
        ? sprintf('[←→] sort column  [↑↓] direction  [s/ENTER/ESC] done   sorting: %s   %d/%d%s',
            $sort_col . ($sort_rev ? '↓' : '↑'), $nsel, $n, $pct)
        : sprintf(
        '[↑↓/jk] [PgUp/Dn] [SPC] select  [ENTER] open  [v]iew  [d]el  [m]ove  [t] %s  [s]ort  [r]efresh  [/] filter  [?] search  [a] all  [c] clear  [q]uit   %d/%d%s%s',
        $toggle_mode, $nsel, $n, $pct,
        ($filter   ? colored("  /filter: $filter",     'bold cyan')   : '')
      . ($fulltext ? colored("  ?search: $fulltext",   'bold yellow') : ''));
    $frame .= colored(substr($footer . ' ' x $cols, 0, $cols - 1), 'white on_blue');
    print $frame;
    STDOUT->flush();
}
sub _confirm {
    my ($prompt) = @_;
    print "\033[2J\033[H$prompt";
    my $ans = '';
    sysread STDIN, $ans, 1;
    return $ans;
}
sub _peek {
    my ($session) = @_;
    my @msgs = $session->{_adapter}->load_messages($session);
    my ($rows, $cols) = _term_size();
    my $wrap = $cols - 9;  
    $wrap = 40 if $wrap < 40;
    my @lines;
    push @lines, { text => _str_bold('Session: ') . $session->{title} };
    push @lines, { text => _str_bold('Path:    ') . _str_boldgrn($session->{cwd}) };
    push @lines, { text => _str_bold('ID:      ') . _str_boldcyn($session->{id}) };
    push @lines, { text => _str_bold('File:    ') . ($session->{_file} // '') };
    push @lines, { text => _str_dim('-' x ($cols - 2)) };
    for my $msg (@msgs) {
        my $is_user = $msg->{role} eq 'user';
        my $prefix  = $is_user ? _str_boldcyn('  You: ') : _str_boldyel('   AI: ');
        my $indent  = ' ' x 7;  
        my $first   = 1;
        (my $text = $msg->{text}) =~ s/\r//g;
        for my $line (split /\n/, $text) {
            $line ||= ' ';
            while (length($line) > $wrap) {
                my $chunk = substr($line, 0, $wrap, '');
                if ($chunk =~ s/(\s+\S+)$//) {
                    $line = $1 . $line;
                    $line =~ s/^\s+//;
                }
                push @lines, { text => ($first ? $prefix : $indent) . $chunk };
                $first = 0;
            }
            push @lines, { text => ($first ? $prefix : $indent) . $line };
            $first = 0;
        }
        push @lines, { text => '' };  
    }
    my $n      = scalar @lines;
    my $vis    = $rows - 2;
    my $offset = $n > $vis ? $n - $vis : 0;
    my $search = '';
    my $search_re;
    my @match_lines;
    my $match_idx = 0;
    _init_term();
    print "\033[?25l";
    while (1) {
        ($rows, $cols) = _term_size();
        $vis = $rows - 2;
        $offset = 0          if $offset < 0;
        $offset = $n - $vis  if $n > $vis && $offset > $n - $vis;
        print "\033[H\033[J";
        my $end = $offset + $vis - 1;
        $end = $n - 1 if $end >= $n;
        for my $i ($offset .. $end) {
            my $text = $lines[$i]{text};
            if ($search_re && $text =~ $search_re) {
                (my $hl = $text) =~ s/($search_re)/colored($1, 'black on_yellow')/ge;
                print $hl . "\n";
            } else {
                print $text . "\n";
            }
        }
        if ($n > $vis) {
            my $bar_h   = int($vis * $vis / $n) || 1;
            my $bar_top = int($offset * $vis / $n);
            for my $r (0 .. $vis - 1) {
                my $ch = ($r >= $bar_top && $r < $bar_top + $bar_h) ? '█' : '│';
                print "\033[" . ($r + 1) . ";${cols}H$ch";
            }
        }
        print "\033[${rows};1H";
        my $hint = $search
            ? sprintf('[n/N] match %d/%d  ', $match_idx + 1, scalar @match_lines) . '[↑↓/jk] scroll  [/] new search  [q/ESC] return'
            : '[↑↓/jk] scroll  [PgUp/Dn] page  [g/G] top/bot  [/] search  [q/ESC] return';
        print colored(substr($hint . ' ' x $cols, 0, $cols - 1), 'white on_blue');
        my $key = _read_key();
        if    ($key eq 'UP'   || $key eq 'k') { $offset-- }
        elsif ($key eq 'DOWN' || $key eq 'j') { $offset++ }
        elsif ($key eq 'PGUP')                { $offset -= $vis }
        elsif ($key eq 'PGDN')                { $offset += $vis }
        elsif ($key eq 'HOME' || $key eq 'g') { $offset = 0 }
        elsif ($key eq 'END'  || $key eq 'G') { $offset = $n - $vis }
        elsif ($key eq 'n' && @match_lines) {
            $match_idx = ($match_idx + 1) % @match_lines;
            $offset = $match_lines[$match_idx];
        }
        elsif ($key eq 'N' && @match_lines) {
            $match_idx = ($match_idx - 1 + @match_lines) % @match_lines;
            $offset = $match_lines[$match_idx];
        }
        elsif ($key eq '/') {
            print "\033[${rows};1H\033[K";
            print colored('/search: ', 'bold cyan');
            STDOUT->flush();
            my $q = '';
            while (1) {
                my $ch = _read_key();
                if ($ch eq "\n" || $ch eq "\r") { last }
                elsif ($ch eq 'ESC' || $ch eq 'EOF') { $q = $search; last }
                elsif ($ch eq 'BACKSPACE' || $ch eq "\x7f" || $ch eq "\x08") {
                    $q = substr($q, 0, -1) if length($q);
                } elsif (length($ch) == 1 && $ch ge ' ') {
                    $q .= $ch;
                }
                print "\033[${rows};1H\033[K";
                print colored('/search: ', 'bold cyan') . colored($q, 'bold white');
                STDOUT->flush();
            }
            if ($q) {
                $search     = $q;
                $search_re  = eval { qr/\Q$search\E/i } // undef;
                @match_lines = $search_re
                    ? grep { $lines[$_]{text} =~ $search_re } 0 .. $n - 1
                    : ();
                $match_idx = 0;
                $offset = @match_lines ? $match_lines[0] : $offset;
            } elsif (@match_lines) {
                $match_idx = ($match_idx + 1) % @match_lines;
                $offset = $match_lines[$match_idx];
            }
        }
        elsif ($key eq 'q' || $key eq 'ESC' || $key eq 'EOF') { last }
    }
    _restore_term();
    print "\033[?25h";
}
sub _do_delete {
    my ($chosen, $sessions, $sel_ids) = @_;
    print "\033[2J\033[H";
    print _str_boldred('Delete ' . scalar(@$chosen) . " session(s)?\n\n");
    for my $s (@$chosen) {
        printf "  %s\n",  _str_bold($s->{title});
        printf "  %s  %s\n", _str_boldgrn($s->{cwd}), _str_dim($s->{date});
        printf "  %s\n",  _str_dim($s->{_file} // '');
        print "\n";
    }
    print _str_boldred('[y] Delete  [n] Cancel: ');
    my $ans = '';
    sysread STDIN, $ans, 1;
    print "\n";
    if (lc($ans) eq 'y') {
        my %deleted_ids;
        for my $session (@$chosen) {
            $session->{_adapter}->delete_session($session);
            delete $sel_ids->{ $session->{id} };
            $deleted_ids{ $session->{id} } = 1;
        }
        @$sessions = grep { !$deleted_ids{$_->{id}} } @$sessions;
    }
}
sub _do_move {
    my ($chosen, $sessions, $sel_ids) = @_;
    print "\033[2J\033[H";
    print "Move " . scalar(@$chosen) . " session(s)\n";
    print "Current: " . _str_boldgrn($chosen->[0]{cwd}) . "\n\nNew directory: ";
    _restore_term();
    my $new_cwd = <STDIN>;
    return unless defined $new_cwd;
    chomp $new_cwd;
    $new_cwd =~ s|/$||;  
    unless ($new_cwd && -d $new_cwd) {
        print _str_boldred("Directory does not exist: $new_cwd\n");
        print "Press Enter..."; <STDIN>;
        return;
    }
    for my $session (@$chosen) {
        my ($ok, $err) = $session->{_adapter}->move_session($session, $new_cwd);
        print $ok ? _str_boldgrn("Moved $session->{id}\n") : _str_boldred("Error: $err\n");
    }
    print "Press Enter..."; <STDIN>;
}
# last component of a class name; s///r needs perl >= 5.14, we support 5.10
sub _short_class {
    my ($class) = @_;
    $class =~ s/.*:://;
    return $class;
}
sub _adapter_tag {
    my ($adapter, $active_or_sel) = @_;
    my $label = $adapter->can('tag')       ? $adapter->tag       : substr(_short_class(ref $adapter), 0, 5);
    my $col   = $adapter->can('tag_color') ? $adapter->tag_color : undef;
    return ($col && !$active_or_sel) ? colored($label, $col) : $label;
}
sub _fmt_size {
    my ($bytes) = @_;
    return '0B'                          unless $bytes;
    return "${bytes}B"                   if $bytes < 1024;
    return sprintf('%.0fK', $bytes/1024) if $bytes < 1024*1024;
    return sprintf('%.1fM', $bytes/1024/1024);
}
sub _rel_time {
    my ($epoch) = @_;
    return 'unknown' unless $epoch;
    my $diff = time() - $epoch;
    return 'just now'                    if $diff < 60;
    return int($diff/60)       . 'm ago' if $diff < 7200;
    return int($diff/3600)     . 'h ago' if $diff < 86400;
    return int($diff/86400)    . 'd ago' if $diff < 86400 * 30;
    return int($diff/86400/30) . 'mo ago' if $diff < 86400 * 365;
    return int($diff/86400/365). 'y ago';
}
1;
