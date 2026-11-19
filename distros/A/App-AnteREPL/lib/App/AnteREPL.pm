use 5.016;
use strict;
use warnings;

package App::AnteREPL;

use Data::Dumper ();
use Encode qw(decode encode FB_CROAK);
use File::Basename qw(dirname);
use File::Spec ();
use File::Temp ();
use Text::Balanced qw(extract_quotelike);
use Text::ParseWords qw(shellwords);
use App::AnteREPL::Shorthand ();

our $VERSION = '0.01';
our $PROGRAM_VERSION = '0.1';
our $FAREWELL = 'Thank, we hope something good happens to you today!';
my $next_workspace = 0;
my $max_line = 999_999_999;

# Exact, uppercase shortcuts only. V groups environment-variable operations.
my %short_commands = (
    A => 'AUTO', A0 => 'AUTO OFF', A1 => 'AUTO ECHO ON', A2 => 'AUTO ECHO OFF',
    C => 'CLS', C1 => 'CD', D => 'DUMP', D1 => 'DEL',
    E => 'EVAL', E1 => 'EDIT', E2 => 'EXPORT', F => 'FUNCTIONS', H => 'HELP',
    I => 'IMPORT', L => 'LIST', L1 => 'LOAD', L2 => 'LIST SLOW', L3 => 'LIST PAUSE',
    N => 'NEW', P => 'PEEK', Q => 'QUIT',
    R => 'RUN', R1 => 'RENUM', R2 => 'RESET', R3 => 'RECOVER',
    S => 'SAVE', S1 => 'STATUS', U => 'UNDO',
    V => 'ENV', V0 => 'ENV RESET', V1 => 'ENV SET', V2 => 'ENV UNSET',
    V3 => 'ENV EDIT', V4 => 'ENV SAVE', V5 => 'ENV LOAD', V6 => 'ENV RELOAD',
);
my %guarded_shortcuts = map { $_ => 1 } qw(C D1 E1 E2 I L1 N Q R1 R2 R3 S U V V0 V1 V2 V3 V4 V5 V6);

sub _expand_short_command {
    my ($source) = @_;
    return $source unless $source =~ /\A(\s*)([A-Z][0-9]*)(!?)(?=\s|\z)/;
    my ($leading, $short, $force, $end) = ($1, $2, $3, $+[0]);
    return $source unless exists $short_commands{$short};
    my ($command, $option) = split / /, $short_commands{$short}, 2;
    my $tail = substr($source, $end);
    # LIST's mode follows its optional range; other fixed options precede args.
    return "$leading$command$force$tail $option" if $short eq 'L2' || $short eq 'L3';
    return "$leading$command$force" . (defined $option ? " $option" : '') . $tail;
}

sub new {
    my ($class) = @_;
    return bless {
        lines     => {},
        saved     => '',
        filename  => undef,
        undo      => [],
        workspace => 'App::AnteREPL::Workspace::S' . ++$next_workspace,
        format    => 'native',
        initial_env => { %ENV },
    }, $class;
}

sub _confirmation_answer {
    my ($self, $description, $forced) = @_;
    die "Confirmation required: $description. Try $forced to proceed without a prompt.\n"
        unless $self->{interactive};
    local $SIG{INT} = sub { die "Interrupted.\n" };
    print "$description. Continue? [y/N] ";
    my ($answer, $error);
    { local $@;
      eval { $answer = $self->{screen} ? $self->{screen}->read_data(1) : scalar <STDIN>; 1 }
          or $error = $@;
    }
    STDIN->clearerr if !$self->{screen} && (!defined $answer || defined $error);
    die $error if defined $error;
    print "\n" unless defined $answer;
    return $answer;
}

sub _confirm_destructive {
    my ($self, $description) = @_;
    my $guard = $self->{shortcut_guard} or return;
    return if $guard->{force} || $guard->{approved};
    my $answer = $self->_confirmation_answer($description, $guard->{label} . '!');
    die "Cancelled.\n" unless defined $answer && $answer =~ /\A\s*y(?:es)?\s*\z/i;
    $guard->{approved} = 1;
}

sub _confirm_environment {
    my ($self, $values) = @_;
    return unless grep { !exists $values->{$_} || $ENV{$_} ne $values->{$_} } keys %ENV;
    $self->_confirm_destructive('Replace or remove current environment values');
}

sub _evaluate_definition {
    my ($self, $definition) = @_;
    my ($type, $name) = @{$definition}{qw(type name)};
    my $package = $self->{workspace} . '::';
    my $existing;
    {
        no strict 'refs';
        if (exists ${$package}{$name}) {
            $existing = $type eq 's' ? defined &{$package . $name}
                : $type eq 'a' ? defined *{$package . $name}{ARRAY}
                : $type eq 'h' ? defined *{$package . $name}{HASH}
                : defined tied(${$package . $name}) || defined ${$package . $name};
        }
    }
    local $self->{shortcut_guard} = {label=>$definition->{label}, force=>$definition->{force}};
    my $target = $type eq 's' ? "function $name" : ($type eq 'a' ? '@' : $type eq 'h' ? '%' : '$') . $name;
    $self->_confirm_destructive("Replace existing $target") if $existing;
    return $self->evaluate($definition->{code}, 0);
}

sub numbers { return sort { $a <=> $b } keys %{ $_[0]->{lines} }; }

sub source {
    my ($self) = @_;
    return join '', map { $self->{lines}{$_} . "\n" } $self->numbers;
}

sub listing {
    my ($self, $range) = @_;
    my ($first, $last) = _range($range);
    return join '', map { $_ . ' ' . $self->{lines}{$_} . "\n" }
        grep { $_ >= $first && $_ <= $last } $self->numbers;
}

sub display_listing {
    my ($self, $range) = @_;
    my ($first, $last) = _range($range);
    my @numbers = grep { $_ >= $first && $_ <= $last } $self->numbers;
    return ('', 0) unless @numbers;
    my $width = length $numbers[-1];
    return (join('', map { sprintf("%-*d %s\n", $width, $_, $self->{lines}{$_}) } @numbers), $width);
}

sub list_program {
    my ($self, $argument) = @_;
    $argument = '' unless defined $argument;
    my $mode = 'normal';
    $mode = lc($1) if $argument =~ s/(?:\A|\s)(SLOW|PAUSE)\s*\z//;
    $argument =~ s/\A\s+|\s+\z//g;
    $argument =~ s/\s*-\s*/-/g;
    my ($text, $width) = $self->display_listing($argument);
    if ($self->{screen}) {
        $self->{screen}->list_rows([split /\n/, $text], $width, $mode);
    }
    else { print $text; }
}

sub dirty { return $_[0]->listing ne $_[0]->{saved}; }

sub clear_screen {
    my ($self) = @_;
    $self->_confirm_destructive('Clear the visible screen and its resize recovery copy')
        if $self->{screen} || (-t STDOUT && ($ENV{TERM} || '') ne 'dumb');
    if ($self->{screen}) { $self->{screen}->clear_display; }
    elsif (-t STDOUT && ($ENV{TERM} || '') ne 'dumb') { print "\e[2J\e[H"; }
}

sub recover_screen {
    my ($self) = @_;
    die "RECOVER requires screen mode.\n" unless $self->{screen};
    $self->{screen}->recover_display($self);
}

sub change_directory {
    my ($self, $tail) = @_;
    my ($path) = _args($tail, 0, 1, 'CD [directory] or CHDIR [directory]');
    if (!defined $path) {
        $path = $ENV{HOME};
        $path = $ENV{USERPROFILE} if (!defined $path || !length $path) && $^O eq 'MSWin32';
        die "No home directory is set; use CD directory.\n" unless defined $path && length $path;
    }
    die "Directory paths cannot contain NUL bytes.\n" if $path =~ /\0/;
    chdir $path or die "Cannot change directory to '$path': $!\n";
}

sub _command_case_error {
    my ($self, $line, $error) = @_;
    return $error if $line =~ /\n/;
    return $error unless $line =~ /\A\s*([A-Za-z][A-Za-z0-9_]*)(!?)(?=\s|;|\z)/;
    my ($word, $force) = ($1, $2);
    # These spellings belong to Perl even when their use raises an error.
    return $error if App::AnteREPL::Shorthand::perl_keyword($word);
    my $upper = uc $word;
    return $error if $word eq $upper;
    return $error unless exists $short_commands{$upper}
        || $upper =~ /\A(?:AUTO|ENV|LIST[0-9]*|RUN|EDIT|DEL|DELETE|RENUM|REORDER|UNDO|SAVE|LOAD|IMPORT|EXPORT|NEW|CLEAR|CLS|RECOVER|RESET|FUNCTIONS|STATUS|HELP|QUIT|EXIT|EVAL|DUMP|PEEK|CD|CHDIR)\z/;
    {
        no strict 'refs';
        return $error if defined &{ $self->{workspace} . '::' . $word };
    }
    return $error unless $error =~ /\ABareword "\Q$word\E" not allowed while "strict subs" in use at PERL_ANTE_REPL_prompt line [0-9]+\b/;
    return "REPL commands must be uppercase; try, \"$upper$force\".\n";
}

sub _input_error {
    my ($error) = @_;
    return $error unless $error eq "Interrupted.\n";
    return $error . "To leave: QUIT, or QUIT! to discard unsaved source.\n"
        . "Ctrl-D exits when AUTO is off and the source is saved.\n";
}

sub _number {
    my ($number) = @_;
    die "Line numbers must be integers from 1 to $max_line.\n"
        unless defined $number && $number =~ /\A[0-9]+\z/
        && $number >= 1 && $number <= $max_line;
    return 0 + $number;
}

sub _range {
    my ($range) = @_;
    return (1, $max_line) unless defined $range && length $range;
    return (_number($range), _number($range)) if $range =~ /\A[0-9]+\z/;
    die "Use a line number or a range such as 10-50, 10-, or -50.\n"
        unless $range =~ /\A([0-9]*)-([0-9]*)\z/ && (length($1) || length($2));
    my ($lo, $hi) = ($1, $2);
    $lo = length($lo) ? _number($lo) : 1;
    $hi = length($hi) ? _number($hi) : $max_line;
    die "Range starts after it ends.\n" if $lo > $hi;
    return ($lo, $hi);
}

sub _replace {
    my ($self, $lines) = @_;
    my $new = join '', map { $_ . ' ' . $lines->{$_} . "\n" }
        sort { $a <=> $b } keys %$lines;
    return 0 if $new eq $self->listing;
    $self->_confirm_destructive('Replace or remove stored source lines')
        if grep { !exists $lines->{$_} || $lines->{$_} ne $self->{lines}{$_} } keys %{ $self->{lines} };
    push @{ $self->{undo} }, { %{ $self->{lines} } };
    shift @{ $self->{undo} } if @{ $self->{undo} } > 50;
    $self->{lines} = { %$lines };
    return 1;
}

sub set_line {
    my ($self, $number, $code, $literal) = @_;
    $number = _number($number);
    my %lines = %{ $self->{lines} };
    if (!defined $code || ($code eq '' && !$literal)) {
        delete $lines{$number};
    }
    else {
        die "A numbered entry must occupy one physical line.\n" if $code =~ /[\r\n\0]/;
        $lines{$number} = $code;
    }
    return $self->_replace(\%lines);
}

