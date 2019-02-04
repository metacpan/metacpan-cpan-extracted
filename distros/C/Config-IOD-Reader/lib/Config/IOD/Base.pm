package Config::IOD::Base;

our $DATE = '2019-01-17'; # DATE
our $VERSION = '0.342'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Carp; # avoided to shave a bit of startup time

use constant +{
    COL_V_ENCODING => 0, # either "!j"... or '"', '[', '{', '~'
    COL_V_WS1 => 1,
    COL_V_VALUE => 2,
    COL_V_WS2 => 3,
    COL_V_COMMENT_CHAR => 4,
    COL_V_COMMENT => 5,
};

sub new {
    my ($class, %attrs) = @_;
    $attrs{default_section} //= 'GLOBAL';
    $attrs{allow_bang_only} //= 1;
    $attrs{allow_duplicate_key} //= 1;
    $attrs{enable_directive} //= 1;
    $attrs{enable_encoding} //= 1;
    $attrs{enable_quoting}  //= 1;
    $attrs{enable_bracket}  //= 1;
    $attrs{enable_brace}    //= 1;
    $attrs{enable_tilde}    //= 1;
    $attrs{enable_expr}     //= 0;
    $attrs{expr_vars}       //= {};
    $attrs{ignore_unknown_directive} //= 0;
    # allow_encodings
    # disallow_encodings
    # allow_directives
    # disallow_directives
    bless \%attrs, $class;
}

# borrowed from Parse::CommandLine. differences: returns arrayref. return undef
# on error (instead of dying).
sub _parse_command_line {
    my ($self, $str) = @_;

    $str =~ s/\A\s+//ms;
    $str =~ s/\s+\z//ms;

    my @argv;
    my $buf;
    my $escaped;
    my $double_quoted;
    my $single_quoted;

    for my $char (split //, $str) {
        if ($escaped) {
            $buf .= $char;
            $escaped = undef;
            next;
        }

        if ($char eq '\\') {
            if ($single_quoted) {
                $buf .= $char;
            }
            else {
                $escaped = 1;
            }
            next;
        }

        if ($char =~ /\s/) {
            if ($single_quoted || $double_quoted) {
                $buf .= $char;
            }
            else {
                push @argv, $buf if defined $buf;
                undef $buf;
            }
            next;
        }

        if ($char eq '"') {
            if ($single_quoted) {
                $buf .= $char;
                next;
            }
            $double_quoted = !$double_quoted;
            next;
        }

        if ($char eq "'") {
            if ($double_quoted) {
                $buf .= $char;
                next;
            }
            $single_quoted = !$single_quoted;
            next;
        }

        $buf .= $char;
    }
    push @argv, $buf if defined $buf;

    if ($escaped || $single_quoted || $double_quoted) {
        return undef;
    }

    \@argv;
}

