##----------------------------------------------------------------------------
## Data Dump Beautifier - ~/lib/Data/Pretty.pm
## Version v0.2.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/08/06
## Modified 2025/10/08
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Data::Pretty;
BEGIN
{
    use strict;
    use warnings;
    use vars qw(
        @EXPORT @EXPORT_OK $VERSION $DEBUG
        %seen %refcnt @dump @fixup %require
        $TRY_BASE64 @FILTERS $INDENT $LINEWIDTH $SHOW_UTF8 $CODE_DEPARSE
    );
    use subs qq(dump);
    use overload ();
    require Exporter;
    *import = \&Exporter::import;
    @EXPORT = qw( dd ddx );
    @EXPORT_OK = qw( dump pp dumpf literal quote );
    our $DEBUG = 0;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

$TRY_BASE64 = 50 unless defined $TRY_BASE64;
$INDENT = '    ' unless defined $INDENT;
$LINEWIDTH = 60 unless defined $LINEWIDTH;
$SHOW_UTF8 = 1 unless defined $SHOW_UTF8;
$CODE_DEPARSE = 1 unless defined $CODE_DEPARSE;

{
    no warnings 'once';
    *pp = \&dump;
}

sub dd {
    print dump(@_), "\n";
}

sub ddx {
    my(undef, $file, $line) = caller;
    $file =~ s,.*[\\/],,;
    my $out = "$file:$line: " . dump(@_) . "\n";
    $out =~ s/^/# /gm;
    print $out;
}

sub dump
{
    local %seen;
    local %refcnt;
    local %require;
    local @fixup;

    require Data::Pretty::FilterContext if @FILTERS;

    my $name = "a";
    my @dump;

    my $use_qw = &_use_qw( [@_] );
    for my $v (@_) {
        # my $val = _dump($v, $name, [], tied($v));
        my $val = _dump(
            $v,
            name => $name,
            idx => [],
            dont_remember => tied($v),
            use_qw => $use_qw,
        );
        push(@dump, [$name, $val]);
    } continue {
        $name++;
    }

    my $out = "";
    if (%require) {
        for (sort keys %require) {
            $out .= "require $_;\n";
        }
    }
    if (%refcnt) {
        # output all those with refcounts first
        for (@dump) {
            my $name = $_->[0];
            if ($refcnt{$name}) {
                $out .= "my \$$name = $_->[1];\n";
                undef $_->[1];
            }
        }
        for (@fixup) {
            $out .= "$_;\n";
        }
    }

    my $paren = (@dump != 1);
    my $formatted = format_list(
        paren => $paren,
        comment => undef,
        values => [map {defined($_->[1]) ? $_->[1] : "\$" .$_->[0]} @dump],
        use_qw => $use_qw,
    );
    my $has_qw = substr( $formatted, 0, 2 ) eq 'qw';
    $out .= "(" if( $paren && !$has_qw );
    $out .= $formatted;
    $out .= ")" if( $paren && !$has_qw );

    if (%refcnt || %require) {
        $out .= ";\n";
        $out =~ s/^/$INDENT/gm;
        $out = "do {\n$out}";
    }

    print STDERR "$out\n" unless defined wantarray;
    $out;
}

sub dumpf {
    require Data::Pretty::Filtered;
    goto &Data::Pretty::Filtered::dump_filtered;
}

sub format_list
{
    my $opts = {@_};
    my $paren = $opts->{paren};
    my $comment = $opts->{comment};
    my $indent_lim = $paren ? 0 : 1;
    my $use_qw = defined( $opts->{use_qw} ) ? $opts->{use_qw} : 1;
    my $values = $opts->{values};
    
    if (@$values > 3) {
        # my $use_quotes = 0;
        # can we use range operator to shorten the list?
        my $i = 0;
        while ($i < @$values) {
            my $j = $i + 1;
            my $v = $values->[$i];
            while ($j < @$values) {
                # NOTE: allow string increment too?
                if ($v eq "0" || $v =~ /^-?[1-9]\d{0,9}\z/) {
                    $v++;
                }
                elsif ($v =~ /^"([A-Za-z]{1,3}\d*)"\z/) {
                    $v = $1;
                    $v++;
                    $v = qq("$v");
                }
                else {
                    last;
                }
                last if $values->[$j] ne $v;
                $j++;
            }
            if ($j - $i > 3) {
                splice(@$values, $i, $j - $i, "$values->[$i] .. $values->[$j-1]");
                $use_qw = 0;
            }
            $i++;
        }
    }

    if( $use_qw )
    {
        my @repl;
        foreach my $v ( @$values )
        {
            ( my $v2 = $v ) =~ s/^\"|\"$//g;
            push( @repl, $v2 );
        }
        @$values = @repl;
    }

    my $tmp = "@$values";
    my $sep = $use_qw ? ' ' : ', ';
    if ($comment || (@$values > $indent_lim && (length($tmp) > $LINEWIDTH || $tmp =~ /\n/))) {
        if( $use_qw )
        {
            my @lines;
            my @buf;
            foreach my $v ( @$values )
            {
                if( scalar( @buf ) && length( $INDENT . join( ' ', @buf, $v ) ) > $LINEWIDTH )
                {
                    push( @lines, $INDENT . join( ' ', @buf ) );
                    @buf = ( $v );
                }
                else
                {
                    push( @buf, $v );
                }
            }
            push( @lines, $INDENT . join( ' ', @buf ) ) if( scalar( @buf ) );
            return (
                $comment
                    ? ( scalar( @lines ) > 1 ? "\n$INDENT" : '' ) . "# $comment" . ( scalar( @lines ) > 1 ? "\n" : '' )
                    : ''
            ) . 'qw(' . "\n" . join("\n", @lines,"") . ')';
        }
        else
        {
            my @elem = @$values;
            for (@elem) { s/^/$INDENT/gm; }
            return "\n" . ($comment ? "$INDENT# $comment\n" : "") .
                   join(",\n", @elem, "");
        }
    } else {
        return $use_qw ? 'qw( ' . join( $sep, @$values ) . ' )' : join($sep, @$values);
    }
}

sub fullname
{
    my($name, $idx, $ref) = @_;
    substr($name, 0, 0) = "\$";

    my @i = @$idx;  # need copy in order to not modify @$idx
    if ($ref && @i && $i[0] eq "\$") {
        shift(@i);  # remove one deref
        $ref = 0;
    }
    while (@i && $i[0] eq "\$") {
        shift @i;
        $name = "\$$name";
    }

    my $last_was_index;
    for my $i (@i) {
        if ($i eq "*" || $i eq "\$") {
            $last_was_index = 0;
            $name = "$i\{$name}";
        } elsif ($i =~ s/^\*//) {
            $name .= $i;
            $last_was_index++;
        } else {
            $name .= "->" unless $last_was_index++;
            $name .= $i;
        }
    }
    $name = "\\$name" if $ref;
    $name;
}

sub literal { return( Data::Pretty::Literal->new( @_ ) ); }

my %esc = (
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);

# put a string value in double quotes
sub quote
{
    local( $_ ) = $_[0];

    # Escape backslash, double quote, and sigils
    s/([\\\"\@\$])/\\$1/g;

    # Fast exit if printable 7-bit ASCII only
    return qq("$_") unless /[^\040-\176]/;

    # Named C0 escapes first
    s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

    # Remaining C0 controls: octal if NOT followed by a digit
    s/([\0-\037])(?!\d)/sprintf('\\%o', ord($1))/eg;

    if( $SHOW_UTF8 && utf8::is_utf8( $_ ) )
    {
        # Decoded text: escape only non-printables and DEL.
        # Use \xHH for <= 0xFF; \x{...} for > 0xFF.
        s/([^\p{Print}]|\x7F)/
            ord($1) <= 0xFF
                ? sprintf('\\x%02X', ord($1))
                : sprintf('\\x{%X}',   ord($1))
        /eg;
    }
    else
    {
        # Bytes / or we don't want to show glyphs:
        # Convert any remaining controls and 0x7F..0xFF to \xHH first
        # (this also handles the "control followed by digit" case as \x00).
        s/([\0-\037\177-\377])/sprintf('\\x%02X', ord($1))/eg;

        # Safety net: anything still outside printable ASCII -> \x{...}
        s/([^\040-\176])/sprintf('\\x{%X}', ord($1))/eg;
    }

    return qq("$_");
}

sub str {
    my $opts = $_[1];
    if (length($_[0]) > 20) {
        for ($_[0]) {
            # Check for repeated string
            if (/^(.)\1\1\1/s) {
                # seems to be a repeating sequence, let's check if it really is
                # without backtracking
                unless (/[^\Q$1\E]/) {
                    my $base = quote($1);
                    my $repeat = length;
                    return "($base x $repeat)"
                }
            }
            # Length protection because the RE engine will blow the stack [RT#33520]
            if (length($_) < 16 * 1024 && /^(.{2,5}?)\1*\z/s) {
                my $base   = quote($1);
                my $repeat = length($_)/length($1);
                return "($base x $repeat)";
            }
        }
    }

    local $_ = &quote;
    # local $_ = $opts->{use_qw} ? $_[0] : &quote;

    if (length($_) > 40  && !/\\x\{/ && length($_) > (length($_[0]) * 2)) {
        # too much binary data, better to represent as a hex/base64 string

        # Base64 is more compact than hex when string is longer than
        # 17 bytes (not counting any require statement needed).
        # But on the other hand, hex is much more readable.
        if ($TRY_BASE64 && length($_[0]) > $TRY_BASE64 &&
        (defined &utf8::is_utf8 && !utf8::is_utf8($_[0])) &&
        eval { require MIME::Base64 })
        {
            $require{"MIME::Base64"}++;
            return "MIME::Base64::decode(\"" .
                     MIME::Base64::encode($_[0],"") .
            "\")";
        }
        return "pack(\"H*\",\"" . unpack("H*", $_[0]) . "\")";
    }
    return $_;
}

sub tied_str {
    my $tied = shift;
    if ($tied) {
        if (my $tied_ref = ref($tied)) {
            $tied = "tied $tied_ref";
        }
        else {
            $tied = "tied";
        }
    }
    return $tied;
}

sub _dump
{
    my $ref  = ref $_[0];
    my $rval = $ref ? $_[0] : \$_[0];
    shift;
    my $opts = {@_};

    my($name, $idx, $dont_remember, $pclass, $pidx) = @$opts{qw( name idx dont_remember pclass pidx )};

    my($class, $type, $id);
    my $strval = overload::StrVal($rval // '');
    # Parse $strval without using regexps, in order not to clobber $1, $2,...
    if ((my $i = rindex($strval, "=")) >= 0) {
        $class = substr($strval, 0, $i);
        $strval = substr($strval, $i+1);
    }
    if ((my $i = index($strval, "(0x")) >= 0) {
        $type = substr($strval, 0, $i);
        $id = substr($strval, $i + 2, -1);
    }
    else {
        die "Can't parse " . overload::StrVal($rval // '');
    }
    if ($] < 5.008 && $type eq "SCALAR") {
        $type = "REF" if $ref eq "REF";
    }
    warn "\$$name(@$idx) ", ( $class || 'undef' ), " $type $id ($ref), strval=$strval" if $DEBUG;

    my $out;
    my $comment;
    my $hide_keys;
    if (@FILTERS) {
        my $pself = "";
        $pself = fullname("self", [@$idx[$pidx..(@$idx - 1)]]) if $pclass;
        my $ctx = Data::Pretty::FilterContext->new($rval, $class, $type, $ref, $pclass, $pidx, $idx);
        my @bless;
        for my $filter (@FILTERS) {
            if (my $f = $filter->($ctx, $rval)) {
                if (my $v = $f->{object}) {
                    local @FILTERS;
                    $out = _dump(
                        $v,
                        name => $name,
                        idx => $idx,
                        dont_remember => 1,
                    );
                    $dont_remember++;
                }
                if (defined(my $c = $f->{bless})) {
                    push(@bless, $c);
                }
                if (my $c = $f->{comment}) {
                    $comment = $c;
                }
                if (defined(my $c = $f->{dump})) {
                    $out = $c;
                    $dont_remember++;
                }
                if (my $h = $f->{hide_keys}) {
                    if (ref($h) eq "ARRAY") {
                        $hide_keys = sub {
                            for my $k (@$h) {
                                return 1 if $k eq $_[0];
                            }
                            return 0;
                        };
                    }
                }
            }
        }
        push(@bless, "") if defined($out) && !@bless;
        if (@bless) {
            $class = shift(@bless);
            warn "More than one filter callback tried to bless object" if @bless;
        }
    }

    unless ($dont_remember) {
        # We do not use reference alias for scalars because they pose no threat of infinite recursion
        my $s;
        if( ( $s = $seen{$id} ) && $type ne 'SCALAR' ) {
            my($sname, $sidx) = @$s;
            $refcnt{$sname}++;
            my $sref = fullname($sname, $sidx,
                    ($ref && $type eq "SCALAR"));
            warn "SEEN: [\$$name(@$idx)] => [\$$sname(@$sidx)] ($ref,$sref)" if $DEBUG;
            return $sref unless $sname eq $name;
            $refcnt{$name}++;
            push(@fixup, fullname($name,$idx)." = $sref");
            return "do{my \$fix}" if @$idx && $idx->[-1] eq '$';
            return "'fix'";
        }
        $seen{$id} = [$name, $idx];
    }

    if ($class) {
        $pclass = $class;
        $pidx = @$idx;
    }

    if (defined $out) {
        # keep it
    }
    # NOTE: scalar, ref or regexp
    elsif ($type eq "SCALAR" || $type eq "REF" || $type eq "REGEXP") {
        if ($ref) {
            # NOTE: regexp
            if ($class && $class eq "Regexp") {
                my $v = "$rval";

                my $mod = "";
                if ($v =~ /^\(\?\^?([msix-]*):([\x00-\xFF]*)\)\z/) {
                    $mod = $1;
                    $v = $2;
                    $mod =~ s/-.*//;
                }

                my $sep = '/';
                my $sep_count = ($v =~ tr/\///);
                if ($sep_count) {
                    # see if we can find a better one
                    for ('|', ',', ':', '#') {
                        my $c = eval "\$v =~ tr/\Q$_\E//";
                        #print "SEP $_ $c $sep_count\n";
                        if ($c < $sep_count) {
                            $sep = $_;
                            $sep_count = $c;
                            last if $sep_count == 0;
                        }
                    }
                }
                $v =~ s/\Q$sep\E/\\$sep/g;

                $out = "qr$sep$v$sep$mod";
                undef($class);
            }
            else {
                delete $seen{$id} if $type eq "SCALAR";  # will be seen again shortly
                my $val = _dump(
                    $$rval,
                    name => $name,
                    idx => [@$idx, "\$"],
                    dont_remember => 0,
                    pclass => $pclass,
                    pidx => $pidx,
                );
                $out = $class ? "do{\\(my \$o = $val)}" : "\\$val";
            }
        # NOTE; regular string
        } else {
            if (!defined $$rval) {
                $out = "undef";
            }
            elsif ($$rval =~ /^-?(?:nan|inf)/i) {
                $out = str($$rval);
            }
            elsif (do {no warnings 'numeric'; $$rval + 0 eq $$rval}) {
                $out = $$rval;
            }
            else {
                $out = str($$rval, $opts);
                # $out = str($$rval);
            }
            if ($class && !@$idx) {
                # Top is an object, not a reference to one as perl needs
                $refcnt{$name}++;
                my $obj = fullname($name, $idx);
                my $cl  = quote($class);
                push(@fixup, "bless \\$obj, $cl");
            }
        }
    }
    # NOTE: glob
    elsif ($type eq "GLOB") {
        if ($ref) {
            delete $seen{$id};
            my $val = _dump(
                $$rval,
                name => $name,
                idx => [@$idx, "*"],
                dont_remember => 0,
                pclass => $pclass,
                pidx => $pidx,
            );
            $out = "\\$val";
            if ($out =~ /^\\\*Symbol::/) {
                $require{Symbol}++;
                $out = "Symbol::gensym()";
            }
        } else {
            my $val = "$$rval";
            $out = "$$rval";

            for my $k (qw(SCALAR ARRAY HASH)) {
                my $gval = *$$rval{$k};
                next unless defined $gval;
                next if $k eq "SCALAR" && ! defined $$gval;  # always there
                my $f = scalar @fixup;
                push(@fixup, "RESERVED");  # overwritten after _dump() below
                $gval = _dump(
                    $gval,
                    name => $name,
                    idx => [@$idx, "*{$k}"],
                    dont_remember => 0,
                    pclass => $pclass,
                    pidx => $pidx,
                );
                $refcnt{$name}++;
                my $gname = fullname($name, $idx);
                $fixup[$f] = "$gname = $gval";  #XXX indent $gval
            }
        }
    }
    # NOTE: array
    elsif ($type eq "ARRAY") {
        my @vals;
        my $tied = tied_str(tied(@$rval));
        # Quick check if we are dealing with a simple array of words/terms
        # and thus if we can use qw( .... ) instead of ( "some", "thing", "else" )
        my $use_qw = &_use_qw( $rval );

        my $i = 0;
        for my $v (@$rval) {
            push(@vals, _dump(
                $v,
                name => $name,
                idx => [@$idx, "[$i]"],
                dont_remember => $tied,
                pclass => $pclass,
                pidx => $pidx,
                use_qw => $use_qw,
            ));
            $i++;
        }
        $out = "[" . format_list(
            paren => 1,
            comment => $tied,
            values => \@vals,
            use_qw => $use_qw,
        ) . "]";
    }
    # NOTE: hash
    elsif ($type eq "HASH") {
        my(@keys, @vals);
        my $tied = tied_str(tied(%$rval));

        # statistics to determine variation in key lengths
        my $kstat_max = 0;
        my $kstat_sum = 0;
        my $kstat_sum2 = 0;

        my @orig_keys = keys %$rval;
        if ($hide_keys) {
            @orig_keys = grep !$hide_keys->($_), @orig_keys;
        }
        my $text_keys = 0;
        for (@orig_keys) {
            $text_keys++, last unless /^[-+]?(?:0|[1-9]\d*)(?:\.\d+)?\z/;
        }

        if ($text_keys) {
            @orig_keys = sort { lc($a) cmp lc($b) } @orig_keys;
        }
        else {
            @orig_keys = sort { $a <=> $b } @orig_keys;
        }

        # my $quote;
        my $need_quotes = {};
        for my $key (@orig_keys) {
            next if $key =~ /^-?[a-zA-Z_]\w*\z/;
            next if $key =~ /^-?[1-9]\d{0,8}\z/;
            next if $key =~ /^-?\d{1,9}\.\d+\z/;
            # $quote++;
            $need_quotes->{ $key }++;
            # last;
        }

        my $need_breakdown = 0;
        for my $key (@orig_keys) {
            my $orig = $key;
            my $val = \$rval->{$key};  # capture value before we modify $key
            # $key = quote($key) if $quote;
            $key = quote($key) if $need_quotes->{ $key };
            $kstat_max = length($key) if length($key) > $kstat_max;
            $kstat_sum += length($key);
            $kstat_sum2 += length($key) * length($key);

            push(@keys, $key);
            # push(@vals, _dump($$val, $name, [@$idx, "{$key}"], $tied, $pclass, $pidx));
            my $this = _dump(
                $$val,
                name => $name,
                idx => [@$idx, "{$key}"],
                dont_remember => $tied,
                pclass => $pclass,
                pidx => $pidx,
            );
            my $this_type;
            if ((my $i = index(overload::StrVal($$val // ''), "(0x")) >= 0) {
                $this_type = substr(overload::StrVal($$val // ''), 0, $i);
            }
            # Our child element is also an HASH, and if it is not empty, this would become too much of a cluttered structure to print in just one line.
            if( defined( $this_type ) && $this_type eq 'HASH' && ref( $rval->{$orig} ) eq 'HASH' && scalar( keys( %{$rval->{$orig}} ) ) )
            {
                $need_breakdown++;
            }
            push( @vals, $this );
        }
        my $nl = "";
        my $klen_pad = 0;
        my $tmp = "@keys @vals";
        if (length($tmp) > $LINEWIDTH || $tmp =~ /\n/ || $tied || $need_breakdown) {
            $nl = "\n";
        }
        $out = "{$nl";
        $out .= "$INDENT# $tied$nl" if $tied;
        while (@keys) {
            my $key = shift @keys;
            my $val = shift @vals;
            my $vpad = $INDENT . (" " x ($klen_pad ? $klen_pad + 4 : 0));
            $val =~ s/\n/\n$vpad/gm;
            my $kpad = $nl ? $INDENT : " ";
            $key .= " " x ($klen_pad - length($key)) if $nl && $klen_pad > length($key);
            $out .= "$kpad$key => $val,$nl";
        }
        $out =~ s/,$/ / unless $nl;
        $out .= "}";
    }
    # NOTE: code
    elsif ($type eq "CODE") {
        if( $CODE_DEPARSE && eval { require B::Deparse } )
        {
            # -sC to cuddle elsif, else and continue
            # -si4 indent by 4 spaces (default)
            # -p use extra parenthesis
            # my $deparse = B::Deparse->new("-p", "-sC");
            my $deparse = B::Deparse->new;
            my $code = $deparse->coderef2text( $rval );
            # Don't let our environment influence the code
            1 while $code =~ s/^\{[\s\n]+use\s(warnings|strict(?:\s'[^\']+')?);\n/\{\n/gs;
            $out = 'sub ' . $code;
        }
        else
        {
            $out = 'sub { ... }';
        }
    }
    # NOTE: vstring
    elsif ($type eq "VSTRING") {
        $out = sprintf +($ref ? '\v%vd' : 'v%vd'), $$rval;
    }
    # NOTE: other type unsupported
    else {
        warn "Can't handle $type data";
        $out = "'#$type#'";
    }

    if ($class && $ref) {
        if( $class eq 'Data::Pretty::Literal' )
        {
            $out = $$rval;
        }
        else
        {
            $out = "bless($out, " . quote($class) . ")";
        }
    }
    if ($comment) {
        $comment =~ s/^/# /gm;
        $comment .= "\n" unless $comment =~ /\n\z/;
        $comment =~ s/^#[ \t]+\n/\n/;
        $out = "$comment$out";
    }
    return $out;
}

sub _use_qw
{
    my $rval = shift( @_ );
    # Quick check if we are dealing with a simple array of words/terms
    # and thus if we can use qw( .... ) instead of ( "some", "thing", "else" )
    my $use_qw = 1;
    my $only_numbers = 0;
    foreach my $v ( @$rval )
    {
        if( !defined( $v ) || 
            ref( $v ) || 
            substr( overload::StrVal( \$v ), 0, 7 ) eq 'VSTRING' ||
            # See perlop/"qw/STRING/" section
            ( !ref( $v ) && $v =~ /[\,\\\#[:blank:]\h\v\a\b\t\n\f\r\e\@\"\$]/ ) )
        {
            $use_qw = 0;
            last;
        }
        $only_numbers++ if( $v =~ /^[-+]?(?:0|[1-9]\d*)(?:\.\d+)?\z/ );
    }
    # Don't use qw() if we are only dealing with numbers
    $use_qw = 0 if( $only_numbers == scalar( @$rval ) || scalar( @$rval ) == 1 );
    return( $use_qw );
}

{
    package
        Data::Pretty::Literal;
    sub new
    {
        my $this = shift( @_ );
        my $str = shift( @_ );
        return( bless( ( ref( $str ) eq 'SCALAR' ? $str : \$str ) => ( ref( $this ) || $this ) ) );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Data::Pretty - Data Dump Beautifier

=head1 SYNOPSIS

    use Data::Pretty qw( dump );
    $str = dump(@list);
    @copy_of_list = eval $str;

    # or use it for easy debug printout
    use Data::Pretty; dd localtime;

    use Data::Pretty qw( dump literal );
    my $users = [qw( John Peter )];
    my $ref = { name => literal( '$users->[0]' ) };
    say dump( $ref ); # { name => $users->[0] }

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This is a fork from L<Data::Dump> and a drop-in replacement with the aim at providing the following improvements:

=over 4

=item * Avoid long indentation matching the length of a property

For example, C<Data::Dump> would produce

    {
        query => { term => { user => "kimchy" } },
        sort  => [
                     { post_date => { order => "asc" } },
                     "user",
                     { name => "desc" },
                     { age => "desc" },
                     "_score",
                 ],
    }

whereas, C<Data::Pretty> would make it more crisp:

    {
        query => {
            term => { user => "kimchy" },
        },
        sort => [
            {
                post_date => { order => "asc" },
            },
            "user",
            { name => "desc" },
            { age => "desc" },
            "_score",
        ],
    }

=item * Break down structure for clarity when necessary

For example, the following structure with L<Data::Dump>:

    { from => 0, query => { term => { user => "kimchy" } }, size => 10 }

would become, under C<Data::Pretty>:

    {
        from => 0,
        query => {
            term => { user => "kimchy" },
        },
        size => 10,
    }

=item * Prevent UTF-8 characters from being encoded in hexadecimal.

C<Data::Dump> would encode C<ジャック> as C<\x{30B8}\x{30E3}\x{30C3}\x{30AF}>, which although correct, is not human readable.

However, not encoding in hexadecimal UTF-8 strings means that if you print it out, you will need to set the L<perlfunc/binmode> to C<utf-8>. You can also use L<open> when printing on the C<STDOUT> or C<STDERR>:

    use open ':std' => 'utf8';

You can disable this by setting C<$Data::Pretty::SHOW_UTF8> to false.

=item * Quoting hash keys

With C<Data::Dump>, whenever at least 1 hash key has non alphanumeric characters, it is rightfully surrounded by double quotes, but unfortunately so are all the other hash keys who do not need surrounding double quotes.

Thus, for example, L<Data::Dump> would produce:

    {
        query => {
            term => { user => "kimchy" },
        },
        sort => [
            {
                _geo_distance => {
                    "distance_type" => "sloppy_arc",
                    "mode" => "min",
                    "order" => "asc",
                    "pin.location" => [-70, 40],
                    "unit" => "km",
                },
            },
        ],
    }

whereas, C<Data::Pretty> would rather produce:

    {
        query => {
            term => { user => "kimchy" },
        },
        sort => [
            {
                _geo_distance => {
                    distance_type => "sloppy_arc",
                    mode => "min",
                    order => "asc",
                    "pin.location" => [-70, 40],
                    unit => "km",
                },
            },
        ],
    }

=item * Specify literal string values

You can set a literal string value in your data by passing it to the L<literal method|/literal>. Normally, a string is quoted and its characters within escaped as they need be. If you use C<literal>, the value will be used as-is in the dump.

For example, consider the following 2 examples, one without and the other with using C<literal>

    use Data::Dump qw( dump literal );
    my $ref = 
    {
        name => '$users->[0]',
        values => '["some","thing"]',
    };
    say dump( $ref ); # { name => "\$users->[0]", values => "[\"some\",\"thing\"]" }

    my $ref = 
    {
        name => literal( '$users->[0]' ),
        values => literal( '["some","thing"]' ),
    };
    say dump( $ref ); # { name => $users->[0], values => ["some","thing"] }

=back

The rest of this documentation is identical to the original L<Data::Dump>.

This module provide a few functions that traverse their argument and produces a string as its result. The string contains Perl code that, when C<eval>ed, produces a deep copy of the original arguments.

The main feature of the module is that it strives to produce output that is easy to read. Example:

    @a = (1, [2, 3], {4 => 5});
    dump(@a);

Produces:

    (1, [2, 3], { 4 => 5 })

If you dump just a little data, it is output on a single line. If you dump data that is more complex or there is a lot of it, line breaks are automatically added to keep it easy to read.

The following functions are provided (only the L<dd|/dd> and L<ddx|/ddx> functions are exported by default):

=head1 FUNCTIONS

=head2 dd( ... )

=head2 ddx( ... )

These functions will call L<dump|/dump> on their argument and print the result to C<STDOUT> (actually, it is the currently selected output handle, but C<STDOUT> is the default for that).

The difference between them is only that C<ddx> will prefix the lines it prints with "# " and mark the first line with the file and line number where it was called. This is meant to be useful for debug printouts of state within programs.

=head2 dump

Returns a string containing a Perl expression. If you pass this string to Perl's built-in eval() function it should return a copy of the arguments you passed to dump().

If you call the function with multiple arguments then the output will be wrapped in parenthesis C<( ..., ... )>.

If you call the function with a single argument the output will not have the wrapping.

If you call the function with a single scalar (non-reference) argument it will just return the scalar quoted if needed, but never break it into multiple lines.

If you pass multiple arguments or references to arrays of hashes then the return value might contain line breaks to format it for easier reading. The returned string will never be C<\n> terminated, even if contains multiple lines. This allows code like this to place the semicolon in the expected place:

    print '$obj = ', dump($obj), ";\n";

If C<dump> is called in void context, then the dump is printed on STDERR and then C<\n> terminated.
You might find this useful for quick debug printouts, but the Ldd|/dd> and L<ddx/ddx> functions might be better alternatives
for this.

There is no difference between L<dump|/dump> and L<pp|/pp>, except that L<dump|/dump> shares its name with a not-so-useful perl builtin.  Because of this some might want to avoid using that name.

=head2 dumpf( ..., \&filter )

Short hand for calling the L<dump_filtered|Data::Pretty::Filtered/dump_filtered> function of L<Data::Pretty::Filtered>.

This works like L<dump|/dump>, but the last argument should be a filter callback function. As objects are visited the filter callback is invoked and it can modify how the objects are dumped.

=for Pod::Coverage format_list

=for Pod::Coverage fullname

=head2 literal

This takes a value and marks it as a literal value that will be used as-is in the resulting dump.

For example, consider the following 2 examples, one without and the other with using C<literal>

    use Data::Dump qw( dump literal );
    my $ref = 
    {
        name => '$users->[0]',
        values => '["some","thing"]',
    };
    say dump( $ref ); # { name => "\$users->[0]", values => "[\"some\",\"thing\"]" }

    my $ref = 
    {
        name => literal( '$users->[0]' ),
        values => literal( '["some","thing"]' ),
    };
    say dump( $ref ); # { name => $users->[0], values => ["some","thing"] }

=head2 pp

Same as L</dump>

=head2 quote( $string )

Returns a quoted version of the provided string.

It differs from C<dump($string)> in that it will quote even numbers and not try to come up with clever expressions that might shorten the output. If a non-scalar argument is provided then it's just stringified instead of traversed.

=for Pod::Coverage str

=for Pod::Coverage tied_str

=head1 CONFIGURATION

There are a few global variables that can be set to modify the output generated by the dump functions. It's wise to localize the setting of these.

=head2 C<$Data::Pretty::CODE_DEPARSE>

When set to true, which is the default, this will use L<B::Deparse>, if available, to reproduce the perl code of the anonymous subroutines found. Note that due to perl's internal way of working, the code reproduced might not be exactly the same as the original.

=head2 C<$Data::Pretty::INDENT>

This holds the string that's used for indenting multiline data structures. It's default value is C<"    "> (four spaces). Set it to C<""> to suppress indentation. Setting it to C<"| "> makes for nice visuals even if the dump output then fails to be valid Perl.

=head2 C<$Data::Pretty::SHOW_UTF8>

When set to true (default), this will show the UTF-8 texts as is and when set to a false value, this will revert to the L<Data::Dump> original behaviour of showing the text with its characters encoded in hexadecimal. For example, a string like

    ジャック

would be encoded in L<Data::Dump> as:

    \x{30B8}\x{30E3}\x{30C3}\x{30AF}

=head2 C<$Data::Pretty::TRY_BASE64>

How long must a binary string be before we try to use the L<base64 encoding|MIME::Base64> for the dump output. The default is C<50>. Set it to C<0> to disable base64 dumps.

=head1 LIMITATIONS

=over 4

=item 1. Core reference

Code references will be dumped as C<< sub { ... } >>. Thus, C<eval>ing them will not reproduce the original routine. The C<...>-operator used will also require perl-5.12 or better to be evaled.

=item 2. Importing dump

If you forget to explicitly import the C<dump> function, your code will core dump. That's because you just called the builtin L<dump|perlfunc/dump> function by accident, which intentionally dumps core. Because of this you can also import the same function as C<pp>, mnemonic for "pretty-print".

=back

=head1 SEE ALSO

L<Data::Pretty::Filtered>, L<Data::Pretty::FilterContext>

L<Data::Dump>, L<Data::Dumper>

=head1 CREDITS

Credits to Gisle Aas for the original L<Data::Dump> version and to Breno G. de Oliveira for maintaining it.

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
