package BBS::Universal::ASCII;
BEGIN { our $VERSION = '0.003' };

sub ascii_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start ASCII Initialize']);
    $self->{'ascii_meta'} = {
        'RETURN'    => { 'out' => chr(13),           'unicode' => ' ', 'desc' => 'Carriage Return' },
        'LINEFEED'  => { 'out' => chr(10),           'unicode' => ' ', 'desc' => 'Linefeed' },
        'NEWLINE'   => { 'out' => chr(13) . chr(10), 'unicode' => ' ', 'desc' => 'Newline' },
        'BACKSPACE' => { 'out' => chr(8),            'unicode' => ' ', 'desc' => 'Backspace' },
        'TAB'       => { 'out' => chr(9),            'unicode' => ' ', 'desc' => 'Tab' },
        'DELETE'    => { 'out' => chr(127),          'unicode' => ' ', 'desc' => 'Delete' },
        'CLS'       => { 'out' => chr(12),           'unicode' => ' ', 'desc' => 'Clear Screen (Formfeed)' },
        'CLEAR'     => { 'out' => chr(12),           'unicode' => ' ', 'desc' => 'Clear Screen (Formfeed)' },
        'RING BELL' => { 'out' => chr(7),            'unicode' => ' ', 'desc' => 'Console Bell' },
    };
    $self->{'debug'}->DEBUG(['End ACSII Initialize']);
    return ($self);
} ## end sub ascii_initialize

sub ascii_output {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start ASCII Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;
    if (length($text) > 1) {
        foreach my $string (keys %{ $self->{'ascii_meta'} }) {
            if ($string =~ /CLEAR|CLS/i && ($self->{'sysop'} || $self->{'local_mode'})) {
                my $ch = locate(($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')), 1) . cldown;
                $text =~ s/\[\%\s+$string\s+\%\]/$ch/gi;
            } else {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'ascii_meta'}->{$string}->{'out'}/gi;
            }
        } ## end foreach my $string (keys %{...})
        while ($text =~ /\[\%\s+HORIZONTAL RULE\s+\%\]/) {
            my $rule = '=' x $self->{'USER'}->{'max_columns'};
            $text =~ s/\[\%\s+HORIZONTAL RULE\s+\%\]/$rule/gs;
        }
    } ## end if (length($text) > 1)
    my $s_len = length($text);
    my $nl    = $self->{'ascii_meta'}->{'NEWLINE'}->{'out'};
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
    $self->{'debug'}->DEBUG(['End ASCII Output']);
    return (TRUE);
} ## end sub ascii_output
1;
