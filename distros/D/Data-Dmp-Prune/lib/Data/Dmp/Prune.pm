## no critic: Modules::ProhibitAutomaticExportation

package Data::Dmp::Prune;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-04'; # DATE
our $DIST = 'Data-Dmp-Prune'; # DIST
our $VERSION = '0.240.0'; # VERSION

use 5.010001;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number blessed reftype refaddr);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dd dmp);
our @EXPORT_OK = qw(dd_ellipsis dmp_ellipsis);

# for when dealing with circular refs
our %_seen_refaddrs;
our %_subscripts;
our @_fixups;

# for when dumping
our %_prune_paths;

our $OPT_MAX_DUMP_LEN_BEFORE_ELLIPSIS = 70;
our $OPT_PERL_VERSION = "5.010";
our $OPT_REMOVE_PRAGMAS = 0;
our $OPT_DEPARSE = 1;
our $OPT_STRINGIFY_NUMBERS = 0;
our $OPT_PRUNE = defined $ENV{DATA_DMP_PRUNE_OPT_PRUNE} ? [split /\s+/, $ENV{DATA_DMP_PRUNE_OPT_PRUNE}] : undef;

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
    my ($val, $subscript, $path) = @_;

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
        push @_fixups, "\$a->$subscript=\$a",
            ($_subscripts{$refaddr} ? "->$_subscripts{$refaddr}" : ""), ";";
        return "'fix'";
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
        $res = "[";
        my $i = 0;
        for (@$val) {
            my $elpath = "$path$i";
            $res .= "," if $i;
            if ($_prune_paths{$elpath}) {
                $res .= "'PRUNED'";
            } else {
                $res .= _dump($_, "$subscript\[$i]", "$path$i/");
            }
            $i++;
        }
        $res .= "]";
    } elsif ($ref eq 'HASH') {
        $res = "{";
        my $i = 0;
        for (sort keys %$val) {
            my $elpath = "$path$_";
            next if $_prune_paths{$elpath};
            $res .= "," if $i++;
            my $k = _quote_key($_);
            my $v = _dump($val->{$_}, "$subscript\{$k}", "$path$k/");
            $res .= "$k=>$v";
        }
        $res .= "}";
    } elsif ($ref eq 'SCALAR') {
        $res = "\\"._dump($$val, $subscript, $path);
    } elsif ($ref eq 'REF') {
        $res = "\\"._dump($$val, $subscript, $path);
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
sub _dd_or_dmp {
    local %_seen_refaddrs;
    local %_subscripts;
    local @_fixups;
    local %_prune_paths = map {$_=>1} @{ $OPT_PRUNE // [] };

    my $res;
    if (@_ > 1) {
        $res = "(" . join(",", map {_dump($_, '', '/')} @_) . ")";
    } else {
        $res = _dump($_[0], '', '/');
    }
    if (@_fixups) {
        $res = "do{my\$a=$res;" . join("", @_fixups) . "\$a}";
    }

    if ($_is_ellipsis) {
        $res = substr($res, 0, $OPT_MAX_DUMP_LEN_BEFORE_ELLIPSIS) . '...'
            if length($res) > $OPT_MAX_DUMP_LEN_BEFORE_ELLIPSIS;
    }

    if ($_is_dd) {
        say $res;
        return wantarray() || @_ > 1 ? @_ : $_[0];
    } else {
        return $res;
    }
}

sub dd { local $_is_dd=1; _dd_or_dmp(@_) } # goto &sub doesn't work with local
sub dmp { goto &_dd_or_dmp }

sub dd_ellipsis { local $_is_dd=1; local $_is_ellipsis=1; _dd_or_dmp(@_) }
sub dmp_ellipsis { local $_is_ellipsis=1; _dd_or_dmp(@_) }

1;
# ABSTRACT: Dump Perl data structures as Perl code, prune some branches

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dmp::Prune - Dump Perl data structures as Perl code, prune some branches

=head1 VERSION

This document describes version 0.240.0 of Data::Dmp::Prune (from Perl distribution Data-Dmp-Prune), released on 2020-10-04.

=head1 SYNOPSIS

In Perl code:

 use Data::Dmp; # exports dd() and dmp()
 {
     local $Data::Dmp::Prune::OPT_PRUNE = ['/3', '/b', '/c/foo'];
     dd [1, 2, 3, 4, 5]; # prints "[1,2,3,'PRUNED',5]"
     $a = dmp({a => 1, b => 2, c => {foo=>1, bar=>2}}); # -> "{a=>1,c=>{bar=>2}}"
 }

On the command line:

 % DATA_DMP_PRUNE_OPT_PRUNE="/3 /b /c/foo" yourscript.pl ...

=head1 DESCRIPTION

This is a fork of L<Data::Dmp> 0.240, with an option to prune some data
structure branches.

=head1 VARIABLES

These section only lists variables specific to Data::Dmp::Prune. For other
variables see Data::Dmp's documentation.

=head2 $Data::Dmp::Prune::OPT_PRUNE

Array reference containing data structure paths to prune. Data structure path
uses "/" as path separator so currently you cannot prune hash key that contains
"/". Each path element represents hash key name or array element index.

=head1 FUNCTIONS

See Data::Dmp's documentation for more details on each function.

=head2 dd

=head2 dmp

=head2 dd_ellipsis

=head2 dmp_ellipsis

=head1 ENVIRONMENT

=head2 DATA_DMP_PRUNE_OPT_PRUNE

Provide default for L</"$Data::Dmp::Prune::OPT_PRUNE">. Value is a string that
will be split on whitespace to become array reference, so currently you cannot
prune hash key that contains whitespace (as well as "/").

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dmp-Prune>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dmp-Prune>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dmp-Prune>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dmp>.

Partial dumpers like L<Data::Dump::Partial>, etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