sub _typed_source {
    my ($code) = @_;
    return $code unless defined $code && $code =~ /\S/;
    # A small input convenience, not a Perl parser. Number-colon entries bypass
    # this entirely; EDIT, IMPORT, LOAD, and the internal setter remain literal.
    return $code if $code =~ /\A\s*(?:=\w|__(?:DATA|END)__\b)/;
    local $@;
    my ($position, $visible, $body, $comment) = (0, '', $code, '');
    while ($position < length $code) {
        my $rest = substr($code, $position);
        # Consume sigils first, so $#array and special variables such as $#
        # and $" are not mistaken for comments or quoted strings.
        if ($rest =~ /\A([\$\@\%](?:\#?[\p{L}_][\p{L}\p{N}_]*(?:::[\p{L}_][\p{L}\p{N}_]*)*|[0-9]+|[^\w\s{]))/) {
            $position += length $1;
            $visible .= 'V';
            next;
        }
        if ($rest =~ /\A#/) {
            $body = substr($code, 0, $position);
            $comment = $rest;
            last;
        }
        # Protect hashes and punctuation inside ordinary strings and Perl's
        # quote-like operators. Never compile or execute input to classify it.
        my $quoted = $rest =~ /\A['"`]/
            || $rest =~ /\A(?:qq|qw|qx|qr|q|m|s|tr|y)\b\s*(?!=>)[^\w\s]/;
        if ($quoted || $rest =~ /\A\//) {
            my ($literal) = extract_quotelike("$rest", '');
            if (defined $literal && length $literal) {
                $position += length $literal;
                $visible .= 'Q';
                next;
            }
            return $code if $quoted; # An unfinished quote needs literal input.
        }
        if ($rest =~ /\A([\p{L}_][\p{L}\p{N}_]*)/) {
            $visible .= $1;
            $position += length $1;
            next;
        }
        $visible .= substr($code, $position++, 1);
    }
    return $code if $visible =~ /\A\s*\z/;
    return $code if $visible =~ /[;{(\[,]\s*\z/;
    return $code if $visible !~ /(?:\+\+|--)\s*\z/
        && $visible =~ /(?:[=+*\/%.?:&|!~-]|->|\b(?:and|or|xor|not))\s*\z/;
    return $code if $visible =~ /}\s*\z/ && $visible =~ /\A\s*(?:}|{|(?:(?:[\w]+:)\s*)?(?:if|unless|while|until|for|foreach|given|when|default|else|elsif|continue|sub|package|BEGIN|UNITCHECK|CHECK|INIT|END)\b)/;
    $body =~ s/(\s*)\z/;$1/;
    return $body . $comment;
}

sub delete_range {
    my ($self, $range) = @_;
    die "DEL needs a line number or range.\n" unless defined $range && length $range;
    my ($first, $last) = _range($range);
    my %lines = %{ $self->{lines} };
    delete @lines{ grep { $_ >= $first && $_ <= $last } keys %lines };
    return $self->_replace(\%lines);
}

sub renumber {
    my ($self, $start, $step) = @_;
    $start = _number(defined $start ? $start : 10);
    $step  = _number(defined $step ? $step : 10);
    my @old = $self->numbers;
    die "Renumbering would exceed $max_line.\n" if @old && $start + $#old * $step > $max_line;
    my %lines;
    $lines{ $start + $_ * $step } = $self->{lines}{ $old[$_] } for 0 .. $#old;
    return $self->_replace(\%lines);
}

sub undo {
    my ($self) = @_;
    die "Nothing to undo.\n" unless @{ $self->{undo} };
    $self->_confirm_destructive('Replace the current program with its previous source version');
    $self->{lines} = pop @{ $self->{undo} };
    return 1;
}

sub _guard {
    my ($self, $command, $force) = @_;
    return if $self->{shortcut_guard}; # Shortcuts confirm immediately before mutation.
    die "Unsaved program. Use SAVE, or $command! to discard it.\n" if $self->dirty && !$force;
}

sub clear {
    my ($self, $force) = @_;
    $self->_guard('NEW', $force);
    $self->_confirm_destructive('Clear the stored program and its save filename')
        if keys %{ $self->{lines} } || defined $self->{filename};
    $self->_replace({});
    $self->{filename} = undef;
    $self->{saved} = '';
    $self->{format} = 'native';
}

sub _read_text {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot open '$path': $!\n";
    local $/;
    my $bytes = <$fh>;
    die "Cannot read '$path': $!\n" unless defined $bytes;
    close $fh or die "Cannot close '$path': $!\n";
    my $text = decode('UTF-8', $bytes, FB_CROAK);
    $text =~ s/\A\x{FEFF}//;
    $text =~ s/\r\n/\n/g;
    die "'$path' contains NUL bytes or unsupported bare carriage returns.\n" if $text =~ /[\0\r]/;
    return $text;
}

sub _write_text {
    my ($path, $text) = @_;
    my $fh = File::Temp->new(TEMPLATE => '.anterepl-XXXXXX', DIR => dirname($path), UNLINK => 1);
    binmode $fh, ':raw' or die "Cannot set file mode: $!\n";
    print {$fh} encode('UTF-8', $text, FB_CROAK) or die "Cannot write '$path': $!\n";
    my $temporary = $fh->filename;
    close $fh or die "Cannot close temporary file for '$path': $!\n";
    if (-e $path) {
        my @stat = stat $path;
        die "Cannot stat '$path': $!\n" unless @stat;
        chmod($stat[2] & 0777, $temporary) or die "Cannot preserve permissions for '$path': $!\n";
    }
    rename $temporary, $path or die "Cannot replace '$path': $!\n";
    return 1;
}

sub save {
    my ($self, $path) = @_;
    $path = $self->{filename} unless defined $path;
    die "SAVE needs a filename, for example SAVE demo.bperl.\n" unless defined $path && length $path;
    my $format = $path =~ /\.pl\z/i ? 'perl' : $path =~ /\.bperl\z/i ? 'native' : $self->{format};
    $self->_confirm_destructive("Overwrite file '$path'") if -e $path || -l $path;
    _write_text($path, $format eq 'perl' ? $self->source : "# PERL ANTE REPL V$PROGRAM_VERSION\n" . $self->listing);
    $self->{filename} = File::Spec->rel2abs($path);
    $self->{format} = $format;
    $self->{saved} = $self->listing;
    return $path;
}

sub load {
    my ($self, $path, $force) = @_;
    $self->_guard('LOAD', $force);
    my $text = _read_text($path);
    if ($text !~ /\A# (?:PERL ANTE REPL|BASIC PERL)\b/ && $path !~ /\.bperl\z/i) {
        my $lines = _source_lines($text);
        $self->_confirm_destructive('Replace the stored program and its save filename')
            if keys %{ $self->{lines} } || defined $self->{filename};
        $self->_replace($lines);
        $self->{filename} = File::Spec->rel2abs($path);
        $self->{format} = 'perl';
        $self->{saved} = $self->listing;
        return scalar keys %$lines;
    }
    my @records = split /\n/, $text, -1;
    pop @records if @records && $records[-1] eq '';
    my $header = @records ? shift @records : '';
    die "Not a PERL ANTE REPL V$PROGRAM_VERSION file. Use a .pl filename or IMPORT for ordinary Perl source.\n"
        unless $header eq "# PERL ANTE REPL V$PROGRAM_VERSION"
            || $header eq "# BASIC PERL V$PROGRAM_VERSION";
    my %lines;
    for my $record (@records) {
        die "Invalid numbered record in '$path'.\n" unless $record =~ /\A([0-9]+)[ \t](.*)\z/;
        my ($number, $code) = (_number($1), $2);
        die "Duplicate line $number in '$path'.\n" if exists $lines{$number};
        $lines{$number} = $code;
    }
    $self->_confirm_destructive('Replace the stored program and its save filename')
        if keys %{ $self->{lines} } || defined $self->{filename};
    $self->_replace(\%lines);
    $self->{filename} = File::Spec->rel2abs($path);
    $self->{format} = 'native';
    $self->{saved} = $self->listing;
    return scalar keys %lines;
}

sub _source_lines {
    my ($text) = @_;
    my @code = split /\n/, $text, -1;
    pop @code if @code && $code[-1] eq '';
    die "Program has too many lines.\n" if @code * 10 > $max_line;
    my %lines;
    $lines{ ($_ + 1) * 10 } = $code[$_] for 0 .. $#code;
    return \%lines;
}

sub import_source {
    my ($self, $path, $force) = @_;
    $self->_guard('IMPORT', $force);
    my $lines = _source_lines(_read_text($path));
    $self->_confirm_destructive('Replace the stored program and forget its save filename')
        if keys %{ $self->{lines} } || defined $self->{filename};
    $self->_replace($lines);
    $self->{filename} = undef;
    $self->{saved} = '';
    $self->{format} = 'native';
    return scalar keys %$lines;
}

sub export_source {
    my ($self, $path) = @_;
    my $prelude = "#!/usr/bin/env perl\nuse 5.016;\nuse strict;\nuse warnings;\nno strict 'vars';\nno warnings 'once';\nuse feature 'say';\n";
    $self->_confirm_destructive("Overwrite file '$path'") if -e $path || -l $path;
    _write_text($path, $prelude . $self->source);
    return $path;
}

sub _edit_text {
    my ($self, $before, $name) = @_;
    my $editor = (defined $ENV{EDITOR} && $ENV{EDITOR} =~ /\S/) ? $ENV{EDITOR}
        : (defined $ENV{VISUAL} && $ENV{VISUAL} =~ /\S/) ? $ENV{VISUAL}
        : $^O eq 'MSWin32' ? 'notepad' : 'vi';
    my @command = shellwords($editor);
    die "EDITOR is empty or has unmatched quotes.\n" unless @command && length $command[0];
    my $directory = File::Temp->newdir('anterepl-XXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $path = File::Spec->catfile("$directory", $name);
    _write_text($path, $before);
    # List-form system: editor arguments are supported; no command shell is involved.
    my $status = $self->{screen}
        ? $self->{screen}->external(sub { system { $command[0] } @command, $path }, 0)
        : system { $command[0] } @command, $path;
    die "Cannot start editor '$command[0]': $!; memory unchanged.\n" if $status == -1;
    die "Editor terminated by signal " . ($status & 127) . "; memory unchanged.\n" if $status & 127;
    die "Editor exited with status " . ($status >> 8) . "; memory unchanged.\n" if $status;
    return _read_text($path);
}

sub edit {
    my ($self) = @_;
    my $before = $self->source;
    my $after = $self->_edit_text($before, 'program.pl');
    return 0 if $before eq $after;
    return $self->_replace(_source_lines($after));
}

sub _env_key {
    my ($key) = @_;
    die "Environment names cannot contain whitespace, =, #, quotes, or NUL.\n"
        unless defined $key && $key =~ /\A[^\s=\0#'\"]+\z/;
    return $key;
}

sub env_text {
    my ($values) = @_;
    $values = \%ENV unless defined $values;
    my $text = '';
    for my $key (sort keys %$values) {
        _env_key($key);
        my $value = $values->{$key};
        die "Environment values must be strings without NUL bytes.\n" if !defined $value || ref $value || $value =~ /\0/;
        my $byte_escapes = '';
        if (!utf8::is_utf8($value)) {
            local $@;
            my $decoded = eval { decode('UTF-8', "$value", FB_CROAK) };
            if (defined $decoded) { $value = $decoded; }
            else { $byte_escapes = 1; }
        }
        if ($value !~ /\A[A-Za-z0-9_.\/:\@%+,=-]*\z/) {
            $value =~ s/([\\"])/\\$1/g;
            $value =~ s/\n/\\n/g;
            $value =~ s/\r/\\r/g;
            $value =~ s/\t/\\t/g;
            $value =~ s/([\x01-\x08\x0b\x0c\x0e-\x1f\x7f])/sprintf('\\x%02X', ord $1)/ge;
            $value =~ s/([\x80-\xff])/sprintf('\\x%02X', ord $1)/ge if $byte_escapes;
            $value = '"' . $value . '"';
        }
        $text .= "$key=$value\n";
    }
    return $text;
}

sub _parse_env {
    my ($text) = @_;
    my (%values, $line);
    for my $record (split /\n/, $text) {
        ++$line;
        next if $record =~ /\A\s*(?:#.*)?\z/;
        die "Invalid environment assignment on line $line; use VAR=value.\n"
            unless $record =~ /\A\s*(?:export\s+)?([^\s=]+)\s*=(.*)\z/;
        my ($key, $value) = (_env_key($1), $2);
        die "Duplicate environment name '$key' on line $line.\n" if exists $values{$key};
        $value =~ s/\A\s+|\s+\z//g;
        if ($value =~ /\A"/) {
            die "Invalid quoted value on environment line $line.\n"
                unless $value =~ /\A"((?:[^"\\]|\\.)*)"\s*(?:#.*)?\z/;
            $value = $1;
            $value = encode('UTF-8', $value) if utf8::is_utf8($value);
            my %escape = ('n'=>"\n", 'r'=>"\r", 't'=>"\t", '\\'=>'\\', '"'=>'"');
            $value =~ s/\\(x[0-9A-Fa-f]{2}|[nrt\\"])/exists $escape{$1} ? $escape{$1} : chr(hex(substr($1, 1)))/ge;
        }
        elsif ($value =~ /\A'/) {
            die "Invalid quoted value on environment line $line.\n" unless $value =~ /\A'([^']*)'\s*(?:#.*)?\z/;
            $value = $1;
            $value = encode('UTF-8', $value) if utf8::is_utf8($value);
        }
        else {
            $value =~ s/(?:\A|\s+)#.*\z//;
            $value =~ s/\s+\z//;
            $value = encode('UTF-8', $value) if utf8::is_utf8($value);
        }
        die "NUL is not allowed in environment values (line $line).\n" if $value =~ /\0/;
        $values{$key} = $value;
    }
    return \%values;
}

sub environment {
    my ($self, $tail) = @_;
    my @args = _args($tail, 0, 3, 'ENV [name | SET name value | UNSET name | EDIT | SAVE file | LOAD file | RELOAD | RESET]');
    if (!@args) { print env_text(); return; }
    my $command = shift @args;
    if ($command eq 'SET') {
        die "Usage: ENV SET name value\n" unless @args == 2;
        my ($key, $value) = @args;
        _env_key($key);
        die "NUL is not allowed in environment values.\n" if $value =~ /\0/;
        $value = encode('UTF-8', $value) if utf8::is_utf8($value);
        $self->_confirm_destructive("Replace environment variable '$key'")
            if exists $ENV{$key} && $ENV{$key} ne $value;
        $ENV{$key} = $value;
    }
    elsif ($command eq 'UNSET') {
        die "Usage: ENV UNSET name\n" unless @args == 1;
        my $key = _env_key($args[0]);
        $self->_confirm_destructive("Remove environment variable '$key'") if exists $ENV{$key};
        delete $ENV{$key};
    }
    elsif ($command eq 'SAVE') {
        die "Usage: ENV SAVE file\n" unless @args == 1;
        $self->_confirm_destructive("Overwrite file '$args[0]'") if -e $args[0] || -l $args[0];
        _write_text($args[0], env_text());
        $self->{env_filename} = File::Spec->rel2abs($args[0]);
        print "Environment saved.\n";
    }
    elsif ($command eq 'LOAD' || $command eq 'RELOAD') {
        die "Usage: ENV $command" . ($command eq 'LOAD' ? ' file' : ' [file]') . "\n"
            if @args > 1 || ($command eq 'LOAD' && !@args);
        my $path = @args ? $args[0] : $self->{env_filename};
        die "No environment file yet. Use ENV LOAD file or ENV SAVE file first.\n" unless defined $path;
        my $values = _parse_env(_read_text($path));
        $self->_confirm_environment($values);
        %ENV = %$values;
        $self->{env_filename} = File::Spec->rel2abs($path);
        print "Environment loaded.\n";
    }
    elsif ($command eq 'EDIT') {
        die "Usage: ENV EDIT\n" if @args;
        my $before = env_text();
        my $after = $self->_edit_text($before, 'environment.env');
        my $values = _parse_env($after);
        $self->_confirm_environment($values);
        %ENV = %$values;
        print $before eq $after ? "Environment unchanged.\n" : "Environment updated.\n";
    }
    elsif ($command eq 'RESET') {
        die "Usage: ENV RESET\n" if @args;
        $self->_confirm_environment($self->{initial_env});
        %ENV = %{ $self->{initial_env} };
        print "Startup environment restored.\n";
    }
    else {
        my ($key) = _args($tail, 1, 1, 'ENV name');
        die "Environment name '$key' is not set.\n" unless exists $ENV{$key};
        print env_text({$key => $ENV{$key}});
    }
}

sub auto_mode {
    my ($self, $tail) = @_;
    my @args = _args($tail, 0, 2, 'AUTO [start [step]], AUTO OFF, or AUTO ECHO ON|OFF');
    if (@args && $args[0] eq 'ECHO') {
        die "Usage: AUTO ECHO ON|OFF\n" unless @args == 2 && $args[1] =~ /\A(?:ON|OFF)\z/;
        $self->{auto_echo} = $args[1] eq 'ON' ? 1 : 0;
        print 'AUTO echo ', ($self->{auto_echo} ? 'on' : 'off'), ".\n";
        return;
    }
    if (@args == 1 && $args[0] eq 'OFF') {
        delete $self->{auto};
        print "AUTO off.\n";
        return;
    }
    my @numbers = $self->numbers;
    my $step = @args > 1 ? _number($args[1]) : 5;
    my $start = @args ? _number($args[0]) : (@numbers ? $numbers[-1] + $step : $step);
    _number($start);
    $start += $step while $start <= $max_line && exists $self->{lines}{$start};
    die "No room for AUTO lines.\n" if $start > $max_line;
    $self->{auto} = { next => $start, step => $step };
    print "AUTO $start, step $step. AUTO OFF, Ctrl-C, or Ctrl-D ends entry.\n";
}

sub auto_store {
    my ($self, $source) = @_;
    die "AUTO source cannot contain NUL bytes or bare carriage returns.\n" if $source =~ /[\r\0]/;
    my $literal = $source =~ s/\A:(?:[ \t])?//;
    my @source = split /\n/, $source, -1;
    # A complete pasted/continued block is already Perl source. Preserve its
    # internal syntax. Single-line input gets the usual semicolon convenience.
    $source[0] = _typed_source($source[0]) if @source == 1 && !$literal;
    my %lines = %{ $self->{lines} };
    my ($next, $step) = @{ $self->{auto} }{qw(next step)};
    my @stored;
    for my $code (@source) {
        $next += $step while $next <= $max_line && exists $lines{$next};
        die "AUTO would exceed $max_line; nothing stored. Use AUTO OFF or choose a new start.\n" if $next > $max_line;
        push @stored, "$next $code\n";
        $lines{$next} = $code;
        $next += $step;
    }
    $self->_replace(\%lines);
    $next += $step while $next <= $max_line && exists $lines{$next};
    if ($next > $max_line) { delete $self->{auto}; }
    else { $self->{auto}{next} = $next; }
    print @stored if $self->{auto_echo};
    print "AUTO off: reached maximum line number.\n" unless $self->{auto};
}

sub input_needs_more {
    my ($self, $source) = @_;
    return 0 if $self->{auto} && $source =~ /\A:/;
    my $more = App::AnteREPL::Shorthand->needs_more($source, sub { $self->_has_function($_[0]) });
    return $more if defined $more;
    return needs_more($source);
}

sub _has_function {
    my ($self, $name) = @_;
    no strict 'refs';
    return defined &{ $self->{workspace} . '::' . $name };
}

sub reset_workspace {
    $_[0]->_confirm_destructive('Discard live workspace variables and functions');
    $_[0]->{workspace} = 'App::AnteREPL::Workspace::S' . ++$next_workspace;
}

sub function_names {
    my ($self) = @_;
    my $package = $self->{workspace} . '::';
    no strict 'refs';
    return sort grep { defined &{ $package . $_ } } keys %{$package};
}

sub evaluate {
    my ($self, $code, $stored) = @_;
    my $label = $stored ? 'PERL_ANTE_REPL_program' : 'PERL_ANTE_REPL_prompt';
    my $source = "package $self->{workspace};\n#line 1 \"$label\"\n" . $code . "\n";
    my ($value, $error);
    {
        local $SIG{INT} = sub { die "Interrupted.\n" };
        ($value, $error) = App::AnteREPL::Evaluator::evaluate($source);
    }
    if (length $error) {
        if ($stored) {
            my @numbers = $self->numbers;
            $error =~ s{at PERL_ANTE_REPL_program line ([0-9]+)}{
                $1 >= 1 && $1 <= @numbers
                    ? 'at stored line ' . $numbers[$1 - 1] . " (source line $1)"
                    : "at program source line $1"
            }ge;
        }
        die $error;
    }
    return $value;
}

sub run {
    my ($self) = @_;
    return $self->evaluate($self->source, 1);
}

sub inspect_value {
    my ($self, $command, $expression) = @_;
    die "$command needs a Perl expression.\n" unless $expression =~ /\S/;
    if ($command eq 'DUMP') {
        local $Data::Dumper::Sortkeys = 1;
        print $self->evaluate("Data::Dumper::Dumper(do { $expression\n })", 0);
        return;
    }
    require Devel::Peek;
    require POSIX;
    # Devel::Peek writes to the native stderr descriptor, bypassing tied Perl
    # handles. Redirect that descriptor temporarily so its output joins VRAM.
    my $temporary = File::Temp->new(UNLINK => 1);
    my $saved = POSIX::dup(2);
    die "Cannot preserve stderr: $!\n" unless defined $saved && $saved >= 0;
    unless (defined POSIX::dup2(fileno($temporary), 2)) {
        POSIX::close($saved);
        die "Cannot capture Devel::Peek output: $!\n";
    }
    $expression =~ s/;\s*\z//;
    my $ok = eval { $self->evaluate("Devel::Peek::Dump($expression\n)", 0); 1 };
    my $error = $@;
    my $restored = POSIX::dup2($saved, 2);
    POSIX::close($saved);
    die "Cannot restore stderr: $!\n" unless defined $restored;
    seek($temporary, 0, 0) or die "Cannot rewind peek output: $!\n";
    local $/;
    my $bytes = <$temporary>;
    print decode('UTF-8', $bytes || '');
    die $error unless $ok;
}

sub needs_more {
    my ($source) = @_;
    $source = _expand_short_command($source);
    # Numbered lines and REPL/file/shell commands keep their own input grammar.
    return 0 if $source =~ /\A\s*(?:[0-9]+(?:[\s:]|\z)|!)/;
    return 0 if $source =~ /\A\s*(?:AUTO|ENV|LIST|RUN|EDIT|DEL|DELETE|RENUM|REORDER|UNDO|SAVE|LOAD|IMPORT|EXPORT|NEW|CLEAR|CLS|RECOVER|RESET|FUNCTIONS|STATUS|HELP|QUIT|EXIT|CD|CHDIR)\b/;
    my @stack;
    my %close = (')' => '(', ']' => '[', '}' => '{');
    my $trivia = qr/(?:\s|\#[^\n]*(?:\n|\z))*/;
    my $name = qr/[\p{L}_][\p{L}\p{N}_]*(?:(?:::|')[\p{L}_][\p{L}\p{N}_]*)*/;
    local $@;
    my $position = 0;
    while ($position < length $source) {
        my $rest = substr($source, $position);
        if ($rest =~ /\A\#[^\n]*(?:\n|\z)/ || $rest =~ /\A\s+/) {
            $position += length $&;
            next;
        }
        # Prototype sigils are declarations, not variables: ($) ends with a
        # closing parenthesis, not the special variable $). Skip only the
        # prototype alphabet here; signatures/default expressions still use
        # the normal scanner, and actual $) / $( variables remain untouched.
        if ($rest =~ /\A(?:sub\b$trivia(?:$name$trivia)?|:$trivia prototype\b$trivia)
                \([\$\@%&*+;_\\\[\]\s]*(\)|\z)/x) {
            return 1 unless length $1;
            $position += length $&;
            next;
        }
        if ($rest =~ /\A([\$\@\%](?:\#?[\p{L}_][\p{L}\p{N}_]*(?:::[\p{L}_][\p{L}\p{N}_]*)*|[0-9]+|[^\w\s{]))/) {
            $position += length $1;
            next;
        }
        my $quoted = $rest =~ /\A['"`]/
            || $rest =~ /\A(?:qq|qw|qx|qr|q|m|s|tr|y)\b\s*(?!=>)[^\w\s]/;
        if ($quoted || $rest =~ /\A\//) {
            my ($literal) = extract_quotelike("$rest", '');
            if (defined $literal && length $literal) { $position += length $literal; next; }
            return 1 if $quoted;
        }
        if ($rest =~ /\A[\p{L}_][\p{L}\p{N}_]*/) { $position += length $&; next; }
        my $char = substr($source, $position++, 1);
        if ($char =~ /[({\[]/) { push @stack, $char; }
        elsif (exists $close{$char}) {
            return 0 unless @stack && pop(@stack) eq $close{$char}; # Let Perl report a mismatch.
        }
    }
    return @stack ? 1 : 0;
}

sub _args {
    my ($tail, $min, $max, $usage) = @_;
    my @args = shellwords($tail);
    die "Usage: $usage\n" if @args < $min || @args > $max || (length($tail) && !@args);
    return @args;
}

sub help {
    return <<'HELP';
PERL ANTE REPL V0.1 / App::AnteREPL
All REPL commands and subcommands must be uppercase, including DUMP and PEEK.
Perl keywords/functions retain their meaning. List shorthand is described below.
A bareword error matching a command gives an uppercase spelling hint instead.
Valid Perl keywords and user functions keep their normal meaning.
Quote filenames and values containing spaces.

SHORTCUTS (one uppercase letter, optionally followed by a digit)
  A    AUTO             A0   AUTO OFF
  A1   AUTO ECHO ON      A2   AUTO ECHO OFF
  C    CLS              C1   CD / CHDIR
  D    DUMP             D1   DEL / DELETE
  E    EVAL             E1   EDIT              E2   EXPORT
  F    FUNCTIONS        H    HELP              I    IMPORT
  L    LIST             L1   LOAD
  L2   LIST SLOW        L3   LIST PAUSE
  N    NEW / CLEAR      P    PEEK              Q    QUIT / EXIT
  R    RUN              R1   RENUM / REORDER
  R2   RESET            R3   RECOVER
  S    SAVE             S1   STATUS            U    UNDO
  V    ENV              V0   ENV RESET         V1   ENV SET
  V2   ENV UNSET        V3   ENV EDIT / EDIT ENV
  V4   ENV SAVE         V5   ENV LOAD          V6   ENV RELOAD

  Arguments keep their meaning. Examples: E say "hi", L 5-20,
  L2 5-20 (LIST 5-20 SLOW), C1 .., V1 NAME "value", S demo.pl, Q!.
  Space separates arguments: L1 loads a file; L 1 lists line 1.
  Shortcuts are not expanded inside Perl
  code or stored source. Full names still work. E also accepts definition tags.

CONFIRMATION FOR DESTRUCTIVE SHORTCUTS
  A shortcut that discards/replaces state asks Continue? [y/N]. Only y or yes
  approves. Enter, No, Ctrl-D, or Esc (screen mode) cancels; Ctrl-C interrupts.
  Add ! to skip confirmation: D1! 10-30, R2!, S! demo.pl, Q!.
  Supported force forms: C! D1! E1! E2! I! L1! N! Q! R1! R2! R3! S! U!
  V! V0! V1! V2! V3! V4! V5! V6!; E! for shorthand definitions only.
  New files and new values do not ask; replacements do. Q always asks.
  Editors prepare changes first, then ask before replacing current state.
  Piped input cannot confirm: add ! explicitly; no following line is consumed.
  Full command names retain their existing behavior. Arbitrary Perl in E/EVAL,
  RUN, and shell commands has normal side effects; these are not classified.

IMMEDIATE DEFINITIONS AND LIST SHORTHAND
  E s name body       Define a function: E s triple return 3 * shift.
  E a name values     Assign @name. E ar name values makes an arrayref $name.
  E h name pairs      Assign %name. E hr name pairs makes a hashref $name.
  a one, two, threee  Define @a containing the strings one, two, threee.
  colors red, blue    Define @colors; settings color => blue defines %settings.

  E accepts lowercase definition tags s/a/ar/h/hr, followed by a name and body.
  E s triple return 3 * shift defines triple. EVAL always takes literal Perl.
  For a spaced substitution, type EVAL s /old/new/. E s/old/new/ also stays Perl.
  Names have letters, digits, underscores; no sigil, namespace, or prototype.
  Data definitions with no values make empty containers. A function needs a body.
  Commas separate values; => separates each hash key/value. Trailing comma OK.
  One optional final semicolon is allowed after a data definition.
  Plain words are quoted exactly; decimal numbers stay numbers; undef is undef.
  'quoted text', "interpolated text", $scalar, [nested, lists], and
  {nested => hashes} work. Quote spaces, punctuation, empty text, and leading
  zeroes: "two words", "red-blue", "", "042". No spelling correction occurs.
  Native quotes q{a,b}, qq{hi $name}, qw(one two), qr/pattern/, substitutions,
  and command quotes also work as values, using Perl's normal semantics.
  Quote operators win over word quoting: write "q", "s" for those literal words
  next to delimiters. Other Perl expressions can go in parentheses.
  Parenthesize Perl expressions: (1 + 2), (1..3), ($ENV{HOME}), (\%ENV).
  They use list context in arrays, scalar context for each hash key/value.
  Nothing is executed merely to decide how to interpret input.

  Bare destination lists need a top-level comma or => and AUTO off. Perl keywords
  and existing functions take priority; E a colors red explicitly assigns @colors.
  During AUTO, use explicit E forms; they execute without storing or ending AUTO.
  Values/functions persist between entries. LIST/SAVE do not include them.
  Open quotes/containers continue; Ctrl-N also inserts a line before submission.
  Replacing an existing shorthand destination asks first. Forced examples:
  E! s triple return 4 * shift; E! a colors green; colors! green, blue.
  Functions contain ordinary Perl; approved redefinition still warns normally.
  Outside its five reserved tags, E also evaluates Perl. EVAL always means Perl,
  including function calls named a/ar/h/hr and declarations with prototypes.
  Ambiguous shorthand is rejected with an explanation. Perl expressions and
  function bodies retain Perl errors, warnings, and any side effects performed.

ENTERING AND RUNNING PERL
  Perl code             Execute immediately, unless AUTO is active.
  10 Perl code          Insert/replace line 10; supply a missing final ;.
  10: exact source      Store one literal line without adding a semicolon.
  10                    Delete line 10. Numbers range from 1 to 999999999.
  AUTO [start [step]]   Store unnumbered source; default increment is 5.
                        Default start: 5, or highest existing number plus 5.
                        Existing numbers are skipped. Use LIST to see numbers.
  AUTO ECHO ON|OFF      Echo numbered copies of stored entries; default OFF.
                        This preference persists for the session; it does not
                        start/end AUTO. Your typed text remains visible.
  AUTO OFF              End AUTO. Ctrl-C/Ctrl-D during entry also end AUTO,
                        keeping stored lines and cancelling unfinished input.
  : exact source        In AUTO, store a literal line without continuation.
  RUN                   Execute the whole stored program in numerical order.
  EVAL code             Uppercase only: execute Perl, including during AUTO.
                        EVAL leaves AUTO on. AUTO OFF resumes ordinary input.
                        EVAL do { ... } groups multiline code without storing.
                        Lowercase eval keeps Perl's normal eval semantics.
  EVAL sub name { ... } Define a session function without storing source.
                        Immediate code and RUN can call it. SAVE excludes it.
                        Redefining warns by default and replaces the function.
  FUNCTIONS             List defined names in this workspace, alphabetically.
                        Includes imports; excludes other packages and stubs.
                        Works during AUTO; does not execute or store source.
  ? expression          Evaluate in scalar context and display the result.
  DUMP expression       Data::Dumper output: DUMP $FOO or DUMP \%ENV.
  PEEK expression       Devel::Peek internals: PEEK $FOO or PEEK $FOO, 10.

  Use $x = 1 or our $x for persistent values; my is local to one evaluation.
  say/print display output. RUN shares package variables with immediate input.
  Stored subroutines become callable after RUN; LOAD/LIST do not define them.
  Open quotes, braces, brackets, or parentheses continue on the next row.
  A closed subroutine definition, including ($) or (@), submits with Enter.
  Ctrl-C cancels unfinished input; commands inside it are still Perl text.
  A complete multiline AUTO entry preserves literal source: supply its final ;.
  Numbered and AUTO colon entries stay literal, one physical line at a time.
  Blank input does nothing. Commands remain available during AUTO.
  For heredocs/POD/unusual Perl, use EDIT or literal numbered/colon entries.
  DUMP and PEEK are prompt commands; stored Perl uses the module functions.

LISTING, EDITING, AND RECOVERY
  LIST                  List all source; numbers left-aligned, padded on right.
  LIST 10               List only line 10.
  LIST 10-50            Inclusive range. Also LIST 10-, LIST -50, LIST10-50.
  LIST [range] SLOW     Start slow. PAUSE instead pauses after each screenful.
                        Space: pause/resume; S: speed; Enter: step one row;
                        Q/Esc/Ctrl-C: stop. Other typing/movement ends LIST.
                        Plain/batch mode prints the whole range without pauses.
  EDIT                  Open the program in $EDITOR, then $VISUAL, then vi
                        (notepad on Windows). Editor receives no line numbers.
                        Save and close: changed source becomes 10,20,... .
                        An unchanged file keeps its numbering. EDIT never runs
                        the source; use SAVE afterward to write the real file.
  DEL range             Delete a line/range; DELETE is an alias.
  RENUM [start [step]]  Renumber; defaults are 10 and 10. REORDER is an alias.
  UNDO                  Undo a source edit (last 50), including EDIT or LOAD.
                        No rollback of executed Perl, %ENV, or file writes.
  CLS                   Clear screen and resize bank; keep the
                        stored program, variables, %ENV, and AUTO.
                        No output in a pipe or on a dumb terminal.
  RECOVER               Restore the saved pre-shrink screen, only if it fits.
                        Replaces current screen text; never runs code or
                        changes stored source. Screen mode only. RECOVER has
                        no ! suffix; shortcut R3! bypasses confirmation.
  NEW / CLEAR           Clear source and its filename; retain Perl variables.
  RESET                 Fresh Perl workspace; retain source and live %ENV.
  STATUS                Line count, save status, filename, and AUTO next/step.

FILES
  LOAD file             Read ordinary Perl or numbered PERL ANTE REPL source.
                        Plain source gets numbers 10,20,... . No execution.
                        .bperl files require a valid native header. Legacy
                        BASIC PERL V0.1 headers remain supported.
  IMPORT file           Read plain Perl as an unsaved copy; no save filename.
  SAVE [file]           Save; reuse last SAVE/LOAD filename and format.
                        .pl writes plain source; .bperl writes numbered source.
                        Other extensions retain the current format.
  EXPORT file           Plain Perl plus default pragmas, for standalone use.
                        Initialize any needed variables in the source itself.
  LOAD!, IMPORT!, NEW!, CLEAR!, QUIT!, EXIT!
                        Explicitly discard unsaved source. No other command
                        accepts this ! suffix in its full name. For shortcuts,
                        see CONFIRMATION above. SAVE/EXPORT replace their file.

ENVIRONMENT
  ENV [name]            Display %ENV or one variable as sorted VAR=value lines.
  ENV SET name value    Set a literal value; quote spaces, e.g. 'hello world'.
  ENV UNSET name        Remove a variable. ENV SET name "" sets an empty value.
  EDIT ENV / ENV EDIT   Edit %ENV with the same editor, using VAR=value lines.
                        Save and close to replace live %ENV; removing a line
                        unsets it. Invalid input leaves the environment intact.
  ENV SAVE file         Save an environment snapshot.
  ENV LOAD file         Replace the whole environment from a snapshot file.
  ENV RELOAD [file]     Re-read the last ENV SAVE/LOAD file, or the named file.
  ENV RESET             Restore the environment inherited at startup.

  Direct Perl $ENV{NAME} assignments/deletes also work. Changes reach future
  child commands; they cannot change the parent shell or re-read its changes.
  Files allow blank lines, # comments, optional export, and quotes. Single
  quotes are literal; double quotes allow \n, \r, \t, \\, \", and \xHH.
  No $variable, backtick, or command expansion. Duplicate names/NUL are errors.
  Names exclude whitespace, =, #, quotes, and NUL. ENV subcommand names are
  reserved; inspect SET with DUMP $ENV{SET}. EDIT ENV changes memory;
  ENV SAVE persists it. ENV LOAD/RELOAD replace, rather than merge, %ENV.

SHELL AND EXIT
  ! command             Run a shell command; screen mode captures output with
                        closed stdin. Examples: ! pwd, ! env, ! cat filename.
  !! command            Give an interactive command the real terminal; press
                        Enter afterward to return. Plain mode uses normal I/O.
  CD [directory]        Change this session's directory; CHDIR is an alias.
                        Quote spaces. No argument uses HOME (USERPROFILE on
                        Windows if HOME is unset). Paths are literal.
  chdir '/path'         Ordinary Perl also works, including chdir $ENV{HOME}.
                        ! cd changes only its child shell's directory.
  HELP                  Display this complete reference; pause by screenful.
                        Plain mode prints it all without pauses.
  QUIT / EXIT           Exit on a fresh line; protect unsaved source unless !.
                        Outside AUTO, Ctrl-D also exits if source is saved.
                        Interactive exits print:
                        Thank, we hope something good happens to you today!

SCREEN KEYS
  Arrows                Move through screen text, including LIST output.
  Left at row start     Move to the previous row's end; stop at the first row.
  Enter                 Submit selected row or its complete multiline entry.
                        Rerunning replaces its output directly below the entry;
                        later entries remain while they fit on screen.
                        Cursor follows the new result.
                        No blank spacer is added. Esc goes to fresh input.
  Shift-Enter / Ctrl-N   Insert newline at cursor without submitting the entry.
                        Shift-Enter needs a distinct terminal key sequence;
                        use Ctrl-N if it behaves like ordinary Enter.
  Insert                Toggle insert/overwrite; default is insert.
                        Blinking bar for insert, blinking block for overwrite.
                        The input loop blinks it every half second; terminal
                        cursor-shape support determines bar versus block.
  Backspace / Delete    Remove characters. Tab inserts to a 4-column tab stop.
  Home / End            Start/end of row. PageUp/PageDown traverse screen rows.
  Esc / Ctrl-End        Fresh blank row at bottom. Ctrl-Home: visible top row.
  Ctrl-U / Ctrl-L       Clear current row / redraw screen.
  Ctrl-C                Cancel input/end AUTO, or interrupt running Perl.
                        Show a reminder of QUIT, QUIT!, and Ctrl-D to leave.
  Ctrl-D                End AUTO/cancel input; otherwise exit if source saved.

  The area inside the white border is VRAM: no off-screen rows or columns.
  The single command legend line is outside VRAM. Type a key label and Enter;
  they are commands, not Ctrl-key bindings. H shows every command.
  An 80x24 terminal has 78x21 editable cells. CLS retains border and legend.
  Plain mode uses normal terminal input without this frame or cursor styling.
  Output scrolls old rows away. Long lines wrap; they do not scroll sideways.
  Shrinking crops rows/columns and warns; one inactive pre-shrink copy is kept.
  Growing adds empty cells, without warning or automatic recovery. Enlarge to
  the size named in the warning, then RECOVER if you want the saved copy back.
  Repeated shrinking keeps that first copy until RECOVER or CLS. It is not
  saved on disk. Scroll-off alone makes no backup. A clipped entry cannot run.
  Use EDIT for code too large for the screen. Wide/combining glyphs may misalign.
  Editing screen text alone changes nothing until Enter. Bracketed paste waits
  for Enter. GUI editors need a wait option, e.g. $ENV{EDITOR} = 'code --wait'.

STARTUP
  anterepl [--quiet] [--plain] [program.pl|program.bperl]
  --quiet               Hide the banner. A startup file is loaded, never run.
  --plain               Plain input; --no-readline is an alias.
  --help / -h           This reference. --version prints application version.
  -- filename           Accept a startup filename beginning with a hyphen.
  Native Windows screen mode needs Term::ReadKey and an ANSI-capable terminal.
  Piped input uses plain mode; errors/incomplete or unsaved input exit nonzero.

More examples: https://github.com/oodler577/p5-App-AnteREPL/wiki
Offline manual: perldoc App::AnteREPL
HELP
}

sub dispatch {
    my ($self, $line) = @_;
    $line =~ s/\r?\n\z//;
    return 1 if $line =~ /\A\s*\z/;
    my $definition = App::AnteREPL::Shorthand->explicit($line);
    if (defined $definition) {
        $self->_evaluate_definition($definition);
        return 1;
    }
    local $self->{shortcut_guard};
    if ($line =~ /\A\s*([A-Z][0-9]*)(!?)(?=\s|\z)/ && exists $short_commands{$1}) {
        my ($short, $force) = ($1, $2);
        if ($guarded_shortcuts{$short}) {
            $self->{shortcut_guard} = {label=>$short, force=>$force};
            # The shortcut layer owns confirmation and force. Do not give the
            # long-command parser a new force spelling of its own.
            $line =~ s/\A(\s*\Q$short\E)!/$1/ if $force;
        }
        elsif ($force) {
            die "The ! suffix is supported only by destructive shortcuts and E! definitions.\n";
        }
    }
    $line = _expand_short_command($line);
    if ($line =~ /\A\s*LIST(?=[0-9-])(.*?)\s*\z/) {
        $self->list_program($1);
        return 1;
    }
    if ($line =~ /\A\s*([0-9]+):(?:[ \t]?(.*))?\z/) {
        $self->set_line($1, defined $2 ? $2 : '', 1);
        return 1;
    }
    if ($line =~ /\A\s*([0-9]+)(?:[ \t](.*))?\z/) {
        my ($number, $code) = ($1, $2);
        $self->set_line($number, _typed_source($code));
        return 1;
    }
    if ($line =~ /\A\s*(DUMP|PEEK)\b\s*(.*)\z/s) {
        $self->inspect_value($1, $2);
        return 1;
    }
    if ($line =~ /\A\s*\?\s*(.*)\z/s) {
        my $value = $self->evaluate($1, 0);
        print Data::Dumper->new([$value])->Terse(1)->Indent(1)->Sortkeys(1)->Dump;
        return 1;
    }
    if ($line =~ /\A\s*(!{1,2})\s*(\S.*)\z/) {
        my ($escape, $command) = ($1, $2);
        my @command = $^O eq 'MSWin32' ? ($ENV{COMSPEC} || 'cmd.exe', '/c', $command) : ('/bin/sh', '-c', $command);
        my $status = $self->{screen}
            ? ($escape eq '!!' ? $self->{screen}->external(sub { system @command }, 1) : $self->{screen}->shell(\@command))
            : system @command;
        die "Cannot start shell: $!\n" if $status == -1;
        die "Shell command failed (status $status).\n" if $status;
        return 1;
    }
    if ($line =~ /\A\s*(AUTO|ENV|LIST|RUN|EDIT|DEL|DELETE|RENUM|REORDER|UNDO|SAVE|LOAD|IMPORT|EXPORT|NEW|CLEAR|CLS|RECOVER|RESET|FUNCTIONS|STATUS|HELP|QUIT|EXIT|EVAL|CD|CHDIR)(!?)(?:\s+(.*?))?\s*\z/s) {
        my ($command, $force, $tail) = ($1, $2, defined $3 ? $3 : '');
        die "The ! suffix is only supported by LOAD, IMPORT, NEW, CLEAR, QUIT, and EXIT.\n"
            if $force && $command !~ /\A(?:LOAD|IMPORT|NEW|CLEAR|QUIT|EXIT)\z/;
        if ($command eq 'EVAL') {
            die "EVAL needs Perl code.\n" unless length $tail;
            $self->evaluate($tail, 0);
        }
        elsif ($command eq 'AUTO') { $self->auto_mode($tail); }
        elsif ($command eq 'ENV') { $self->environment($tail); }
        elsif ($command eq 'CD' || $command eq 'CHDIR') { $self->change_directory($tail); }
        elsif ($command eq 'EDIT' && $tail eq 'ENV') { $self->environment('EDIT'); }
        elsif ($command eq 'LIST') {
            $self->list_program($tail);
        }
        elsif ($command eq 'DEL' || $command eq 'DELETE') {
            my ($range) = _args($tail, 1, 1, 'DEL line-or-range');
            $self->delete_range($range);
        }
        elsif ($command eq 'RENUM' || $command eq 'REORDER') {
            my @args = _args($tail, 0, 2, 'RENUM [start [step]]');
            $self->renumber(@args);
        }
        elsif ($command eq 'SAVE') {
            my ($path) = _args($tail, 0, 1, 'SAVE [file]');
            print 'Saved ', $self->save($path), ".\n";
        }
        elsif ($command eq 'LOAD' || $command eq 'IMPORT') {
            my ($path) = _args($tail, 1, 1, "$command file");
            my $count = $command eq 'LOAD' ? $self->load($path, $force) : $self->import_source($path, $force);
            print "Loaded $count lines.\n";
        }
        elsif ($command eq 'EXPORT') {
            my ($path) = _args($tail, 1, 1, 'EXPORT file');
            print 'Exported ', $self->export_source($path), ".\n";
        }
        else {
            _args($tail, 0, 0, $command);
            if ($command eq 'RUN') { $self->run; }
            elsif ($command eq 'EDIT') {
                print $self->edit ? "Program updated; lines numbered 10,20,...\n" : "Program unchanged.\n";
            }
            elsif ($command eq 'UNDO') { $self->undo; print "Program edit undone.\n"; }
            elsif ($command eq 'CLS') { $self->clear_screen; }
            elsif ($command eq 'RECOVER') { $self->recover_screen; }
            elsif ($command eq 'NEW' || $command eq 'CLEAR') { $self->clear($force); }
            elsif ($command eq 'RESET') { $self->reset_workspace; print "Perl workspace reset; program retained.\n"; }
            elsif ($command eq 'FUNCTIONS') {
                my @names = $self->function_names;
                print @names ? join('', map { "$_\n" } @names)
                    : "No functions defined in this workspace.\n";
            }
            elsif ($command eq 'STATUS') {
                my @numbers = $self->numbers;
                print scalar(@numbers), ' lines; ', ($self->dirty ? 'unsaved changes' : 'unchanged'),
                    '; ', (defined $self->{filename} ? $self->{filename} : 'no save filename'), ".\n";
                print "AUTO next $self->{auto}{next}, step $self->{auto}{step}.\n" if $self->{auto};
            }
            elsif ($command eq 'HELP') {
                if ($self->{screen}) { $self->{screen}->list_rows([split /\n/, help()], 0, 'pause', 'HELP'); }
                else { print help(); }
            }
            elsif ($command eq 'QUIT' || $command eq 'EXIT') {
                $self->_confirm_destructive('Exit the REPL and discard its live workspace and any unsaved source');
                $self->_guard('QUIT', $force);
                return 0;
            }
        }
        return 1;
    }
    my $implicit = App::AnteREPL::Shorthand->implicit($line, sub { $self->_has_function($_[0]) });
    if (defined $implicit) {
        die "List shorthand is immediate input. Try E a name values or E h name pairs during AUTO, or A0 first.\n"
            if $self->{auto};
        $self->_evaluate_definition($implicit);
    }
    elsif ($self->{auto}) { $self->auto_store($line); }
    else {
        local $@;
        my $ok = eval { $self->evaluate($line, 0); 1 };
        die $self->_command_case_error($line, $@) unless $ok;
    }
    return 1;
}

sub main {
    my @args = @_;
    my ($quiet, $plain, $filename);
    while (@args) {
        my $arg = shift @args;
        if ($arg eq '--help' || $arg eq '-h') {
            print "Usage: anterepl [--quiet] [--plain] [program.pl|program.bperl]\n\n", help();
            return 0;
        }
        elsif ($arg eq '--version') { print "App::AnteREPL $VERSION (PERL ANTE REPL V$PROGRAM_VERSION)\n"; return 0; }
        elsif ($arg eq '--quiet') { $quiet = 1; }
        elsif ($arg eq '--plain' || $arg eq '--no-readline') { $plain = 1; }
        elsif ($arg eq '--') {
            die "Only one startup file is supported.\n" if defined $filename || @args != 1;
            $filename = shift @args;
        }
        elsif ($arg =~ /^-/ || defined $filename) { die "Usage: anterepl [--quiet] [--plain] [program.bperl]\n"; }
        else { $filename = $arg; }
    }
    binmode STDIN, ':encoding(UTF-8)';
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
    $| = 1;
    my $self = __PACKAGE__->new;
    $self->load($filename, 1) if defined $filename;
    my $interactive = -t STDIN && -t STDOUT;
    $self->{interactive} = $interactive;
    if ($interactive && !$plain && ($ENV{TERM} || '') ne 'dumb') {
        my $screen = eval { App::AnteREPL::Screen->terminal };
        if ($screen) { return $screen->session($self, $quiet); }
        print STDERR "Screen editing unavailable: $@";
        print STDERR "Using plain input without a prompt.\n";
    }
    print "*** PERL ANTE REPL V$PROGRAM_VERSION ***\nType HELP for commands.\n" unless $quiet;
    my $had_error = 0;
    while (1) {
        my ($line, $read_ok);
        {
            local $SIG{INT} = sub { die "Interrupted.\n" };
            $read_ok = eval {
                $line = <STDIN>;
                while (defined $line && $self->input_needs_more($line)) {
                    my $next = <STDIN>;
                    if (!defined $next && $interactive && $self->{auto}) {
                        $line = undef;
                        last;
                    }
                    die "Incomplete Perl entry at end of input.\n" unless defined $next;
                    $line .= $next;
                }
                1;
            };
        }
        if (!$read_ok) {
            my $error = $@;
            print STDERR "AUTO off.\n" if delete $self->{auto};
            print STDERR _input_error($error);
            $had_error = 1;
            next;
        }
        if (!defined $line) {
            STDIN->clearerr if $interactive;
            if ($interactive && $self->{auto}) {
                $self->auto_mode('OFF');
                next;
            }
            if ($self->dirty) {
                print STDERR "Unsaved program. Use SAVE or QUIT! to discard it.\n";
                if ($interactive) { next; }
                return 1;
            }
            last;
        }
        my $continue;
        my $ok = eval { $continue = $self->dispatch($line); 1 };
        if (!$ok) { print STDERR _input_error($@); $had_error = 1; next; }
        if (!$continue) { print "\n" unless $interactive; last; }
    }
    print "\n$FAREWELL\n" if $interactive;
    return $interactive ? 0 : $had_error;
}

package App::AnteREPL::Screen;
use Encode qw(decode FB_DEFAULT);
use Time::HiRes qw(time);
our $active;

sub new {
    return bless { rows => [{ text => '' }], row => 0, col => 0, top => 0,
        left => 0, width => 80, height => 24, serial => 0, insert => 1 }, $_[0];
}

sub terminal {
    my ($class) = @_;
    my $self = $class->new;
    open $self->{in}, '<&', \*STDIN or die "Cannot duplicate terminal input: $!\n";
    open $self->{out}, '>&', \*STDOUT or die "Cannot duplicate terminal output: $!\n";
    open $self->{err}, '>&', \*STDERR or die "Cannot duplicate terminal errors: $!\n";
    binmode $self->{in}, ':raw';
    binmode $self->{out}, ':encoding(UTF-8)';
    $self->{out}->autoflush(1);
    if (eval { require Term::ReadKey; 1 }) { $self->{backend} = 'readkey'; }
    else {
        die "Install Term::ReadKey for native Windows screen editing (cpanm Term::ReadKey).\n" if $^O eq 'MSWin32';
        require POSIX;
        $self->{backend} = 'posix';
        my $saved = POSIX::Termios->new;
        $saved->getattr(fileno($self->{in})) or die "Cannot read terminal settings: $!\n";
        $self->{saved_term} = $saved;
        my $raw = POSIX::Termios->new;
        $raw->getattr(fileno($self->{in}));
        $raw->setlflag($raw->getlflag & ~(POSIX::ICANON() | POSIX::ECHO() | POSIX::ECHONL()));
        $raw->setiflag($raw->getiflag & ~POSIX::IXON());
        $raw->setcc(POSIX::VMIN(), 1);
        $raw->setcc(POSIX::VTIME(), 0);
        $self->{raw_term} = $raw;
        eval { require 'sys/ioctl.ph'; $self->{winsize} = &TIOCGWINSZ if defined &TIOCGWINSZ; };
    }
    return $self;
}

sub dimensions {
    my ($self) = @_;
    return unless $self->{in};
    my ($width, $height);
    if ($self->{backend} eq 'readkey') {
        ($width, $height) = eval { Term::ReadKey::GetTerminalSize($self->{out}) };
    }
    elsif ($self->{winsize}) {
        my $size = pack('S4', 0, 0, 0, 0);
        ($height, $width) = unpack('S4', $size) if ioctl($self->{in}, $self->{winsize}, $size);
    }
    $self->terminal_size($width || $self->{terminal_width} || 80,
        $height || $self->{terminal_height} || 24);
}

sub terminal_size {
    my ($self, $width, $height) = @_;
    my ($old_width, $old_height) = @{$self}{qw(terminal_width terminal_height)};
    my $framed = $width >= 3 && $height >= 4;
    @{$self}{qw(terminal_width terminal_height framed)} = ($width, $height, $framed);
    delete $self->{last_frame} if !defined $old_width || $old_width != $width || $old_height != $height;
    # Keep the reservation even when too small to draw it, so enlarging a tiny
    # terminal never reduces VRAM when the frame becomes visible again.
    my ($inner_width, $inner_height) = ($width > 2 ? $width - 2 : 1, $height > 3 ? $height - 3 : 1);
    if (!$self->{size_seen}++) {
        @{$self}{qw(width height)} = ($inner_width, $inner_height);
        $self->_fit;
    }
    else { $self->resize($inner_width, $inner_height, $old_width, $old_height); }
}

# Only these rows are active screen memory. There is no off-screen viewport.
# Soft rows wrap one source line; group joins explicit multiline input.
sub _discard_rows {
    my ($self, $start, $count) = @_;
    return unless $count;
    my @gone = splice @{ $self->{rows} }, $start, $count;
    my %groups = map { $_->{group} ? ($_->{group} => 1) : () } @gone;
    $_->{clipped} = 1 for grep { $_->{group} && $groups{$_->{group}} } @{ $self->{rows} };
    if ($start == 0 && $self->{rows}[0] && delete $self->{rows}[0]{soft}) {
        $self->{rows}[0]{clipped} = 1;
    }
    elsif ($start && $gone[0]{soft} && $self->{rows}[$start - 1]) {
        $self->{rows}[$start - 1]{clipped} = 1;
    }
    for my $key (qw(row output_row data_row)) {
        next unless defined $self->{$key};
        my $old = $self->{$key};
        $self->{data_lost} = 1 if $key eq 'data_row' && $old >= $start && $old < $start + $count;
        $self->{$key} -= $count if $old >= $start + $count;
        $self->{$key} = $start if $old >= $start && $old < $start + $count;
        $self->{$key} = $#{ $self->{rows} } if $self->{$key} > $#{ $self->{rows} };
        $self->{$key} = 0 if $self->{$key} < 0;
    }
}

sub _fit {
    my ($self) = @_;
    my ($w, $h) = @{$self}{qw(width height)};
    for (my $i = 0; $i < @{ $self->{rows} }; ++$i) {
        my $row = $self->{rows}[$i];
        next unless length($row->{text}) > $w
            || ($self->{row} == $i && $self->{col} >= $w);
        my $tail = substr($row->{text}, $w, length($row->{text}), '');
        my $next = $self->{rows}[$i + 1];
        if ($next && $next->{soft}) {
            $next->{text} = $tail . $next->{text};
            $self->{col} += length $tail if $self->{row} == $i + 1;
            $self->{data_col} += length $tail if defined $self->{data_row} && $self->{data_row} == $i + 1;
        }
        else {
            my %copy = %$row;
            delete $copy{list_width};
            splice @{ $self->{rows} }, $i + 1, 0, { %copy, text => $tail, soft => 1 };
            ++$self->{$_} for grep { defined $self->{$_} && $self->{$_} > $i } qw(row output_row data_row);
        }
        if ($self->{row} == $i && $self->{col} >= $w) {
            ++$self->{row}; $self->{col} -= $w;
        }
        if (defined $self->{data_row} && $self->{data_row} == $i && $self->{data_col} >= $w) {
            ++$self->{data_row}; $self->{data_col} -= $w;
        }
        $self->{output_row} = $self->{row} if defined $self->{output_row};
    }
    my $excess = @{ $self->{rows} } - $h;
    if ($excess > 0) {
        my $head = $self->{row} - $h + 1;
        $head = 0 if $head < 0;
        $head = $excess if $head > $excess;
        $self->_discard_rows(0, $head);
        $self->_discard_rows($h, @{ $self->{rows} } - $h) if @{ $self->{rows} } > $h;
    }
    $self->{col} = length($self->{rows}[$self->{row}]{text})
        if $self->{col} > length($self->{rows}[$self->{row}]{text});
    $self->{top} = $self->{left} = 0;
}

sub resize {
    my ($self, $width, $height, $terminal_width, $terminal_height) = @_;
    return if $width < 1 || $height < 1;
    return if $width == $self->{width} && $height == $self->{height};
    my $shrink = $width < $self->{width} || $height < $self->{height};
    if ($shrink) {
        # Keep the first unclaimed snapshot through repeated resize events.
        $self->{resize_bank} ||= { width=>$self->{width}, height=>$self->{height},
            terminal_width=>$terminal_width || $self->{width},
            terminal_height=>$terminal_height || $self->{height},
            row=>$self->{row}, col=>$self->{col}, rows=>[map { +{%$_} } @{ $self->{rows} }] };
    }
    @{$self}{qw(width height top left)} = ($width, $height, 0, 0);
    delete $self->{last_frame};
    return unless $shrink; # Growing adds empty cells; never restores the bank.
    my %groups;
    for my $i (0 .. $#{ $self->{rows} }) {
        my $row = $self->{rows}[$i];
        next unless length($row->{text}) > $width;
        substr($row->{text}, $width) = '';
        $row->{clipped} = 1;
        $groups{$row->{group}} = 1 if $row->{group};
    }
    $_->{clipped} = 1 for grep { $_->{group} && $groups{$_->{group}} } @{ $self->{rows} };
    $self->_discard_rows($height, @{ $self->{rows} } - $height) if @{ $self->{rows} } > $height;
    $self->{col} = $width - 1 if $self->{col} >= $width;
    $self->{data_lost} = 1 if defined $self->{data_row};
    delete @{$self}{qw(output_row output_owner)};
    $self->fresh(1);
    my $bank = $self->{resize_bank};
    $self->append("# Screen clipped; RECOVER at $bank->{terminal_width}x$bank->{terminal_height}.\n");
}

sub recover_display {
    my ($self, $repl) = @_;
    my $bank = $self->{resize_bank} or die "No saved screen. RECOVER follows a terminal shrink.\n";
    die "Enlarge the terminal to at least $bank->{terminal_width}x$bank->{terminal_height}, then RECOVER.\n"
        if $self->{width} < $bank->{width} || $self->{height} < $bank->{height};
    $repl->_confirm_destructive('Replace the visible screen with its saved resize recovery copy') if $repl;
    $self->{rows} = [map { +{%$_} } @{ $bank->{rows} }];
    @{$self}{qw(row col top left)} = ($bank->{row}, $bank->{col}, 0, 0);
    delete @{$self}{qw(resize_bank output_row output_owner last_frame)};
    $self->{keep_cursor} = 1;
    $self->render;
}

sub enter {
    my ($self) = @_;
    if ($self->{backend} eq 'readkey') { Term::ReadKey::ReadMode('cbreak', $self->{in}); }
    else { $self->{raw_term}->setattr(fileno($self->{in}), POSIX::TCSANOW()); }
    $self->{entered} = 1;
    delete $self->{last_frame};
    $active = $self;
    print {$self->{out}} "\e[?1049h\e[?2004h\e[2J";
    $self->render;
}

sub leave {
    my ($self) = @_;
    return unless delete $self->{entered};
    print {$self->{out}} "\e[?2004l\e[0 q\e[?25h\e[?1049l";
    if ($self->{backend} eq 'readkey') { Term::ReadKey::ReadMode('restore', $self->{in}); }
    else { $self->{saved_term}->setattr(fileno($self->{in}), POSIX::TCSANOW()); }
}

END { eval { $active->leave if $active; }; }

sub fresh {
    my ($self, $bottom) = @_;
    return if delete $self->{keep_cursor};
    my $in_place = !$bottom && defined $self->{output_row};
    my $row = $in_place ? $self->{output_row} : $#{ $self->{rows} };
    if ($in_place) {
        if (length $self->{rows}[$row]{text}) {
            ++$row;
            push @{ $self->{rows} }, { text => '' } if $row == @{ $self->{rows} };
        }
        elsif ($row < $#{ $self->{rows} }
            && ($self->{rows}[$row]{output_for} || 0) == $self->{output_owner}) {
            # append's final blank row is a cursor position, not a separator.
            # Preserve actual blank output rows and the following entry itself.
            splice @{ $self->{rows} }, $row, 1;
        }
        if ($self->{rows}[$row]{text} eq ''
            && ($self->{rows}[$row]{output_for} || 0) == $self->{output_owner}) {
            $self->{rows}[$row] = { text => '' };
        }
    }
    else {
        push @{ $self->{rows} }, { text => '' } if length $self->{rows}[$row]{text};
        $row = $#{ $self->{rows} };
        $self->{rows}[$row] = { text => '' };
    }
    $self->{row} = $row;
    $self->{col} = 0;
    $self->{left} = 0;
    delete @{$self}{qw(output_row output_owner)};
    $self->_fit;
}

sub start_output {
    my ($self, $first, $last) = @_;
    my $owner = $self->{rows}[$first]{entry_id} || ++$self->{serial};
    for my $index ($first .. $last) {
        $self->{rows}[$index]{entry_id} = $owner;
        delete $self->{rows}[$index]{output_for};
    }
    my $row = $last + 1;
    splice @{ $self->{rows} }, $row, 1
        if $self->{rows}[$row] && $self->{rows}[$row]{soft} && $self->{rows}[$row]{text} eq '';
    my $end = $row;
    ++$end while $end < @{ $self->{rows} }
        && ($self->{rows}[$end]{output_for} || 0) == $owner;
    splice @{ $self->{rows} }, $row, $end - $row;
    my $next = $self->{rows}[$row];
    # Reuse a blank input row; preserve subsequent commands and their output.
    unless ($next && $next->{text} eq '' && !$next->{group}
        && !$next->{entry_id} && !$next->{output_for}) {
        splice @{ $self->{rows} }, $row, 0, { text => '' };
    }
    $self->{rows}[$row]{output_for} = $owner;
    @{$self}{qw(row col left output_row output_owner)} = ($row, 0, 0, $row, $owner);
    $self->_fit;
}

sub clear_display {
    my ($self) = @_;
    $self->{rows} = [{ text => '' }];
    @{$self}{qw(row col top left)} = (0, 0, 0, 0);
    delete @{$self}{qw(list_status output_row output_owner resize_bank keep_cursor last_frame)};
    $self->render;
}

sub append {
    my ($self, $text) = @_;
    my $row = defined $self->{output_row} ? $self->{output_row} : $#{ $self->{rows} };
    $text =~ s/\r\n/\n/g;
    $text =~ s/\e\][^\a]*(?:\a|\e\\)//g;
    $text =~ s/\e\[[0-?]*[ -\/]*[\@-~]//g;
    $text =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/?/g;
    for my $part (split /(\n|\r|\t)/, $text) {
        if ($part eq "\n") {
            if ($self->{rows}[$row]{soft} && $self->{rows}[$row]{text} eq '') {
                delete $self->{rows}[$row]{soft};
                next;
            }
            my $next = { text => '' };
            $next->{output_for} = $self->{output_owner} if $self->{output_owner};
            splice @{ $self->{rows} }, ++$row, 0, $next;
        }
        elsif ($part eq "\r") { $self->{rows}[$row]{text} = ''; }
        elsif ($part eq "\t") { $self->{rows}[$row]{text} .= ' ' x (8 - length($self->{rows}[$row]{text}) % 8); }
        else { $self->{rows}[$row]{text} .= $part; }
    }
    $self->{output_row} = $row if defined $self->{output_row};
    $self->{row} = $row;
    $self->{col} = length $self->{rows}[$row]{text};
    $self->{left} = 0;
    $self->_fit;
    $self->render if $self->{entered};
}

sub render {
    my ($self) = @_;
    $self->dimensions;
    $self->_fit;
    return unless $self->{entered};
    my ($h, $w) = ($self->{height}, $self->{width});
    my $framed = $self->{framed};
    my $edge = "\e[97;40m";
    my $normal = "\e[0m";
    my $frame = "\e[?25l\e[H$normal";
    $frame .= "\e[2J" if !$framed && $self->{terminal_width};
    if ($framed) {
        my $top = "\x{2500}" x $w;
        substr($top, 0, 6) = ' VRAM ' if $w >= 6;
        $frame .= "\e[2K$edge\x{250c}$top\x{2510}$normal";
    }
    for my $offset (0 .. $h - 1) {
        my $row = $self->{rows}[$offset];
        my $text = $row ? $row->{text} : '';
        $text = $self->{list_status} if $self->{list_status}
            && $offset == $self->{row} && $text eq '';
        $text = substr($text, 0, $w);
        $frame .= "\e[" . ($offset + 1 + !!$framed) . ";1H\e[2K";
        $frame .= $framed
            ? "$edge\x{2502}$normal" . $text . (' ' x ($w - length $text)) . "$edge\x{2502}$normal"
            : $text;
    }
    if ($framed) {
        $frame .= "\e[" . ($h + 2) . ";1H\e[2K$edge\x{2514}" . ("\x{2500}" x $w) . "\x{2518}$normal";
        my @legend = $self->legend_lines;
        for my $i (0 .. $#legend) {
            my $text = $legend[$i];
            $text =~ s/(\A|  )([A-Z][0-9]*)(?= |\z)/$1\e[7m$2\e[27m/g;
            $frame .= "\e[" . ($h + 3 + $i) . ";1H\e[2K$text$normal";
        }
    }
    $frame .= "\e[" . ($self->{row} + 1 + !!$framed) . ';' . ($self->{col} + 1 + !!$framed) . 'H';
    $frame .= $self->{insert} ? "\e[6 q" : "\e[2 q";
    my $now = $self->_cursor_time;
    if (!defined $self->{last_frame} || $self->{last_frame} ne $frame) {
        $self->{last_frame} = $frame;
        $self->{cursor_epoch} = $now;
        $self->{cursor_visible} = !$self->{list_status};
        print {$self->{out}} $frame . ($self->{cursor_visible} ? "\e[?25h" : '');
        return;
    }
    return if $self->{list_status};
    my $visible = int(($now - $self->{cursor_epoch}) / 0.5) % 2 ? 0 : 1;
    return if $visible == $self->{cursor_visible};
    $self->{cursor_visible} = $visible;
    print {$self->{out}} $visible ? "\e[?25h" : "\e[?25l";
}

sub _cursor_time { time }

sub legend_lines {
    my ($self) = @_;
    my @rows;
    for my $items (
        ['H Help', 'Q Quit', 'L List', 'R Run', 'E Eval', 'A Auto',
            'E1 Edit', 'S Save', 'L1 Load', 'C Cls', 'F Subs', 'V Env'],
    ) {
        my $text = '';
        for my $item (@$items) {
            my $next = length $text ? "$text  $item" : $item;
            last if length $next > $self->{terminal_width};
            $text = $next;
        }
        $text = substr($items->[0], 0, 1) unless length $text;
        push @rows, $text;
    }
    return @rows;
}

sub list_rows {
    my ($self, $rows, $width, $mode, $label) = @_;
    $label ||= 'LIST';
    return unless @$rows;
    $self->dimensions;
    my $controlled = @$rows > $self->{height} - 1 || $mode ne 'normal';
    my ($slow, $paused, $stop, $page_count, $cancelled) = ($mode eq 'slow', 0, 0, 0, 0);
    local $SIG{INT} = sub { $stop = $cancelled = 1 };
    my $ok = eval {
        LINE: for my $index (0 .. $#$rows) {
            last if $stop;
            $self->{list_status} = "$label " . ($slow ? 'slow' : 'normal') . ' | Space pause | S speed | Q stop' if $controlled;
            $self->append($rows->[$index] . "\n");
            # Remember which spaces belong to LIST's number column so editing
            # and resubmitting a listed row never accumulates source indentation.
            my $listed = $self->{row} - 1;
            --$listed while $listed > 0 && $self->{rows}[$listed]{soft};
            $self->{rows}[$listed]{list_width} = $width if $listed >= 0;
            ++$page_count;
            next if !$controlled || $index == $#$rows;
            $paused = 1 if $mode eq 'pause' && $page_count >= $self->{height} - 1;
            my $until = time + ($slow ? 0.25 : 0.03);
            while (!$stop) {
                $self->{list_status} = $paused
                    ? "$label paused | Space resume | Enter step | S speed | Q stop"
                    : "$label " . ($slow ? 'slow' : 'normal') . ' | Space pause | S speed | Q stop';
                $self->render;
                my $remaining = $until - time;
                last if !$paused && $remaining <= 0;
                my $key = $self->key($paused ? 0.1 : $remaining);
                next if !ref($key) && $key eq 'NONE';
                if ((!ref($key) && $key =~ /\A(?:CANCEL|EOF|ESC)\z/) || (ref($key) && $key->[0] eq 'TEXT' && $key->[1] =~ /\A[qQ]\z/)) {
                    $cancelled = 1 if !ref($key) && $key eq 'CANCEL';
                    $stop = 1;
                    last;
                }
                if (ref($key) && $key->[0] eq 'TEXT' && $key->[1] eq ' ') {
                    $paused = !$paused;
                    $page_count = 0 unless $paused;
                }
                elsif (ref($key) && $key->[0] eq 'TEXT' && $key->[1] =~ /\A[sS]\z/) { $slow = !$slow; }
                elsif (!ref($key) && $key eq 'ENTER') { $paused = 1; $page_count = 0; next LINE; }
                else {
                    # A new command or a cursor movement ends LIST and is
                    # handed back to the editor, rather than eating typed input.
                    push @{ $self->{pending_keys} }, $key;
                    last LINE;
                }
                $until = time + ($slow ? 0.25 : 0.03);
            }
        }
        1;
    };
    my $error = $@;
    delete $self->{list_status};
    $self->{out}->clearerr if $self->{out};
    $self->render;
    die $error unless $ok;
    die "Interrupted.\n" if $cancelled;
}

sub byte {
    my ($self, $timeout) = @_;
    # ReadKey's Unix timed read can fall through to blocking getc when a
    # signal interrupts select. Use interruptible byte reads on Unix even
    # when ReadKey handles terminal modes; Windows needs its keyboard API.
    if ($self->{backend} eq 'readkey' && $^O eq 'MSWin32') {
        return Term::ReadKey::ReadKey(defined $timeout ? $timeout : 0, $self->{in});
    }
    if (defined $timeout) {
        my $set = '';
        vec($set, fileno($self->{in}), 1) = 1;
        return undef unless select($set, undef, undef, $timeout) > 0;
    }
    my $count = sysread($self->{in}, my $char, 1);
    return undef unless $count;
    return $char;
}

sub key {
    my ($self, $timeout) = @_;
    return shift @{ $self->{pending_keys} } if $self->{pending_keys} && @{ $self->{pending_keys} };
    my $char = $self->byte($timeout);
    return defined $timeout ? 'NONE' : 'EOF' unless defined $char;
    if ($char eq "\e") {
        my $next = $self->byte(0.08);
        return 'ESC' unless defined $next;
        return 'ESC' unless $next eq '[' || $next eq 'O';
        my $sequence = $next;
        while (length $sequence < 20) {
            my $part = $self->byte(0.08);
            last unless defined $part;
            $sequence .= $part;
            last if $part =~ /[A-Za-z~]/;
        }
        my %keys = ('[A'=>'UP', '[B'=>'DOWN', '[C'=>'RIGHT', '[D'=>'LEFT',
            'OA'=>'UP', 'OB'=>'DOWN', 'OC'=>'RIGHT', 'OD'=>'LEFT',
            '[H'=>'HOME', '[F'=>'END', 'OH'=>'HOME', 'OF'=>'END',
            '[1~'=>'HOME', '[4~'=>'END', '[7~'=>'HOME', '[8~'=>'END',
            '[2~'=>'INSERT', '[3~'=>'DELETE', '[5~'=>'PAGEUP', '[6~'=>'PAGEDOWN',
            '[1;5H'=>'TOP', '[1;5F'=>'BOTTOM', '[27;2;13~'=>'NEWLINE');
        # CSI-u Shift+Enter, including key press/repeat event forms. Ignore
        # release events. No terminal-wide keyboard protocol is enabled here.
        return 'NEWLINE' if $sequence =~ /\A\[13;2(?::[12])?u\z/;
        if ($sequence eq '[200~') {
            my $paste = '';
            while ($paste !~ /\e\[201~\z/) {
                my $byte = $self->byte;
                last unless defined $byte;
                $paste .= $byte;
            }
            $paste =~ s/\e\[201~\z//;
            $paste = decode('UTF-8', $paste, FB_DEFAULT) unless utf8::is_utf8($paste);
            $paste =~ s/\r\n?/\n/g;
            $paste =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]//g;
            return ['PASTE', $paste];
        }
        return $keys{$sequence} || 'IGNORE';
    }
    my %control = ("\r"=>'ENTER', "\n"=>'ENTER', "\x7f"=>'BACKSPACE', "\x08"=>'BACKSPACE',
        "\x03"=>'CANCEL', "\x04"=>'ENDINPUT', "\x0e"=>'NEWLINE',
        "\x15"=>'CLEAR', "\x0c"=>'REDRAW', "\t"=>'TAB');
    return $control{$char} if exists $control{$char};
    return 'IGNORE' if ord($char) < 32;
    if (!utf8::is_utf8($char) && ord($char) >= 128) {
        my $count = ord($char) < 224 ? 2 : ord($char) < 240 ? 3 : 4;
        for (2 .. $count) { my $byte = $self->byte(0.2); last unless defined $byte; $char .= $byte; }
        $char = decode('UTF-8', $char, FB_DEFAULT);
    }
    return ['TEXT', $char];
}

sub edit_key {
    my ($self, $key) = @_;
    $self->_fit;
    my $row = $self->{rows}[ $self->{row} ];
    if (ref $key) {
        my $text = $key->[1];
        if ($key->[0] eq 'PASTE' && $text =~ /\n/) {
            my $group = $row->{group} || ++$self->{serial};
            my ($first, $last) = ($self->{row}, $self->{row});
            --$first while $first && $self->{rows}[$first]{soft};
            ++$last while $self->{rows}[$last + 1] && $self->{rows}[$last + 1]{soft};
            $self->{rows}[$_]{group} = $group for $first .. $last;
            my $before = substr($row->{text}, 0, $self->{col});
            my $after = substr($row->{text}, $self->{col});
            my @parts = split /\n/, $before . $text . $after, -1;
            my %owner = map { exists $row->{$_} ? ($_ => $row->{$_}) : () } qw(entry_id output_for clipped);
            splice @{ $self->{rows} }, $self->{row}, 1, map { {text=>$_, group=>$group, %owner} } @parts;
            $self->{rows}[$self->{row}]{soft} = 1 if $row->{soft};
            $self->{row} += $#parts;
            $self->{col} = length($parts[-1]) - length($after);
        }
        else {
            my $replace = $self->{insert} || $key->[0] eq 'PASTE' ? 0 : length $text;
            substr($row->{text}, $self->{col}, $replace, $text);
            $self->{col} += length $text;
        }
    }
    elsif ($key eq 'UP' || $key eq 'DOWN' || $key eq 'PAGEUP' || $key eq 'PAGEDOWN') {
        my $delta = $key =~ /PAGE/ ? $self->{height} - 1 : 1;
        $delta = -$delta if $key eq 'UP' || $key eq 'PAGEUP';
        $self->{row} += $delta;
        $self->{row} = 0 if $self->{row} < 0;
        $self->{row} = $#{ $self->{rows} } if $self->{row} > $#{ $self->{rows} };
        my $length = length $self->{rows}[ $self->{row} ]{text};
        --$length if $length == $self->{width};
        $self->{col} = $length if $self->{col} > $length;
    }
    elsif ($key eq 'LEFT') {
        if ($self->{col} > 0) { --$self->{col}; }
        elsif ($self->{row} > 0) {
            --$self->{row};
            $self->{col} = length $self->{rows}[$self->{row}]{text};
            --$self->{col} if $self->{col} == $self->{width};
        }
    }
    elsif ($key eq 'RIGHT') { ++$self->{col} if $self->{col} < length $row->{text}; }
    elsif ($key eq 'HOME') { $self->{col} = 0; }
    elsif ($key eq 'END') {
        $self->{col} = length $row->{text};
        --$self->{col} if $self->{col} == $self->{width};
    }
    elsif ($key eq 'TOP') { $self->{row} = $self->{col} = 0; }
    elsif ($key eq 'BOTTOM' || $key eq 'ESC') { $self->fresh(1); }
    elsif ($key eq 'INSERT') { $self->{insert} = !$self->{insert}; }
    elsif ($key eq 'BACKSPACE') {
        if (!$self->{col} && $self->{row} && $row->{soft}) {
            --$self->{row};
            $row = $self->{rows}[$self->{row}];
            $self->{col} = length $row->{text};
        }
        substr($row->{text}, --$self->{col}, 1, '') if $self->{col} > 0;
    }
    elsif ($key eq 'DELETE') { substr($row->{text}, $self->{col}, 1, '') if $self->{col} < length $row->{text}; }
    elsif ($key eq 'CLEAR') {
        %$row = (text => ''); $self->{col} = 0;
        if ($self->{rows}[$self->{row} + 1] && delete $self->{rows}[$self->{row} + 1]{soft}) {
            $self->{rows}[$self->{row} + 1]{clipped} = 1;
        }
    }
    elsif ($key eq 'NEWLINE') { $self->edit_key(['PASTE', "\n"]); }
    elsif ($key eq 'TAB') { $self->edit_key(['TEXT', ' ' x (4 - $self->{col} % 4)]); }
    $self->_fit;
}

sub entry {
    my ($self) = @_;
    my ($first, $last) = ($self->{row}, $self->{row});
    my $group = $self->{rows}[$first]{group};
    if (defined $group) {
        --$first while $first > 0 && ($self->{rows}[$first - 1]{group} || 0) == $group;
        ++$last while $last < $#{ $self->{rows} } && ($self->{rows}[$last + 1]{group} || 0) == $group;
    }
    --$first while $first > 0 && $self->{rows}[$first]{soft};
    ++$last while $self->{rows}[$last + 1] && $self->{rows}[$last + 1]{soft};
    die "This entry was clipped. Re-enter it, use EDIT, or enlarge and RECOVER a saved screen.\n"
        if grep { $_->{clipped} } @{ $self->{rows} }[$first .. $last];
    --$last if $last > $first && $self->{rows}[$last]{soft} && $self->{rows}[$last]{text} eq '';
    my $text = join('', map { ($_ == $first || $self->{rows}[$_]{soft} ? '' : "\n")
        . $self->{rows}[$_]{text} } $first .. $last);
    if ($self->{rows}[$first]{list_width}) {
        my $width = $self->{rows}[$first]{list_width};
        if (length($text) > $width && substr($text, $width, 1) eq ' '
            && substr($text, 0, $width) =~ /\A([0-9]+) *\z/) {
            $text = $1 . ' ' . substr($text, $width + 1);
        }
    }
    return ($text, $first, $last);
}

sub read_entry {
    my ($self) = @_;
    while (1) {
        $self->render;
        my $key = $self->key(0.1);
        next if !ref($key) && $key eq 'NONE';
        if (!ref($key) && $key eq 'ENTER') {
            my ($text, $first, $last) = $self->entry;
            if ($self->{repl} ? $self->{repl}->input_needs_more($text) : App::AnteREPL::needs_more($text)) {
                my $group = $self->{rows}[$first]{group} || ++$self->{serial};
                $self->{rows}[$_]{group} = $group for $first .. $last;
                # Editing an earlier row of a complete entry must not insert a
                # second copy; incomplete entries continue after their last row.
                splice @{ $self->{rows} }, $last + 1, 0, {text=>'', group=>$group};
                $self->{row} = $last + 1;
                $self->{col} = 0;
                $self->_fit;
                next;
            }
            $self->start_output($first, $last);
            return $text;
        }
        if (!ref($key) && $key eq 'ENDINPUT') {
            if ($self->{repl} && $self->{repl}{auto}) {
                $self->fresh(1);
                return 'AUTO OFF';
            }
            return undef;
        }
        if (!ref($key) && $key eq 'EOF') { return undef; }
        if (!ref($key) && $key eq 'CANCEL') { die "Interrupted.\n"; }
        $self->edit_key($key);
    }
}

sub read_data {
    my ($self, $confirmation) = @_;
    my $row = defined $self->{output_row} ? $self->{output_row} : $#{ $self->{rows} };
    $self->{row} = $row;
    my $start = length $self->{rows}[$row]{text};
    $self->{col} = $start;
    local @{$self}{qw(data_row data_col data_lost)} = ($row, $start, 0);
    while (1) {
        $self->render;
        die "Input was clipped by the screen boundary. Please run the command again.\n" if $self->{data_lost};
        my $key = $self->key(0.1);
        next if !ref($key) && $key eq 'NONE';
        if (!ref($key) && $key eq 'ENTER') {
            my $last = $self->{data_row};
            ++$last while $self->{rows}[$last + 1] && $self->{rows}[$last + 1]{soft};
            my $value = substr($self->{rows}[$self->{data_row}]{text}, $self->{data_col});
            $value .= $self->{rows}[$_]{text} for $self->{data_row} + 1 .. $last;
            $self->{row} = $last;
            $self->{col} = length $self->{rows}[$last]{text};
            $self->{output_row} = $last if defined $self->{output_row};
            $self->append("\n");
            return "$value\n";
        }
        return undef if !ref($key) && ($key eq 'EOF' || $key eq 'ENDINPUT');
        return undef if $confirmation && !ref($key) && $key eq 'ESC';
        die "Interrupted.\n" if !ref($key) && $key eq 'CANCEL';
        if (ref $key) { $key->[1] =~ s/\n/ /g; $self->edit_key($key); }
        elsif ($key eq 'LEFT' || $key eq 'BACKSPACE') {
            if ($self->{row} > $self->{data_row}
                || ($self->{row} == $self->{data_row} && $self->{col} > $self->{data_col})) {
                $self->edit_key($key);
            }
        }
        elsif ($key eq 'HOME') { @{$self}{qw(row col)} = @{$self}{qw(data_row data_col)}; }
        elsif ($key =~ /\A(?:RIGHT|END|DELETE|INSERT|TAB)\z/) { $self->edit_key($key); }
    }
}

sub external {
    my ($self, $code, $pause) = @_;
    $self->leave;
    my $status;
    my $ok = eval {
        local *STDIN;
        local *STDOUT;
        local *STDERR;
        open STDIN, '<&', $self->{in} or die $!;
        open STDOUT, '>&', $self->{out} or die $!;
        open STDERR, '>&', $self->{err} or die $!;
        $status = $code->();
        if ($pause) { print STDOUT "\nPress Enter to return to PERL ANTE REPL."; scalar <STDIN>; }
        1;
    };
    my $error = $@;
    $self->enter;
    die $error unless $ok;
    return $status;
}

sub shell {
    my ($self, $command) = @_;
    require POSIX;
    my $file = File::Temp->new(UNLINK => 1);
    open my $null, '<', File::Spec->devnull or die $!;
    my @saved = map { POSIX::dup($_) } 0 .. 2;
    die "Cannot preserve shell file descriptors: $!\n" if grep { !defined $_ || $_ < 0 } @saved;
    my ($status, $error);
    eval {
        for my $fd (0 .. 2) {
            my $target = $fd ? fileno($file) : fileno($null);
            die "Cannot redirect shell descriptor $fd: $!\n" unless defined POSIX::dup2($target, $fd);
        }
        $status = system @$command;
        1;
    } or $error = $@;
    for my $fd (0 .. 2) { POSIX::dup2($saved[$fd], $fd); POSIX::close($saved[$fd]); }
    seek($file, 0, 0) or die $!;
    local $/;
    my $bytes = <$file>;
    $self->append(decode('UTF-8', $bytes || '', FB_DEFAULT));
    die $error if defined $error;
    return $status;
}

sub session {
    my ($self, $repl, $quiet) = @_;
    local $repl->{interactive} = 1;
    $repl->{screen} = $self;
    local $self->{repl} = $repl;
    $self->enter;
    my $ok = eval {
        local $SIG{TERM} = sub { die "Terminated.\n" };
        local $SIG{HUP} = sub { die "Terminal disconnected.\n" } unless $^O eq 'MSWin32';
        local *STDOUT;
        local *STDERR;
        local *STDIN;
        tie *STDOUT, 'App::AnteREPL::ScreenOutput', $self;
        tie *STDERR, 'App::AnteREPL::ScreenOutput', $self;
        tie *STDIN, 'App::AnteREPL::ScreenInput', $self;
        print "*** PERL ANTE REPL V$App::AnteREPL::PROGRAM_VERSION ***\nType HELP for commands.\n" unless $quiet;
        while (1) {
            my $line;
            my $read_ok;
            {
                local $SIG{INT} = sub { die "Interrupted.\n" };
                $read_ok = eval { $line = $self->read_entry; 1 };
            }
            if (!$read_ok) {
                my $error = $@;
                $self->{out}->clearerr;
                $self->fresh(1);
                print STDERR "AUTO off.\n" if delete $repl->{auto};
                print STDERR App::AnteREPL::_input_error($error);
                next;
            }
            if (!defined $line) {
                if ($repl->dirty) { $self->fresh(1); print STDERR "Unsaved program. Use SAVE or QUIT!.\n"; next; }
                last;
            }
            my $continue;
            my $ran = eval { $continue = $repl->dispatch($line); 1 };
            # Perl/native I/O can move the real cursor after a captured write.
            # Redraw once after each command even when its model is unchanged.
            delete $self->{last_frame};
            if (!$ran) { print STDERR App::AnteREPL::_input_error($@); }
            elsif (!$continue) { last; }
            $self->fresh;
        }
        1;
    };
    my $error = $@;
    $self->leave;
    # Write to the restored terminal, not the screen's captured output. Keep
    # this out of leave(), which also suspends the screen for EDIT and shells.
    print {$self->{out}} "\n";
    print {$self->{out}} "$App::AnteREPL::FAREWELL\n" if $ok;
    delete $repl->{screen};
    die $error unless $ok;
    return 0;
}

package App::AnteREPL::ScreenOutput;
sub TIEHANDLE { bless { screen => $_[1] }, $_[0] }
sub PRINT { my $self = shift; $self->{screen}->append(join(defined $, ? $, : '', @_) . (defined $\ ? $\ : '')); return 1; }
sub PRINTF { my ($self, $format, @args) = @_; $self->{screen}->append(sprintf $format, @args); return 1; }
sub WRITE { my ($self, $buffer, $length, $offset) = @_; my $part = substr($buffer, $offset || 0, $length); $self->{screen}->append($part); return length $part; }
sub FILENO { fileno $_[0]->{screen}{out} }
sub BINMODE { 1 }
sub CLOSE { 1 }

package App::AnteREPL::ScreenInput;
sub TIEHANDLE { bless { screen => $_[1] }, $_[0] }
sub READLINE { $_[0]->{screen}->read_data }
sub FILENO { fileno $_[0]->{screen}{in} }
sub BINMODE { 1 }
sub CLOSE { 1 }

# Keep REPL internals and their lexical variables out of the user's evaluation.
package App::AnteREPL::Evaluator;
use strict;
use warnings;
no strict 'vars';
no warnings 'once';
use feature 'say';

sub evaluate {
    local $@;
    return (scalar(eval $_[0]), $@);
}

1;

__END__

=head1 NAME

App::AnteREPL - BASIC-style program editing with real Perl execution

=head1 SYNOPSIS

    anterepl

    $name = 'world';
    10 say "Hello, $name";
    LIST
    10 say "Hello, $name";
    RUN
    Hello, world
    EDIT
    SAVE hello.bperl
    QUIT

=head1 DESCRIPTION

App::AnteREPL installs the C<anterepl> executable, with the banner
C<*** PERL ANTE REPL V0.1 ***>. It combines
immediate Perl execution with an in-memory program indexed by line numbers.
It requires Perl 5.16 or newer. Type HELP for the command reference.

Install from a release archive with C<cpanm ./App-AnteREPL-0.01.tar.gz>, or
run C<perl Makefile.PL>, C<make test>, and C<make install> in the distribution.
For development without installation, use C<perl -Ilib script/anterepl>.

Numbers are editing addresses, not BASIC labels. RUN concatenates the stored
lines in numeric order and evaluates them together, so blocks, subroutines,
multiline strings, and heredocs work. Stored syntax/runtime errors report the
corresponding numbered line when Perl supplies its source location.

=head1 COMMAND CASE

All AnteREPL commands and subcommands must be uppercase: C<LIST>, C<AUTO OFF>,
C<AUTO ECHO ON>, C<ENV SET>, C<EDIT ENV>, C<LIST SLOW>, C<DUMP>, and C<PEEK>.
Aliases such as C<DELETE>, C<REORDER>, C<CLEAR>, and C<EXIT> follow the same rule.

Lowercase and mixed-case words are not command aliases. Perl's
lowercase C<eval> keeps its normal behavior, and a user-defined C<list> function
can be called normally. If immediate input fails with a bareword error and its
first word matches a REPL command, the interpreter error is replaced with a
short spelling hint, for example:

    cls
    REPL commands must be uppercase; try, "CLS".

The command is not executed automatically. Valid Perl keywords, including
C<eval>, C<chdir>, C<delete>, and C<reset>, retain their normal meaning and
diagnostics. Defined functions keep their own diagnostics too. Unknown names,
explicit C<EVAL> code, and stored source retain normal Perl errors.
Command arguments retain their case, including filenames, environment names,
values, and Perl source. C<ENV set> looks up the variable named C<set>;
C<ENV SET name value> sets a variable.

Immediate definitions and implicit destination lists have the explicit grammar
under L</SHORTCUTS AND SHORTHAND>. Ordinary Perl remains unchanged in numbered
source, LOAD, IMPORT, EDIT, and literal EVAL. The lowercase definition tags
follow C<E> and are distinct from uppercase REPL commands.

=head1 SHORTCUTS AND SHORTHAND

Every command has a shortcut with one uppercase letter and at most one digit.
Full names remain available, and arguments keep the same meaning:

    A   AUTO                 A0  AUTO OFF
    A1  AUTO ECHO ON         A2  AUTO ECHO OFF
    C   CLS                  C1  CD / CHDIR
    D   DUMP                 D1  DEL / DELETE
    E   EVAL                 E1  EDIT                 E2  EXPORT
    F   FUNCTIONS            H   HELP                 I   IMPORT
    L   LIST                 L1  LOAD
    L2  LIST SLOW            L3  LIST PAUSE
    N   NEW / CLEAR          P   PEEK                 Q   QUIT / EXIT
    R   RUN                  R1  RENUM / REORDER
    R2  RESET                R3  RECOVER
    S   SAVE                 S1  STATUS               U   UNDO
    V   ENV                  V0  ENV RESET            V1  ENV SET
    V2  ENV UNSET            V3  ENV EDIT / EDIT ENV
    V4  ENV SAVE             V5  ENV LOAD             V6  ENV RELOAD

C<V> groups environment-variable operations. C<L2 5-20> means
C<LIST 5-20 SLOW>; C<L3 5-20> means C<LIST 5-20 PAUSE>. Separate arguments with
spaces: C<L1 file.pl> loads, while C<L 1> lists line 1. There is no prefix
guessing. Full command names retain their existing behavior.

=head2 Confirmation and force

Destructive shortcuts ask C<Continue? [y/N]> before discarding or replacing
state. Only C<y> or C<yes> approves. Enter, No, Ctrl-D, and Esc in screen mode
cancel; Ctrl-C interrupts. Append C<!> to skip the question:

    D1! 10-30
    R2!
    S! demo.pl
    Q!

The supported force forms are C<C!>, C<D1!>, C<E1!>, C<E2!>, C<I!>, C<L1!>,
C<N!>, C<Q!>, C<R1!>, C<R2!>, C<R3!>, C<S!>, C<U!>, C<V!>, and C<V0!>
through C<V6!>. They protect source replacement/deletion, the live workspace,
screen clearing/recovery, file overwrites, and environment changes. New files
and new values do not ask. Q always asks, even when source is saved, because
exiting also discards the live workspace. Editors prepare their results before
asking to apply replacements. Invalid input and unchanged values do not ask.

Shorthand function/container redefinitions also ask. C<E! s triple return 4 *
shift>, C<E! a colors green>, and C<colors! green, blue> bypass their
questions. New definitions need no confirmation. Declining leaves existing
data intact and does not evaluate a replacement's expressions. Approved
function redefinition retains Perl's usual warning.

Piped input cannot confirm and fails with a hint to append C<!>; it never reads
the next program line as an answer. Full-length commands retain their previous
semantics. Arbitrary code evaluated by E/EVAL or RUN, and shell commands, has
normal side effects; the REPL does not infer whether that code is destructive.

=head2 Explicit immediate definitions

C<E> accepts five lowercase definition tags:

    E s triple return 3 * shift
    say triple 14
    42
    E a colors red, blue
    E ar names Ada, "Grace Hopper"
    E h options color => blue, count => 3
    E hr record name => Ada, tags => [one, two]

These define a function, C<@colors>, C<$names> as an array reference,
C<%options>, and C<$record> as a hash reference, respectively. Names are plain
ASCII identifiers without sigils or namespaces. Omit the values to make an
empty container, for example C<E ar names>. A function must have a body.

Functions contain ordinary Perl, may recurse, and retain normal redefinition
warnings. Open braces support multiline bodies. Prototypes, attributes, package
names, and other advanced declarations belong in literal C<EVAL sub ...>.
C<E s triple return 3 * shift> defines a function. C<E> reserves the five
spaced tags for shorthand; C<EVAL> always takes literal Perl. Thus
C<EVAL s /old/new/> performs a spaced substitution, while C<E s/old/new/>
also remains Perl because it has no spaced tag. Other ordinary Perl, such as
C<E say triple 14>, works directly with E.

Definitions are immediate and persist in the workspace between evaluations.
They do not enter LIST or SAVE, including during AUTO; AUTO remains active.
These are package variables, rather than lexicals limited to one evaluation.

=head2 Named lists with implicit quoting

With AUTO off, a lowercase-leading destination name followed by a top-level
comma-separated list names an array. An arrow selects a hash:

    a one, two, threee
    D \@a
    settings color => blue, count => 3
    D \%settings

The first entry assigns C<@a = ('one', 'two', 'threee')>. Spelling is preserved.
Perl keywords and existing workspace functions take priority over bare
destination names. Explicit C<E a ...> and C<E h ...> definitions select a
destination even if a function has the same name. At least one top-level comma or arrow
is required for the named-list form. C<E a names Ada> handles a one-item
list. During AUTO, a recognized named list is rejected with directions to use an
explicit C<E> definition or leave AUTO. Numbered and file source stay literal.

=head2 The value grammar

Every data form uses the same rules, recursively:

=over 4

=item *

Commas separate items. Hashes require C<< key => value >> for each item. One
trailing comma and one final statement semicolon are allowed. Missing items
and mixed pairs/lists are errors.

=item *

A word consisting of letters, digits, and underscores, beginning with a letter
or underscore, becomes an exact string. The special word C<undef> is Perl undef.
Simple signed decimal numbers, fractions, and exponents remain numbers.

=item *

Single and double quotes have their ordinary Perl meaning, including escapes
and interpolation. Quote spaces, punctuation, empty strings, and leading zeroes:
C<"two words">, C<"red-blue">, C<"">, C<"042">. No spelling correction occurs.
Native quote operators also work directly: C<q{a,b}>, C<qq{hi $name}>,
C<qw(one two)>, C<qr/pattern/>, substitutions, transliterations, and command
quotes. Quoted commas/arrows are never separators. Quote operators take
precedence over implicit words; write C<"q"> or C<"s"> when those words are
literal data next to delimiters. Lists expand in array context; each hash
key/value still receives scalar context. Command quotes execute normally.

=item *

A simple scalar such as C<$count> refers to its live value. Square brackets
construct array references; braces construct hash references. Their contents
follow this same grammar, so C<< [one, {color => blue}] >> needs no word quotes.

=item *

Parentheses mark an explicit Perl expression, for example C<(1 + 2)>, C<(1..3)>,
C<($ENV{HOME})>, or C<(\%ENV)>. Expressions have list context in arrays and
scalar context in each hash key/value position. Hash duplicate keys keep the
last value, as in Perl. Nested array/hash literals cannot be hash keys.

=back

Unquoted punctuation or multiword values are not guessed. An ambiguous entry
gets a friendly explanation and is rejected before evaluation. Nothing is
compiled or run to classify input. Once accepted, explicit Perl expressions
and function bodies execute once with normal warnings/errors and side effects;
those effects are not rolled back. EVAL always accepts literal Perl; E reserves
its five shorthand tags and otherwise evaluates Perl. Stored programs are never
rewritten as shorthand.

=head2 Function calls without parentheses

Use ordinary Perl call syntax when the function is already defined:

    EVAL sub triple { 3 * shift }
    say triple 14
    42

Prototypes keep Perl's usual parsing rules, including scalar, list, and block
arguments. AnteREPL does not insert or remove call parentheses:

    EVAL sub scalar_arg ($) { 3 * $_[0] }
    say scalar_arg 14
    42
    EVAL sub total (@) { my $n = 0; $n += $_ for @_; $n }
    say total 1, 2, 3
    6
    EVAL sub apply (&@) { my $f = shift; map { $f->($_) } @_ }
    say join q{,}, apply { $_[0] * 2 } 1, 2, 3
    2,4,6

The parentheses in prototype declarations and code-reference calls above are
intentional. Keep parentheses where Perl requires them or where they clarify
argument grouping. A prototype declared by RUN is also available to later
immediate calls.

=head1 AUTO ENTRY

AUTO lets you enter program source without typing editing numbers:

    AUTO
    say "hi"
    say "there!"
    AUTO OFF
    LIST
    5  say "hi";
    10 say "there!";

The default increment is 5. With an existing program, AUTO starts 5 past its
highest number. C<AUTO 100> chooses a start; C<AUTO 100 10> also chooses a step.
Occupied numbers are skipped, so AUTO never silently overwrites stored lines.
Explicitly numbered entries still edit or delete the indicated line.

AUTO OFF returns to immediate execution. Ctrl-C or Ctrl-D while entering text
also ends AUTO and discards only the unfinished entry, retaining stored source.
Ctrl-D leaves the REPL running when AUTO is active. In plain terminal mode,
use Ctrl-D on an empty physical input line; piped EOF still ends batch input.
Blank entries do nothing. LIST,
RUN, EDIT, SAVE, ENV, and other commands remain available; C<EVAL code> executes
immediately while AUTO is active. STATUS shows the next number and step.

Single-line entries get the usual implicit semicolon. Open delimiters continue
onto subsequent rows, just as in immediate mode; the complete multiline entry
is stored together, preserving its literal source and requiring its own final
semicolon. Each physical line receives a number. A multiline paste is also
stored together; UNDO reverses the entire entry. C<: exact source> stores one
literal line without continuation or an inserted terminator, useful for heredoc
contents and other unusual syntax. AUTO does not echo a second, numbered copy
by default; use LIST to see assigned numbers. C<AUTO ECHO ON> enables those
copies; C<AUTO ECHO OFF> disables them. This preference lasts for the session
and does not start or stop AUTO. Typed screen text and AUTO status/error
messages remain visible.

=head1 SESSION-ONLY FUNCTIONS

Use a named subroutine to install a function in the current REPL workspace's
symbol table without adding its definition to the numbered program:

    AUTO OFF
    EVAL sub triple {
        return 3 * shift;
    }
    say triple 14

Press ordinary Enter after the closing brace. The definition prints nothing;
the next entry calls it and prints 42. EVAL also works while AUTO is active,
but leaves AUTO on. Use C<? triple 14> for an immediate call during AUTO.

Prototypes work the same way: C<E sub twice ($) { 2 * $_[0] }> completes
with one Enter, and C<say twice 21> on the next entry prints 42. If the body
is still open, input continues until its closing brace. While collecting an
unfinished entry, text such as C<CLS> is part of that entry, not a command.
Press Ctrl-C to cancel it and return to fresh input. Ctrl-D outside AUTO
exits when the stored program has no unsaved changes.

The function lives in the workspace package of this Perl process. It is
callable by immediate input and RUN, but does not appear in LIST or SAVE.
CLS and NEW/CLEAR retain it. RESET selects a fresh workspace where that name
is no longer defined. Here "session-only" does not mean Perl's C<local> keyword
or a lexical C<my sub>; it is a normal named package subroutine.

To persist a definition deliberately, enter its source as numbered lines,
through AUTO, or through EDIT, then SAVE the program. There is no automatic
copying of evaluated source into the program or session serialization.

=head2 Listing functions

C<FUNCTIONS> prints defined function names in the current workspace, one per
line in alphabetical order. It includes imported functions and aliases in that
package, but excludes other packages, forward declarations without a body,
and anonymous functions held only in variables. An empty workspace reports
C<No functions defined in this workspace.> The command must be uppercase,
takes no arguments, and works during AUTO without storing or executing source.
Definitions in numbered source appear only after RUN installs them.

=head2 Redefining functions and running setup code

Statements outside a subroutine body run once each time the EVAL entry is
submitted. The named subroutine remains available afterward. For example:

    EVAL do {
        $setups++;
        sub triple { return 3 * shift; }
    }
    FUNCTIONS
    say triple 14

Defining C<triple> again replaces the function used by subsequent calls and
normally prints Perl's C<Subroutine triple redefined> warning. There is no
confirmation prompt. Existing code references, such as C<$old = \&triple>,
still call the previous body. Perl warning controls such as
C<no warnings 'redefine'> apply within the entry as usual.

Evaluation is not transactional: named subroutines are installed at compile
time, so a later runtime exception does not undo their definitions or other
side effects already performed.

=head1 ENVIRONMENT

    ENV
    ENV PATH
    ENV SET GREETING 'hello world'
    ENV UNSET GREETING
    EDIT ENV
    ENV SAVE session.env
    ENV LOAD session.env
    ENV RELOAD
    ENV RESET

ENV displays the current process environment as sorted C<VAR=value> lines.
Direct Perl changes such as C<$ENV{FOO} = 'bar'> and C<delete $ENV{FOO}> are also
visible. Changes affect subsequent Perl evaluations and child shell commands.
They do not change the parent shell. RESET alone resets only Perl variables;
ENV RESET restores the environment captured when AnteREPL started.

EDIT ENV (also ENV EDIT) opens a private temporary C<environment.env> in the
same editor as EDIT. Save and close it to replace the live environment.
Deleting a variable's line unsets it; an empty file clears the environment.
Invalid input or an unsuccessful editor exit leaves the environment unchanged.
Program source and its UNDO stack are separate from environment edits.

ENV SAVE writes a snapshot. ENV LOAD replaces the whole environment from a
file; it does not merge. ENV RELOAD re-reads the last successfully loaded or
saved environment file, or an explicitly supplied filename. EDIT ENV changes
memory only; ENV SAVE writes those changes to disk. No command can re-read
later changes made in the parent shell; save a file there and ENV LOAD it.

The file format is ordinary C<VAR=value>, with optional C<export> prefixes,
blank lines, and C<#> comments. Unquoted values have outer whitespace removed;
a hash preceded by whitespace starts a comment. Single-quoted values are
literal. Double-quoted values support C<\\n>, C<\\r>, C<\\t>, C<\\\\>, C<\\">,
and C<\\xHH>. Quotes preserve leading/trailing spaces and hashes. UTF-8 text
is supported, with byte escapes for non-UTF-8 values. Duplicate names and NUL
values are rejected. Names cannot contain whitespace, equals signs, hashes,
quotes, or NUL. Values are never expanded: dollar signs, command substitutions,
and backticks remain data. ENV SET uses shell-style argument quoting, also
without expansion; single quotes are useful for Windows backslash paths.

    EDITOR=vim
    GREETING="hello world"
    LITERAL='$HOME stays literal'

ENV subcommand names are reserved after ENV. Inspect a variable called SET,
for example, with C<DUMP $ENV{SET}>.

=head1 LISTING PROGRAMS

LIST left-aligns the line numbers and pads on their right, so the Perl source
starts in one column. The column width follows the largest number in the
selected range. This display padding never changes saved source or adds extra
indentation when a listed screen row is edited and submitted again.

    LIST
    LIST 10
    LIST 10-50
    LIST 10-
    LIST -50
    LIST10-50
    LIST SLOW
    LIST 10-500 PAUSE

Ranges are inclusive; spaces around the hyphen are accepted. Long listings
scroll upward row by row in screen mode. Space pauses/resumes, S toggles
normal/slow speed (approximately 33/4 rows per second), Enter steps one row and
remains paused, and Q/Esc/Ctrl-C stops. Other typing or cursor movement stops
LIST and passes that key to the editor. The temporary control hint is not
stored in screen memory. SLOW starts slowly; PAUSE stops after each screenful.
Plain mode and piped output never wait for keys or insert listing delays.

=head1 IMPLICIT SEMICOLONS

Ordinary numbered entries supply a missing final semicolon when stored:

    10 say "hi"
    LIST
    10 say "hi";

Existing terminators are retained. Full-line comments and common block or
continuation lines are left alone. A supplied semicolon goes before a trailing
comment, and hashes inside quoted strings are not treated as comments.

This convenience is not a complete Perl parser. For deliberate multiline
expressions, multiline strings, heredoc contents/terminators, POD, or unusual
syntax, use a colon immediately after the editing number to store exact source:

    10: my $text = <<'TEXT';
    20: hello
    30: TEXT
    40 say $text

The colon is an input instruction and is not part of the stored source. EDIT,
IMPORT, and LOAD also preserve literal source; they do not insert semicolons.
An already stored line is normalized only when re-entered without the colon.

=head1 EDIT

EDIT writes the current program, without line numbers, into a private temporary
C<program.pl> and starts C<$EDITOR>, falling back to C<$VISUAL>, then C<vi>
(C<notepad> on Windows). Set an editor that waits until editing is finished:

    export EDITOR=vim
    export EDITOR='code --wait'

The editor command is parsed into an executable and arguments; it is not passed
through a shell. Quote an executable path containing spaces. Windows paths
should use forward slashes when setting EDITOR. Shell expansions, pipes, and
redirections are not supported in EDITOR; use a wrapper script if needed.

After a successful exit, the saved UTF-8 file replaces the in-memory program,
renumbered 10,20,30,... . An unchanged file preserves the existing numbering.
Failure to start, nonzero exit, a missing/unreadable file, invalid UTF-8, NUL
bytes, or bare CR characters leaves the existing program intact. LF and CRLF
files are accepted. Blank lines are retained. UNDO restores the previous
program after a successful edit, including its numbering.

EDIT never runs or syntax-checks your source. Incomplete Perl is allowed in the
buffer; RUN reports errors. This avoids executing BEGIN blocks merely by
editing. Temporary editor files are removed when EDIT finishes.

=head1 WORKSPACE

Immediate input and RUN share a Perl package. C<$x = 1> and C<our $x = 1> persist
between evaluations, along with package arrays, hashes, and subroutines.
C<my> variables are local to one immediate evaluation or one complete RUN.
Pragmas and lexical imports must be repeated in each evaluation that needs
them; C<say> is enabled by default. Evaluation uses scalar context. Use
C<? expression> for Data::Dumper output; ordinary input does not automatically
print its return value. C<EVAL code> bypasses command and line-number parsing.
EVAL must be uppercase; lowercase C<eval> retains Perl's string/block evaluation
and exception-catching behavior. All REPL commands and subcommands must also
be uppercase.

RESET switches to a fresh workspace but keeps the source program. NEW/CLEAR
clear the source but retain the workspace. RUN does not reset variables first.
An exception does not roll back side effects. This runs ordinary Perl with
your account's privileges; C<exit> exits the tool. UNDO affects only stored
source, not executed Perl, shell commands, or saved files.

To execute several blocks together without storing source, leave AUTO off and
type or paste a C<do { ... }> entry, or use C<EVAL do { ... }> during AUTO:

    EVAL do {
        my $total = 0;
        for my $n (1 .. 3) { $total += $n; }
        if ($total > 0) { say $total; }
    };

This prints 6 and leaves the stored program unchanged. Delimiter continuation
holds the entry until its closing brace. Bracketed paste also groups multiline
text and waits for Enter; the enclosing block works when typing line by line.

Named subroutines defined by immediate input persist in the shared workspace.
A definition in stored source becomes callable after RUN evaluates the program:

    10 sub twice { return 2 * shift }
    RUN
    say twice 21

This prints 42. RUN executes the whole program, including other top-level
statements. LOAD and LIST only deal with source; they do not define functions.
Editing or deleting source does not change an already defined function until
it is redefined or RESET selects a fresh workspace. Use LIST or EDIT to revisit
the stored definition, and C<EVAL say twice 21> to call it during AUTO.

=head1 DIRECTORIES

CD and its alias CHDIR change AnteREPL's own working directory:

    CD ..
    CHDIR '/path/to/work'
    CD 'directory with spaces'

With no argument they use C<HOME>, or C<USERPROFILE> on native Windows if HOME
is unset. Paths are literal; quote spaces. These commands do not expand shell
variables or C<~>. A failed change gives an explanation and retains the current
directory. Lowercase C<chdir> remains ordinary Perl, including expressions:

    chdir $ENV{HOME} or die $!

Relative file commands and future child processes use the changed directory.
C<! cd ...> changes only its short-lived child shell, not AnteREPL. Neither
form can change the parent shell's directory.

=head1 FILES AND RECOVERY

LOAD accepts ordinary Perl source as well as UTF-8 numbered files bearing a
PERL ANTE REPL header. Plain source receives numbers 10,20,..., preserving comments,
blank lines, and indentation. It is never executed during loading. A C<.bperl>
filename must have a valid native header; files starting with a PERL ANTE REPL
header are validated as native regardless of extension.

SAVE remembers the loaded filename and format. C<SAVE file.pl> writes plain
source without editing numbers; C<SAVE file.bperl> writes numbered source.
Other extensions retain the current format (native for a new program).
Plain source normalizes line endings to LF and ends every stored line with a
newline. C<IMPORT file> remains available to bring in plain source as an unsaved
copy without adopting its filename. Old C<# BASIC PERL V0.1> headers remain
compatible; native-format saves write C<# PERL ANTE REPL V0.1>.

EXPORT writes an ordinary Perl script with a small prelude enabling the same
default pragmas. Workspace values are never serialized. Exported programs must
initialize the values they need to run independently.

File writes use a temporary file in the destination directory and rename it
after a successful close. LOAD validates the whole file before changing the
buffer. LOAD, IMPORT, NEW/CLEAR, and QUIT refuse to discard unsaved changes;
append C<!> to those commands to override. UNDO remembers the last 50 program
changes. The save filename is not rolled back by UNDO. Editing does not save
your source file: use SAVE afterward. No automatic crash recovery is provided.

Interactive exits through QUIT, EXIT, Q, their C<!> forms, or Ctrl-D print
C<Thank, we hope something good happens to you today!> on its own line.
In screen mode this happens after restoring the original terminal display
and default cursor style. The farewell is omitted from piped/batch output.

=head1 SCREEN EDITING AND MULTILINE INPUT

=head2 The screen is a small sheet of graph paper

The area inside the white border is the working "VRAM". An 80-column,
24-row terminal has 78 columns by 21 rows of editable cells: the border uses
two columns and two rows, and a command legend uses the bottom row.
The border and legend are outside VRAM; cursor movement, scrolling, LIST,
CLS, and RECOVER operate on the interior. There are no extra rows above it
or columns hiding to the right. New output at the bottom scrolls old rows away.
Long input and output wrap at the right edge. Wrapped source remains one line
of Perl; wrapping does not insert a newline into its code.

The legend shows common command spellings with highlighted labels. Type a
label such as C<H>, C<L>, or C<Q> and press Enter; these are not Ctrl-key
bindings. C<H> lists all commands. Narrow windows show fewer legend items,
keeping Help and Quit first. Below three columns or four rows the frame and
legend are omitted. Plain mode has no frame or command legend.

The input loop blinks the cursor every half second by toggling its visibility,
without relying on the terminal's native blinking setting. Insert requests a
bar shape; overwrite requests a block. Cursor-shape support determines whether
the shape changes. Typing makes the cursor visible immediately. Plain mode
leaves cursor appearance to the terminal.

Think of resizing as changing the size of a sheet of graph paper:

=over 4

=item * Smaller: cells at the right and bottom are cut off.

AnteREPL first keeps one separate copy of the screen, then crops the active
area and prints a warning. The warning can itself scroll rows away. It tells
you the full terminal size needed for recovery, including space for the border
and legend. There is no confirmation question.

=item * Bigger: new cells are empty.

No warning is needed. Cropped text does not come back automatically. The
saved copy is not active: cursor keys cannot reach it and Enter cannot run it.

=item * RECOVER: ask for the saved sheet back.

Enlarge to at least the dimensions in the warning, then type C<RECOVER>.
This replaces the current screen with the saved copy, including screen edits
made before shrinking. It does not merge newer screen text or execute code.
It refuses if the terminal is still too small. The copy is consumed on success.

=back

Repeated shrinking keeps the first unclaimed copy, so dragging a window edge
does not replace it with already-cropped text. C<CLS> clears both the active
screen and this copy. Neither is saved between sessions. Ordinary scrolling
does not create a recovery copy. The app checks dimensions while waiting for
input, so resizing does not need a keystroke; running Perl must return control
or print before the screen can refresh.

An entry damaged by cropping or scrolling cannot be submitted as partial Perl.
Re-enter it, recover an intact screen, or use C<EDIT> for larger source.
C<HELP> pauses by screenful; C<LIST PAUSE> and line ranges let you read source
without losing it above the screen. PageUp and Ctrl-Home stay inside the visible
area. Plain mode has no screen bank or C<RECOVER>.

The numbered program is a separate notebook. Resizing, scrolling, C<CLS>, and
C<RECOVER> do not change its source, your variables, functions, or environment.
C<LIST> copies stored source back onto the screen; C<SAVE> writes that source
to a file. C<EDIT> opens the stored program, not a picture of the screen.

This follows the C64 screen-editor idea: move through displayed text and press
Return to submit it. Its character screen was 40 by 25; AnteREPL uses your
terminal's dimensions. Resizing and the recovery bank are AnteREPL features,
not C64 hardware emulation. See the original
L<Commodore 64 User's Guide|https://www.homecomputermuseum.nl/wp-content/uploads/2020/04/Commodore-64_Users-Guide-1982.pdf>.

=head2 Editing visible entries

Interactive mode uses an ANSI screen with no input prompt or shell-style
command history. New output scrolls the view upward. Arrow keys move the cursor
through displayed input and output, including LIST output. Edit a numbered row
and press Enter to update the stored program. Editing screen text alone does
not change the program or execute it. When you resubmit an earlier entry, its
new output replaces its previous output immediately below the entry, and the
cursor stays just below the new result. If another entry follows, the cursor
moves to its start without inserting a blank spacer or erasing that entry.
Shorter or silent results remove stale output rows; blank lines deliberately
printed by Perl remain. Later entries and their output remain while they fit;
Esc or Ctrl-End moves to fresh input at the bottom. Multiline entries put their
result below the whole group, even when you press Enter on a row in the middle.
This changes only the screen display: executing Perl still repeats its normal
side effects.

C<CLS> clears the display and resize bank, returning the cursor
to the top left. The stored program, live Perl variables, C<%ENV>,
AUTO settings, save filename, unsaved status, and source UNDO remain intact.
C<LIST> displays the program again; C<RUN> still executes it. C<CLEAR> instead
erases the stored program, while Ctrl-L only redraws existing screen text.
In plain mode, CLS emits clear/home escapes only to a terminal whose TERM is
not C<dumb>; it produces no output when redirected or piped.

Typing inserts characters by default, including when editing earlier rows;
Insert switches between insert and overwrite. Backspace/Delete remove characters,
Home/End move within a row. Left at the start of a row moves to the end of
the previous row, stopping at the visible top row. Empty rows are visited
one at a time. PageUp/PageDown move within visible screen text.
Esc or Ctrl-End returns to a blank row at the bottom; Ctrl-Home visits the
top row. Ctrl-U clears a row, Ctrl-L redraws, and Ctrl-C cancels input or
interrupts running Perl. Ctrl-C also shows exit directions: QUIT, QUIT! to
discard unsaved source, or Ctrl-D when AUTO is off and source is saved.
There is no saved history. Wide/combining Unicode
glyphs can misalign the cursor; the editor assumes
one terminal cell per character.

Shift-Enter or Ctrl-N inserts a newline at the cursor without submitting,
splitting the current row and keeping it in the same multiline group. This
works even when the entry is already complete. Enter submits the entire group
once its delimiters are closed, including from a row in the middle. Insert
mode still controls whether subsequent typing inserts or overwrites text.

Shift-Enter requires the terminal to report a distinct key sequence. CSI-u
C<ESC [ 13 ; 2 u> and xterm C<ESC [ 27 ; 2 ; 13 ~> are recognized. If the
terminal sends ordinary Enter for both keys, AnteREPL cannot distinguish them;
use Ctrl-N or configure Shift-Enter to send one of those sequences. These
editing keys apply to screen input, not C<--plain> or program STDIN reads.

For immediate Perl, Enter continues on the next screen row while a brace,
bracket, parenthesis, or quoted literal remains open. Once closed, Enter
submits the whole entry. Earlier multiline entries remain grouped when edited
and resubmitted. Bracketed multiline paste waits for Enter before evaluating.
No extra continuation prompt is printed, and input is never compiled merely
to decide whether it needs another row. This is delimiter continuation, not a
complete Perl parser; use EDIT or literal numbered lines for heredocs/POD and
complex source. Numbered program lines retain their existing single-line rules.

DUMP expression is a prompt command backed by Data::Dumper::Dumper:

    $FOO = {
        bar => 1,
        names => [qw(Alice Bob)],
    };
    DUMP $FOO
    DUMP \%ENV

PEEK expression calls the core Devel::Peek::Dump directly on the expression,
including an optional limit, e.g. C<PEEK $FOO> or C<PEEK $FOO, 10>. Its native
stderr output is captured into the editable display. These are prompt commands;
in stored Perl use the module functions explicitly. They do not redefine Perl's
CORE::dump keyword.

Perl print/say/warn output and simple C<E<lt>STDINE<gt>> line input use the screen.
C<! command> captures external stdout/stderr into screen rows when it finishes,
with closed input. Use C<!! command> for interactive external programs; it lends
them the real terminal and waits for Enter before returning to the screen.
EDIT likewise restores normal terminal settings while your editor runs.
Use these escapes for external programs: direct system/exec calls and arbitrary
XS terminal output bypass the screen model.

Screen mode needs an ANSI-capable terminal. On Unix, it uses core POSIX terminal
support, or Term::ReadKey if installed. Native Windows requires Term::ReadKey
(C<cpanm Term::ReadKey>); its Windows backend has not been validated here.
C<--plain> disables screen editing and uses plain input with no prompt or history.
The old C<--no-readline> flag is an alias for C<--plain>.

C<--quiet> suppresses the banner. A startup filename is loaded but never
executed automatically. Piped input uses plain mode and supports the same
immediate delimiter continuation. Batches return a nonzero status after command
errors, incomplete input at EOF, or unsaved stored source at EOF. Outside AUTO,
Ctrl-D refuses to exit an interactive session with unsaved source. Source files and
workspace values have the same lifetime rules in both terminal modes.

=head1 SEE ALSO

L<https://github.com/oodler577/p5-App-AnteREPL/wiki> contains installation,
first-session, editing, environment, and troubleshooting walkthroughs.
Type HELP for the complete command and keyboard reference, also available
from C<anterepl --help>.

=head1 AUTHOR

Brett Estrade

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Brett Estrade.

This software is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
