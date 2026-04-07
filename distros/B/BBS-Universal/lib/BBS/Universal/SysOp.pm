package BBS::Universal::SysOp;
BEGIN { our $VERSION = '0.020'; }

sub sysop_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Initialize']);

    # Screen size and derived sections for layout
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    $self->{'wsize'} = $wsize;
    $self->{'hsize'} = $hsize;
    $self->{'debug'}->DEBUG(["Screen Size is $wsize x $hsize"]);

    my $sections     = _sections_for_width($wsize);
    my $versions     = $self->sysop_versions_format($sections, FALSE);
    my $bbs_versions = $self->sysop_versions_format($sections, TRUE);

    # Visual config
    $self->{'sysop_menu_colors'} = [91, 93, 92, 95, 94, 96];
    $self->{'sysop_menu_files'}  = ['', '', '', '', ''];

    # Default user capability flags
    $self->{'flags_default'} = {
        'prefer_nickname' => 'ON',
        'view_files'      => 'ON',
        'upload_files'    => 'OFF',
        'download_files'  => 'ON',
        'remove_files'    => 'OFF',
        'read_message'    => 'ON',
        'post_message'    => 'ON',
        'remove_message'  => 'OFF',
        'sysop'           => 'OFF',
        'show_email'      => 'OFF',
    };

    # Tokens (static + dynamic)
    my $static  = _build_static_tokens($self, $versions, $bbs_versions);
    my $dynamic = _build_dynamic_tokens($self);
    $self->{'sysop_tokens'} = { %{$static}, %{$dynamic} };

    # Field orderings
    $self->{'SYSOP ORDER DETAILED'} = [
        qw(
            id
            fullname
            username
            given
            family
            nickname
            email
            birthday
            location
            access_level
            date_format
            baud_rate
            text_mode
            max_columns
            max_rows
            timeout
            retro_systems
            accomplishments
            prefer_nickname
            view_files
            upload_files
            download_files
            remove_files
            play_fortunes
            read_message
            post_message
            remove_message
            sysop
            banned
            login_time
            logout_time
        )
    ];

    $self->{'SYSOP ORDER ABBREVIATED'} = [
        qw(
            id
            fullname
            username
            given
            family
            nickname
            text_mode
        )
    ];

    # Field type definitions
    $self->{'SYSOP FIELD TYPES'} = {
        'id'              => { 'type' => NUMERIC, 'max' => 2,   'min' => 2 },
        'username'        => { 'type' => HOST,    'max' => 32,  'min' => 16 },
        'fullname'        => { 'type' => STRING,  'max' => 20,  'min' => 15 },
        'given'           => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'family'          => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'nickname'        => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'email'           => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'birthday'        => { 'type' => STRING,  'max' => 10,  'min' => 10 },
        'location'        => { 'type' => STRING,  'max' => 120, 'min' => 40 },
        'date_format'     => { 'type' => RADIO,   'max' => 14,  'min' => 14, 'choices' => ['MONTH/DAY/YEAR', 'DAY/MONTH/YEAR', 'YEAR/MONTH/DAY'], 'default' => 'DAY/MONTH/YEAR', },
        'access_level'    => { 'type' => RADIO,   'max' => 12,  'min' => 12, 'choices' => ['USER', 'VETERAN', 'JUNIOR SYSOP', 'SYSOP'], 'default' => 'USER', },
        'baud_rate'       => { 'type' => RADIO,   'max' => 5,   'min' => 5,  'choices' => ['FULL', '115200', '57600', '38400', '19200', '9600', '4800', '2400', '1200', '600', '300'], 'default' => 'FULL', },
        'login_time'      => { 'type' => STRING,  'max' => 10,  'min' => 10 },
        'logout_time'     => { 'type' => STRING,  'max' => 10,  'min' => 10 },
        'text_mode'       => { 'type' => RADIO,   'max' => 7,   'min' => 9, 'choices' => ['ANSI', 'ASCII', 'ATASCII', 'PETSCII'], 'default' => 'ASCII', },
        'max_rows'        => { 'type' => NUMERIC, 'max' => 3,   'min' => 3, 'default' => 25 },
        'max_columns'     => { 'type' => NUMERIC, 'max' => 3,   'min' => 3, 'default' => 80 },
        'timeout'         => { 'type' => NUMERIC, 'max' => 5,   'min' => 5, 'default' => 10 },
        'retro_systems'   => { 'type' => STRING,  'max' => 120, 'min' => 40 },
        'accomplishments' => { 'type' => STRING,  'max' => 120, 'min' => 40 },
        'prefer_nickname' => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'view_files'      => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'ON' },
        'banned'          => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'upload_files'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'download_files'  => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'remove_files'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'read_message'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'ON' },
        'post_message'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'remove_message'  => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'play_fortunes'   => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'ON' },
        'sysop'           => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'password'        => { 'type' => STRING,  'max' => 64,  'min' => 32 },
    };

    $self->{'debug'}->DEBUG(['End SysOp Initialize']);
    return $self;
} ## end sub sysop_initialize

# Helper: map terminal width to section count
sub _sections_for_width {
    my ($wsize) = @_;
    return 1 if $wsize <= 80;
    return 2 if $wsize <= 120;
    return 3 if $wsize <= 160;
    return 4 if $wsize <= 200;
    return 5 if $wsize <= 240;
    return 6;
} ## end sub _sections_for_width

# Helper: build static token fields from $self
sub _build_static_tokens {
    my ($self, $versions, $bbs_versions) = @_;
    return {
        'HOSTNAME'     => $self->sysop_hostname,
        'IP ADDRESS'   => $self->sysop_ip_address(),
        'CPU BITS'     => $self->{'CPU'}->{'CPU BITS'},
        'CPU CORES'    => $self->{'CPU'}->{'CPU CORES'},
        'CPU SPEED'    => $self->{'CPU'}->{'CPU SPEED'},
        'CPU IDENTITY' => $self->{'CPU'}->{'CPU IDENTITY'},
        'CPU THREADS'  => $self->{'CPU'}->{'CPU THREADS'},
        'HARDWARE'     => $self->{'CPU'}->{'HARDWARE'},
        'VERSIONS'     => $versions,
        'BBS VERSIONS' => $bbs_versions,
        'BBS NAME'     => colored(['green'], $self->{'CONF'}->{'BBS NAME'}),
    };
} ## end sub _build_static_tokens

# Helper: build dynamic token closures (uniform style)
sub _build_dynamic_tokens {
    my ($self) = @_;
    return {
        'THREADS COUNT'   => sub { my $self = shift; return $self->{'CACHE'}->get('THREADS_RUNNING'); },
        'USERS COUNT'     => sub { my $self = shift; return $self->db_count_users(); },
        'UPTIME'          => sub { my $self = shift; my $uptime = `uptime -p`; chomp($uptime); return $uptime; },
        'DISK FREE SPACE' => sub { my $self = shift; return $self->sysop_disk_free(); },
        'MEMORY'          => sub { my $self = shift; return $self->sysop_memory(); },
        'ONLINE'          => sub { my $self = shift; return $self->sysop_online_count(); },
        'CPU LOAD'        => sub { my $self = shift; return $self->cpu_info->{'CPU LOAD'}; },
        'ENVIRONMENT'     => sub { my $self = shift; return $self->sysop_showenv(); },
        'FILE CATEGORY'   => sub {
			my $self = shift;
			my $sth  = $self->{'dbh'}->prepare('SELECT description FROM file_categories WHERE id=?');
			$sth->execute($self->{'USER'}->{'file_category'});
			my ($result) = $sth->fetchrow_array();
			return $self->news_title_colorize($result);
		},
        'SYSOP VIEW CONFIGURATION'   => sub { my $self = shift; return $self->sysop_view_configuration('string'); },
        'COMMANDS REFERENCE'         => sub { my $self = shift; return $self->sysop_list_commands(); },
        'MIDDLE VERTICAL RULE color' => sub { my $self = shift; my $color = shift; return $self->sysop_locate_middle('B_' . $color); },
    };
} ## end sub _build_dynamic_tokens

# Helper: get sorted keys plus optional appended items
sub _collect_names {
    my ($href, @extra) = @_;
    my @k = sort(keys %{$href});
    push @k, @extra if @extra;
    return @k;
} ## end sub _collect_names

# Helper: compute max width from list
sub _compute_max_width {
    my ($list_ref, $min) = @_;
    my $w = $min // 1;
    foreach my $cell (@{$list_ref}) { $w = max(length($cell), $w); }
    return $w;
} ## end sub _compute_max_width

# Helper: standard two-column table render with paging breaks
sub _render_table {
    my ($title_left, $title_right, $left_ref, $right_ref, $wsize, $srow) = @_;
    my $lw    = _compute_max_width($left_ref,  1);
    my $rw    = _compute_max_width($right_ref, 1);
    my $table = Text::SimpleTable->new($lw, $rw);
    $table->row($title_left, $title_right);
    $table->hr();
    my $count = 0;
    while (scalar(@{$left_ref}) || scalar(@{$right_ref})) {
        my $l = scalar(@{$left_ref})  ? shift(@{$left_ref})  : ' ';
        my $r = scalar(@{$right_ref}) ? shift(@{$right_ref}) : ' ';
        $table->row($l, $r);
        $count++;
        if ($count > $srow) {
            $count = 0;
            $table->hr();
            $table->row($title_left, $title_right);
            $table->hr();
        } ## end if ($count > $srow)
    } ## end while (scalar(@{$left_ref...}))
    return $table->twin('ORANGE')->draw();
} ## end sub _render_table

# Helper: substitutions registry
sub _substitutions_for_mode {
    my ($mode) = @_;
    return [
        # Common header highlight
        [qr/ (C|DESCRIPTION|TYPE|SYSOP MENU COMMANDS|SYSOP TOKENS|USER MENU COMMANDS|USER TOKENS|ATASCII TOKENS|PETSCII TOKENS|ASCII TOKENS) /, ' [% BRIGHT YELLOW %]$1[% RESET %] '],

        # USER/SYSOP italicize "color" and "text"
        ($mode =~ /USER|SYSOP/ ? ([qr/color/, '[% ITALIC %][% FAINT %]color[% RESET %]'], [qr/text/, '[% ITALIC %][% FAINT %]text[% RESET %]'],) : ()),

        # PETSCII color names mapped to ANSI
        ($mode eq 'PETSCII' ? ([qr/│ (WHITE)/, '│ [% BRIGHT WHITE %]$1[% RESET %]'], [qr/│ (YELLOW)/, '│ [% YELLOW %]$1[% RESET %]'], [qr/│ (CYAN)/, '│ [% CYAN %]$1[% RESET %]'], [qr/│ (GREEN)/, '│ [% GREEN %]$1[% RESET %]'], [qr/│ (PINK)/, '│ [% PINK %]$1[% RESET %]'], [qr/│ (BLUE)/, '│ [% BLUE %]$1[% RESET %]'], [qr/│ (RED)/, '│ [% RED %]$1[% RESET %]'], [qr/│ (PURPLE)/, '│ [% COLOR 127 %]$1[% RESET %]'], [qr/│ (DARK PURPLE)/, '│ [% COLOR 53 %]$1[% RESET %]'], [qr/│ (GRAY)/, '│ [% GRAY 9 %]$1[% RESET %]'], [qr/│ (BROWN)/, '│ [% COLOR 94 %]$1[% RESET %]'],) : ()),
    ];
} ## end sub _substitutions_for_mode

sub _apply_substitutions {
    my ($text, $rules) = @_;
    for my $rule (@$rules) {
        my ($re, $rep) = @$rule;
        $text =~ s/$re/$rep/g;
    }
    return $text;
} ## end sub _apply_substitutions

