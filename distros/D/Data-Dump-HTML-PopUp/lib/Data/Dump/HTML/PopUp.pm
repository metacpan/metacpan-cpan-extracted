## no critic: Modules::ProhibitAutomaticExportation

package Data::Dump::HTML::PopUp;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
use HTML::Entities qw(encode_entities);
use Scalar::Util qw(looks_like_number blessed reftype refaddr);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-17'; # DATE
our $DIST = 'Data-Dump-HTML-PopUp'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT = qw(dd);
our @EXPORT_OK = qw(dump);

# for when dealing with circular refs
our %_seen_refaddrs;
our %_subscripts;
our @_fixups;
our @_result_divs; # elem: [refaddr, subscript, html-source]

our $OPT_PERL_VERSION = "5.010";
our $OPT_REMOVE_PRAGMAS = 0;
our $OPT_DEPARSE = 1;
our $OPT_STRINGIFY_NUMBERS = 0;
our $OPT_LIBRARY_LINK_MODE = "local";

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
    my ($val, $subscript, $depth) = @_;

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
            return encode_entities(_double_quote($val));
        }
    }
    my $refaddr = sprintf("%x", refaddr($val));
    $_subscripts{$refaddr} //= $subscript;
    if ($_seen_refaddrs{$refaddr}++) {
        my $target = "\$var" .
            ($_subscripts{$refaddr} ? "->$_subscripts{$refaddr}" : "");
        push @_fixups, "\$var->$subscript = $target;\n";
        return "<a href=#r$refaddr>".encode_entities(_single_quote($target))."</a>";
    }

    my $class;

    if ($ref eq 'Regexp' || $ref eq 'REGEXP') {
        require Regexp::Stringify;
        return encode_entities(
            Regexp::Stringify::stringify_regexp(
                regexp=>$val, with_qr=>1, plver=>$OPT_PERL_VERSION)
        );
    }

    if (blessed $val) {
        $class = $ref;
        $ref = reftype($val);
    }

    my $res = "";
    $res .= ("  " x $depth);
    if ($ref eq 'ARRAY') {
        $res .= "[\n";
        my $i = 0;
        for (@$val) {
            $res .= ",   # ".("." x $depth)."[".($i-1)."]\n" if $i;
            $res .= ("  " x ($depth+1));
            my $elem_ref = ref $_;
            my $elem_res = _dump($_, "$subscript\[$i]", $depth+1);
            if (($elem_ref eq 'ARRAY' || $elem_ref eq 'HASH') && length($elem_res) > 100) {
                my $elem_refaddr = sprintf("%x", refaddr($_));
                push @_result_divs, [$elem_refaddr, "$subscript\[$i]", $elem_res];
                $res .= qq(<a href="#r$elem_refaddr" target="_modal">).encode_entities(_single_quote("\$var->$subscript\[$i]"))."</a>";
            } else {
                $res .= $elem_res;
            }
            $i++;
        }
        $res .= "\n" . ("  " x $depth) . "]";
    } elsif ($ref eq 'HASH') {
        $res .= "{\n";
        my $i = 0;
        for (sort keys %$val) {
            $res .= ",   # ".("." x $depth)."{".($i-1)."}\n" if $i;
            $res .= ("  " x ($depth+1));
            my $k = _quote_key($_);
            my $val_ref = ref $val->{$_};
            my $val_res = _dump($val->{$_}, "$subscript\{$k}", $depth+1);
            if (($val_ref eq 'ARRAY' || $val_ref eq 'HASH') && length($val_res) > 100) {
                my $val_refaddr = sprintf("%x", refaddr($val->{$_}));
                push @_result_divs, [$val_refaddr, "$subscript\{$k}", $val_res];
                $res .= encode_entities($k) . " =&gt; " . qq(<a href="#r$val_refaddr" target="_modal">).encode_entities(_single_quote("\$var->$subscript\{$k}"))."</a>";
            } else {
                $res .= encode_entities($k) . " =&gt; " . $val_res;
            }
            $i++;
        }
        $res .= "\n" . ("  " x $depth) . "}";
    } elsif ($ref eq 'SCALAR') {
        if (defined $class) {
            $res .= "do { my \$o="._dump($$val, $subscript)."; \\\$o}";
        } else {
            $res .= "\\"._dump($$val, $subscript);
        }
    } elsif ($ref eq 'REF') {
        $res .= "\\"._dump($$val, $subscript);
    } elsif ($ref eq 'CODE') {
        $res .= encode_entities( $OPT_DEPARSE ? _dump_code($val) : 'sub{"DUMMY"}' );
    } else {
        die "Sorry, I can't dump $val (ref=$ref) yet";
    }

    $res = "bless($res,".encode_entities(_double_quote($class)).")" if defined($class);
    $res;
}

