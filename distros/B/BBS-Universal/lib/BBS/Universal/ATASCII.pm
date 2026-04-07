package BBS::Universal::ATASCII;
BEGIN { our $VERSION = '0.007'; }

sub atascii_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start ATASCII Initialize']);
    $self->{'atascii_meta'} = {
        # Control
        'ESC'                          => { 'out' => chr(27),  'unicode' => '␛', 'desc' => 'Escape', },
        'UP'                           => { 'out' => chr(28),  'unicode' => ' ', 'desc' => 'Move Cursor Up', },
        'DOWN'                         => { 'out' => chr(29),  'unicode' => ' ', 'desc' => 'Move Cursor Down', },
        'LEFT'                         => { 'out' => chr(30),  'unicode' => ' ', 'desc' => 'Move Cursor Left', },
        'RIGHT'                        => { 'out' => chr(31),  'unicode' => ' ', 'desc' => 'Move Cursor Right', },
        'CLEAR'                        => { 'out' => chr(125), 'unicode' => ' ', 'desc' => 'Clear Screen', },
        'BACKSPACE'                    => { 'out' => chr(126), 'unicode' => ' ', 'desc' => 'Backspace', },
        'TAB'                          => { 'out' => chr(127), 'unicode' => ' ', 'desc' => 'Tab', },
        'RETURN'                       => { 'out' => chr(155), 'unicode' => ' ', 'desc' => 'Carriage Return', },
        'DELETE LINE'                  => { 'out' => chr(156), 'unicode' => ' ', 'desc' => 'Delete Line', },
        'INSERT LINE'                  => { 'out' => chr(157), 'unicode' => ' ', 'desc' => 'Insert Line', },
        'CLEAR TAB STOP'               => { 'out' => chr(158), 'unicode' => ' ', 'desc' => 'Clear Tab Stop', },
        'SET TAB STOP'                 => { 'out' => chr(159), 'unicode' => ' ', 'desc' => 'Set Tab Stop', },
        'BUZZER'                       => { 'out' => chr(253), 'unicode' => ' ', 'desc' => 'Console Bell', },
        'RING BELL'                    => { 'out' => chr(253), 'unicode' => ' ', 'desc' => 'Console Bell', },
        'DELETE'                       => { 'out' => chr(254), 'unicode' => ' ', 'desc' => 'Delete', },
        'INSERT'                       => { 'out' => chr(255), 'unicode' => ' ', 'desc' => 'Insert', },

        # Normal

        'HEART'                        => { 'out' => chr(0),   'unicode' => '♥', 'desc' => 'Heart', },
        'VERTICAL BAR MIDDLE LEFT'     => { 'out' => chr(1),   'unicode' => '┣', 'desc' => 'Vertical Bar Middle Left', },
        'RIGHT VERTICAL BAR'           => { 'out' => chr(2),   'unicode' => '🮇', 'desc' => 'Right Vertical Bar', },
        'BOTTOM RIGHT CORNER'          => { 'out' => chr(3),   'unicode' => '┛', 'desc' => 'Bottom Right Corner', },
        'VERTICAL BAR MIDDLE RIGHT'    => { 'out' => chr(4),   'unicode' => '┫', 'desc' => 'Vertical Bar Middle Right', },
        'TOP RIGHT CORNER'             => { 'out' => chr(5),   'unicode' => '┓', 'desc' => 'Top Right Corner', },
        'LARGE FORWARD SLASH'          => { 'out' => chr(6),   'unicode' => '╱', 'desc' => 'Large Forward Slash', },
        'LARGE BACKSLASH'              => { 'out' => chr(7),   'unicode' => '╲', 'desc' => 'Large Backslash', },
        'TOP LEFT WEDGE'               => { 'out' => chr(8),   'unicode' => '◢', 'desc' => 'Top Left Wedge', },
        'BOTTOM RIGHT BOX'             => { 'out' => chr(9),   'unicode' => '▗', 'desc' => 'Bottom Right Box', },
        'TOP RIGHT WEDGE'              => { 'out' => chr(10),  'unicode' => '◣', 'desc' => 'Top Right Wedge', },
        'TOP RIGHT BOX'                => { 'out' => chr(11),  'unicode' => '▝', 'desc' => 'Top Right Box', },
        'TOP LEFT BOX'                 => { 'out' => chr(12),  'unicode' => '▘', 'desc' => 'Top Left Box', },
        'TOP HORIZONTAL BAR'           => { 'out' => chr(13),  'unicode' => '🮂', 'desc' => 'Top Horizontal Bar', },
        'BOTTOM HORIZONTAL BAR'        => { 'out' => chr(14),  'unicode' => '▂', 'desc' => 'Bottom Horizontal Bar', },
        'BOTTOM LEFT BOX'              => { 'out' => chr(15),  'unicode' => '▖', 'desc' => 'Bottom Left Box', },
        'CLUB'                         => { 'out' => chr(16),  'unicode' => '♣', 'desc' => 'Club', },
        'TOP LEFT CORNER'              => { 'out' => chr(17),  'unicode' => '┏', 'desc' => 'Top Left Corner', },
        'HORIZONTAL BAR'               => { 'out' => chr(18),  'unicode' => '━', 'desc' => 'Horizontal Bar', },
        'CROSS BAR'                    => { 'out' => chr(19),  'unicode' => '╋', 'desc' => 'Cross Bar', },
        'CENTER DOT'                   => { 'out' => chr(20),  'unicode' => '⏺', 'desc' => 'Center Dot', },
        'BOTTOM BOX'                   => { 'out' => chr(21),  'unicode' => '▄', 'desc' => 'Bottom Box', },
        'LEFT VERTICAL BAR'            => { 'out' => chr(22),  'unicode' => '▎', 'desc' => 'Left Vertical Bar', },
        'HORIZONTAL BAR MIDDLE TOP'    => { 'out' => chr(23),  'unicode' => '┳', 'desc' => 'Horizontal Bar Middle Top', },
        'HORIZONTAL BAR MIDDLE BOTTOM' => { 'out' => chr(24),  'unicode' => '┻', 'desc' => 'Horizontal Bar Middle Bottom', },
        'LEFT VERTICAL BAR'            => { 'out' => chr(25),  'unicode' => '▌', 'desc' => 'Left Vertical Bar', },
        'BOTTOM LEFT CORNER'           => { 'out' => chr(26),  'unicode' => '┗', 'desc' => 'Botom Left Corner', },
        'UP ARROW'                     => { 'out' => chr(28),  'unicode' => '🡹', 'desc' => 'Up Arrow', },
        'DOWN ARROW'                   => { 'out' => chr(29),  'unicode' => '🡻', 'desc' => 'Down Arrow', },
        'LEFT ARROW'                   => { 'out' => chr(30),  'unicode' => '🡸', 'desc' => 'Left Arrow', },
        'RIGHT ARROW'                  => { 'out' => chr(31),  'unicode' => '🡺', 'desc' => 'Right Arrow', },
        'DIAMOND'                      => { 'out' => chr(96),  'unicode' => '♦', 'desc' => 'Diamond', },
        'SPADE'                        => { 'out' => chr(123), 'unicode' => '♠', 'desc' => 'Spade', },
        'MIDDLE VERTICAL BAR'          => { 'out' => chr(124), 'unicode' => '|', 'desc' => 'Middle Vertical Bar', },
        'BACK ARROW'                   => { 'out' => chr(125), 'unicode' => '🢰', 'desc' => 'Back Arrow', },
        'LEFT TRIANGLE'                => { 'out' => chr(126), 'unicode' => '◀', 'desc' => 'Left Triangle', },
        'RIGHT TRIANGLE'               => { 'out' => chr(127), 'unicode' => '▶', 'desc' => 'Right Triangle', },
    };

    my $inv = "\e[7m";
    my $ni  = "\e[27m";

	my @list = keys %{ $self->{'atascii_meta'} };
    foreach my $name (@list) {
		next if ($name =~ /^(ESC|UP|DOWN|LEFT|RIGHT|CLEAR|BACKSPACE|TAB|RETURN|NEWLINE|DELETE LINE|INSERT LINE|CLEAR TAB STOP|BUZZER|RING BELL|DELETE|INSERT)$/);
		$self->{'atascii_meta'}->{"REVERSED $name"}->{'unicode'} = $inv . $self->{'atascii_meta'}->{$name}->{'unicode'} . $ni;
        $self->{'atascii_meta'}->{"REVERSED $name"}->{'out'}     = chr(128 + ord($self->{'atascii_meta'}->{$name}->{'out'}));
        $self->{'atascii_meta'}->{"REVERSED $name"}->{'desc'}    = 'Reversed ' . $self->{'atascii_meta'}->{$name}->{'desc'};
    }

    $self->{'atascii_table'} = [
        # Normal
        '♥', '┣', '🮇', '┛', '┫', '┓', '╱', '╲', '◢', '▗', '◣', '🬁', '🬀', '▔', '▂', '▖', '♣', '┏', '━', '╋', '⏺', '▄', '▎', '┳', '┻', '▌', '┗', '␛', '🡹', '🡻', '🡸', '🡺',
        ' ', '!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?',
        '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', "\\", ']', '^', '_',
        '♦', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '♠', '|', '🢰', '◀', '▶',
    ];
    foreach my $count (0 .. 127) { # Add inverts for table
        $self->{'atascii_table'}->[$count + 128] = $inv . $self->{'atascii_table'}->[$count] . $ni;
    }
    $self->{'debug'}->DEBUG(['End ATASCII Initialize']);
    return ($self);
} ## end sub atascii_initialize