# Optional: isolate the very large ANSI catalog builder to its own function (preserving behavior)
sub _render_ansi_catalog {
    my ($self, $wsize) = @_;

    # This preserves the original logic and content, but organizes the huge string building
    # into manageable sections. The content below is copied verbatim from your ANSI branch,
    # with only structural arrangement and minor variable scoping cleanups.

    # Header banner
    my $text .= '[% BRIGHT GREEN %]╭' . '─' x 122 . '╮[% RESET %]' . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                                 _    _   _ ____ ___   _____ ___  _  _______ _   _ ____                                   [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                                / \  | \ | / ___|_ _| |_   _/ _ \| |/ / ____| \ | / ___|                                  [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                               / _ \ |  \| \___ \| |    | || | | | ' /|  _| |  \| \___ \                                  [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                              / ___ \| |\  |___) | |    | || |_| | . \| |___| |\  |___) |                                 [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                             /_/   \_\_| \_|____/___|   |_| \___/|_|\_\_____|_| \_|____/                                  [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                                                                                                                          [% BRIGHT GREEN %]│[% RESET %]} . "\n";

    my $bar = '[% BRIGHT GREEN %]│[% RESET %]';
    # CLEAR section
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]CLEAR [% RESET %][% BRIGHT GREEN %]' . '═' x 56 . '╤' . '═' x 56 . '╡[% RESET %]' . "\n";
    {
        my @names = (sort(keys %{ $self->{'ansi_meta'}->{'clear'} }));
        while (scalar(@names)) {
            my $name = shift(@names);
            $text .= '[% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-63s', $name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('clear', $name)) . ' [% BRIGHT GREEN %]│[% RESET %]' . "\n";
        }
    }

    # CURSOR section
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]CURSOR [% RESET %][% BRIGHT GREEN %]' . '═' x 55 . '╪' . '═' x 56 . '╡[% RESET %]' . "\n";
    {
        my @names = (sort(keys %{ $self->{'ansi_meta'}->{'cursor'} }));
        while (scalar(@names)) {
            my $name = shift(@names);
            $text .= "$bar " . sprintf('%-63s', $name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('cursor', $name)) . " $bar\n";
        }
        $text .= "$bar " . sprintf('%-63s', 'LOCATE column,row') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Sets the cursor location') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s', 'SCROLL UP count') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Scrolls the screen up by "count" lines') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s', 'SCROLL DOWN count') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Scrolls the screen down by "count" lines') . " $bar\n";
    }

    # ATTRIBUTES section
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]ATTRIBUTES [% RESET %][% BRIGHT GREEN %]' . '═' x 51 . '╪' . '═' x 56 . '╡[% RESET %]' . "\n";
    {
        my @names = grep(!/FONT \d/, (sort(keys %{ $self->{'ansi_meta'}->{'attributes'} })));
        foreach my $name (@names) {
            if ($name =~ /FONT|HIDE|RING BELL/) {
                $text .= "$bar " . sprintf('%-63s', $name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('attributes', $name)) . " $bar\n";
                $text .= "$bar " . sprintf('%-63s', 'FONT 1-9') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Set specific font (1-9)') . " $bar\n" if ($name eq 'FONT DEFAULT');
            } else {
                $text .= '[% BRIGHT GREEN %]│[% RESET %][% ' . $name . ' %]' . sprintf(' %-63s', $name) . ' [% RESET %][% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('attributes', $name)) . " $bar\n";
            }
        } ## end foreach my $name (@names)
        $text .= "$bar " . sprintf('%-62s', 'UNDERLINE COLOR RGB red,green,blue ') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Set the underline color using RGB') . " $bar\n";
    }

    # Colors
    {
        my $f;
        my $b;
        foreach my $code ('ANSI 3 BIT','ANSI 4 BIT','ANSI 8 BIT','ANSI 24 BIT') {
            if ($code eq 'ANSI 3 BIT') {
                $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]' . sprintf('%-11s',$code) . ' [% RESET %][% BRIGHT GREEN %]════════════════╤═════════════════════════════════╪════════════════════════════════════════════════════════╡[% RESET %]' . "\n";
            } else {
                $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]' . sprintf('%-11s',$code) . ' [% RESET %][% BRIGHT GREEN %]════════════════╪═════════════════════════════════╪════════════════════════════════════════════════════════╡[% RESET %]' . "\n";
            }
            if ($code eq 'ANSI 8 BIT') {
				foreach my $count (16 .. 231) {
					$text .= '[% BRIGHT GREEN %]│[% RESET %][% COLOR ' . $count . ' %]' . sprintf(' %-29s ',"COLOR $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% BLACK %][% B_COLOR ' . $count . ' %]' . sprintf(' %-31s ', "B_COLOR $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ',$self->ansi_description('foreground',"COLOR $count")) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
				}
				foreach my $count (0 .. 23) {
					$text .= '[% BRIGHT GREEN %]│[% RESET %][% GRAY ' . $count . ' %]' . sprintf(' %-29s ', "GRAY $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% BLACK %][% B_GRAY ' . $count . ' %]' . sprintf(' %-31s ', "B_GRAY $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ',$self->ansi_description('foreground',"GRAY $count")) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
				}
            }
            foreach my $name (grep(!/COLOR |GRAY /,sort(keys %{$self->{'ansi_meta'}->{'foreground'}}))) {
                if ($self->ansi_type($self->{'ansi_meta'}->{'foreground'}->{$name}->{'out'}) eq $code) {
					if ($name =~ /^(DEFAULT|NAVY|COLOR 16|BLACK|MEDIUM BLUE|ARMY GREEN|BISTRE|BULGARIAN ROSE|CHARCOAL|COOL BLACK|DARK BLUE|DARK GREEN|DARK JUNGLE GREEN|DARK MIDNIGHT BLUE|DUKE BLUE|EGYPTIAN BLUE|MEDIUM JUNGLE GREEN|MIDNIGHT BLUE|NAVY BLUE|ONYX|OXFORD BLUE|PHTHALO BLUE|PHTHALO GREEN|PRUSSIAN BLUE|SAINT PATRICK BLUE|SEAL BROWN|SMOKEY BLACK|ULTRAMARINE|ZINNWALDITE BROWN)$/) {
						$text .= '[% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-29s ',$name) . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% B_' . $name . ' %]' . sprintf(' %-31s ', "B_${name}") . '[% RESET %]│' . sprintf(' %-54s ',$self->ansi_description('foreground',$name)) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
					} else {
						$text .= '[% BRIGHT GREEN %]│[% RESET %][% ' . $name . ' %]' . sprintf(' %-29s ',$name) . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% BLACK %][% B_' . $name . ' %]' . sprintf(' %-31s ', "B_${name}") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ',$self->ansi_description('foreground',$name)) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
					}
				}
            }
        }
        $text .= '[% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-29s ','RGB red,green,blue') . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-31s ', 'B_RGB red,green,blue') . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ','Set color to a value 0-255 per primary color.') . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
    }

    # Special
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]SPECIAL [% RESET %][% BRIGHT GREEN %]════════════════════╧═════════════════════════════════╪════════════════════════════════════════════════════════╡[% RESET %]' . "\n";

    {
        my @names = (sort(keys %{$self->{'ansi_meta'}->{'special'}}));
        while(scalar(@names)) {
            my $name = shift(@names);
            $text .= "$bar " . sprintf('%-63s',$name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s',$self->ansi_description('special',$name)) . " $bar\n";
        }
        $text .= '[% BRIGHT GREEN %]│ ─────────────────────────────────────────────────────────────── │ ────────────────────────────────────────────────────── │[% RESET %]' . "\n";
        $text .= "$bar " . sprintf('%-63s', 'HORIZONTAL RULE color') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s','Horizontal rule the width of the screen in the') . " $bar\n";
        $text .= '[% BRIGHT GREEN %]│[% RESET %]                                                                 [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s','specified color.') . " $bar\n";
        $text .= '[% BRIGHT GREEN %]│ ─────────────────────────────────────────────────────────────── │ ────────────────────────────────────────────────────── │[% RESET %]' . "\n";
        $text .= "$bar " . sprintf('%-63s','BOX color,column,row,width,height,type') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Shows framed text box in the selected frame type and') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s',' ') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'color.  Text goes between the BOX and ENDBOX token') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s','    types:') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'See the "frames" option') . " $bar\n";
        $text .= "$bar " . sprintf('%63s','DOUBLE, THIN, THICK, CIRCLE, ROUNDED, BLOCK, WEDGE') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', ' ') . " $bar\n";
        $text .= "$bar " . sprintf('%63s','BIG WEDGE, DOTS, DIAMOND, STAR, SQUARE, DITHERED, NOTES') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', ' ') . " $bar\n";
        $text .= "$bar " . sprintf('%63s','HEARTS, CHRISTIAN, ARROWS, BIG ARROWS, PARALLELOGRAM') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', ' ') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s','ENDBOX') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Ends the BOX token function') . " $bar\n";
    }
    $text .= '[% BRIGHT GREEN %]╰─────────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────╯[% RESET %]' . "\n";

    # Post processing identical to original
    {
        my $new = 'UNDERLINE COLOR RGB [% UNDERLINE COLOR RGB 255,0,0 %][% UNDERLINE %]red[% RESET %],[% UNDERLINE %][% UNDERLINE COLOR RGB 0,255,0 %]green[% RESET %],[% UNDERLINE %][% UNDERLINE COLOR RGB 0,0,255 %]blue[% RESET %]';
        $text =~ s/UNDERLINE COLOR RGB red,green,blue/$new /gs;

        $new = '[% FAINT %][% ITALIC %] color     [% RESET %]';
        $text =~ s/ color     /$new/gs;

        $new = '[% FAINT %][% ITALIC %] count     [% RESET %]';
        $text =~ s/ count     /$new/gs;

        $new = ' [% RED %][% ITALIC %]red[% RESET %],[% GREEN %][% ITALIC %]green[% RESET %],[% BLUE %][% ITALIC %]blue[% RESET %]';
        $text =~ s/ red,green,blue/$new/gs;

        $new = ' [% FAINT %][% ITALIC %]column[% RESET %],[% FAINT %][% ITALIC %]row[% RESET %] ';
        $text =~ s/ column,row /$new/gs;

        $new = ' [% FAINT %][% ITALIC %]color[% RESET %],[% FAINT %][% ITALIC %]column[% RESET %],[% FAINT %][% ITALIC %]row[% RESET %],[% FAINT %][% ITALIC %]width[% RESET %],[% FAINT %][% ITALIC %]height[% RESET %],[% FAINT %][% ITALIC %]type[% RESET %] ';
        $text =~ s/ color,column,row,width,height,type /$new/gs;
    }

    return $text;
} ## end sub _render_ansi_catalog