sub _escape_uri {
    require URI::Escape;
    URI::Escape::uri_escape(shift, "^A-Za-z0-9\-\._~/:"); # : for drive notation on Windows
}

sub _preamble {
    if ($OPT_LIBRARY_LINK_MODE eq 'none') {
        return '';
    }

    my $jquery_ver = '3.7.1';
    my $modally_ver = '1.1.0';
    my $res = '';
    if ($OPT_LIBRARY_LINK_MODE eq 'embed') {
        require File::ShareDir;
        require File::Slurper;
        my $dist_dir = File::ShareDir::dist_dir('Data-Dump-HTML-PopUp');
        my $path;

        $path = "$dist_dir/modally-$modally_ver/jquery.modally.css";
        -r $path or die "Can't embed $path: $!";
        $res .= "<!-- embedding jquery.modally.css -->\n<style>\n" . File::Slurper::read_text($path) . "\n</style>\n\n";

        $path = "$dist_dir/jquery-$jquery_ver/jquery.min.js";
        -r $path or die "Can't embed $path: $!";
        $res .= "<!-- embedding jquery.min.js -->\n<style>\n" . File::Slurper::read_text($path) . "\n</style>\n\n";

        $path = "$dist_dir/modally-$modally_ver/jquery.modally.js";
        -r $path or die "Can't embed $path: $!";
        $res .= "<!-- embedding jquery.modally.js -->\n<style>\n" . File::Slurper::read_text($path) . "\n</style>\n\n";
    } elsif ($OPT_LIBRARY_LINK_MODE eq 'local') {
        require File::ShareDir;
        my $dist_dir = File::ShareDir::dist_dir('Data-Dump-HTML-PopUp');
        $dist_dir =~ s!\\!/!g if $^O eq 'MSWin32';
        $res .= qq(<link rel="stylesheet" type="text/css" href="file://)._escape_uri("$dist_dir/modally-$modally_ver/jquery.modally.css").qq(">\n);
        $res .= qq(<script src="file://)._escape_uri("$dist_dir/jquery-$jquery_ver/jquery.min.js").qq("></script>\n);
        $res .= qq(<script src="file://)._escape_uri("$dist_dir/modally-$modally_ver/jquery.modally.js").qq("></script>\n);
    } elsif ($OPT_LIBRARY_LINK_MODE eq 'cdn') {
        # no CDN yet for modally
        die "'cdn' linking mode is not yet supported";
    } else {
        die "Unknown value for the '\$OPT_LIBRARY_LINK_MODE' option: '$OPT_LIBRARY_LINK_MODE', please use one of local|embed|cdn|none";
    }
}

