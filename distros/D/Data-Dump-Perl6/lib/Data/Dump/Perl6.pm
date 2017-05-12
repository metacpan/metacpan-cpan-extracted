package Data::Dump::Perl6;

use strict;
use vars qw(@EXPORT @EXPORT_OK $VERSION $DEBUG);
use subs qq(dump);

require Exporter;
*import    = \&Exporter::import;
@EXPORT    = qw(dd_perl6 ddx_perl6);
@EXPORT_OK = qw(dump_perl6 pp_perl6 quote_perl6);

$VERSION = "0.01";
$DEBUG   = 0;

use overload ();
use Scalar::Util qw(blessed);
use vars qw(%seen %refcnt @dump @fixup $INDENT $UTF8 $PARAM_NAME);

$INDENT     = "  "      unless defined $INDENT;
$PARAM_NAME = 'content' unless defined $PARAM_NAME;
$UTF8       = 0         unless defined $UTF8;

my %fh = (
          '*main::STDIN'  => '$*IN',
          '*main::STDOUT' => '$*OUT',
          '*main::STDERR' => '$*ERR',
         );

sub dump_perl6 {
    local %seen;
    local %refcnt;
    local @fixup;

    my $name = "a";
    my @dump;

    for my $v (@_) {
        my $val = _dump($v, $name, [], tied($v));
        push(@dump, [$name, $val]);
    }
    continue {
        $name++;
    }

    my $out = "";
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
    $out .= "(" if $paren;
    $out .= format_list($paren, undef, map { defined($_->[1]) ? $_->[1] : "\$" . $_->[0] } @dump);
    $out .= ")" if $paren;

    if (%refcnt) {
        $out .= ";\n";
        $out =~ s/^/$INDENT/gm;
        $out = "do {\n$out}";
    }

    print STDERR "$out\n" unless defined wantarray;
    $out;
}

*pp_perl6 = \&dump_perl6;

sub dd_perl6 {
    print dump_perl6(@_), "\n";
}

sub ddx_perl6 {
    my (undef, $file, $line) = caller;
    $file =~ s,.*[\\/],,;
    my $out = "$file:$line: " . dump_perl6(@_) . "\n";
    $out =~ s/^/# /gm;
    print $out;
}