sub sysop_list_commands {
    my $self = shift;
    my $mode = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List Commands']);

    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $size = ($hsize - ($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')));
    my $srow = $size - 5;

    my $text = '';

    if ($mode && $mode eq 'ASCII') {
        my @asctkn = (sort(keys %{ $self->{'ascii_meta'} }), 'HORIZONTAL RULE');
        my $asc    = 12;
        foreach my $cell (@asctkn) { $asc = max(length($cell), $asc); }
        my $table = Text::SimpleTable->new($asc, 25);
        $table->row('ASCII TOKENS', 'DESCRIPTION');
        $table->hr();
        while (scalar(@asctkn)) {
            my $ascii_tokens = shift(@asctkn);
            $table->row($ascii_tokens, $self->{'ascii_meta'}->{$ascii_tokens}->{'desc'});
        }
        $text = $self->center($table->twin('ORANGE')->draw(), $wsize);

    } elsif ($mode && $mode eq 'ANSI') {

        # Use refactored dedicated ANSI builder while preserving original output
        $text = _render_ansi_catalog($self, $wsize);

    } elsif ($mode && $mode eq 'ATASCII') {
        my @atatkn = (sort(keys %{ $self->{'atascii_meta'} }));

        $text  = '[% ORANGE %]╔' . '═' x 86 . '╗[% RESET %]' . "\n";
        $text .= "[% ORANGE %]║[% YELLOW  %]    ## ## ##          [% BRIGHT BLUE %]╔═══╗ ╒═╦═╕ ╔═══╗ ╔═══╗ ╔═══╕ ╒═╦═╕ ╒═╦═╕       [% YELLOW  %]    ## ## ##    [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% GREEN   %]    ## ## ##          [% BRIGHT BLUE %]║   ║   ║   ║   ║ ║   ╜ ║       ║     ║         [% GREEN   %]    ## ## ##    [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% CYAN    %]    ## ## ##          [% BRIGHT BLUE %]╠═══╣   ║   ╠═══╣ ╚═══╗ ║       ║     ║         [% CYAN    %]    ## ## ##    [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% BLUE    %]  ###  ##  ###        [% BRIGHT BLUE %]║   ║   ║   ║   ║ ╓   ║ ║       ║     ║         [% BLUE    %]  ###  ##  ###  [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% MAGENTA %] ###   ##   ###       [% BRIGHT BLUE %]╜   ╙   ╙   ╜   ╙ ╚═══╝ ╚═══╛ ╘═╩═╛ ╘═╩═╛       [% MAGENTA %] ###   ##   ### [% ORANGE %]║[% RESET %]\n";
        $text .= '[% ORANGE %]╠══════╦' . '═' x 39 . '╦' . '═' x 39 . '╣[% RESET %]' . "\n";
        $text .= "[% ORANGE %]║[% BRIGHT YELLOW %] CHAR [% ORANGE %]║[% BRIGHT YELLOW %] ATASCII TOKENS                        [% ORANGE %]║[% BRIGHT YELLOW %] DESCRIPTION                           [% ORANGE %]║[% RESET %]\n";
        $text .= '[% ORANGE %]╠══════╬' . '═' x 39 . '╬' . '═' x 39 . '╣[% RESET %]' . "\n";

        foreach my $name (@atatkn) {
            $text .= '[% ORANGE %]║[% RESET %]  ' . $self->{'atascii_meta'}->{$name}->{'unicode'} . '   [% ORANGE %]║[% RESET %] ' . sprintf('%-37s %s %-37s %s', $name, '[% ORANGE %]║[% RESET %]', $self->{'atascii_meta'}->{$name}->{'desc'}, '[% ORANGE %]║[% RESET %]') . "\n";
        }
		$text .= '[% ORANGE %]║[% RESET %] ' . '[% HORIZONTAL BAR %]' x 4 . ' [% ORANGE %]║[% RESET %] ' . sprintf('%-37s %s %-37s %s', 'HORIZONTAL RULE', '[% ORANGE %]║[% RESET %]', 'Horizontal rule', '[% ORANGE %]║[% RESET %]') . "\n";

        $text .= "[% ORANGE %]╚══════╩═══════════════════════════════════════╩═══════════════════════════════════════╝[% RESET %]\n";

    } elsif ($mode && $mode eq 'PETSCII') {
        # ─ ━ │ ┃ ┄ ┅ ┆ ┇ ┈ ┉ ┊ ┋ ┌ ┍ ┎ ┏ ┐ ┑ ┒ ┓ └ ┕ ┖ ┗ ┘ ┙ ┚ ┛ ├ ┝ ┞ ┟ ┠ ┡ ┢ ┣ ┤ ┥ ┦ ┧ ┨ ┩ ┪ ┫ ┬ ┭ ┮ ┯ ┰ ┱ ┲ ┳ ┴ ┵ ┶ ┷ ┸ ┹ ┺ ┻ ┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋ ╌ ╍ ╎ ╏ ═ ║ ╒ ╓ ╔ ╕ ╖ ╗ ╘ ╙ ╚ ╛ ╜ ╝ ╞ ╟ ╠ ╡ ╢ ╣ ╤ ╥ ╦ ╧ ╨ ╩ ╪ ╫ ╬ ╭ ╮ ╯ ╰ ╱ ╲ ╳ ╴ ╵ ╶ ╷ ╸ ╹ ╺ ╻ ╼ ╽ ╾ ╿
		# 🬀 🬁 🬂 🬃 🬄 🬅 🬆 🬇 🬈 🬉 🬊 🬋 🬌 🬍 🬎 🬏 🬐 🬑 🬒 🬓 🬔 🬕 🬖 🬗 🬘 🬙 🬚 🬛 🬜 🬝 🬞 🬟 🬠 🬡 🬢 🬣 🬤 🬥 🬦 🬧 🬨 🬩 🬪 🬫 🬬 🬭 🬮 🬯 🬰 🬱 🬲 🬳 🬴 🬵 🬶 🬷 🬸 🬹 🬺 🬻 🬼 🬽 🬾 🬿 🭀 🭁 🭂 🭃 🭄 🭅 🭆 🭇 🭈 🭉 🭊 🭋 🭌 🭍 🭎 🭏 🭐 🭑 🭒 🭓 🭔 🭕 🭖 🭗 🭘 🭙 🭚 🭛 🭜 🭝 🭞 🭟 🭠 🭡 🭢 🭣 🭤 🭥 🭦 🭧 🭨 🭩 🭪 🭫 🭬 🭭 🭮 🭯
		#  🭰 🭱 🭲 🭳 🭴 🭵 🭶 🭷 🭸 🭹 🭺 🭻 🭼 🭽 🭾 🭿 🮀 🮁 🮂 🮃 🮄 🮅 🮆 🮇 🮈 🮉 🮊 🮋 🮌 🮍 🮎 🮏 🮐 🮑 🮒 🮔 🮕 🮖 🮗 🮘 🮙 🮚 🮛 🮜 🮝 🮞 🮟 🮠 🮡 🮢 🮣 

        my @pettkn = sort(keys %{ $self->{'petscii_meta'} });

        $text  = '[% ORANGE %]╔' . '═' x 108 . '╗[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %] .o88b. [% RESET                                           %][% BRIGHT WHITE %]                          8""""8 8"""" ""8"" 8""""8 8""""8 8  8                        [% BLUE %] .o88b. [% RESET %]    [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]d8P  Y8 [% RESET                                           %][% BRIGHT WHITE %]                          8    8 8       8   8      8    " 8  8                        [% BLUE %]d8P  Y8 [% RESET %]    [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]8P     🮅🮅🮅🭚[% RESET                                           %][% BRIGHT WHITE %]                       8eeee8 8eeee   8e  8eeeee 8e     8e 8e                       [% BLUE %]8P     🮅🮅🮅🭚[% RESET %] [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]8b     [% RED %][% REVERSE %]🮂🮂🮂[% RESET %][% RED %]🬿[% RESET %][% BRIGHT WHITE %]                       88     88      88      88 88     88 88                       [% BLUE %]8b     [% RED %][% REVERSE %]🮂🮂🮂[% RESET %][% RED %]🬿[% RESET %] [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]Y8b  d8 [% RESET                                           %][% BRIGHT WHITE %]                          88     88      88  e   88 88   e 88 88                       [% BLUE %]Y8b  d8 [% RESET %]    [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]' . " `Y88P'" . '[% RESET                                 %][% BRIGHT WHITE %]                           88     88eee   88  8eee88 88eee8 88 88                       ' . "[% BLUE %] `Y88P'" . '[% RESET %]     [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]╠══════╦' . '═' x 50 . '╦' . '═' x 50 . '╣[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% BRIGHT YELLOW %] CHAR [% ORANGE %]║[% BRIGHT YELLOW %] PETSCII TOKENS                                   [% ORANGE %]║[% BRIGHT YELLOW %] DESCRIPTION                                      [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]╠══════╬' . '═' x 50 . '╬' . '═' x 50 . '╣[% RESET %]' . "\n";

        foreach my $name (@pettkn) {
            $text .= '[% ORANGE %]║[% RESET %]  ' . $self->{'petscii_meta'}->{$name}->{'unicode'} . '   [% ORANGE %]║[% RESET %] ' . sprintf('%-48s %s %-48s %s', $name, '[% ORANGE %]║[% RESET %]', $self->{'petscii_meta'}->{$name}->{'desc'}, '[% ORANGE %]║[% RESET %]') . "\n";
        }
        $text .= '[% ORANGE %]║[% RESET %] ' . '[% HORIZONTAL BAR %]' x 4 . ' [% ORANGE %]║[% RESET %] ' . sprintf('%-48s %s %-48s %s', 'HORIZONTAL RULE color', '[% ORANGE %]║[% RESET %]', 'Horizontal rule in specified color', '[% ORANGE %]║[% RESET %]') . "\n";

        $text .= '[% ORANGE %]╚══════╩' . '═' x 50 . '╩' . '═' x 50 . '╝[% RESET %]' . "\n";

        $text =~ s/│ (WHITE)/│ \[\% BRIGHT WHITE \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (YELLOW)/│ \[\% YELLOW \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (CYAN)/│ \[\% CYAN \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (GREEN)/│ \[\% GREEN \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (PINK)/│ \[\% PINK \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (BLUE)/│ \[\% BLUE \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (RED)/│ \[\% RED \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (PURPLE)/│ \[\% COLOR 127 \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (DARK PURPLE)/│ \[\% COLOR 53 \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (GRAY)/│ \[\% GRAY 9 \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (BROWN)/│ \[\% COLOR 94 \%\]$1\[\% RESET \%\]/g;

    } elsif ($mode && $mode eq 'USER') {
        my @usr = (sort(keys %{ $self->{'COMMANDS'} }));
        my @tkn = (sort(keys %{ $self->{'TOKENS'} }, 'JUSTIFIED text ENDJUSTIFIED', 'WRAP text ENDWRAP'));
        my $y   = 1;
        my $z   = 1;
        foreach my $cell (@usr) { $y = max(length($cell), $y); }
        foreach my $cell (@tkn) { $z = max(length($cell), $z); }
        my $table = Text::SimpleTable->new($y, $z);
        $table->row('USER MENU COMMANDS', 'USER TOKENS');
        $table->hr();
        my ($user_names, $token_names);
        my $count = 0;

        while (scalar(@usr) || scalar(@tkn)) {
            $user_names  = scalar(@usr) ? shift(@usr) : ' ';
            $token_names = scalar(@tkn) ? shift(@tkn) : ' ';
            $table->row($user_names, $token_names);
            $count++;
            if ($count > $srow) {
                $count = 0;
                $table->hr();
                $table->row('USER MENU COMMANDS', 'USER TOKENS');
                $table->hr();
            } ## end if ($count > $srow)
        } ## end while (scalar(@usr) || scalar...)
        $text = $self->center($table->twin('ORANGE')->draw(), $wsize);
        foreach my $name (qw(color text)) {
            my $ch = '[% ITALIC %][% FAINT %]' . $name . '[% RESET %]';
            $text =~ s/$name/$ch/gs;
        }

    } elsif ($mode && $mode eq 'SYSOP') {
        my @sys  = (sort(keys %{$main::SYSOP_COMMANDS}));
        my @stkn = (sort(keys %{ $self->{'sysop_tokens'} }, 'JUSTIFIED text ENDJUSTIFIED', 'WRAP text ENDWRAP'));
        my $x    = 1;
        my $xt   = 1;
        foreach my $cell (@sys)  { $x  = max(length($cell), $x); }
        foreach my $cell (@stkn) { $xt = max(length($cell), $xt); }
        my $table = Text::SimpleTable->new($x, $xt);
        $table->row('SYSOP MENU COMMANDS', 'SYSOP TOKENS');
        $table->hr();
        my ($sysop_names, $sysop_tokens);
        my $count = 0;

        while (scalar(@sys) || scalar(@stkn)) {
            $sysop_names  = scalar(@sys)  ? shift(@sys)  : ' ';
            $sysop_tokens = scalar(@stkn) ? shift(@stkn) : ' ';
            $table->row($sysop_names, $sysop_tokens);
            $count++;
            if ($count > $srow) {
                $count = 0;
                $table->hr();
                $table->row('SYSOP MENU COMMANDS', 'SYSOP TOKENS');
                $table->hr();
            } ## end if ($count > $srow)
        } ## end while (scalar(@sys) || scalar...)
        $text = $self->center($table->twin('ORANGE')->draw(), $wsize);
        foreach my $name (qw(color text)) {
            my $ch = '[% ITALIC %][% FAINT %]' . $name . '[% RESET %]';
            $text =~ s/$name/$ch/gs;
        }
    } ## end elsif ($mode && $mode eq ...)

    # Common header highlights (preserving original behavior)
    $text =~ s/ (DESCRIPTION|TYPE|SYSOP MENU COMMANDS|SYSOP TOKENS|USER MENU COMMANDS|USER TOKENS|PETSCII TOKENS|ASCII TOKENS) / \[\% BRIGHT YELLOW \%\]$1\[\% RESET \%\] /g;

    $self->{'debug'}->DEBUG(['End SysOp List Commands']);
    return ($self->ansi_decode($text));
} ## end sub sysop_list_commands

sub sysop_online_count {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Online Count']);
    my $count = $self->{'CACHE'}->get('ONLINE');
    $self->{'debug'}->DEBUG(["  SysOp Online Count $count", 'End SysOp Online Count']);
    return ($count);
} ## end sub sysop_online_count

sub sysop_versions_format {
    my $self     = shift;
    my $sections = shift;
    my $bbs_only = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Versions Format']);
    my $versions = "\n";
    my $heading  = '';          #  = "\t";
    my $counter  = $sections;

    for (my $count = $sections - 1; $count > 0; $count--) {
        $heading .= ' NAME                         VERSION ';
        if ($count) {
            $heading .= "\t";
        } else {
            $heading .= "\n";
        }
    } ## end for (my $count = $sections...)
    $heading = '[% BRIGHT YELLOW %][% B_RED %]' . $heading . '[% RESET %]';
    foreach my $v (sort(keys %{ $self->{'VERSIONS'} })) {
        next if ($bbs_only && $v !~ /^BBS/);
        $versions .= sprintf(' %-28s  %.03f', $v, $self->{'VERSIONS'}->{$v});
        $counter--;
        if ($counter <= 1) {
            $counter = $sections;
            $versions .= "\n";
        } else {
            $versions .= "\t";
        }
    } ## end foreach my $v (sort(keys %{...}))
    chop($versions) if (substr($versions, -1, 1) eq "\t");
    $self->{'debug'}->DEBUG(['End SysOp Versions Format']);
    return ($heading . $versions . "\n");
} ## end sub sysop_versions_format

sub sysop_disk_free {    # Show the Disk Free portion of Statistics
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Disk Free']);
    my $diskfree = '';
    if ((-e '/usr/bin/duf' || -e '/usr/local/bin/duf') && $self->configuration('USE DUF') =~ /^(TRUE|YES|OM)$/) {
        my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
        $diskfree = `duf -theme ansi -width $wsize`;
    } else {
        my @free  = split(/\n/, `nice df -h -T`);    # Get human readable disk free showing type
        my $width = 1;
        foreach my $l (@free) {
            $width = max(length($l), $width);        # find the width of the widest line
        }
        foreach my $line (@free) {
            next if ($line =~ /tmp|boot/);
            if ($line =~ /^Filesystem/) {
                $diskfree .= '[% B_BLUE %][% BRIGHT YELLOW %]' . " $line " . ' ' x ($width - length($line)) . "[% RESET %]\n";    # Make the heading the right width
            } else {
                $diskfree .= " $line\n";
            }
        } ## end foreach my $line (@free)
    } ## end else [ if ((-e '/usr/bin/duf'...))]
    $self->{'debug'}->DEBUG(['End SysOp Disk Free']);
    return ($diskfree);
} ## end sub sysop_disk_free

sub sysop_load_menu {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Load Menu', "  SysOp Load Menu $file"]);
    my $mapping = { 'TEXT' => '' };
    my $mode    = 1;
    my $text    = locate($row, 1) . cldown;
    open(my $FILE, '<', $file);

    shift(@{ $self->{'sysop_menu_files'} });
    push(@{ $self->{'sysop_menu_files'} }, $file);
    for (my $count = 0; $count < 5; $count++) {
        if ($count == 4) {
            print locate(($count + 1), 108), colored(['green', 'on_black'], clline . $self->{'sysop_menu_files'}->[$count]);
        } else {
            print locate(($count + 1), 108), colored(['ansi22', 'on_black'], clline . $self->{'sysop_menu_files'}->[$count]);
        }
    } ## end for (my $count = 0; $count...)
    while (chomp(my $line = <$FILE>)) {
        next if ($line =~ /^\#/);
        if ($mode) {
            if ($line !~ /^---/) {
                my ($k, $cmd, $color, $t) = split(/\|/, $line);
                $k   = uc($k);
                $cmd = uc($cmd);
                $self->{'debug'}->DEBUGMAX([$k, $cmd, $color, $t]);
                $mapping->{$k} = {
                    'command' => $cmd,
                    'color'   => $color,
                    'text'    => $t,
                };
            } else {
                $mode = 0;
            }
        } else {
            $mapping->{'TEXT'} .= $self->sysop_detokenize($line) . "\n";
        }
    } ## end while (chomp(my $line = <$FILE>...))
    close($FILE);
    $self->{'debug'}->DEBUG(['End SysOp Load Menu']);
    return ($mapping);
} ## end sub sysop_load_menu

sub sysop_pager {
    my $self   = shift;
    my $text   = shift;
    my $offset = (scalar(@_)) ? shift : 0;

    $self->{'debug'}->DEBUG(['Start SysOp Pager']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my @lines;
    @lines = split(/\n$/, $text);
    my $size = ($hsize - ($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')));
    $size -= $offset;
    my $scroll = TRUE;
    my $count  = 1;

    while (scalar(@lines)) {
        my $line = shift(@lines);
        $self->sysop_output("$line\n");

        #        $self->sysop_ansi_output("$line\n");
        $count++;
        if ($count >= $size) {
            $count  = 1;
            $scroll = $self->sysop_scroll();
            last unless ($scroll);
        }
    } ## end while (scalar(@lines))
    $self->{'debug'}->DEBUG(['End SysOp Pager']);
    return ($scroll);
} ## end sub sysop_pager

sub sysop_parse_menu {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    my $row     = $self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST');
    my $animate = ($self->{'CONF'}->{'SYSOP ANIMATED MENU'}) ? TRUE : FALSE;
    $self->{'debug'}->DEBUG(['Start SysOp Parse Menu', "  SysOp Parse Menu $file"]);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown;
    my $scroll = $self->sysop_pager($mapping->{'TEXT'}, 3);
    my $keys   = '';
    print "\r", cldown unless ($scroll);
    $self->sysop_show_choices($mapping);
    $self->sysop_prompt('Choose');
    my $key;
    do {
        $key = uc($self->sysop_keypress($row, $animate));
        threads->yield();
    } until (exists($mapping->{$key}));
    print $mapping->{$key}->{'command'}, "\n";
    $self->{'debug'}->DEBUG(['End SysOp Parse Menu']);
    return ($mapping->{$key}->{'command'});
} ## end sub sysop_parse_menu

sub sysop_decision {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start SysOp Decision']);
    my $response;
    do {
        $response = uc($self->sysop_keypress());
    } until ($response =~ /Y|N/i || $response eq chr(13));
    if ($response eq 'Y') {
        print "YES\n";
        $self->{'debug'}->DEBUG(['  SysOp Decision YES']);
        $self->{'debug'}->DEBUG(['End SysOp Decision']);
        return (TRUE);
    } ## end if ($response eq 'Y')
    $self->{'debug'}->DEBUG(['  SysOp Decision NO']);
    print "NO\n";
    $self->{'debug'}->DEBUG(['End SysOp Decision']);
    return (FALSE);
} ## end sub sysop_decision

sub sysop_keypress {
    my $self = shift;
    my $row;
    my $animate = FALSE;
    if (scalar(@_)) {
        $row     = shift;
        $animate = shift;
    }

    my $key;
    do {
        $self->{'CACHE'}->set('SHOW_STATUS', FALSE);
        ReadMode 'ultra-raw';
        $key = ReadKey(0.25);
        ReadMode 'restore';
        $self->sysop_animate($row) if ($animate);
        threads->yield();
        $self->{'CACHE'}->set('SHOW_STATUS', TRUE);
    } until (defined($key));
    return ($key);
} ## end sub sysop_keypress

sub sysop_animate {
    my $self = shift;
    my $row  = shift;

    my @color = @{ $self->{'sysop_menu_colors'} };

    my $text = "\e[s" . "\e[1;91H\e[48;2;0;0;96m\e[93m " . $self->clock() . " \e[" . $row++ . ";1H\e[" . $color[0] . "m◥\e[" . ($color[0] + 10) . "m \e[0m\e[" . $color[0] . "m\e[7m◥\e[0m" . "\e[" . $row++ . ";2H\e[" . $color[1] . "m◥\e[" . ($color[1] + 10) . "m \e[0m\e[" . $color[1] . "m\e[7m◥\e[0m" . "\e[" . $row++ . ";3H\e[" . $color[2] . "m◥\e[" . ($color[2] + 10) . "m \e[0m\e[" . $color[2] . "m\e[7m◥\e[0m" . "\e[" . $row++ . ";3H\e[" . $color[3] . "m◢\e[" . ($color[3] + 10) . "m \e[0m\e[" . $color[3] . "m\e[7m◢\e[0m" . "\e[" . $row++ . ";2H\e[" . $color[4] . "m◢\e[" . ($color[4] + 10) . "m \e[0m\e[" . $color[4] . "m\e[7m◢\e[0m" . "\e[" . $row++ . ";1H\e[" . $color[5] . "m◢\e[" . ($color[5] + 10) . "m \e[0m\e[" . $color[5] . "m\e[7m◢\e[0m" . "\e[u";

    $self->{'CACHE'}->set('SHOW_STATUS', FALSE);
    print $text;
    $self->{'CACHE'}->set('SHOW_STATUS', TRUE);

    my $l = pop(@color);
    unshift(@color, $l);
    $self->{'sysop_menu_colors'} = \@color;
} ## end sub sysop_animate

sub sysop_ip_address {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp IP Address']);
    chomp(my $ip = `nice hostname -I`);
    $self->{'debug'}->DEBUG(["  SysOp IP Address:  $ip", 'End SysOp IP Address']);
    return ($ip);
} ## end sub sysop_ip_address

sub sysop_hostname {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Hostname']);
    chomp(my $hostname = `nice hostname`);
    $self->{'debug'}->DEBUG(["  SysOp Hostname:  $hostname", 'End SysOp Hostname']);
    return ($hostname);
} ## end sub sysop_hostname

sub sysop_locate_middle {
    my $self  = shift;
    my $color = (scalar(@_)) ? shift : 'B_WHITE';

    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $middle = int($wsize / 2);
    my $string;
    if ($color =~ /^B_/) {
        $string = "\r" . $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x $middle . $self->{'ansi_meta'}->{'background'}->{$color}->{'out'} . ' ' . $self->{'ansi_meta'}->{'attributes'}->{'RESET'}->{'out'};
    } else {
        $string = "\r" . $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x $middle . $self->{'ansi_meta'}->{'foreground'}->{$color}->{'out'} . ' ' . $self->{'ansi_meta'}->{'attributes'}->{'RESET'}->{'out'};
    }
    return ($string);
} ## end sub sysop_locate_middle

sub sysop_memory {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Memory']);
    my $memory = `nice free`;
    my @mem    = split(/\n$/, $memory);
    my $output = '[% BLACK %][% B_GREEN %]  ' . shift(@mem) . ' [% RESET %]' . "\n";
    while (scalar(@mem)) {
        $output .= shift(@mem) . "\n";
    }
    if ($output =~ /(Mem\:       )/) {
        my $ch = '[% BLACK %][% B_GREEN %] ' . $1 . ' [% RESET %]';
        $output =~ s/Mem\:       /$ch/;
    }
    if ($output =~ /(Swap\:      )/) {
        my $ch = '[% BLACK %][% B_GREEN %] ' . $1 . ' [% RESET %]';
        $output =~ s/Swap\:      /$ch/;
    }
    $self->{'debug'}->DEBUG(['End SysOp Memory']);
    return ($output);
} ## end sub sysop_memory

sub sysop_true_false {
    my $self    = shift;
    my $boolean = shift;
    my $mode    = shift;

    $boolean = $boolean + 0;
    if ($mode eq 'TF') {
        return (($boolean) ? 'TRUE' : 'FALSE');
    } elsif ($mode eq 'YN') {
        return (($boolean) ? 'YES' : 'NO');
	} elsif ($mode eq 'OO') {
		return(($boolean) ? 'ON' : 'OFF');
    }
    return ($boolean);
} ## end sub sysop_true_false

sub sysop_list_users {
    my $self      = shift;
    my $list_mode = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List Users']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $table;
    my $date_format = $self->configuration('DATE FORMAT');
    $date_format =~ s/YEAR/\%Y/;
    $date_format =~ s/MONTH/\%m/;
    $date_format =~ s/DAY/\%d/;
    my $name_width  = 15;
    my $value_width = $wsize - 22;
    my $sth;
    my @order;
    my $sql;

    if ($list_mode =~ /DETAILED/) {
        $sql   = q{ SELECT * FROM users_view };
        $sth   = $self->{'dbh'}->prepare($sql);
        @order = @{ $self->{'SYSOP ORDER DETAILED'} };
    } else {
        @order = @{ $self->{'SYSOP ORDER ABBREVIATED'} };
        $sql   = 'SELECT id,username,fullname,given,family,nickname,text_mode FROM users_view';
        $sth   = $self->{'dbh'}->prepare($sql);
    }
    $sth->execute();
    if ($list_mode =~ /VERTICAL/) {
        while (my $row = $sth->fetchrow_hashref()) {
            foreach my $name (@order) {
                next if ($name =~ /retro_systems|accomplishments/);
                if ($name ne 'id' && $row->{$name} =~ /^(0|1)$/) {
                    $row->{$name} = $self->sysop_true_false($row->{$name}, 'YN');
                }
                $value_width = max(length($row->{$name}), $value_width);
            } ## end foreach my $name (@order)
        } ## end while (my $row = $sth->fetchrow_hashref...)
        $sth->finish();
        $sth = $self->{'dbh'}->prepare($sql);
        $sth->execute();
        $table = Text::SimpleTable->new($name_width, $value_width);
        $table->row('NAME', 'VALUE');

        while (my $Row = $sth->fetchrow_hashref()) {
            $table->hr();
            foreach my $name (@order) {
                if ($name !~ /id|time/ && $Row->{$name} =~ /^(0|1)$/) {
                    $Row->{$name} = $self->sysop_true_false($Row->{$name}, 'YN');
                } elsif ($name eq 'timeout') {
                    $Row->{$name} = $Row->{$name} . ' Minutes';
                }
                $self->{'debug'}->DEBUGMAX([$name, $Row->{$name}]);
                $table->row($name . '', $Row->{$name} . '');
            } ## end foreach my $name (@order)
        } ## end while (my $Row = $sth->fetchrow_hashref...)
        $sth->finish();
        my $string = $table->thick('CYAN')->draw();
        my $ch     = colored(['bright_yellow'], 'NAME');
        $string =~ s/ NAME / $ch /;
        $ch = colored(['bright_yellow'], 'VALUE');
        $string =~ s/ VALUE / $ch /;
        $self->sysop_pager("$string\n");
    } else {    # Horizontal
        my @hw;
        foreach my $name (@order) {
            push(@hw, $self->{'SYSOP FIELD TYPES'}->{$name}->{'min'});
        }
        $table = Text::SimpleTable->new(@hw);
        if ($list_mode =~ /ABBREVIATED/) {
            $table->row(@order);
        } else {
            my @title = ();
            foreach my $heading (@order) {
                push(@title, $self->sysop_vertical_heading($heading));
            }
            $table->row(@title);
        } ## end else [ if ($list_mode =~ /ABBREVIATED/)]
        $table->hr();
        while (my $row = $sth->fetchrow_hashref()) {
            my @vals = ();
            foreach my $name (@order) {
                push(@vals, $row->{$name} . '');
                $self->{'debug'}->DEBUGMAX([$name, $row->{$name}]);
            }
            $table->row(@vals);
        } ## end while (my $row = $sth->fetchrow_hashref...)
        $sth->finish();
        my $string = $table->thick('CYAN')->draw();
        $self->sysop_pager("$string\n");
    } ## end else [ if ($list_mode =~ /VERTICAL/)]
    print 'Press a key to continue ... ';
    $self->{'debug'}->DEBUG(['End SysOp List Users']);
    return ($self->sysop_keypress());
} ## end sub sysop_list_users

sub sysop_delete_files { # Placeholder
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Delete Files']);
    $self->{'debug'}->DEBUG(['End SysOp Delete Files']);
    return (TRUE);
} ## end sub sysop_delete_files

sub sysop_list_files {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List Files']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=?');
    $sth->execute($self->{'USER'}->{'file_category'});
    my $sizes = {};
    while (my $row = $sth->fetchrow_hashref()) {
        foreach my $name (keys %{$row}) {
            if ($name eq 'file_size') {
                my $size = format_number($row->{$name});
                $sizes->{$name} = max(length($size), $sizes->{$name});
            } else {
                $sizes->{$name} = max(length($row->{$name}), $sizes->{$name});
            }
        } ## end foreach my $name (keys %{$row...})
    } ## end while (my $row = $sth->fetchrow_hashref...)
    $sth->finish();
    my $table;
    if ($wsize > 150) {
        $table = Text::SimpleTable->new(max(5, $sizes->{'title'}), max(8, $sizes->{'filename'}), max(4, $sizes->{'type'}), max(11, $sizes->{'description'}), max(8, $sizes->{'username'}), max(4, $sizes->{'file_size'}), max(8, $sizes->{'uploaded'}), max(9, $sizes->{'thumbs_up'}), max(11, $sizes->{'thumbs_down'}));
        $table->row('TITLE', 'FILENAME', 'TYPE', 'DESCRIPTION', 'UPLOADER', 'SIZE', 'UPLOADED', 'THUMBS UP', 'THUMBS DOWN');
    } else {
        $table = Text::SimpleTable->new(max(5, $sizes->{'filename'}), max(8, $sizes->{'title'}), max(4, $sizes->{'extension'}), max(11, $sizes->{'description'}), max(8, $sizes->{'username'}), max(4, $sizes->{'file_size'}), max(9, $sizes->{'thumbs_up'}), max(11, $sizes->{'thumbs_down'}));
        $table->row('TITLE', 'FILENAME', 'TYPE', 'DESCRIPTION', 'UPLOADER', 'SIZE', 'THUMBS UP', 'THUMBS DOWN');
    }
    $table->hr();
    $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=?');
    $sth->execute($self->{'USER'}->{'file_category'});
    my $category;

    while (my $row = $sth->fetchrow_hashref()) {
        if ($wsize > 150) {
            $table->row($row->{'title'}, $row->{'filename'}, $row->{'type'}, $row->{'description'}, $row->{'username'}, format_number($row->{'file_size'}), $row->{'uploaded'}, sprintf('%-06u', $row->{'thumbs_up'}), sprintf('%-06u', $row->{'thumbs_down'}));
        } else {
            $table->row($row->{'title'}, $row->{'filename'}, $row->{'extension'}, $row->{'description'}, $row->{'username'}, format_number($row->{'file_size'}), sprintf('%-06u', $row->{'thumbs_up'}), sprintf('%-06u', $row->{'thumbs_down'}));
        }
        $category = $row->{'category'};
    } ## end while (my $row = $sth->fetchrow_hashref...)
    $sth->finish();
    $self->sysop_output("\n" . '[% B_ORANGE %][% BLACK %] Current Category [% RESET %] [% BRIGHT YELLOW %][% BLACK RIGHT-POINTING TRIANGLE %][% RESET %] [% BRIGHT WHITE %][% FILE CATEGORY %][% RESET %]');
    my $tbl = $table->twin('YELLOW')->draw();
    while ($tbl =~ / (TITLE|FILENAME|TYPE|DESCRIPTION|UPLOADER|SIZE|UPLOADED|THUMBS UP|THUMBS DOWN) /) {
        my $ch  = $1;
        my $new = '[% BRIGHT GREEN %]' . $ch . '[% RESET %]';
        $tbl =~ s/ $ch / $new /gs;
    }
    $self->sysop_output("\n$tbl\nPress a Key To Continue ...");
    $self->sysop_keypress();
    print " BACK\n";
    $self->{'debug'}->DEBUG(['End SysOp List Files']);
    return (TRUE);
} ## end sub sysop_list_files

sub sysop_color_border {
    my ($self, $tbl, $color, $type) = @_;

    $self->{'debug'}->DEBUG(['Start SysOp Color Border']);
    $color = '[% ' . $color . ' %]';
    my $new;
    if ($tbl =~ /(─)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/─/\[\% BOX DRAWINGS DOUBLE HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/─/\[\% BOX DRAWINGS HEAVY HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(─)/)
    if ($tbl =~ /(│)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/│/\[\% BOX DRAWINGS DOUBLE VERTICAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/│/\[\% BOX DRAWINGS HEAVY VERTICAL \%\]/gs;
        }
        $new = '[% RESET %]' . $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(│)/)
    if ($tbl =~ /(┌)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/┌/\[\% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/┌/\[\% BOX DRAWINGS DOUBLE DOWN AND RIGHT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┌/\[\% BOX DRAWINGS HEAVY DOWN AND RIGHT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┌)/)
    if ($tbl =~ /(└)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/└/\[\% BOX DRAWINGS LIGHT ARC UP AND RIGHT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/└/\[\% BOX DRAWINGS DOUBLE UP AND RIGHT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/└/\[\% BOX DRAWINGS HEAVY UP AND RIGHT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(└)/)
    if ($tbl =~ /(┬)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┬/\[\% BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┬/\[\% BOX DRAWINGS HEAVY DOWN AND HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┬)/)
    if ($tbl =~ /(┐)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/┐/\[\% BOX DRAWINGS LIGHT ARC DOWN AND LEFT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/┐/\[\% BOX DRAWINGS DOUBLE DOWN AND LEFT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┐/\[\% BOX DRAWINGS HEAVY DOWN AND LEFT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┐)/)
    if ($tbl =~ /(├)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/├/\[\% BOX DRAWINGS DOUBLE VERTICAL AND RIGHT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/├/\[\% BOX DRAWINGS HEAVY VERTICAL AND RIGHT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(├)/)
    if ($tbl =~ /(┘)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/┘/\[\% BOX DRAWINGS LIGHT ARC UP AND LEFT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/┘/\[\% BOX DRAWINGS DOUBLE UP AND LEFT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┘/\[\% BOX DRAWINGS HEAVY UP AND LEFT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┘)/)
    if ($tbl =~ /(┼)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┼/\[\% BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┼/\[\% BOX DRAWINGS HEAVY VERTICAL AND HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┼)/)
    if ($tbl =~ /(┤)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┤/\[\% BOX DRAWINGS DOUBLE VERTICAL AND LEFT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┤/\[\% BOX DRAWINGS HEAVY VERTICAL AND LEFT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┤)/)
    if ($tbl =~ /(┴)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┴/\[\% BOX DRAWINGS DOUBLE UP AND HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┴/\[\% BOX DRAWINGS HEAVY UP AND HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┴)/)
    $self->{'debug'}->DEBUG(['End SysOp Color Border']);
    return ($tbl);
} ## end sub sysop_color_border

sub sysop_select_file_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Select File Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM file_categories');
    $sth->execute();
    my $table = Text::SimpleTable->new(3, 30, 50);
    $table->row('ID', 'TITLE', 'DESCRIPTION');
    $table->hr();
    my $max_id = 1;
    while (my $row = $sth->fetchrow_hashref()) {
        $table->row($row->{'id'}, $row->{'title'}, $row->{'description'});
        $max_id = $row->{'id'};
    }
    $sth->finish();
    my $text = $table->twin('MAGENTA')->draw();
    while ($text =~ / (ID|TITLE|DESCRIPTION) /) {
        my $ch  = $1;
        my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
        $text =~ s/ $ch / $new /gs;
    }
    $self->sysop_output($text . "\n");
    $self->sysop_prompt('Choose ID (< = Nevermind)');
    my $line;
    do {
        $line = uc($self->sysop_get_line(ECHO, 3, ''));
    } until ($line =~ /^(\d+|\<)/i);
    my $response = FALSE;
    if ($line >= 1 && $line <= $max_id) {
        $sth = $self->{'dbh'}->prepare('UPDATE users SET file_category=? WHERE id=1');
        $sth->execute($line);
        $sth->finish();
        $self->{'USER'}->{'file_category'} = $line + 0;
        $response = TRUE;
    } ## end if ($line >= 1 && $line...)
    $self->{'debug'}->DEBUG(['End SysOp Select File Category']);
    return ($response);
} ## end sub sysop_select_file_category

sub sysop_edit_file_categories {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Edit File Categories']);
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM file_categories');
    $sth->execute();
    my $table = Text::SimpleTable->new(3, 30, 50);
    $table->row('ID', 'TITLE', 'DESCRIPTION');
    $table->hr();
    while (my $row = $sth->fetchrow_hashref()) {
        $table->row($row->{'id'}, $row->{'title'}, $row->{'description'});
    }
    $sth->finish();
    my $text = $table->boxes->draw();
    while ($text =~ / (ID|TITLE|DESCRIPTION) /) {
        my $ch  = $1;
        my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
        $text =~ s/ $ch / $new /gs;
    }
    $self->sysop_output("$text\n");
    $self->sysop_prompt('Choose ID (A = Add, < = Nevermind)');
    my $line;
    do {
        $line = uc($self->sysop_get_line(ECHO, 3, ''));
    } until ($line =~ /^(\d+|A|\<)/i);
    if ($line eq 'A') {    # Add
        $self->{'debug'}->DEBUG(['  SysOp Edit File Categories Add']);
        print "\nADD NEW FILE CATEGORY\n";
        $table = Text::SimpleTable->new(11, 80);
        $table->row('TITLE',       "\n" . charnames::string_vianame('OVERLINE') x 80);
        $table->row('DESCRIPTION', "\n" . charnames::string_vianame('OVERLINE') x 80);
        my $text = $table->twin('MAGENTA')->draw();
        while ($text =~ / (TITLE|DESCRIPTION) /) {
            my $ch  = $1;
            my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
            $text =~ s/ $ch / $new /gs;
        }
        $self->sysop_output("\n$text");
        print $self->{'ansi_meta'}->{'cursor'}->{'UP'}->{'out'} x 5, $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 16;
        my $title = $self->sysop_get_line(ECHO, 80, '');
        if ($title ne '') {
            print "\r", $self->{'ansi_meta'}->{'cursor'}->{'DOWN'}->{'out'}, $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 16;
            my $description = $self->sysop_get_line(ECHO, 80, '');
            if ($description ne '') {
                $sth = $self->{'dbh'}->prepare('INSERT INTO file_categories (title,description) VALUES (?,?)');
                $sth->execute($title, $description);
                $sth->finish();
                print "\n\nNew Entry Added\n";
            } else {
                print "\n\nNevermind\n";
            }
        } else {
            print "\n\n\nNevermind\n";
        }
    } elsif ($line =~ /\d+/) {    # Edit
        $self->{'debug'}->DEBUG(['  SysOp Edit File Categories Edit']);
    }
    $self->{'debug'}->DEBUG(['Start SysOp Edit File Categories']);
    return (TRUE);
} ## end sub sysop_edit_file_categories

sub sysop_vertical_heading {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Vertical Heading']);
    my $heading = '';
    for (my $count = 0; $count < length($text); $count++) {
        $heading .= substr($text, $count, 1) . "\n";
    }
    $self->{'debug'}->DEBUG(['End SysOp Vertical Heading']);
    return ($heading);
} ## end sub sysop_vertical_heading

sub sysop_view_configuration {
    my $self = shift;
    my $view = shift;

    $self->{'debug'}->DEBUG(['Start SysOp View Configuration']);

    # Get maximum widths
    my $name_width  = 6;
    my $value_width = 80;
    foreach my $cnf (keys %{ $self->configuration() }) {
        if ($cnf eq 'STATIC') {
            foreach my $static (keys %{ $self->{'CONF'}->{$cnf} }) {
                $name_width  = max(length($static),                            $name_width);
                $value_width = max(length($self->{'CONF'}->{$cnf}->{$static}), $value_width);
            }
        } else {
            $name_width  = max(length($cnf),                    $name_width);
            $value_width = max(length($self->{'CONF'}->{$cnf}), $value_width);
        }
    } ## end foreach my $cnf (keys %{ $self...})

    # Assemble table
    my $table = ($view) ? Text::SimpleTable->new($name_width, $value_width) : Text::SimpleTable->new(6, $name_width, $value_width);
    if ($view) {
        $table->row('STATIC NAME', 'STATIC VALUE');
        $table->hr();
    }
    foreach my $conf (sort(keys %{ $self->{'CONF'}->{'STATIC'} })) {
        next if ($conf eq 'DATABASE PASSWORD');
        if ($view) {
            $table->row($conf, $self->{'CONF'}->{'STATIC'}->{$conf});
        }
    } ## end foreach my $conf (sort(keys...))
    if ($view) {
        $table->hr();
        $table->row('CONFIG NAME', 'CONFIG VALUE');
    } else {
        $table->row('CHOICE', 'CONFIG NAME', 'CONFIG VALUE');
    }
    $table->hr();
    my $count = 0;
    foreach my $conf (sort(keys %{ $self->{'CONF'} })) {
        my $choice = chr(65 + $count);
        next if ($conf eq 'STATIC');
        my $c = $self->{'CONF'}->{$conf};
        if ($conf eq 'DEFAULT TIMEOUT') {
            $c .= ' Minutes';
        } elsif ($conf eq 'DEFAULT BAUD RATE') {
            $c .= ' bps - 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, FULL';
        } elsif ($conf eq 'THREAD MULTIPLIER') {
            $c .= ' x CPU Cores';
        } elsif ($conf eq 'DEFAULT TEXT MODE') {
            $c .= ' - ANSI, ASCII, ATASCII, PETSCII';
        }
        if ($view) {
            $table->row($conf, $c);
        } else {
            if ($conf =~ /AUTHOR/) {
                $table->row(' ', $conf, $c);
            } else {
                $table->row($choice, $conf, $c);
                $count++;
            }
        } ## end else [ if ($view) ]
    } ## end foreach my $conf (sort(keys...))
    my $output = $table->thick('RED')->draw();
    foreach my $change ('AUTHOR EMAIL', 'AUTHOR LOCATION', 'AUTHOR NAME', 'DATABASE USERNAME', 'DATABASE NAME', 'DATABASE PORT', 'DATABASE TYPE', 'DATBASE USERNAME', 'DATABASE HOSTNAME', '300, 600, 1200, 2400, 4800, 9600, 19200, FULL', '%d = day, %m = Month, %Y = Year', 'ANSI, ASCII, ATASCII, PETSCII', 'ANSI, ASCII, ATAASCII,PETSCII') {
        if ($output =~ /$change/) {
            my $ch;
            if (/^(AUTHOR|DATABASE)/) {
                $ch = '[% YELLOW %]' . $change . '[% RESET %]';
            } else {
                $ch = '[% GRAY 11 %]' . $change . '[% RESET %]';
            }
            $output =~ s/$change/$ch/gs;
        } ## end if ($output =~ /$change/)
    } ## end foreach my $change ('AUTHOR EMAIL'...)
    {
        my $ch = colored(['cyan'], 'CHOICE');
        $output =~ s/CHOICE/$ch/gs;
        $ch = colored(['bright_yellow'], 'STATIC NAME');
        $output =~ s/STATIC NAME/$ch/gs;
        $ch = colored(['bright_yellow'], 'STATIC VALUE');
        $output =~ s/STATIC VALUE/$ch/gs;
        $ch = colored(['green'], 'CONFIG NAME');
        $output =~ s/CONFIG NAME/$ch/gs;
        $ch = colored(['cyan'], 'CONFIG VALUE');
        $output =~ s/CONFIG VALUE/$ch/gs;
        $ch = colored(['green'], 'TRUE');
        $output =~ s/TRUE/$ch/gs;
        $ch = colored(['red'], 'FALSE');
        $output =~ s/FALSE/$ch/gs;
        $ch = colored(['green'], 'ON');
        $output =~ s/ ON / $ch /gs;
        $ch = colored(['red'], 'OFF');
        $output =~ s/ OFF / $ch /gs;
        $ch = colored(['green'], 'YES');
        $output =~ s/YES/$ch/gs;
        $ch = colored(['red'], 'NO');
        $output =~ s/ NO / $ch /gs;
    }
    my $response;
    if ("$view" eq 'string') {
        $response = $output;
    } elsif ($view == TRUE) {
        print $self->sysop_detokenize($output);
        print 'Press a key to continue ... ';
        $response = $self->sysop_keypress();
    } elsif ($view == FALSE) {
        print $self->sysop_detokenize($output);
        print $self->sysop_menu_choice('TOP',    '',    '');
        print $self->sysop_menu_choice('Z',      'RED', 'Return to Settings Menu');
        print $self->sysop_menu_choice('BOTTOM', '',    '');
        $self->sysop_prompt('Choose');
        $response = TRUE;
    } ## end elsif ($view == FALSE)
    $self->{'debug'}->DEBUG(['End SysOp View Configuration']);
    return ($response);
} ## end sub sysop_view_configuration

sub sysop_edit_configuration {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Edit Configuration']);
    $self->sysop_view_configuration(FALSE);
    my $types = {
        'BBS NAME'            => { 'max' => 50, 'type' => STRING, },
        'BBS ROOT'            => { 'max' => 60, 'type' => STRING, },
        'HOST'                => { 'max' => 20, 'type' => HOST, },
        'THREAD MULTIPLIER'   => { 'max' => 2,  'type' => NUMERIC, },
        'PORT'                => { 'max' => 5,  'type' => NUMERIC, },
        'DEFAULT BAUD RATE'   => { 'max' => 5,  'type' => RADIO, 'choices' => ['300', '600', '1200', '2400', '4800', '9600', '19200', '38400', '57600', '115200', 'FULL'], },
        'DEFAULT TEXT MODE'   => { 'max' => 7,  'type' => RADIO, 'choices' => ['ANSI', 'ASCII', 'ATASCII', 'PETSCII'], },
        'DEFAULT TIMEOUT'     => { 'max' => 3,  'type' => NUMERIC, },
        'FILES PATH'          => { 'max' => 60, 'type' => STRING, },
        'LOGIN TRIES'         => { 'max' => 1,  'type' => NUMERIC, },
        'MEMCACHED HOST'      => { 'max' => 20, 'type' => HOST, },
        'MEMCACHED NAMESPACE' => { 'max' => 32, 'type' => STRING, },
        'MEMCACHED PORT'      => { 'max' => 5,  'type' => NUMERIC, },
        'DATE FORMAT'         => { 'max' => 14, 'type' => RADIO,   'choices' => ['MONTH/DAY/YEAR', 'DAY/MONTH/YEAR', 'YEAR/MONTH/DAY',], },
        'SYSOP ANIMATED MENU' => { 'max' => 5,  'type' => BOOLEAN, 'choices' => ['ON', 'OFF'], },
        'USE DUF'             => { 'max' => 5,  'type' => BOOLEAN, 'choices' => ['ON', 'OFF'], },
        'PLAY SYSOP SOUNDS'   => { 'max' => 5,  'type' => BOOLEAN, 'choices' => ['ON', 'OFF'], },
    };
    my $choice;
    do {
        $choice = uc($self->sysop_keypress());
    } until ($choice =~ /[A-R]|Z/i);
    if ($choice =~ /Z/i) {
        print "BACK\n";
        return (FALSE);
    }

    $choice = ("$choice" =~ /[A-Y]/i) ? $choice = (ord($choice) - 65) : $choice;
    my @conf = grep(!/STATIC|AUTHOR/, sort(keys %{ $self->{'CONF'} }));
    if ($types->{ $conf[$choice] }->{'type'} == RADIO || $types->{ $conf[$choice] }->{'type'} == BOOLEAN) {
        print '(Edit) ', $conf[$choice], ' (' . join(' ', @{ $types->{ $conf[$choice] }->{'choices'} }) . ') ', charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE'), '  ';
    } else {
        print '(Edit) ', $conf[$choice], ' ', charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE'), '  ';
    }
    my $string;
    $self->{'debug'}->DEBUGMAX([$self->configuration()]);
    $string = $self->sysop_get_line($types->{ $conf[$choice] }, $self->configuration($conf[$choice]));
    my $response = TRUE;
    if ($string eq '') {
        $response = FALSE;
    } else {
        $self->configuration($conf[$choice], $string);
    }
    $self->{'debug'}->DEBUG(['End SysOp Edit Configuration']);
    return ($response);
} ## end sub sysop_edit_configuration

sub sysop_get_key {
    my $self     = shift;
    my $echo     = shift;
    my $blocking = shift;

    my $key     = undef;
    my $mode    = $self->{'USER'}->{'text_mode'};
    my $timeout = $self->{'USER'}->{'timeout'} * 60;
    local $/ = "\x{00}";
    ReadMode 'ultra-raw';
    $key = ($blocking) ? ReadKey($timeout) : ReadKey(-1);
    ReadMode 'restore';
    threads->yield;
    return ($key) if ($key eq chr(13));

    if ($key eq chr(127)) {
        $key = $self->{'ansi_meta'}->{'cursor'}->{'BACKSPACE'}->{'out'};
    }
    if ($echo == NUMERIC && defined($key)) {
        unless ($key =~ /[0-9]/) {
            $key = '';
        }
    }
    threads->yield;
    return ($key);
} ## end sub sysop_get_key

sub sysop_get_line {
    my $self = shift;
    my $echo = shift;
    my $type = $echo;

    my $line;
    my $limit;
    my $choices;
    my $key;

    $self->{'CACHE'}->set('SHOW_STATUS', FALSE);
    $self->{'debug'}->DEBUG(['Start SysOp Get Line']);
    $self->flush_input();

    if (ref($type) eq 'HASH') {
        $limit = $type->{'max'};
        if (exists($type->{'choices'})) {
            $choices = $type->{'choices'};
            if (exists($type->{'default'})) {
                $line = $type->{'default'};
            } else {
                $line = shift;
            }
        } ## end if (exists($type->{'choices'...}))
        $echo = $type->{'type'};
    } else {
        if ($echo == STRING || $echo == ECHO || $echo == NUMERIC || $echo == HOST) {
            $limit = shift;
        }
        $line = shift;
    } ## end else [ if (ref($type) eq 'HASH')]
    chomp($line);
    $self->{'debug'}->DEBUGMAX([$type, $echo, $line]);
    print $line if ($line ne '');
    my $mode = 'ANSI';
    my $bs   = $self->{'ansi_meta'}->{'cursor'}->{'BACKSPACE'}->{'out'};
    if ($echo == RADIO) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line RADIO']);

        my $mapping;
        my @menu_choices = @{$self->{'MENU CHOICES'}};

        foreach my $choice (@{$choices}) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $choice,
                'color'        => 'WHITE',
                'access_level' => 'USER',
                'text'         => $choice,
            }
        }
        print "\n";
        $self->sysop_show_choices($mapping);
        $self->sysop_prompt('Choose');
        my $key;
        do {
            $key = uc($self->sysop_get_key(SILENT, BLOCKING));
        } until (exists($mapping->{$key}) || $key eq chr(3));
        if ($key eq chr(3)) {
            $line = '';
        } else {
            $line = $mapping->{$key}->{'command'};
        }
    } elsif ($echo == BOOLEAN) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line BOOLEAN']);
        do {
            $key = $self->sysop_get_key(SILENT, BLOCKING);
            if (uc($key) eq 'T') {
                $line = 'ON';
                print $self->{'ansi_meta'}->{'cursor'}->{'LEFT'}->{'out'} x 5, 'ON', clline;
            } elsif (uc($key) eq 'F') {
                $line = 'OFF';
                print $self->{'ansi_meta'}->{'cursor'}->{'LEFT'}->{'out'} x 4, 'OFF', clline;
            } elsif ($key ne chr(13) && $key ne chr(3)) {
                print chr(7);
            }
        } until ($key eq chr(13) or $key eq chr(3));
    } elsif ($echo == NUMERIC) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line NUMERIC']);
        while ($key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->sysop_get_key(NUMERIC, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $bs || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            print "$key $key";
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[0-9]/) {
                        print $key;
                        $line .= $key;
                    } else {
                        print chr(7);
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $bs || $key eq chr(127))) {
                    $key = $bs;
                    print "$key $key";
                    chop($line);
                } else {
                    print chr(7);
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while ($key ne chr(13) &&...)
    } elsif ($echo == HOST) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line HOST']);
        while ($key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $bs || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->sysop_output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[a-z]|[0-9]|\./) {
                        print lc($key);
                        $line .= lc($key);
                    } else {
                        print chr(7);
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $bs || $key eq chr(127))) {
                    $key = $bs;
                    print "$key $key";
                    chop($line);
                } else {
                    print chr(7);
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while ($key ne chr(13) &&...)
    } else {
        $self->{'debug'}->DEBUG(['  SysOp Get Line NORMAL']);
        while ($key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $bs) {
                        my $len = length($line);
                        if ($len > 0) {
                            print "$key $key";
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && ord($key) > 31 && ord($key) < 127) {
                        print $key;
                        $line .= $key;
                    } else {
                        print chr(7);
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $bs)) {
                    $key = $bs;
                    print "$key $key";
                    chop($line);
                } else {
                    print chr(7);
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while ($key ne chr(13) &&...)
    } ## end else [ if ($echo == RADIO) ]
    threads->yield();
    $line = '' if ($key eq chr(3));
    print "\n";
    $self->{'CACHE'}->set('SHOW_STATUS', TRUE);
    $self->{'debug'}->DEBUG(['End SysOp Get Line']);
    return ($line);
} ## end sub sysop_get_line

sub sysop_user_delete {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Delete']);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    delete($mapping->{'TEXT'});
    my ($key_exit) = (keys %{$mapping});
    my $key;
    $self->sysop_prompt('Please enter the username or account number');
    my $search = $self->sysop_get_line(ECHO, 20, '');
    return (FALSE) if ($search eq '' || $search eq 'sysop' || $search eq '1');
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE id=? OR username=?');
    $sth->execute($search, $search);
    my $user_row = $sth->fetchrow_hashref();
    $sth->finish();

    if (defined($user_row)) {
        my $table = Text::SimpleTable->new(16, 60);
        $table->row('FIELD', 'VALUE');
        $table->hr();
        foreach my $field (@{ $self->{'SYSOP ORDER DETAILED'} }) {
            if ($field ne 'id' && $user_row->{$field} =~ /^(0|1)$/) {
                $user_row->{$field} = $self->sysop_true_false($user_row->{$field}, 'YN');
            } elsif ($field eq 'timeout') {
                $user_row->{$field} = $user_row->{$field} . ' Minutes';
            }
            $table->row($field, $user_row->{$field} . '');
        } ## end foreach my $field (@{ $self...})
        if ($self->sysop_pager($table->thick('RED')->draw())) {
            print "Are you sure that you want to delete this user (Y|N)?  ";
            my $answer = $self->sysop_decision();
            if ($answer) {
                print "\n\nDeleting ", $user_row->{'username'}, " ... ";
                $sth = $self->users_delete($user_row->{'id'});
            }
        } ## end if ($self->sysop_pager...)
    } ## end if (defined($user_row))
    $self->{'debug'}->DEBUG(['End SysOp User Delete']);
} ## end sub sysop_user_delete

sub sysop_user_edit {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Edit']);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    delete($mapping->{'TEXT'});
    my ($key_exit) = (keys %{$mapping});
    my @choices = qw( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y );
    my $key;
    $self->sysop_prompt('Please enter the username or account number');
    my $search = $self->sysop_get_line(ECHO, 20, '');
    return (FALSE) if ($search eq '');
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE id=? OR username=?');
    $sth->execute($search, $search);
    my $user_row = $sth->fetchrow_hashref();
    $sth->finish();

    if (defined($user_row)) {
        my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
        do {
            my $valsize = 1;
            foreach my $fld (keys %{$user_row}) {
                $valsize = max($valsize, length($user_row->{$fld}));
            }
            $valsize = min($valsize, $wsize - 29);
            my $table = Text::SimpleTable->new(6, 16, $valsize);
            $table->row('CHOICE', 'FIELD', 'VALUE');
            $table->hr();
            my $count = 0;
            my %choice;
            foreach my $field (@{ $self->{'SYSOP ORDER DETAILED'} }) {
                if ($field =~ /_time|fullname|_category|id/) {
                    $table->row(' ', uc($field), $user_row->{$field} . '');
                } else {
                    if ($user_row->{$field} =~ /^(0|1)$/) {
                        $table->row($choices[$count], uc($field), $self->sysop_true_false($user_row->{$field}, 'YN'));
                    } elsif ($field eq 'access_level') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - USER, VETERAN, JUNIOR SYSOP, SYSOP');
                    } elsif ($field eq 'date_format') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - YEAR/MONTH/DAY, MONTH/DAY/YEAR, DAY/MONTH/YEAR');
                    } elsif ($field eq 'baud_rate') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, FULL');
                    } elsif ($field eq 'text_mode') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - ASCII, ANSI, ATASCII, PETSCII');
                    } elsif ($field eq 'timeout') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - Minutes');
                    } else {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . '');
                    }
                    $count++ if ($key_exit eq $choices[$count]);
                    $choice{ $choices[$count] } = $field;
                    $count++;
                } ## end else [ if ($field =~ /_time|fullname|_category|id/)]
            } ## end foreach my $field (@{ $self...})
            my $tbl = $table->round('BRIGHT CYAN')->draw();
            while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /) {
                my $ch = $1;
                my $new;
                if ($ch =~ /Yes/) {
                    $new = '[% GREEN %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /No/) {
                    $new = '[% RED %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /CHOICE|FIELD|VALUE/) {
                    $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                } else {
                    $new = '[% RGB 50,50,150 %]' . $ch . '[% RESET %]';
                }
                $tbl =~ s/$ch/$new/g;
            } ## end while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /)
            $self->sysop_output('[% CLS %]' . $tbl . "\n");
            $self->sysop_show_choices($mapping);
            $self->sysop_prompt('Choose');
            do {
                $key = uc($self->sysop_keypress());
            } until ('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ' =~ /$key/i);
            if ($key !~ /$key_exit/i) {
                print 'Edit > (', $choice{$key}, ' = ', $user_row->{ $choice{$key} }, ') > ';
                if ($choice{$key} =~ /^(play_fortunes|prefer_nickname|view_files|upload_files|download_files|remove_files|read_message|post_message|remove_message|sysop)$/) {
                    $user_row->{ $choice{$key} } = ($user_row->{ $choice{$key} } == 1) ? 0 : 1;
                    my $sth = $self->{'dbh'}->prepare('UPDATE permissions SET ' . $choice{$key} . '= !' . $choice{$key} . '  WHERE id=?');
                    $sth->execute($user_row->{'id'});
                    $sth->finish();
                } elsif($choice{$key} =~ /text_mode/) {
                    my $new = $self->sysop_get_line($self->{'SYSOP FIELD TYPES'}->{ $choice{$key} }, $user_row->{ $choice{$key} });
                    $user_row->{ $choice{$key} } = $new;
                    my $sth = $self->{'dbh'}->prepare('UPDATE users SET ' . $choice{$key} . '=? WHERE id=?');
                    $sth->execute($new, $self->{'text_modes'}->{$user_row->{'id'}});
                    $sth->finish();
                } else {
                    my $new = $self->sysop_get_line($self->{'SYSOP FIELD TYPES'}->{ $choice{$key} }, $user_row->{ $choice{$key} });
                    $user_row->{ $choice{$key} } = $new;
                    my $sth = $self->{'dbh'}->prepare('UPDATE users SET ' . $choice{$key} . '=? WHERE id=?');
                    $sth->execute($new, $user_row->{'id'});
                    $sth->finish();
                } ## end else [ if ($choice{$key} =~ /^(prefer_nickname|view_files|upload_files|download_files|remove_files|read_message|post_message|remove_message|sysop)$/)]
            } else {
                print "BACK\n";
            }
        } until ($key =~ /$key_exit/i);
    } elsif ($search ne '') {
        print "User not found!\n\n";
    }
    $self->{'debug'}->DEBUG(['End SysOp User Edit']);
    return (TRUE);
} ## end sub sysop_user_edit

sub sysop_new_user_edit {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Edit']);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    delete($mapping->{'TEXT'});
    my ($key_exit) = (keys %{$mapping});
    my @choices = qw( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y );
    my $key;
    my @responses;
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE access_level=?');
    $sth->execute('USER');
    my $user_row;

    while ($user_row = $sth->fetchrow_hashref()) {
        push(@responses, $user_row);
    }
    $sth->finish();

    $self->{'debug'}->DEBUGMAX(\@responses);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    while ($user_row = pop(@responses)) {
        do {
            my $valsize = 1;
            foreach my $fld (keys %{$user_row}) {
                $valsize = max($valsize, length($user_row->{$fld}));
            }
            $valsize = min($valsize, $wsize - 29);
            my $table = Text::SimpleTable->new(6, 16, $valsize);
            $table->row('CHOICE', 'FIELD', 'VALUE');
            $table->hr();
            my $count = 0;
            my %choice;
            foreach my $field (@{ $self->{'SYSOP ORDER DETAILED'} }) {
                if ($field =~ /_time|fullname|_category|id/) {
                    $table->row(' ', $field, $user_row->{$field} . '');
                } else {
                    if ($user_row->{$field} =~ /^(0|1)$/) {
                        $table->row($choices[$count], $field, $self->sysop_true_false($user_row->{$field}, 'YN'));
                    } elsif ($field eq 'access_level') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - USER, VETERAN, JUNIOR SYSOP, SYSOP');
                    } elsif ($field eq 'date_format') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - YEAR/MONTH/DAY, MONTH/DAY/YEAR, DAY/MONTH/YEAR');
                    } elsif ($field eq 'baud_rate') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - 300, 600, 1200, 2400, 4800, 9600, 19200, FULL');
                    } elsif ($field eq 'text_mode') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - ASCII, ANSI, ATASCII, PETSCII');
                    } elsif ($field eq 'timeout') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - Minutes');
                    } else {
                        $table->row($choices[$count], $field, $user_row->{$field} . '');
                    }
                    $count++ if ($key_exit eq $choices[$count]);
                    $choice{ $choices[$count] } = $field;
                    $count++;
                } ## end else [ if ($field =~ /_time|fullname|_category|id/)]
            } ## end foreach my $field (@{ $self...})
            my $tbl = $table->round('BRIGHT CYAN')->draw();
            while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /) {
                my $ch = $1;
                my $new;
                if ($ch =~ /Yes/) {
                    $new = '[% GREEN %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /No/) {
                    $new = '[% RED %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /CHOICE|FIELD|VALUE/) {
                    $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                } else {
                    $new = '[% RGB 50,50,150 %]' . $ch . '[% RESET %]';
                }
                $tbl =~ s/$ch/$new/g;
            } ## end while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /)
            $self->sysop_output('[% CLS %]' . $tbl . "\n");
            $self->sysop_show_choices($mapping);
            $self->sysop_prompt('Choose');
            do {
                $key = uc($self->sysop_keypress());
            } until ('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ' =~ /$key/i);
            if ($key !~ /$key_exit/i) {
                print 'Edit > (', $choice{$key}, ' = ', $user_row->{ $choice{$key} }, ') > ';
                my $new = $self->sysop_get_line(ECHO, 1 + $self->{'SYSOP FIELD TYPES'}->{ $choice{$key} }->{'max'}, $user_row->{ $choice{$key} });
                unless ($new eq '') {
                    $new =~ s/^(Yes|On)$/1/i;
                    $new =~ s/^(No|Off)$/0/i;
                }
                $user_row->{ $choice{$key} } = $new;
                if ($key =~ /prefer_nickname|view_files|upload_files|download_files|remove_files|read_message|post_message|remove_message|sysop/) {
                    my $sth = $self->{'dbh'}->prepare('UPDATE permissions SET ' . choice { $key } . '=? WHERE id=?');
                    $sth->execute($new, $user_row->{'id'});
                    $sth->finish();
                } else {
                    my $sth = $self->{'dbh'}->prepare('UPDATE users SET ' . $choice{$key} . '=? WHERE id=?');
                    $sth->execute($new, $user_row->{'id'});
                    $sth->finish();
                }
            } else {
                print "BACK\n";
            }
        } until ($key =~ /$key_exit/i);
    } ## end while ($user_row = pop(@responses...))
    $self->{'debug'}->DEBUG(['End SysOp User Edit']);
    return (TRUE);
} ## end sub sysop_new_user_edit

sub sysop_user_add {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Add']);
    my $flags_default = $self->{'flags_default'};
    my $mapping       = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    my $table = Text::SimpleTable->new(15, 150);
    my $user_template;
    my @tmp = grep(!/id|banned|fullname|_time|max_|_category/, @{ $self->{'SYSOP ORDER DETAILED'} });
    push(@tmp, 'password');

    foreach my $name (@tmp) {
        my $size = max(3, $self->{'SYSOP FIELD TYPES'}->{$name}->{'max'});
        if ($name eq 'timeout') {
            $table->row($name, '_' x $size . ' - Minutes');
        } elsif ($name eq 'baud_rate') {
            $table->row($name, '_' x $size . ' - 300 or 600 or 1200 or 2400 or 4800 or 9600 or 19200 or FULL');
        } elsif ($name =~ /username|given|family|password/) {
            if ($name eq 'given') {
                $table->row("$name (first)", '_' x $size . ' - Cannot be empty');
            } elsif ($name eq 'family') {
                $table->row("$name (last)", '_' x $size . ' - Cannot be empty');
            } else {
                $table->row($name, '_' x $size . ' - Cannot be empty');
            }
        } elsif ($name eq 'date_format') {
            $table->row($name, '_' x $size . ' - YEAR/MONTH/DAY or MONTH/DAY/YEAR or DAY/MONTH/YEAR');
        } elsif ($name eq 'access_level') {
            $table->row($name, '_' x $size . ' - USER or VETERAN or JUNIOR SYSOP or SYSOP');
        } elsif ($name eq 'text_mode') {
            $table->row($name, '_' x $size . ' - ANSI or ASCII or ATASCII or PETSCII');
        } elsif ($name eq 'birthday') {
            $table->row($name, '_' x $size . ' - YEAR-MM-DD');
        } elsif ($name =~ /(prefer_nickname|_files|_message|sysop|fortunes)/) {
            $table->row($name, '_' x $size . ' - Yes/No or True/False or On/Off or 1/0');
        } elsif ($name =~ /location|retro_systems|accomplishments/) {
            $table->row($name, '_' x ($self->{'SYSOP FIELD TYPES'}->{$name}->{'max'}));
        } else {
            $table->row($name, '_' x $size);
        }
        $user_template->{$name} = undef;
    } ## end foreach my $name (@tmp)
    my $string = $table->boxes->draw();
    while ($string =~ / (Cannot be empty|YEAR.MM.DD|USER or VETERAN or JUNIOR SYSOP or SYSOP|YEAR.MONTH.DAY or MONTH.DAY.YEAR or DAY.MONTH.YEAR|300 or 600 or 1200 or 2400 or 4800 or 9600 or 19200 or FULL|ANSI or ASCII or ATASCII or PETSCII|Minutes|Yes.No or True.False or On.Off or 1.0) /) {
        my $ch  = $1;
        my $new = '[% RGB 50,50,150 %]' . $ch . '[% RESET %]';
        $string =~ s/$ch/$new/gs;
    }
    $self->sysop_output($self->sysop_color_border($string, 'PINK', 'DEFAULT'));
    $self->sysop_show_choices($mapping);
    my $column     = 21;
    my $adjustment = $self->{'CACHE'}->get('START_ROW') - 1;
    foreach my $entry (@tmp) {
        do {
            print locate($row + $adjustment, $column), '_' x max(3, $self->{'SYSOP FIELD TYPES'}->{$entry}->{'max'}), locate($row + $adjustment, $column);
            chomp($user_template->{$entry} = $self->sysop_get_line($self->{'SYSOP FIELD TYPES'}->{$entry}));
            return ('BACK') if ($user_template->{$entry} eq '<' || $user_template->{$entry} eq chr(3));
            if ($entry =~ /text_mode|baud_rate|timeout|given|family/) {
                if ($user_template->{$entry} eq '') {
                    if ($entry eq 'text_mode') {
                        $user_template->{$entry} = 'ASCII';
                    } elsif ($entry eq 'baud_rate') {
                        $user_template->{$entry} = 'FULL';
                    } elsif ($entry eq 'timeout') {
                        $user_template->{$entry} = $self->{'CONF'}->{'DEFAULT TIMEOUT'};
                    } elsif ($entry =~ /prefer|_files|_message|sysop|_fortunes/) {
                        $user_template->{$entry} = $flags_default->{$entry};
                    } else {
                        $user_template->{$entry} = uc($user_template->{$entry});
                    }
                } elsif ($entry =~ /given|family/) {
                    my $ucuser = uc($user_template->{$entry});
                    if ($ucuser eq $user_template->{$entry}) {
                        $user_template->{$entry} = ucfirst(lc($user_template->{$entry}));
                    } else {
                        substr($user_template->{$entry}, 0, 1) = uc(substr($user_template->{$entry}, 0, 1));
                    }
                } ## end elsif ($entry =~ /given|family/)
                print locate($row + $adjustment, $column), $user_template->{$entry};
            } elsif ($entry =~ /prefer_|_files|_message|sysop|_fortunes/) {
                $user_template->{$entry} = uc($user_template->{$entry});
                print locate($row + $adjustment, $column), $user_template->{$entry};
            }
        } until ($self->sysop_validate_fields($entry, $user_template->{$entry}, $row + $adjustment, $column));
        if ($user_template->{$entry} =~ /^(yes|on|true|1)$/i) {
            $user_template->{$entry} = TRUE;
        } elsif ($user_template->{$entry} =~ /^(no|off|false|0)$/i) {
            $user_template->{$entry} = FALSE;
        }
        $adjustment++;
    } ## end foreach my $entry (@tmp)
    $self->{'debug'}->DEBUGMAX([$user_template]);
    if ($self->users_add($user_template)) {
        print "\n\n", colored(['green'], 'SUCCESS'), "\n";
        $self->{'debug'}->DEBUG(['sysop_user_add end']);
        return (TRUE);
    }
    $self->{'debug'}->DEBUG(['End SysOp User Add']);
    return (FALSE);
} ## end sub sysop_user_add

sub sysop_show_choices {
    my $self    = shift;
    my $mapping = shift;

    $self->{'debug'}->DEBUG(['SysOp Show Choices']);
    my @list = grep(!/TEXT/, (sort(keys %{$mapping})));
    my $twin = FALSE;
    $twin = TRUE if (scalar(@list) > 1 && $self->{'USER'}->{'max_columns'} > 40);
    my $max = 0;
    if ($twin) {
        foreach my $name (@list) {
            $max = max(length($mapping->{$name}->{'text'}), $max);
        }
        $max += 3;
        $self->output(sprintf("%s%s%s%-${max}s %s%s%s", '[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]', ' ' x $max, '[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]') . "\n");
    } else {
        $self->output('[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %][% BOX DRAWINGS LIGHT HORIZONTAL %][% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]' . "\n");
    }
    while (scalar(@list)) {
        my $kmenu = shift(@list);
        if ($twin) {
            $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, sprintf('%-' . ($max - 1) . 's', $mapping->{$kmenu}->{'text'}));
            if (scalar(@list)) {
                $kmenu = shift(@list);
                $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'});
            } else {
                $self->output(sprintf('%s%s%s', '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]'));
                $twin = FALSE;
            }
        } else {
            $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'});
        }
        $self->output("\n");
    } ## end while (scalar(@list))
    if ($twin) {
        $self->output(sprintf("%s%s%s%-${max}s %s%s%s", '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]', ' ' x $max, '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]'));
    } else {
        $self->output('[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %][% BOX DRAWINGS LIGHT HORIZONTAL %][% BOX DRAWINGS LIGHT ARC UP AND LEFT %]');
    }
    $self->{'debug'}->DEBUG(['End Show Choices']);
} ## end sub sysop_show_choices

sub sysop_validate_fields {
    my ($self, $name, $val, $row, $column) = @_;

    $self->{'debug'}->DEBUG(['Start SysOp Validate Fields']);
    my $size     = max(3, $self->{'SYSOP FIELD TYPES'}->{$name}->{'max'});
    my $response = TRUE;
    if ($name =~ /(username|given|family|baud_rate|timeout|_files|_message|sysop|prefer|password)/ && $val eq '') {    # cannot be empty
        print locate($row, ($column + $size)), colored(['red'], ' Cannot Be Empty'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'baud_rate' && $val !~ /^(300|600|1200|2400|4800|9600|FULL)$/i) {
        print locate($row, ($column + $size)), colored(['red'], ' Only 300,600,1200,2400,4800,9600,FULL'), locate($row, $column);
        $response = FALSE;
    } elsif ($name =~ /max_/ && $val =~ /\D/i) {
        print locate($row, ($column + $size)), colored(['red'], ' Only Numeric Values'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'timeout' && $val =~ /\D/) {
        print locate($row, ($column + $size)), colored(['red'], ' Must be numeric'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'text_mode' && $val !~ /^(ASCII|ATASCII|PETSCII|ANSI)$/) {
        print locate($row, ($column + $size)), colored(['red'], ' Only ASCII,ATASCII,PETSCII,ANSI'), locate($row, $column);
        $response = FALSE;
    } elsif ($name =~ /(prefer_nickname|_files|_message|sysop)/ && $val !~ /^(yes|no|true|false|on|off|0|1)$/i) {
        print locate($row, ($column + $size)), colored(['red'], ' Only Yes/No or On/Off or 1/0'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'birthday' && $val ne '' && $val !~ /(\d\d\d\d)-(\d\d)-(\d\d)/) {
        print locate($row, ($column + $size)), colored(['red'], ' YEAR-MM-DD'), locate($row, $column);
        $self->{'debug'}->DEBUG(['sysop_validate_fields end']);
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['Start SysOp Validate Fields']);
    return ($response);
} ## end sub sysop_validate_fields

sub sysop_prompt {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Prompt']);
    my $response = "\n" . '[% B_BRIGHT MAGENTA %][% BLACK %] SYSOP TOOL [% RESET %] ' . $text . ' [% PINK %][% BLACK RIGHTWARDS ARROWHEAD %][% RESET %] ';
    print $self->sysop_detokenize($response);
    $self->{'debug'}->DEBUG(['End SysOp Prompt']);
    return (TRUE);
} ## end sub sysop_prompt

sub sysop_detokenize {
    my $self = shift;
    my $text = shift;

    # OPERATION TOKENS
    foreach my $key (keys %{ $self->{'sysop_tokens'} }) {
        my $ch = '';
        if ($key eq 'MIDDLE VERTICAL RULE color' && $text =~ /\[\%\s+MIDDLE VERTICAL RULE (.*?)\s+\%\]/) {
            my $color = $1;
            if (ref($self->{'sysop_tokens'}->{$key}) eq 'CODE') {
                $ch = $self->{'sysop_tokens'}->{$key}->($self, $color);
            }
            $text =~ s/\[\%\s+MIDDLE VERTICAL RULE (.*?)\s+\%\]/$ch/gi;
        } elsif ($text =~ /\[\%\s+$key\s+\%\]/) {
            if (ref($self->{'sysop_tokens'}->{$key}) eq 'CODE') {
                $ch = $self->{'sysop_tokens'}->{$key}->($self);
            } else {
                $ch = $self->{'sysop_tokens'}->{$key};
            }
            $text =~ s/\[\%\s+$key\s+\%\]/$ch/gi;
        } ## end elsif ($text =~ /\[\%\s+$key\s+\%\]/)
    } ## end foreach my $key (keys %{ $self...})

    $text = $self->ansi_decode($text);

    return ($text);
} ## end sub sysop_detokenize

sub sysop_menu_choice {
    my $self   = shift;
    my $choice = shift;
    my $color  = shift;
    my $desc   = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Menu Choice']);
    my $response;
    if ($choice eq 'TOP') {
        $response = charnames::string_vianame('BOX DRAWINGS LIGHT ARC DOWN AND RIGHT') . charnames::string_vianame('BOX DRAWINGS LIGHT HORIZONTAL') . charnames::string_vianame('BOX DRAWINGS LIGHT ARC DOWN AND LEFT') . "\n";
    } elsif ($choice eq 'BOTTOM') {
        $response = $self->news_title_colorize(charnames::string_vianame('BOX DRAWINGS LIGHT ARC UP AND RIGHT') . charnames::string_vianame('BOX DRAWINGS LIGHT HORIZONTAL') . charnames::string_vianame('BOX DRAWINGS LIGHT ARC UP AND LEFT')) . "\n";
    } else {
        $response = $self->ansi_decode(charnames::string_vianame('BOX DRAWINGS LIGHT VERTICAL') . '[% BOLD %][% ' . $color . ' %]' . $choice . '[% RESET %]' . charnames::string_vianame('BOX DRAWINGS LIGHT VERTICAL') . ' [% ' . $color . ' %]' . charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE') . '[% RESET %] ' . $desc . "\n");
    }
    $self->{'debug'}->DEBUG(['End SysOp Menu Choice']);
    return ($response);
} ## end sub sysop_menu_choice

sub sysop_showenv {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp ShowENV']);
    my $MAX  = 0;
    my $text = '';
    foreach my $e (keys %ENV) {
        $MAX = max(length($e), $MAX);
    }

    foreach my $env (sort(keys %ENV)) {
        if ($ENV{$env} =~ /\n/g || $env eq 'WHATISMYIP_INFO') {
            my @in     = split(/\n/, $ENV{$env});
            my $indent = $MAX + 4;
            $text .= '[% BRIGHT WHITE %]' . sprintf("%${MAX}s", $env) . "[% RESET %] = ---\n";
            foreach my $line (@in) {
                if ($line =~ /\:/) {
                    my ($f, $l) = $line =~ /^(.*?):(.*)/;
                    chomp($l);
                    chomp($f);
                    $f = uc($f);
                    if ($f eq 'IP') {
                        $l = colored(['bright_green'], $l);
                        $f = 'IP ADDRESS';
                    }
                    my $le = 11 - length($f);
                    $f .= ' ' x $le;
                    $l = colored(['green'],    uc($l))                                                                         if ($l =~ /^ok/i);
                    $l = colored(['bold red'], 'U') . colored(['bold bright_white'], 'S') . colored(['bold bright_blue'], 'A') if ($l =~ /^us/i);
                    $text .= colored(['bold bright_cyan'], sprintf("%${indent}s", $f)) . " = $l\n";
                } else {
                    $text .= "$line\n";
                }
            } ## end foreach my $line (@in)
        } else {
            my $orig = $ENV{$env};
            my $new;

            if ($orig =~ /(256color)/) {
                $new = colored(['red'], '2') . colored(['green'], '5') . colored(['yellow'], '6') . colored(['cyan'], 'c') . colored(['bright_blue'], 'o') . colored(['magenta'], 'l') . colored(['bright_green'], 'o') . colored(['bright_blue'], 'r');
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(truecolor)/) {
                $new = colored(['red'], 't') . colored(['green'], 'r') . colored(['yellow'], 'u') . colored(['cyan'], 'e') . colored(['bright_blue'], 'c') . colored(['magenta'], 'o') . colored(['bright_green'], 'l') . colored(['bright_blue'], 'o') . colored(['red'], 'r');
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(\d+\.\d+\.\d+\.\d+)/) {
                $new = '[% BRIGHT GREEN %]' . $1 . '[% RESET %]';
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(ubuntu)/i) {
                $new = '[% ORANGE %]' . $1 . '[% RESET %]';
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(redhat)/i) {
                $new = colored(['bright_red'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(fedora)/i) {
                $new = colored(['bright_cyan'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(mint)/i) {
                $new = colored(['bright_green'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(zorin)/i) {
                $new = colored(['bright_white'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(wayland)/i) {
                $new = colored(['bright_yellow'], $1);
                $orig =~ s/$1/$new/g;
            }
            $text .= colored(['bold white'], sprintf("%${MAX}s", $env)) . ' = ' . $orig . "\n";
        } ## end else [ if ($ENV{$env} =~ /\n/g...)]
    } ## end foreach my $env (sort(keys ...))
    $self->{'debug'}->DEBUG(['End SysOp ShowENV']);
    return ($text);
} ## end sub sysop_showenv

sub sysop_scroll {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Scroll']);
    my $response = TRUE;
    print $self->{'ansi_meta'}->{'attributes'}->{'RESET'}->{'out'}, "\rScroll?  ";
    if ($self->sysop_keypress(ECHO, BLOCKING) =~ /N/i) {
        $response = FALSE;
    } else {
        print "\r" . clline;
    }
    $self->{'debug'}->DEBUG(['End SysOp Scroll']);
    return (TRUE);
} ## end sub sysop_scroll

sub sysop_list_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List BBS']);
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view ORDER BY bbs_name');
    $sth->execute();
    my @listing;
    my ($id_size, $name_size, $hostname_size, $poster_size) = (2, 4, 14, 6);
    while (my $row = $sth->fetchrow_hashref()) {
        push(@listing, $row);
        $name_size     = max(length($row->{'bbs_name'}),     $name_size);
        $hostname_size = max(length($row->{'bbs_hostname'}), $hostname_size);
        $id_size       = max(length('' . $row->{'bbs_id'}),  $id_size);
        $poster_size   = max(length($row->{'bbs_poster'}),   $poster_size);
    } ## end while (my $row = $sth->fetchrow_hashref...)
    my $table = Text::SimpleTable->new($id_size, $name_size, $hostname_size, 5, $poster_size);
    $table->row('ID', 'NAME', 'HOSTNAME/PHONE', 'PORT', 'POSTER');
    $table->hr();
    foreach my $line (@listing) {
        $table->row($line->{'bbs_id'}, $line->{'bbs_name'}, $line->{'bbs_hostname'}, $line->{'bbs_port'}, $line->{'bbs_poster'});
    }
    $self->sysop_output($table->round('BRIGHT BLUE')->draw());
    print 'Press a key to continue... ';
    $self->sysop_keypress();
    $self->{'debug'}->DEBUG(['End SysOp List BBS']);
    return (TRUE);
} ## end sub sysop_list_bbs

sub sysop_edit_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Edit BBS']);
    my @choices = (qw( bbs_id bbs_name bbs_hostname bbs_port ));
    $self->sysop_prompt('Please enter the ID, the hostname/phone, or the BBS name to edit');
    my $search;
    $search = $self->sysop_get_line(ECHO, 50, '');
    return (FALSE) if ($search eq '');
    print "\r", cldown, "\n";
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view WHERE bbs_id=? OR bbs_name=? OR bbs_hostname=?');
    $sth->execute($search, $search, $search);

    if ($sth->rows() > 0) {
        my $bbs = $sth->fetchrow_hashref();
        $sth->finish();
        my $table = Text::SimpleTable->new(6, 12, 50);
        my $index = 1;
        $table->row('CHOICE', 'FIELD NAME', 'VALUE');
        $table->hr();
        foreach my $name (qw(bbs_id bbs_poster bbs_name bbs_hostname bbs_port)) {
            if ($name =~ /bbs_id|bbs_poster/) {
                $table->row(' ', $name, $bbs->{$name});
            } else {
                $table->row($index, $name, $bbs->{$name});
                $index++;
            }
        } ## end foreach my $name (qw(bbs_id bbs_poster bbs_name bbs_hostname bbs_port))
        $self->sysop_output($table->round('BRIGHT BLUE')->draw());
        $self->sysop_prompt('Edit which field (Z=Nevermind)');
        my $choice;
        do {
            $choice = $self->sysop_keypress();
        } until ($choice =~ /[1-3]|Z/i);
        if ($choice =~ /\D/) {
            print "BACK\n";
            return (FALSE);
        }
        $self->sysop_prompt($choices[$choice] . ' (' . $bbs->{ $choices[$choice] } . ') ');
        my $width = ($choices[$choice] eq 'bbs_port') ? 5 : 50;
        my $new   = $self->sysop_get_line(ECHO, $width, '');
        if ($new eq '') {
            $self->{'debug'}->DEBUG(['sysop_edit_bbs end']);
            return (FALSE);
        }
        $sth = $self->{'dbh'}->prepare('UPDATE bbs_listing SET ' . $choices[$choice] . '=? WHERE bbs_id=?');
        $sth->execute($new, $bbs->{'bbs_id'});
        $sth->finish();
    } else {
        $sth->finish();
    }
    $self->{'debug'}->DEBUG(['End SysOp Edit BBS']);
    return (TRUE);
} ## end sub sysop_edit_bbs

sub sysop_add_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Add BBS']);
    my $table = Text::SimpleTable->new(14, 50);
    foreach my $name ('BBS NAME', 'HOSTNAME/PHONE', 'PORT') {
        my $count = ($name eq 'PORT') ? 5 : 50;
        $table->row($name, "\n" . charnames::string_vianame('OVERLINE') x $count);
        $table->hr() unless ($name eq 'PORT');
    }
    my @order = (qw(bbs_name bbs_hostname bbs_port));
    my $bbs   = {
        'bbs_name'     => '',
        'bbs_hostname' => '',
        'bbs_port'     => '',
    };
    my $index    = 0;
    my $response = TRUE;
    $self->sysop_output($table->round('BRIGHT BLUE')->draw());
    print $self->{'ansi_meta'}->{'cursor'}->{'UP'}->{'out'} x 9, $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 19;
    $bbs->{'bbs_name'} = $self->sysop_get_line(ECHO, 50, '');
    $self->{'debug'}->DEBUG(['  BBS Name:  ' . $bbs->{'bbs_name'}]);

    if ($bbs->{'bbs_name'} ne '' && length($bbs->{'bbs_name'}) > 3) {
        print $self->{'ansi_meta'}->{'cursor'}->{'DOWN'}->{'out'} x 2, "\r", $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 19;
        $bbs->{'bbs_hostname'} = $self->sysop_get_line(ECHO, 50, '');
        $self->{'debug'}->DEBUG(['  BBS Hostname:  ' . $bbs->{'bbs_hostname'}]);
        if ($bbs->{'bbs_hostname'} ne '' && length($bbs->{'bbs_hostname'}) > 5) {
            print $self->{'ansi_meta'}->{'cursor'}->{'DOWN'}->{'out'} x 2, "\r", $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 19;
            $bbs->{'bbs_port'} = $self->sysop_get_line(ECHO, 5, '');
            $self->{'debug'}->DEBUG(['  BBS Port:  ' . $bbs->{'bbs_port'}]);
            if ($bbs->{'bbs_port'} ne '' && $bbs->{'bbs_port'} =~ /^\d+$/) {
                $self->{'debug'}->DEBUG(['  Add to BBS List']);
                my $sth = $self->{'dbh'}->prepare('INSERT INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES (?,?,?,1)');
                $sth->execute($bbs->{'bbs_name'}, $bbs->{'bbs_hostname'}, $bbs->{'bbs_port'});
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
    $self->{'debug'}->DEBUG(['End SysOp Add BBS']);
    return ($response);
} ## end sub sysop_add_bbs

sub sysop_delete_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Delete BBS']);
    $self->sysop_prompt('Please enter the ID, the hostname, or the BBS name to delete');
    my $search;
    $search = $self->sysop_get_line(ECHO, 50, '');
    if ($search eq '') {
        return (FALSE);
    }
    print "\r", cldown, "\n";
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view WHERE bbs_id=? OR bbs_name=? OR bbs_hostname=?');
    $sth->execute($search, $search, $search);

    if ($sth->rows() > 0) {
        my $bbs = $sth->fetchrow_hashref();
        $sth->finish();
        my $table = Text::SimpleTable->new(12, 50);
        $table->row('FIELD NAME', 'VALUE');
        $table->hr();
        foreach my $name (qw(bbs_id bbs_poster bbs_name bbs_hostname bbs_port)) {
            $table->row($name, $bbs->{$name});
        }
        $self->sysop_output($table->round('RED')->draw());
        print 'Are you sure that you want to delete this BBS from the list (Y|N)?  ';
        my $choice = $self->sysop_decision();
        unless ($choice) {
            $self->{'debug'}->DEBUG(['End SysOp Delete BBS']);
            return (FALSE);
        }
        $sth = $self->{'dbh'}->prepare('DELETE FROM bbs_listing WHERE bbs_id=?');
        $sth->execute($bbs->{'bbs_id'});
    } ## end if ($sth->rows() > 0)
    $sth->finish();
    $self->{'debug'}->DEBUG(['End SysOp Delete BBS']);
    return (TRUE);
} ## end sub sysop_delete_bbs

sub sysop_add_file_category {
	my $self = shift;

    my $bar = '[% BRIGHT GREEN %]│[% RESET %]';
	my $max_columns = $self->{'USER'}->{'max_columns'};
	my $table = '[% BRIGHT GREEN %]╭' . '─' x ($max_columns - 2) . '╮[% RESET %]' . "\n";
	$table   .= sprintf('%s %s       TITLE? %s%-' . ($max_columns - 15) . 's %s', $bar, '[% B_GREEN %][% BLACK %]', '[% RESET %]', '', $bar) . "\n";
	$table   .= sprintf('%s %s DESCRIPTION? %s%-' . ($max_columns - 15) . 's %s', $bar, '[% B_YELLOW %][% BLACK %]', '[% RESET %]', '', $bar) . "\n";
	$table   .= sprintf('%s %s   FILE PATH? %s%-' . ($max_columns - 15) . 's %s', $bar, '[% B_MAGENTA %][% BLACK %]', '[% RESET %]', '', $bar) . "\n";
	$table   .= '[% BRIGHT GREEN %]╰' . '─' x ($self->{'USER'}->{'max_columns'} - 2) . '╯[% RESET %]' . "\n";
	$self->output($table);
	$self->output('[% UP %]' x 4 . '[% RIGHT %]' x 17);
	my $title = $self->sysop_get_line({ 'max' => ($max_columns - 17), 'type' => STRING, }, '');
	return(FALSE) if (length($title) < 4);
	$self->output('[% RIGHT %]' x 17);
	my $desc  = $self->sysop_get_line({ 'max' => ($max_columns - 17), 'type' => STRING, }, '');
	return(FALSE) if (length($desc) < 4);
	$self->output('[% RIGHT %]' x 17);
	my $path  = $self->sysop_get_line({ 'max' => ($max_columns - 17), 'type' => STRING, }, lc($title));
	return(FALSE) if (length($path) < 3);
    $self->sysop_prompt('Is this correct [y/n]?');
	if ($self->sysop_decision()) {
		print "YES\n";
		print "Adding category to the database...";
		my $sth = $self->{'dbh'}->prepare('INSERT INTO file_categories (title,description,path) VALUES (?,?,?)');
		$sth->execute($title, $desc, $path);
		$sth->finish();
		print "Done\nAdding ", $self->{'CONF'}->{'FILES PATH'},$path,'...';
		mkdir($self->{'CONF'}->{'FILES PATH'} . $path);
		print "Done\nFile category added\n";
		sleep 1;
		return(TRUE);
	} else {
		print "NO\n";
		return(FALSE);
	}
}

sub sysop_add_file {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Add File']);
    opendir(my $DIR, 'files/files/');
    my @dir = grep(!/^\.+/, readdir($DIR));
    closedir($DIR);
    my $list;
    my $nw  = 0;
    my $sw  = 4;
    my $tw  = 0;
    my $sth = $self->{'dbh'}->prepare('SELECT id FROM files WHERE filename=?');
    my $search;
    my $root          = $self->configuration('BBS ROOT');
    my $files_path    = $self->configuration('FILES PATH');
    my $file_category = $self->{'USER'}->{'file_category'};

    foreach my $file (@dir) {
        $sth->execute($file);
        my $rows = $sth->rows();
        if ($rows <= 0) {
            $nw = max(length($file), $nw);
            my $raw_size = (-s "$root/$files_path/$file");
            my $size     = format_number($raw_size);
            $sw = max(length("$size"), $sw, 4);
            my ($ext, $type) = $self->files_type($file);
            $tw                          = max(length($type), $tw);
            $list->{$file}->{'raw_size'} = $raw_size;
            $list->{$file}->{'size'}     = $size;
            $list->{$file}->{'type'}     = $type;
            $list->{$file}->{'ext'}      = uc($ext);
        } ## end if ($rows <= 0)
    } ## end foreach my $file (@dir)
    $sth->finish();
    if (defined($list)) {
        my @names = grep(!/^README.md$/, (sort(keys %{$list})));
        if (scalar(@names)) {
            $self->{'debug'}->DEBUGMAX($list);
            my $table = Text::SimpleTable->new($nw, $sw, $tw);
            $table->row('FILE', 'SIZE', 'TYPE');
            $table->hr();
            foreach my $file (sort(keys %{$list})) {
                $table->row($file, $list->{$file}->{'size'}, $list->{$file}->{'type'});
            }
            my $text = $table->twin('GREEN')->draw();
            $self->sysop_pager($text);
            while (scalar(@names)) {
                ($search) = shift(@names);
                $self->sysop_output('[% B_WHITE %][% BLACK %] Current Category [% RESET %] [% BRIGHT YELLOW %][% BLACK RIGHT-POINTING TRIANGLE %][% RESET %] [% BRIGHT WHITE %][% FILE CATEGORY %][% RESET %]' . "\n\n");
                $self->sysop_prompt('Which file would you like to add?  ');
                $search = $self->sysop_get_line(ECHO, $nw, $search);
                my $filename = "$root/$files_path/$search";
                if (-e $filename) {
                    $self->sysop_prompt('               What is the Title?');
                    my $title = $self->sysop_get_line(ECHO, 255, '');
                    if (defined($title) && $title ne '') {
                        $self->sysop_prompt('                Add a description');
                        my $description = $self->sysop_get_line(ECHO, 65535, '');
                        if (defined($description) && $description ne '') {
                            my $head = "\n" . '[% REVERSE %]    Category [% RESET %] [% FILE CATEGORY %]' . "\n" . '[% REVERSE %]   File Name [% RESET %] ' . $search . "\n" . '[% REVERSE %]       Title [% RESET %] ' . $title . "\n" . '[% REVERSE %] Description [% RESET %] ' . $description . "\n\n";
                            print $self->sysop_detokenize($head);
                            $self->sysop_prompt('Is this correct?');
                            if ($self->sysop_decision()) {
                                $sth = $self->{'dbh'}->prepare('INSERT INTO files (filename, title, user_id, category, file_type, description, file_size) VALUES (?,?,1,?,(SELECT id FROM file_types WHERE extension=?),?,?)');
                                $sth->execute($search, $title, $self->{'USER'}->{'file_category'}, $list->{$search}->{'ext'}, $description, $list->{$search}->{'raw_size'});
                                if ($self->{'dbh'}->err) {
                                    $self->{'debug'}->ERROR([$self->{'dbh'}->errstr]);
                                }
                                $sth->finish();
                            } ## end if ($self->sysop_decision...)
                        } ## end if (defined($description...))
                    } ## end if (defined($title) &&...)
                } ## end if (-e $filename)
            } ## end while (scalar(@names))
        } else {
            $self->sysop_output("\n\n" . '[% BRIGHT RED %]NO FILES TO ADD![% RESET %]  ');
            sleep 2;
        }
    } else {
        print colored(['yellow'], 'No unmapped files found'), "\n";
        sleep 2;
    }
    $self->{'debug'}->DEBUG(['End SysOp Add File']);
} ## end sub sysop_add_file

sub sysop_bbs_list_bulk_import {
    my $self = shift;

    my $filename = $self->configuration('BBS ROOT') . "/bbs_list.txt";
    $self->{'debug'}->DEBUG(['Start SysOp BBS List Bulk Import of ' . $filename]);
    if (-e "$filename") {
        $self->sysop_output("\n\nImporting/merging BBS list from bbs_list.txt\n\n");
        $self->sysop_output('[% GREEN %]╭───────────────────────────────────────────────────────────────────┬──────────────────────────────────┬───────╮[% RESET %]' . "\n");
        $self->sysop_output('[% GREEN %]│[% RESET %] NAME                                                              [% GREEN %]│[% RESET %] HOSTNAME/PHONE                   [% GREEN %]│[% RESET %] PORT  [% GREEN %]│[% RESET %]' . "\n");
        $self->sysop_output('[% GREEN %]├───────────────────────────────────────────────────────────────────┼──────────────────────────────────┼───────┤[% RESET %]' . "\n");
        open(my $FILE, '<', $filename);
        chomp(my @bbs = <$FILE>);
        close($FILE);

        my $sth = $self->{'dbh'}->prepare('REPLACE INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES (?,?,?,?)');
        foreach my $row (@bbs) {
            if ($row =~ /^. \S/ && $row !~ /^\* = NEW/) {
                $row =~ s/^\* /  /;
                my ($name, $url) = (substr($row, 2, 41), substr($row, 43));
                $name =~ s/(.*?)\s+$/$1/;
                my ($address, $port) = split(/:/, $url);
                $port = 23 unless (defined($port));
                $sth->execute($name, $address, $port, $self->{'USER'}->{'id'});
                $self->sysop_output('[% GREEN %]│[% RESET %] ' . sprintf('%-65s', $name) . '[% GREEN %] │[% RESET %] ' . sprintf('%-32s', $address) . ' [% GREEN %]│[% RESET %] ' . sprintf('%5d', $port) . ' [% GREEN %]│[% RESET %]' . "\n");
            } ## end if ($row =~ /^. \S/ &&...)
        } ## end foreach my $row (@bbs)
        $sth->finish();
        $self->sysop_output('[% GREEN %]╰───────────────────────────────────────────────────────────────────┴──────────────────────────────────┴───────╯[% RESET %]' . "\n\nImport Complete\n");
    } else {
        print "\n", chr(7), colored(['red'], 'Cannot find '), $filename, "\n";
        $self->{'debug'}->WARNING(["Cannot find $filename"]);
    }
    print "\nPress any key to continue";
    $self->sysop_get_key(SILENT, BLOCKING);
    $self->{'debug'}->DEBUG(['End SysOp BBS List Bulk Import']);
    return (TRUE);
} ## end sub sysop_bbs_list_bulk_import

sub sysop_ansi_output {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp ANSI Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;
    my $text   = $self->ansi_decode(shift);
    my $s_len  = length($text);
    my $nl     = $self->{'ansi_meta'}->{'cursor'}->{'NEWLINE'}->{'out'};
    my @lines  = split(/\n/, $text);
    my $size   = $self->{'USER'}->{'max_rows'};

    while (scalar(@lines)) {
        my $line = shift(@lines);
        print $line;
        $size--;
        if ($size <= 0) {
            $size = $self->{'USER'}->{'max_rows'};
            last unless ($self->scroll(("\n")));
        } else {
            print "\n";
        }
    } ## end while (scalar(@lines))
    $self->{'debug'}->DEBUG(['End SysOp ANSI Output']);
    return (TRUE);
} ## end sub sysop_ansi_output

sub sysop_output {
    my $self = shift;
    $| = 1;
    $self->{'debug'}->DEBUG(['Start SysOp Output']);
    my $text = $self->detokenize_text(shift);

    my $response = TRUE;
    if (defined($text) && $text ne '') {
        while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si) {
            my $wrapped = $1;
            my $format  = Text::Format->new(
                'columns'     => $self->{'USER'}->{'max_columns'} - 1,
                'tabstop'     => 4,
                'extraSpace'  => TRUE,
                'firstIndent' => 0,
            );
            $wrapped = $format->format($wrapped);
            chomp($wrapped);
            $text =~ s/\[\%\s+WRAP\s+\%\].*?\[\%\s+ENDWRAP\s+\%\]/$wrapped/s;
        } ## end while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si)
        while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si) {
            my $wrapped = $1;
            my $format  = Text::Format->new(
                'columns'     => $self->{'USER'}->{'max_columns'} - 1,
                'tabstop'     => 4,
                'extraSpace'  => TRUE,
                'firstIndent' => 0,
                'justify'     => TRUE,
            );
            $wrapped = $format->format($wrapped);
            chomp($wrapped);
            $text =~ s/\[\%\s+JUSTIFIED\s+\%\].*?\[\%\s+ENDJUSTIFIED\s+\%\]/$wrapped/s;
        } ## end while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si)
        $self->sysop_ansi_output($text);
    } else {
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['End SysOp Output']);
    return ($response);
} ## end sub sysop_output
1;