# return ($err, $res, $decoded_val)
sub _parse_raw_value {
    my ($self, $val, $needs_res) = @_;

    if ($val =~ /\A!/ && $self->{enable_encoding}) {

        $val =~ s/!(\w+)(\s+)// or return ("Invalid syntax in encoded value");
        my ($enc, $ws1) = ($1, $2);

        my $res; $res = [
            "!$enc", # COL_V_ENCODING
            $ws1, # COL_V_WS1
            $1, # COL_V_VALUE
            $2, # COL_V_WS2
            $3, # COL_V_COMMENT_CHAR
            $4, # COL_V_COMMENT
        ] if $needs_res;

        # canonicalize shorthands
        $enc = "json" if $enc eq 'j';
        $enc = "hex"  if $enc eq 'h';
        $enc = "expr" if $enc eq 'e';

        if ($self->{allow_encodings}) {
            return ("Encoding '$enc' is not in ".
                        "allow_encodings list")
                unless grep {$_ eq $enc} @{$self->{allow_encodings}};
        }
        if ($self->{disallow_encodings}) {
            return ("Encoding '$enc' is in ".
                        "disallow_encodings list")
                if grep {$_ eq $enc} @{$self->{disallow_encodings}};
        }

        if ($enc eq 'json') {

            # XXX imperfect regex for simplicity, comment should not contain
            # "]", '"', or '}' or it will be gobbled up as value by greedy regex
            # quantifier
            $val =~ /\A
                     (".*"|\[.*\]|\{.*\}|\S+)
                     (\s*)
                     (?: ([;#])(.*) )?
                     \z/x or return ("Invalid syntax in JSON-encoded value");
            my $decode_res = $self->_decode_json($val);
            return ($decode_res->[1]) unless $decode_res->[0] == 200;
            return (undef, $res, $decode_res->[2]);

        } elsif ($enc eq 'path' || $enc eq 'paths') {

            my $decode_res = $self->_decode_path_or_paths($val, $enc);
            return ($decode_res->[1]) unless $decode_res->[0] == 200;
            return (undef, $res, $decode_res->[2]);

        } elsif ($enc eq 'hex') {

            $val =~ /\A
                     ([0-9A-Fa-f]*)
                     (\s*)
                     (?: ([;#])(.*) )?
                     \z/x or return ("Invalid syntax in hex-encoded value");
            my $decode_res = $self->_decode_hex($1);
            return ($decode_res->[1]) unless $decode_res->[0] == 200;
            return (undef, $res, $decode_res->[2]);

        } elsif ($enc eq 'base64') {

            $val =~ m!\A
                      ([A-Za-z0-9+/]*=*)
                      (\s*)
                      (?: ([;#])(.*) )?
                      \z!x or return ("Invalid syntax in base64-encoded value");
            my $decode_res = $self->_decode_base64($1);
            return ($decode_res->[1]) unless $decode_res->[0] == 200;
            return (undef, $res, $decode_res->[2]);

        } elsif ($enc eq 'none') {

            return (undef, $res, $val);

        } elsif ($enc eq 'expr') {

            return ("expr is not allowed (enable_expr=0)")
                unless $self->{enable_expr};
            # XXX imperfect regex, expression can't contain # and ; because it
            # will be assumed as comment
            $val =~ m!\A
                      ((?:[^#;])+?)
                      (\s*)
                      (?: ([;#])(.*) )?
                      \z!x or return ("Invalid syntax in expr-encoded value");
            my $decode_res = $self->_decode_expr($1);
            return ($decode_res->[1]) unless $decode_res->[0] == 200;
            return (undef, $res, $decode_res->[2]);

        } else {

            return ("unknown encoding '$enc'");

        }

    } elsif ($val =~ /\A"/ && $self->{enable_quoting}) {

        $val =~ /\A
                 "( (?:
                         \\\\ | # backslash
                         \\.  | # escaped something
                         [^"\\]+ # non-doublequote or non-backslash
                     )* )"
                 (\s*)
                 (?: ([;#])(.*) )?
                 \z/x or return ("Invalid syntax in quoted string value");
        my $res; $res = [
            '"', # COL_V_ENCODING
            '', # COL_V_WS1
            $1, # VOL_V_VALUE
            $2, # COL_V_WS2
            $3, # COL_V_COMMENT_CHAR
            $4, # COL_V_COMMENT
        ] if $needs_res;
        my $decode_res = $self->_decode_json(qq("$1"));
        return ($decode_res->[1]) unless $decode_res->[0] == 200;
        return (undef, $res, $decode_res->[2]);

    } elsif ($val =~ /\A\[/ && $self->{enable_bracket}) {

        # XXX imperfect regex for simplicity, comment should not contain "]" or
        # it will be gobbled up as value by greedy regex quantifier
        $val =~ /\A
                 \[(.*)\]
                 (?:
                     (\s*)
                     ([#;])(.*)
                 )?
                 \z/x or return ("Invalid syntax in bracketed array value");
        my $res; $res = [
            '[', # COL_V_ENCODING
            '', # COL_V_WS1
            $1, # VOL_V_VALUE
            $2, # COL_V_WS2
            $3, # COL_V_COMMENT_CHAR
            $4, # COL_V_COMMENT
        ] if $needs_res;
        my $decode_res = $self->_decode_json("[$1]");
        return ($decode_res->[1]) unless $decode_res->[0] == 200;
        return (undef, $res, $decode_res->[2]);

    } elsif ($val =~ /\A\{/ && $self->{enable_brace}) {

        # XXX imperfect regex for simplicity, comment should not contain "}" or
        # it will be gobbled up as value by greedy regex quantifier
        $val =~ /\A
                 \{(.*)\}
                 (?:
                     (\s*)
                     ([#;])(.*)
                 )?
                 \z/x or return ("Invalid syntax in braced hash value");
        my $res; $res = [
            '{', # COL_V_ENCODING
            '', # COL_V_WS1
            $1, # VOL_V_VALUE
            $2, # COL_V_WS2
            $3, # COL_V_COMMENT_CHAR
            $4, # COL_V_COMMENT
        ] if $needs_res;
        my $decode_res = $self->_decode_json("{$1}");
        return ($decode_res->[1]) unless $decode_res->[0] == 200;
        return (undef, $res, $decode_res->[2]);

    } elsif ($val =~ /\A~/ && $self->{enable_tilde}) {

        $val =~ /\A
                 ~(.*)
                 (\s*)
                 (?: ([;#])(.*) )?
                 \z/x or return ("Invalid syntax in path value");
        my $res; $res = [
            '~', # COL_V_ENCODING
            '', # COL_V_WS1
            $1, # VOL_V_VALUE
            $2, # COL_V_WS2
            $3, # COL_V_COMMENT_CHAR
            $4, # COL_V_COMMENT
        ] if $needs_res;

        my $decode_res = $self->_decode_path_or_paths($val, 'path');
        return ($decode_res->[1]) unless $decode_res->[0] == 200;
        return (undef, $res, $decode_res->[2]);

    } else {

        $val =~ /\A
                 (.*?)
                 (\s*)
                 (?: ([#;])(.*) )?
                 \z/x or return ("Invalid syntax in value"); # shouldn't happen, regex should match any string
        my $res; $res = [
            '', # COL_V_ENCODING
            '', # COL_V_WS1
            $1, # VOL_V_VALUE
            $2, # COL_V_WS2
            $3, # COL_V_COMMENT_CHAR
            $4, # COL_V_COMMENT
        ] if $needs_res;
        return (undef, $res, $1);

    }
    # should not be reached
}

sub _get_my_user_name {
    if ($^O eq 'MSWin32') {
        return $ENV{USERNAME};
    } else {
        return $ENV{USER} if $ENV{USER};
        my @pw;
        eval { @pw = getpwuid($>) };
        return $pw[0] if @pw;
    }
}

# borrowed from PERLANCAR::File::HomeDir 0.04
sub _get_my_home_dir {
    if ($^O eq 'MSWin32') {
        # File::HomeDir always uses exists($ENV{x}) first, does it want to avoid
        # accidentally creating env vars?
        return $ENV{HOME} if $ENV{HOME};
        return $ENV{USERPROFILE} if $ENV{USERPROFILE};
        return join($ENV{HOMEDRIVE}, "\\", $ENV{HOMEPATH})
            if $ENV{HOMEDRIVE} && $ENV{HOMEPATH};
    } else {
        return $ENV{HOME} if $ENV{HOME};
        my @pw;
        eval { @pw = getpwuid($>) };
        return $pw[7] if @pw;
    }

    die "Can't get home directory";
}

# borrowed from PERLANCAR::File::HomeDir 0.05, with some modifications
sub _get_user_home_dir {
    my ($name) = @_;

    if ($^O eq 'MSWin32') {
        # not yet implemented
        return undef;
    } else {
        # IF and only if we have getpwuid support, and the name of the user is
        # our own, shortcut to my_home. This is needed to handle HOME
        # environment settings.
        if ($name eq getpwuid($<)) {
            return _get_my_home_dir();
        }

      SCOPE: {
            my $home = (getpwnam($name))[7];
            return $home if $home and -d $home;
        }

        return undef;
    }

}

sub _decode_json {
    my ($self, $val) = @_;
    state $json = do {
        if (eval { require Cpanel::JSON::XS; 1 }) {
            Cpanel::JSON::XS->new->allow_nonref;
        } else {
            require JSON::PP;
            JSON::PP->new->allow_nonref;
        }
    };
    my $res;
    eval { $res = $json->decode($val) };
    if ($@) {
        return [500, "Invalid JSON: $@"];
    } else {
        return [200, "OK", $res];
    }
}

sub _decode_path_or_paths {
    my ($self, $val, $which) = @_;

    if ($val =~ m!\A~([^/]+)?(?:/|\z)!) {
        my $home_dir = length($1) ?
            _get_user_home_dir($1) : _get_my_home_dir();
        unless ($home_dir) {
            if (length $1) {
                return [500, "Can't get home directory for user '$1' in path"];
            } else {
                return [500, "Can't get home directory for current user in path"];
            }
        }
        $val =~ s!\A~([^/]+)?!$home_dir!;
    }
    $val =~ s!(?<=.)/\z!!;

    if ($which eq 'path') {
        return [200, "OK", $val];
    } else {
        return [200, "OK", [glob $val]];
    }
}

sub _decode_hex {
    my ($self, $val) = @_;
    [200, "OK", pack("H*", $val)];
}

sub _decode_base64 {
    my ($self, $val) = @_;
    require MIME::Base64;
    [200, "OK", MIME::Base64::decode_base64($val)];
}

sub _decode_expr {
    require Config::IOD::Expr;

    my ($self, $val) = @_;
    no strict 'refs';
    local *{"Config::IOD::Expr::_Compiled::val"} = sub {
        my $arg = shift;
        if ($arg =~ /(.+)\.(.+)/) {
            return $self->{_res}{$1}{$2};
        } else {
            return $self->{_res}{ $self->{_cur_section} }{$arg};
        }
    };
    Config::IOD::Expr::_parse_expr($val);
}

sub _err {
    my ($self, $msg) = @_;
    die join(
        "",
        @{ $self->{_include_stack} } ? "$self->{_include_stack}[0] " : "",
        "line $self->{_linum}: ",
        $msg
    );
}

sub _push_include_stack {
    require Cwd;

    my ($self, $path) = @_;

    # included file's path is based on the main (topmost) file
    if (@{ $self->{_include_stack} }) {
        require File::Spec;
        my ($vol, $dir, $file) =
            File::Spec->splitpath($self->{_include_stack}[-1]);
        $path = File::Spec->rel2abs($path, File::Spec->catpath($vol, $dir));
    }

    my $abs_path = Cwd::abs_path($path) or return [400, "Invalid path name"];
    return [409, "Recursive", $abs_path]
        if grep { $_ eq $abs_path } @{ $self->{_include_stack} };
    push @{ $self->{_include_stack} }, $abs_path;
    return [200, "OK", $abs_path];
}

sub _pop_include_stack {
    my $self = shift;

    die "BUG: Overpopped _pop_include_stack"
        unless @{$self->{_include_stack}};
    pop @{ $self->{_include_stack} };
}

sub _init_read {
    my $self = shift;

    $self->{_include_stack} = [];

    # set expr variables
    {
        last unless $self->{enable_expr};
        no strict 'refs';
        my $pkg = \%{"Config::IOD::Expr::_Compiled::"};
        undef ${"Config::IOD::Expr::_Compiled::$_"} for keys %$pkg;
        my $vars = $self->{expr_vars};
        ${"Config::IOD::Expr::_Compiled::$_"} = $vars->{$_} for keys %$vars;
    }
}

sub _read_file {
    my ($self, $filename) = @_;
    open my $fh, "<", $filename
        or die "Can't open file '$filename': $!";
    binmode($fh, ":encoding(utf8)");
    local $/;
    my $res = scalar <$fh>;
    close $fh;
    $res;
}

sub read_file {
    my $self = shift;
    my $filename = shift;
    $self->_init_read;
    my $res = $self->_push_include_stack($filename);
    die "Can't read '$filename': $res->[1]" unless $res->[0] == 200;
    $res =
        $self->_read_string($self->_read_file($filename), @_);
    $self->_pop_include_stack;
    $res;
}

sub read_string {
    my $self = shift;
    $self->_init_read;
    $self->_read_string(@_);
}

1;
# ABSTRACT: Base class for Config::IOD and Config::IOD::Reader

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD::Base - Base class for Config::IOD and Config::IOD::Reader

=head1 VERSION

This document describes version 0.342 of Config::IOD::Base (from Perl distribution Config-IOD-Reader), released on 2019-01-17.

=head1 EXPRESSION

=for BEGIN_BLOCK: expression

Expression allows you to do things like:

 [section1]
 foo=1
 bar="monkey"

 [section2]
 baz =!e 1+1
 qux =!e "grease" . val("section1.bar")
 quux=!e val("qux") . " " . val('baz')

And the result will be:

 {
     section1 => {foo=>1, bar=>"monkey"},
     section2 => {baz=>2, qux=>"greasemonkey", quux=>"greasemonkey 2"},
 }

For safety, you'll need to set C<enable_expr> attribute to 1 first to enable
this feature.

The syntax of the expression (the C<expr> encoding) is not officially specified
yet in the L<IOD> specification. It will probably be Expr (see
L<Language::Expr::Manual::Syntax>). At the moment, this module implements a very
limited subset that is compatible (lowest common denominator) with Perl syntax
and uses C<eval()> to evaluate the expression. However, only the limited subset
is allowed (checked by Perl 5.10 regular expression).

The supported terms:

 number
 string (double-quoted and single-quoted)
 undef literal
 simple variable ($abc, no namespace, no array/hash sigil, no special variables)
 function call (only the 'val' function is supported)
 grouping (parenthesis)

The supported operators are:

 + - .
 * / % x
 **
 unary -, unary +, !, ~

The C<val()> function refers to the configuration key. If the argument contains
".", it will be assumed as C<SECTIONNAME.KEYNAME>, otherwise it will access the
current section's key. Since parsing is done in a single pass, you can only
refer to the already mentioned key.

Code will be compiled using Perl's C<eval()> in the
C<Config::IOD::Expr::_Compiled> namespace, with C<no strict>, C<no warnings>.

=for END_BLOCK: expression

=head1 ATTRIBUTES

=for BEGIN_BLOCK: attributes

=head2 default_section => str (default: C<GLOBAL>)

If a key line is specified before any section line, this is the section that the
key will be put in.

=head2 enable_directive => bool (default: 1)

If set to false, then directives will not be parsed. Lines such as below will be
considered a regular comment:

 ;!include foo.ini

and lines such as below will be considered a syntax error (B<regardless> of the
C<allow_bang_only> setting):

 !include foo.ini

B<NOTE: Turning this setting off violates IOD specification.>

=head2 enable_encoding => bool (default: 1)

If set to false, then encoding notation will be ignored and key value will be
parsed as verbatim. Example:

 name = !json null

With C<enable_encoding> turned off, value will not be undef but will be string
with the value of (as Perl literal) C<"!json null">.

B<NOTE: Turning this setting off violates IOD specification.>

=head2 enable_quoting => bool (default: 1)

If set to false, then quotes on key value will be ignored and key value will be
parsed as verbatim. Example:

 name = "line 1\nline2"

With C<enable_quoting> turned off, value will not be a two-line string, but will
be a one line string with the value of (as Perl literal) C<"line 1\\nline2">.

B<NOTE: Turning this setting off violates IOD specification.>

=head2 enable_bracket => bool (default: 1)

If set to false, then JSON literal array will be parsed as verbatim. Example:

 name = [1,2,3]

With C<enable_bracket> turned off, value will not be a three-element array, but
will be a string with the value of (as Perl literal) C<"[1,2,3]">.

B<NOTE: Turning this setting off violates IOD specification.>

=head2 enable_brace => bool (default: 1)

If set to false, then JSON literal object (hash) will be parsed as verbatim.
Example:

 name = {"a":1,"b":2}

With C<enable_brace> turned off, value will not be a hash with two pairs, but
will be a string with the value of (as Perl literal) C<'{"a":1,"b":2}'>.

B<NOTE: Turning this setting off violates IOD specification.>

=head2 enable_tilde => bool (default: 1)

If set to true (the default), then value that starts with C<~> (tilde) will be
assumed to use !path encoding, unless an explicit encoding has been otherwise
specified.

Example:

 log_dir = ~/logs  ; ~ will be resolved to current user's home directory

With C<enable_tilde> turned off, value will still be literally C<~/logs>.

B<NOTE: Turning this setting off violates IOD specification.>

=head2 allow_encodings => array

If defined, set list of allowed encodings. Note that if C<disallow_encodings> is
also set, an encoding must also not be in that list.

Also note that, for safety reason, if you want to enable C<expr> encoding,
you'll also need to set C<enable_expr> to 1.

=head2 disallow_encodings => array

If defined, set list of disallowed encodings. Note that if C<allow_encodings> is
also set, an encoding must also be in that list.

Also note that, for safety reason, if you want to enable C<expr> encoding,
you'll also need to set C<enable_expr> to 1.

=head2 enable_expr => bool (default: 0)

Whether to enable C<expr> encoding. By default this is turned on, for safety.
Please see L</"EXPRESSION"> for more details.

=head2 allow_directives => array

If defined, only directives listed here are allowed. Note that if
C<disallow_directives> is also set, a directive must also not be in that list.

=head2 disallow_directives => array

If defined, directives listed here are not allowed. Note that if
C<allow_directives> is also set, a directive must also be in that list.

=head2 allow_bang_only => bool (default: 1)

Since the mistake of specifying a directive like this:

 !foo

instead of the correct:

 ;!foo

is very common, the spec allows it. This reader, however, can be configured to
be more strict.

=head2 allow_duplicate_key => bool (default: 1)

If set to 0, you can forbid duplicate key, e.g.:

 [section]
 a=1
 a=2

or:

 [section]
 a=1
 b=2
 c=3
 a=10

In traditional INI file, to specify an array you specify multiple keys. But when
there is only a single key, it is unclear if the value is a single-element array
or a scalar. You can use this setting to avoid this array/scalar ambiguity in
config file and force user to use JSON encoding or bracket to specify array:

 [section]
 a=[1,2]

B<NOTE: Turning this setting off violates IOD specification.>

=head2 ignore_unknown_directive => bool (default: 0)

If set to true, will not die if an unknown directive is encountered. It will
simply be ignored as a regular comment.

B<NOTE: Turning this setting on violates IOD specification.>

=for END_BLOCK: attributes

=head1 METHODS

=for BEGIN_BLOCK: methods

=head2 new(%attrs) => obj

=head2 $reader->read_file($filename)

Read IOD configuration from a file. Die on errors.

=head2 $reader->read_string($str)

Read IOD configuration from a string. Die on errors.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD-Reader>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