sub _dump {
    my $ref = ref $_[0];
    my $rval = $ref ? $_[0] : \$_[0];
    shift;

    my ($name, $idx, $dont_remember, $pclass, $pidx) = @_;

    my ($class, $type, $id);
    my $strval = overload::StrVal($rval);

    # Parse $strval without using regexps, in order not to clobber $1, $2,...
    if ((my $i = rindex($strval, "=")) >= 0) {
        $class = substr($strval, 0, $i);
        $strval = substr($strval, $i + 1);
    }
    if ((my $i = index($strval, "(0x")) >= 0) {
        $type = substr($strval, 0,      $i);
        $id   = substr($strval, $i + 2, -1);
    }
    else {
        die "Can't parse " . overload::StrVal($rval);
    }
    if ($] < 5.008 && $type eq "SCALAR") {
        $type = "REF" if $ref eq "REF";
    }
    warn "\$$name(@$idx) $class $type $id ($ref)" if $DEBUG;

    my $out;
    my $comment;
    my $hide_keys;

    unless ($dont_remember) {
        if (my $s = $seen{$id}) {
            my ($sname, $sidx) = @$s;
            $refcnt{$sname}++;
            my $sref = fullname($sname, $sidx, ($ref && $type eq "SCALAR"));
            warn "SEEN: [\$$name(@$idx)] => [\$$sname(@$sidx)] ($ref,$sref)" if $DEBUG;

            unless ($sname eq $name) {
                $sref =~ s/\.\Q$PARAM_NAME\E\z//;
                return $sref;
            }
            $refcnt{$name}++;

            # Remove the "$PARAM_NAME" from blessed objects
            if (blessed($rval)) {
                $idx->[-1] =~ s/\.\Q$PARAM_NAME\E\z//;
                $sref =~ s/\.\Q$PARAM_NAME\E\z//;
            }

            push(@fixup, fullname($name, $idx) . " = $sref");
            return "do{my \$fix}" if @$idx && $idx->[-1] eq '$';
            return "Any";
        }
        $seen{$id} = [$name, $idx];
    }

    if ($class) {
        $pclass = $class;
        $pidx   = @$idx;
    }

    if (defined $out) {

        # keep it
    }
    elsif ($type eq "SCALAR" || $type eq "REF" || $type eq "REGEXP") {
        if ($ref) {
            if ($class && $class eq "Regexp") {
                die "Can't handle regular expressions for Perl6";
                my $v = "$rval";

                my $mod = "";
                if ($v =~ /^\(\?\^?([msix-]*):([\x00-\xFF]*)\)\z/) {
                    $mod = $1;
                    $v   = $2;
                    $mod =~ s/-.*//;
                }

                my $sep       = '/';
                my $sep_count = ($v =~ tr/\///);
                if ($sep_count) {

                    # see if we can find a better one
                    for ('|', ',', ':') {
                        my $c = eval "\$v =~ tr/\Q$_\E//";

                        #print "SEP $_ $c $sep_count\n";
                        if ($c < $sep_count) {
                            $sep       = $_;
                            $sep_count = $c;
                            last if $sep_count == 0;
                        }
                    }
                }
                $v =~ s/\Q$sep\E/\\$sep/g;

                $out = "rx$sep$v$sep$mod";
                undef($class);
            }
            else {
                delete $seen{$id} if $type eq "SCALAR";    # will be seen again shortly
                my $val = _dump($$rval, $name, [@$idx, ""], 0, $pclass, $pidx);

                #$out = $class ? "do{\\(my \$o = $val)}" : "\\($val)";
                #$out = $class ? '' : "\\($val)";
                $out = $val;
            }
        }
        else {
            if (!defined $$rval) {
                $out = "Nil";
            }
            elsif (
                   do { no warnings 'numeric'; $$rval + 0 eq $$rval }
              ) {
                $out = $$rval;
            }
            else {
                $out = str($$rval);
            }
            if ($class && !@$idx) {

                # Top is an object, not a reference to one as perl needs
                $refcnt{$name}++;
                my $obj = fullname($name, $idx);

                #my $cl  = quote_perl6($class);
                #push(@fixup, "bless \\$obj, $cl");
                push @fixup, "$class.bless($PARAM_NAME => $obj)";
            }
        }
    }
    elsif ($type eq "GLOB") {
        if ($ref) {
            delete $seen{$id};
            my $val = _dump($$rval, $name, [@$idx, "*"], 0, $pclass, $pidx);

            if (exists $fh{$val}) {
                $out = $fh{$val};
            }
            else {
                $out = $val;
            }
        }
        else {
            my $val = "$$rval";
            $out = "$$rval";

            if (exists $fh{$out}) {
                $out = $fh{$out};
            }
            else {
                $out =~ s/^\*(?:main::)?//;
                $out = qq{IO::Handle.new(path => IO::Special.new(what => "<$out>"), ins => 0, chomp => Bool::True)};

                #die "Can't handle filehandles for Perl6"
            }
        }
    }
    elsif ($type eq "ARRAY") {
        my @vals;
        my $tied = tied_str(tied(@$rval));
        my $i    = 0;
        for my $v (@$rval) {
            push(@vals, _dump($v, $name, [@$idx, "[$i]" . (blessed($v) ? ".$PARAM_NAME" : '')], $tied, $pclass, $pidx));
            $i++;
        }
        $out = "[" . format_list(1, $tied, @vals) . "]";
    }
    elsif ($type eq "HASH") {
        my (@keys, @vals);
        my $tied = tied_str(tied(%$rval));

        # statistics to determine variation in key lengths
        my $kstat_max  = 0;
        my $kstat_sum  = 0;
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
            @orig_keys = sort { (lc($a) cmp lc($b)) || ($a cmp $b) } @orig_keys;
        }
        else {
            @orig_keys = sort { $a <=> $b } @orig_keys;
        }

        my $quote;
        for my $key (@orig_keys) {
            next if $key =~ /^[a-zA-Z_]\w*\z/;
            next if $key =~ /^[1-9]\d{0,8}\z/;

            if ($UTF8) {
                next if $key =~ /^[\pL_][\pL\w]*\z/;
            }

            $quote++;
            last;
        }

        for my $key (@orig_keys) {
            my $val = \$rval->{$key};    # capture value before we modify $key

            my $unquoted_key = $key;
            $key       = quote_perl6($key) if $quote;
            $kstat_max = length($key)      if length($key) > $kstat_max;
            $kstat_sum  += length($key);
            $kstat_sum2 += length($key) * length($key);

            push(@keys, $key);

            $unquoted_key =~ s/([<>])/\\$1/g;
            push(
                 @vals,
                 _dump(
                       $$val, $name, [@$idx, "<$unquoted_key>" . (blessed($$val) ? ".$PARAM_NAME" : '')],
                       $tied, $pclass, $pidx
                      )
                );
        }
        my $nl       = "";
        my $klen_pad = 0;
        my $tmp      = "@keys @vals";
        if (length($tmp) > 60 || $tmp =~ /\n/ || $tied) {
            $nl = "\n";

            # Determine what padding to add
            if ($kstat_max < 4) {
                $klen_pad = $kstat_max;
            }
            elsif (@keys >= 2) {
                my $n      = @keys;
                my $avg    = $kstat_sum / $n;
                my $stddev = sqrt(($kstat_sum2 - $n * $avg * $avg) / ($n - 1));

                # I am not actually very happy with this heuristics
                if ($stddev / $kstat_max < 0.25) {
                    $klen_pad = $kstat_max;
                }
                if ($DEBUG) {
                    push(@keys, "__S");
                    push(@vals, sprintf("%.2f (%d/%.1f/%.1f)", $stddev / $kstat_max, $kstat_max, $avg, $stddev));
                }
            }
        }
        $out = "{$nl";
        $out .= "$INDENT# $tied$nl" if $tied;
        while (@keys) {
            my $key  = shift @keys;
            my $val  = shift @vals;
            my $vpad = $INDENT . (" " x ($klen_pad ? $klen_pad + 4 : 0));
            $val =~ s/\n/\n$vpad/gm;
            my $kpad = $nl ? $INDENT : " ";
            $key .= " " x ($klen_pad - length($key)) if $nl && $klen_pad > length($key);
            $out .= "$kpad$key => $val,$nl";
        }
        $out =~ s/,$/ / unless $nl;
        $out .= "}";
    }
    elsif ($type eq "CODE") {
        $out = 'sub { ... }';
    }
    elsif ($type eq "VSTRING") {
        $out = sprintf 'v%vd', $$rval;
    }
    else {
        warn "Can't handle $type data";
        $out = "'#$type#'";
    }

    if ($class && $ref) {

        # Class must be something like 'Class::Name'
        if ($class !~ /^[\pL_][\pL\d_]*(?:::[\pL\d_]+)*\z/) {
            die "Can't handle class name <$class> for Perl6";
        }

        $out = "$class.bless($PARAM_NAME => $out)";
    }
    if ($comment) {
        $comment =~ s/^/# /gm;
        $comment .= "\n" unless $comment =~ /\n\z/;
        $comment =~ s/^#[ \t]+\n/\n/;
        $out = "$comment$out";
    }
    return $out;
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

