## no critic: Modules::ProhibitAutomaticExportation

package Data::Dump::HTML::Collapsible;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
use HTML::Entities qw(encode_entities);
use Scalar::Util qw(looks_like_number blessed reftype refaddr);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-12'; # DATE
our $DIST = 'Data-Dump-HTML-Collapsible'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT = qw(dd);
our @EXPORT_OK = qw(dump);

# for when dealing with circular refs
our %_seen_refaddrs;
our %_subscripts;
our @_fixups;

our $OPT_PERL_VERSION = "5.010";
our $OPT_REMOVE_PRAGMAS = 0;
our $OPT_DEPARSE = 1;
our $OPT_STRINGIFY_NUMBERS = 0;

# BEGIN COPY PASTE FROM Data::Dump
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
sub _double_quote {
    local($_) = $_[0];

    # If there are many '"' we might want to use qq() instead
    s/([\\\"\@\$])/\\$1/g;
    return qq("$_") unless /[^\040-\176]/;  # fast exit

    s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

    # no need for 3 digits in escape for these
    s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

    s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
    s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

    return qq("$_");
}
# END COPY PASTE FROM Data::Dump

# BEGIN COPY PASTE FROM String::PerlQuote
sub _single_quote {
    local($_) = $_[0];
    s/([\\'])/\\$1/g;
    return qq('$_');
}
# END COPY PASTE FROM String::PerlQuote

sub _dump_code {
    my $code = shift;

    state $deparse = do {
        require B::Deparse;
        B::Deparse->new("-l"); # -i option doesn't have any effect?
    };

    my $res = $deparse->coderef2text($code);

    my ($res_before_first_line, $res_after_first_line) =
        $res =~ /(.+?)^(#line .+)/ms;

    if ($OPT_REMOVE_PRAGMAS) {
        $res_before_first_line = "{";
    } elsif ($OPT_PERL_VERSION < 5.016) {
        # older perls' feature.pm doesn't yet support q{no feature ':all';}
        # so we replace it with q{no feature}.
        $res_before_first_line =~ s/no feature ':all';/no feature;/m;
    }
    $res_after_first_line =~ s/^#line .+//gm;

    $res = "sub" . $res_before_first_line . $res_after_first_line;
    $res =~ s/^\s+//gm;
    $res =~ s/\n+//g;
    $res =~ s/;\}\z/}/;
    $res;
}

sub _quote_key {
    $_[0] =~ /\A-?[A-Za-z_][A-Za-z0-9_]*\z/ ||
        $_[0] =~ /\A-?[1-9][0-9]{0,8}\z/ ? $_[0] : _double_quote($_[0]);
}

sub _dump {
    my ($val, $subscript) = @_;

    my $ref = ref($val);
    if ($ref eq '') {
        if (!defined($val)) {
            return "undef";
        } elsif (looks_like_number($val) && !$OPT_STRINGIFY_NUMBERS &&
                     # perl does several normalizations to number literal, e.g.
                     # "+1" becomes 1, 0123 is octal literal, etc. make sure we
                     # only leave out quote when the number is not normalized
                     $val eq $val+0 &&
                     # perl also doesn't recognize Inf and NaN as numeric
                     # literals (ref: perldata) so these unquoted literals will
                     # choke under 'use strict "subs"
                     $val !~ /\A-?(?:inf(?:inity)?|nan)\z/i
                 ) {
            return $val;
        } else {
            return _double_quote($val);
        }
    }
    my $refaddr = refaddr($val);
    $_subscripts{$refaddr} //= $subscript;
    if ($_seen_refaddrs{$refaddr}++) {
        my $target = "\$var" .
            ($_subscripts{$refaddr} ? "->$_subscripts{$refaddr}" : "");
        push @_fixups, "\$var->$subscript=$target;";
        return _single_quote($target);
    }

    my $class;

    if ($ref eq 'Regexp' || $ref eq 'REGEXP') {
        require Regexp::Stringify;
        return Regexp::Stringify::stringify_regexp(
            regexp=>$val, with_qr=>1, plver=>$OPT_PERL_VERSION);
    }

    if (blessed $val) {
        $class = $ref;
        $ref = reftype($val);
    }

    my $res;
    if ($ref eq 'ARRAY') {
        $res = "<details><summary>$subscript ".encode_entities("$val")."</summary>[";
        my $i = 0;
        for (@$val) {
            $res .= ",\n" if $i;
            $res .= _dump($_, "$subscript\[$i]");
            $i++;
        }
        $res .= "]</details>";
    } elsif ($ref eq 'HASH') {
        $res = "<details><summary>$subscript ".encode_entities("$val")."</summary>{";
        my $i = 0;
        for (sort keys %$val) {
            $res .= ",\n" if $i;
            my $k = _quote_key($_);
            my $v = _dump($val->{$_}, "$subscript\{$k}");
            $res .= "$k =&gt; $v";
            $i++;
        }
        $res .= "}</details>";
    } elsif ($ref eq 'SCALAR') {
        if (defined $class) {
            $res = "do { my \$o="._dump($$val, $subscript)."; \\\$o}";
        } else {
            $res = "\\"._dump($$val, $subscript);
        }
    } elsif ($ref eq 'REF') {
        $res = "\\"._dump($$val, $subscript);
    } elsif ($ref eq 'CODE') {
        $res = $OPT_DEPARSE ? _dump_code($val) : 'sub{"DUMMY"}';
    } else {
        die "Sorry, I can't dump $val (ref=$ref) yet";
    }

    $res = "bless($res,"._double_quote($class).")" if defined($class);
    $res;
}

our $_is_dd;
our $_is_ellipsis;
sub _dd_or_dump {
    local %_seen_refaddrs;
    local %_subscripts;
    local @_fixups;

    my $res;
    if (@_ > 1) {
        $res = "(" . join(",", map {_dump($_, '')} @_) . ")";
    } else {
        $res = _dump($_[0], '');
    }
    if (@_fixups) {
        $res = "do{my\$var=$res;" . join("", @_fixups) . "\$var}";
    }

    $res = "<style>details {  margin-left: 1em; } summary { margin-left: -1em; }</style><pre>$res</pre>";
    if ($_is_dd) {
        say $res;
        return wantarray() || @_ > 1 ? @_ : $_[0];
    } else {
        return $res;
    }
}

sub dd { local $_is_dd=1; _dd_or_dump(@_) } # goto &sub doesn't work with local
sub dump { goto &_dd_or_dump }

1;
# ABSTRACT: Dump Perl data structures as HTML document with collapsible sections

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::HTML::Collapsible - Dump Perl data structures as HTML document with collapsible sections

=head1 VERSION

This document describes version 0.002 of Data::Dump::HTML::Collapsible (from Perl distribution Data-Dump-HTML-Collapsible), released on 2024-03-12.

=head1 SYNOPSIS

 use Data::Dump::HTML::Collapsible; # exports dd(), can export dump()
 dd [1, 2, 3];

=head1 DESCRIPTION

This module dumps Perl data structure to HTML document where you can expand and
collapse nodes to drill down and roll up your data. It currently uses the C<<
<summary> >> and C<< <details> >> HTML elements.

=head1 VARIABLES

=head2 $Data::Dump::HTML::Collapsible::OPT_PERL_VERSION

String, default: 5.010.

Set target Perl version. If you set this to, say C<5.010>, then the dumped code
will keep compatibility with Perl 5.10.0. This is used in the following ways:

=over

=item * passed to L<Regexp::Stringify>

=item * when dumping code references

For example, in perls earlier than 5.016, feature.pm does not understand:

 no feature ':all';

so we replace it with:

 no feature;

=back

=head2 $Data::Dump::HTML::Collapsible::OPT_REMOVE_PRAGMAS

Bool, default: 0.

If set to 1, then pragmas at the start of coderef dump will be removed. Coderef
dump is produced by L<B::Deparse> and is of the form like:

 sub { use feature 'current_sub', 'evalbytes', 'fc', 'say', 'state', 'switch', 'unicode_strings', 'unicode_eval'; $a <=> $b }

If you want to dump short coderefs, the pragmas might be distracting. You can
turn turn on this option which will make the above dump become:

 sub { $a <=> $b }

Note that without the pragmas, the dump might be incorrect.

=head2 $Data::Dump::HTML::Collapsible::::OPT_DEPARSE

Bool, default: 1.

Can be set to 0 to skip deparsing code. Coderefs will be dumped as
C<sub{"DUMMY"}> instead, like in Data::Dump.

=head2 $Data::Dump::HTML::Collapsible::::OPT_STRINGIFY_NUMBERS

Bool, default: 0.

If set to true, will dump numbers as quoted string, e.g. 123 as "123" instead of
123. This might be helpful if you want to compute the hash of or get a canonical
representation of data structure.

=head1 FUNCTIONS

=head2 dd

=head2 dump

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-HTML-Collapsible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-HTML-Collapsible>.

=head1 SEE ALSO

Other data structure dumpers to (collapsible) tree: L<Data::HTML::TreeDumper>
(doesn't handle recursion), L<Data::TreeDumper>
(L<Data::TreeDumper::Renderer::DHTML>, L<Data::TreeDumper::Renderer::GTK>),
L<Data::Dumper::GUI>.

Other data structure dumpers that outputs to HTML: L<Data::HTMLDumper>,
L<Data::Dumper::HTML>, L<Data::Format::Pretty::HTML>.

Other data structure dumpers: L<Data::Dumper>, L<Data::Dump>,
L<Data::Dump::Color>, L<Data::Dmp>, L<Data::Printer>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-HTML-Collapsible>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