sub atascii_output {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start ATASCII Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;

    if (length($text) > 1) {
        while ($text =~ /\[\%\s+HORIZONTAL RULE\s+\%\]/) {
            my $rule = '[% TOP HORIZONTAL BAR %]' x $self->{'USER'}->{'max_columns'};
            $text =~ s/\[\%\s+HORIZONTAL RULE\s+\%\]/$rule/gs;
        }
        foreach my $string (keys %{ $self->{'atascii_meta'} }) {
            if ($string eq $self->{'atascii_meta'}->{'CLEAR'}->{'out'} && ($self->{'sysop'} || $self->{'local_mode'})) {
                my $ch = locate(($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')), 1) . cldown;
                $text =~ s/\[\%\s+$string\s+\%\]/$ch/gi;
            } else {
                $text =~ s/\[\% $string \%\]/$self->{'atascii_meta'}->{$string}->{'out'}/gi;
            }
        } ## end foreach my $string (keys %{...})
    } ## end if (length($text) > 1)
    my $s_len = length($text);
    my $nl    = $self->{'atascii_meta'}->{'NEWLINE'}->{'out'};
    foreach my $count (0 .. $s_len) {
        my $char = substr($text, $count, 1);
        if ($char eq "\n") {
            if ($text !~ /$nl/ && !$self->{'local_mode'}) {    # translate only if the file doesn't have ASCII newlines
                $char = $nl;
            }
            $lines--;
            if ($lines <= 0) {
                $lines = $mlines;
                last unless ($self->scroll($nl));
            }
        } ## end if ($char eq "\n")
        $self->send_char($char);
    } ## end foreach my $count (0 .. $s_len)
    $self->{'debug'}->DEBUG(['End ATASCII Output']);
    return (TRUE);
} ## end sub atascii_output
1;