sub fullname {
    my ($name, $idx, $ref) = @_;
    substr($name, 0, 0) = "\$";

    my @i = @$idx;    # need copy in order to not modify @$idx
    if ($ref && @i && $i[0] eq "\$") {
        shift(@i);    # remove one deref
        $ref = 0;
    }
    while (@i && $i[0] eq "\$") {    # this will never happen
        shift @i;
        $name = "\$($name)";
    }

    my $last_was_index;
    for my $i (@i) {
        if ($i eq "*" || $i eq "\$") {
            $last_was_index = 0;

            #$name = "$i\{$name}";
            #$name = "$i$name";
            $name = "$i\($name)";
        }
        elsif ($i =~ s/^\*//) {
            $name .= $i;
            $last_was_index++;
        }
        else {
            #$name .= "->" unless $last_was_index++;
            $name .= $i;
        }
    }

    #$name = "\\($name)" if $ref;
    $name;
}

sub format_list {
    my $paren      = shift;
    my $comment    = shift;
    my $indent_lim = $paren ? 0 : 1;
    if (@_ > 3) {

        # can we use range operator to shorten the list?
        my $i = 0;
        while ($i < @_) {
            my $j = $i + 1;
            my $v = $_[$i];
            while ($j < @_) {

                # XXX allow string increment too?
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
                last if $_[$j] ne $v;
                $j++;
            }
            if ($j - $i > 3) {
                splice(@_, $i, $j - $i, "$_[$i] .. $_[$j-1]");
            }
            $i++;
        }
    }
    my $tmp = "@_";
    if ($comment || (@_ > $indent_lim && (length($tmp) > 60 || $tmp =~ /\n/))) {
        my @elem = @_;
        for (@elem) { s/^/$INDENT/gm; }
        return "\n" . ($comment ? "$INDENT# $comment\n" : "") . join(",\n", @elem, "");
    }
    else {
        return join(", ", @_);
    }
}

