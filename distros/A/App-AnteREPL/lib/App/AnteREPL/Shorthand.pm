use 5.016;
use strict;
use warnings;

package App::AnteREPL::Shorthand;

use Text::Balanced qw(extract_bracketed extract_quotelike);

my %keyword;

# Ask this Perl about its own keywords without compiling any user code.
sub perl_keyword {
    my ($name) = @_;
    return $keyword{$name} if exists $keyword{$name};
    local $@;
    return $keyword{$name} = eval { my $prototype = prototype "CORE::$name"; 1 } ? 1 : 0;
}

sub _fail {
    die "Ambiguous shorthand: $_[0]. Try EVAL with explicit Perl syntax.\n";
}

sub _trim {
    my ($text) = @_;
    $text =~ s/\A\s+|\s+\z//g;
    return $text;
}

sub _starts_quote {
    my ($text) = @_;
    return $text =~ /\A['"`]/
        || $text =~ /\A(?:qq|qw|qx|qr|q|m|s|tr|y)(?=\s|[^\w\s])\s*(?!=>)\S/;
}

sub _quote {
    my ($text) = @_;
    local $@;
    my ($quote) = extract_quotelike("$text", '');
    _fail('unclosed quoted value') unless defined $quote && length $quote;
    return $quote;
}

sub _group {
    my ($text) = @_;
    my $open = substr($text, 0, 1);
    if ($open eq '(') {
        local $@;
        my ($group) = extract_bracketed("$text", q{()[]{}'"`q}, '');
        return $group if defined $group && length $group;
        _fail($@ =~ /Mismatched/ ? 'mismatched expression delimiters' : 'unclosed parenthesized expression');
    }
    my $close = $open eq '[' ? ']' : '}';
    my $position = 1;
    while ($position < length $text) {
        my $rest = substr($text, $position);
        my $char = substr($rest, 0, 1);
        return substr($text, 0, $position + 1) if $char eq $close;
        _fail('mismatched container delimiters') if $char =~ /[)\]}]/;
        if ($rest =~ /\A\$[A-Za-z_][A-Za-z0-9_]*/) { $position += length $&; }
        elsif (_starts_quote($rest)) { $position += length _quote($rest); }
        elsif ($char =~ /[([{]/) { $position += length _group($rest); }
        elsif ($rest =~ /\A[\p{L}_][\p{L}\p{N}_]*/) { $position += length $&; }
        else { ++$position; }
    }
    _fail('unclosed container');
}

# Split only at the requested top-level separator. Perl expressions enclosed
# in parentheses are opaque: this scanner never compiles or evaluates them.
sub _split {
    my ($text, $separator) = @_;
    my @parts;
    my ($start, $position) = (0, 0);
    while ($position < length $text) {
        my $rest = substr($text, $position);
        my $char = substr($rest, 0, 1);
        if ($rest =~ /\A\$[A-Za-z_][A-Za-z0-9_]*/) { $position += length $&; }
        elsif (_starts_quote($rest)) { $position += length _quote($rest); }
        elsif ($char =~ /[([{]/) {
            $position += length _group($rest);
        }
        elsif ($char =~ /[)\]}]/) { _fail('unexpected closing delimiter'); }
        elsif (substr($rest, 0, length $separator) eq $separator) {
            push @parts, substr($text, $start, $position - $start);
            $position += length $separator;
            $start = $position;
        }
        elsif ($rest =~ /\A[\p{L}_][\p{L}\p{N}_]*/) { $position += length $&; }
        else { ++$position; }
    }
    push @parts, substr($text, $start);
    return @parts;
}

sub _value {
    my ($text) = @_;
    $text = _trim($text);
    _fail('a value is missing') unless length $text;
    return 'undef' if $text eq 'undef';
    return "'$text'" if $text =~ /\A[\p{L}_][\p{L}\p{N}_]*\z/;
    return $text if $text =~ /\A[+-]?(?:(?:0|[1-9][0-9]*)(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?\z/;
    return $text if $text =~ /\A\$[A-Za-z_][A-Za-z0-9_]*\z/;
    if (_starts_quote($text)) {
        my $quote = _quote($text);
        return $quote if _trim(substr($text, length $quote)) eq '';
        _fail('a quoted value must occupy the whole item');
    }
    if ($text =~ /\A[([{]/) {
        my $group = _group($text);
        my $rest = substr($text, length $group);
        _fail('a container or parenthesized expression must occupy the whole item')
            unless defined $group && length $group && _trim($rest) eq '';
        my $open = substr($group, 0, 1);
        return $group if $open eq '(';
        my $body = substr($group, 1, length($group) - 2);
        return '[' . _array($body) . ']' if $open eq '[';
        return '{' . _hash($body) . '}';
    }
    _fail("cannot read value '$text'; quote literal text or parenthesize a Perl expression");
}

sub _items {
    my ($text) = @_;
    return () unless length _trim($text);
    my @items = _split($text, ',');
    pop @items if @items > 1 && _trim($items[-1]) eq ''; # One trailing comma.
    _fail('a value is missing between commas') if grep { _trim($_) eq '' } @items;
    return @items;
}

sub _array {
    my ($text) = @_;
    return join ', ', map { _value($_) } _items($text);
}

sub _hash {
    my ($text) = @_;
    my @pairs;
    for my $item (_items($text)) {
        my @pair = _split($item, '=>');
        _fail('each hash item needs exactly one key => value pair') unless @pair == 2;
        _fail('hash keys cannot be container literals') if _trim($pair[0]) =~ /\A[\[{]/;
        # A pair always has one key and one value. Arrays belong in [...];
        # parenthesized expressions in these two positions use scalar context.
        push @pairs, 'scalar(' . _value($pair[0]) . ') => scalar(' . _value($pair[1]) . ')';
    }
    return join ', ', @pairs;
}

sub _definition {
    my ($type, $name, $body) = @_;
    if ($type eq 's') {
        _fail('a function body is missing; try E s name return expression') unless $body =~ /\S/;
        _fail("'$name' is a Perl keyword; choose another function name") if perl_keyword($name);
        return "sub $name {\n$body\n}";
    }
    return '@' . $name . ' = (' . _array($body) . ');' if $type eq 'a';
    return '$' . $name . ' = [' . _array($body) . '];' if $type eq 'ar';
    return '%' . $name . ' = (' . _hash($body) . ');' if $type eq 'h';
    return '$' . $name . ' = {' . _hash($body) . '};' if $type eq 'hr';
    die "Unknown internal shorthand type\n";
}

sub explicit {
    my ($class, $line) = @_;
    return unless $line =~ /\A\s*E(!?)\s+(s|a|ar|h|hr)(?=\s|\z)(.*)\z/s;
    my ($force, $type, $tail) = ($1, $2, $3);
    $tail =~ s/;\s*\z// if $type ne 's';
    _fail("$type needs a plain destination name, without a sigil")
        unless $tail =~ /\A\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s+(.*))?\z/s;
    my ($name, $body) = ($1, defined $2 ? $2 : '');
    return { code=>_definition($type, $name, $body), type=>$type, name=>$name, force=>$force, label=>'E' };
}

sub _implicit_candidate {
    my ($line, $is_function) = @_;
    return unless $line =~ /\A\s*([a-z_][A-Za-z0-9_]*)(!?)\s+(.+)\z/s;
    my ($name, $force, $body) = ($1, $2, $3);
    return if perl_keyword($name) || (!$force && $is_function && $is_function->($name));
    return if $body =~ /\A=>/; # Perl's autoquoted hash key, not a destination.
    return unless $body =~ /,|=>/;
    return ($name, $body, $force);
}

sub implicit {
    my ($class, $line, $is_function) = @_;
    my ($name, $body, $force) = _implicit_candidate($line, $is_function);
    return unless defined $name;
    $body =~ s/;\s*\z//; # One optional statement terminator, outside the values.
    my @commas = _split($body, ',');
    my @arrows = _split($body, '=>');
    return unless @commas > 1 || @arrows > 1;
    my $type = @arrows > 1 ? 'h' : 'a';
    return { code=>_definition($type, $name, $body), type=>$type, name=>$name, force=>$force, label=>$name };
}

sub needs_more {
    my ($class, $line, $is_function) = @_;
    my $body;
    if ($line =~ /\A\s*E!?\s+(?:a|ar|h|hr)\s+[A-Za-z_][A-Za-z0-9_]*\s+(.*)\z/s) {
        $body = $1;
    }
    else { (undef, $body) = _implicit_candidate($line, $is_function); }
    return unless defined $body;
    local $@;
    my $ok = eval { _split($body, ','); 1 };
    return !$ok && $@ =~ /unclosed/ ? 1 : 0;
}

1;

__END__

=head1 NAME

App::AnteREPL::Shorthand - internal immediate-definition parser

=head1 DESCRIPTION

This internal module recognizes the bounded shorthand grammar described in
L<App::AnteREPL/SHORTCUTS AND SHORTHAND>. It produces Perl source without
compiling or executing user input. Its helpers are not a public API.

=cut