sub _postamble {
    if ($OPT_LIBRARY_LINK_MODE eq 'none') {
        '';
    } else {
        "<script>" . join("", map { $_ == 0 ? '' : qq(\$('#r$_result_divs[$_][0]').modally('r$_result_divs[$_][0]',{});)} 0 .. $#_result_divs) . "</script>";
    }
}

our $_is_dd;
sub _dd_or_dump {
    local %_seen_refaddrs;
    local %_subscripts;
    local @_fixups;
    local @_result_divs;

    my $res;
    if (@_ > 1) {
        die "Currently multiple arguments are not supported, please only pass 1 argument";
        #$res = "(" . join(",\n", map {_dump($_, '', 0)} @_) . ")";
    } else {
        $res = _dump($_[0], '', 0);
    }
    if (@_fixups) {
        $res = "do { my \$var = $res;\n" . join("", map {encode_entities $_} @_fixups) . "\$var }";
    }

    # the root variable is referenced. we need to create a modal div too for it,
    # which duplicates the result.
    {
        last unless ref $_[0];
        my $refaddr = sprintf("%x", refaddr($_[0]));
        last unless $_seen_refaddrs{$refaddr} > 1;
        unshift @_result_divs, [$refaddr, '', $res];
    }

    $res = _preamble() .
        "<pre>$res</pre>" .
        join("", map {
            qq(<div id="r$_result_divs[$_][0]" style="display:none").($_ == 0 ? qq( class="modally-init") : '').qq(><pre>).
                "# \$var".($_result_divs[$_][1] ? "-&gt;".$_result_divs[$_][1] : '')."\n".
                $_result_divs[$_][2].
                qq(</pre></div>)
            } 0 .. $#_result_divs).
        _postamble();

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
# ABSTRACT: Dump Perl data structures as HTML document with nested pop ups

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::HTML::PopUp - Dump Perl data structures as HTML document with nested pop ups

=head1 VERSION

This document describes version 0.001 of Data::Dump::HTML::PopUp (from Perl distribution Data-Dump-HTML-PopUp), released on 2024-03-17.

=head1 SYNOPSIS

 use Data::Dump::HTML::PopUp; # exports dd(), can export dump()
 dd [1, 2, 3];

=head1 DESCRIPTION

This module is a L<Data::Dump> variant that dumps Perl data structure to HTML
document where you can expand and collapse nodes to drill down and roll up your
data. The nodes will expand in (nested) pop up modal dialogs. It currently uses
jQuery [1] and Modally [2] JavaScript libraries.

There are other collapsible HTML dumper modules on CPAN (see L</SEE ALSO>).

=head1 VARIABLES

=head2 $Data::Dump::HTML::PopUp::OPT_PERL_VERSION

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

=head2 $Data::Dump::HTML::PopUp::OPT_REMOVE_PRAGMAS

Bool, default: 0.

If set to 1, then pragmas at the start of coderef dump will be removed. Coderef
dump is produced by L<B::Deparse> and is of the form like:

 sub { use feature 'current_sub', 'evalbytes', 'fc', 'say', 'state', 'switch', 'unicode_strings', 'unicode_eval'; $a <=> $b }

If you want to dump short coderefs, the pragmas might be distracting. You can
turn turn on this option which will make the above dump become:

 sub { $a <=> $b }

Note that without the pragmas, the dump might be incorrect.

=head2 $Data::Dump::HTML::PopUp::::OPT_DEPARSE

Bool, default: 1.

Can be set to 0 to skip deparsing code. Coderefs will be dumped as
C<sub{"DUMMY"}> instead, like in Data::Dump.

=head2 $Data::Dump::HTML::PopUp::::OPT_STRINGIFY_NUMBERS

Bool, default: 0.

If set to true, will dump numbers as quoted string, e.g. 123 as "123" instead of
123. This might be helpful if you want to compute the hash of or get a canonical
representation of data structure.

=head2 $Data::Dump::HTML::PopUp::::OPT_LIBRARY_LINK_MODE

Str, default: "local". Valid values: "none", "embed", "local", "cdn".

Specify how the JavaScript libraries should be linked in the generated HTML
page. The JavaScript libraries are linked at the preamble which is generated
before the actual dump:

 <link rel="stylesheet" href="jquery.modally.css">
 <script src="jquery.min.js"></script>
 <script src="jquery.modally.js"></script>

If the setting is set to C<none>, then no preamble will be produced at all. If
the setting is set to C<embed>, then instead of being linked, the source code of
the JavaScript libraries will be directly embedded. If the setting is set to
C<local>, then the links will be to the local filesystem to the library files
included in the distribution's shared directory. If the setting is set to
C<cdn>, then the links will be to the CDN URLs.

=head1 FUNCTIONS

=head2 dd

=head2 dump

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-HTML-PopUp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-HTML-PopUp>.

=head1 SEE ALSO

[1] jQuery JavaScript library, L<http://www.jquery.com>

[2] Modally plugin for jQuery, L<https://www.jqueryscript.net/lightbox/nested-modal-modally.html>

Other data structure dumpers to (collapsible) tree:
L<Data::Dump::HTML::Collapsible>, L<Data::HTML::TreeDumper> (also uses C<<
<details> >> and C<< <summary> >> HTML elements, doesn't handle recursion),
L<Data::TreeDumper> (L<Data::TreeDumper::Renderer::DHTML>,
L<Data::TreeDumper::Renderer::GTK>), L<Data::Dumper::GUI>.

Other data structure dumpers that outputs to HTML: L<Data::HTMLDumper>,
L<Data::Dumper::HTML>, L<Data::Format::Pretty::HTML>.

Other data structure dumpers, among others: L<Data::Dumper>, L<Data::Dump>,
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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-HTML-PopUp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