sub str {
    if (length($_[0]) > 20) {
        for ($_[0]) {

            # Check for repeated string
            if (/^(.)\1\1\1/s) {

                # seems to be a repeating sequence, let's check if it really is
                # without backtracking
                unless (/[^\Q$1\E]/) {
                    my $base   = quote_perl6($1);
                    my $repeat = length;
                    return "($base x $repeat)";
                }
            }

            # Length protection because the RE engine will blow the stack [RT#33520]
            if (length($_) < 16 * 1024 && /^(.{2,5}?)\1*\z/s) {
                my $base   = quote_perl6($1);
                my $repeat = length($_) / length($1);
                return "($base x $repeat)";
            }
        }
    }

    scalar &quote_perl6;
}

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
sub quote_perl6 {
    local ($_) = $_[0];

    # If there are many '"' we might want to use qq() instead
    s/([\\\"\@\${}])/\\$1/g;
    return qq("$_") unless /[^\040-\176]/;    # fast exit

    s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

    # no need for 3 digits in escape for these
    #s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

    s/([\0-\037])/sprintf('\\x[%x]',ord($1))/eg;

    if ($UTF8) {
        s/([^\pL\pN\pM\pP\pS\040-\176])/sprintf('\\x[%x]',ord($1))/eg;
    }
    else {
        s/([\177-\377])/sprintf('\\x[%x]',ord($1))/eg;
        s/([^\040-\176])/sprintf('\\x[%x]',ord($1))/eg;
    }

    return qq("$_");
}

1;

=encoding utf8

=head1 NAME

Data::Dump::Perl6 - Pretty printing of data structures as Perl6 code

=head1 SYNOPSIS

 use Data::Dump::Perl6 qw(dump_perl6);

 $str = dump_perl6(@list);
 print "$str\n";

=head1 DESCRIPTION

This module provide functions that takes a list of values as their
argument and produces a string as its result. The string contains Perl6
code that, when interpreted by perl6, produces a deep copy of the original
arguments.

The main feature of the module is that it strives to produce output
that is easy to read.  Example:

    @a = (1, [2, 3], {4 => 5});
    dump_perl6(@a);

Produces:

    "(1, [2, 3], { 4 => 5 })"

If you dump just a little data, it is output on a single line. If
you dump data that is more complex or there is a lot of it, line breaks
are automatically added to keep it easy to read.

The following functions are provided (only the dd* functions are exported by default):

=over

=item dump_perl6( ... )

=item pp_perl6( ... )

If you call the function with multiple arguments then the output will
be wrapped in parenthesis "( ..., ... )".  If you call the function with a
single argument the output will not have the wrapping.  If you call the function with
a single scalar (non-reference) argument it will just return the
scalar quoted if needed, but never break it into multiple lines.  If you
pass multiple arguments or references to arrays of hashes then the
return value might contain line breaks to format it for easier
reading.  The returned string will never be "\n" terminated, even if
contains multiple lines.  This allows code like this to place the
semicolon in the expected place:

   print '$obj = ', dump_perl6($obj), ";\n";

If dump_perl6() is called in void context, then the dump is printed on
STDERR and then "\n" terminated.  You might find this useful for quick
debug printouts, but the dd*() functions might be better alternatives
for this.

There is no difference between dump_perl6() and pp_perl6().

=item quote_perl6( $string )

Returns a quoted version of the provided string.

It differs from C<dump_perl6($string)> in that it will quote even numbers
and not try to come up with clever expressions that might shorten the
output.  If a non-scalar argument is provided then it's just stringified
instead of traversed.

=item dd_perl6( ... )

=item ddx_perl6( ... )

These functions will call dump_perl6() on their argument and print the
result to STDOUT (actually, it's the currently selected output handle, but
STDOUT is the default for that).

The difference between them is only that ddx_perl6() will prefix the
lines it prints with "# " and mark the first line with the file and
line number where it was called.  This is meant to be useful for debug
printouts of state within programs.

=back

=head1 CONFIGURATION

There are a few global variables that can be set to modify the output
generated by the dump functions.  It's wise to localize the setting of
these.

=over

=item $Data::Dump::Perl6::INDENT

This holds the string that's used for indenting multiline data structures.
It's default value is "  " (two spaces).  Set it to "" to suppress indentation.

=item $Data::Dump::Perl6::UTF8

A true value will dump strings with original Unicode letters, symbols, numbers
and marks. By default, hexadecimal escapes are used for non-ASCII code points.

=item $Data::Dump::Perl6::PARAM_NAME

This holds the name of a class parameter, which is used in creating Perl6
blessed objects. The default value is C<content>.

Example:

 bless([], "Foo")

is dumped as:

 Foo.bless(content => [])

=back

=head1 BUGS/LIMITATIONS

Code references will be dumped as C<< sub { ... } >>.

Regular expressions are currently unsupported. An exception will be
thrown when any regular expression is encountered.

Filehandles are limited to C<STDIN>, C<STDOUT> and C<STDERR>.

Class names cannot contain punctuation marks.

=head1 SEE ALSO

L<Data::Dump> (from which this codebase is based)

L<JSON>, L<YAML> - Another alternative to exchange data with Perl6 (and
other languages) is to export/import via YAML and JSON.

=head1 ACKNOWLEDGEMENTS

Data::Dump::Perl6 is a quick hack, based on Gisle Ass' wonderful C<Data::Dump>.

=head1 REPOSITORY

L<https://github.com/trizen/Data-Dump-Perl6>

=head1 AUTHORS

The C<Data::Dump::Perl6> module is written by Daniel Șuteu
<trizenx@gmail.com>, based on C<Data::Dump> module by Gisle Aas
<gisle@aas.no>, based on C<Data::Dumper> by Gurusamy Sarathy
<gsar@umich.edu>.

 Copyright 2015 Daniel Șuteu.
 Copyright 1998-2010 Gisle Aas.
 Copyright 1996-1998 Gurusamy Sarathy.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
