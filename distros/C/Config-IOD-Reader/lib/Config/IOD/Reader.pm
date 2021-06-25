package Config::IOD::Reader;

our $DATE = '2021-06-23'; # DATE
our $VERSION = '0.343'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Config::IOD::Base);

sub _merge {
    my ($self, $section) = @_;

    my $res = $self->{_res};
    for my $msect (@{ $self->{_merge} }) {
        if ($msect eq $section) {
            # ignore merging self
            next;
            #local $self->{_linum} = $self->{_linum}-1;
            #$self->_err("Can't merge section '$msect' to '$section': ".
            #                "Same section");
        }
        if (!exists($res->{$msect})) {
            local $self->{_linum} = $self->{_linum}-1;
            $self->_err("Can't merge section '$msect' to '$section': ".
                            "Section '$msect' not seen yet");
        }
        for my $k (keys %{ $res->{$msect} }) {
            $res->{$section}{$k} //= $res->{$msect}{$k};
        }
    }
}

sub _init_read {
    my $self = shift;

    $self->SUPER::_init_read;
    $self->{_res} = {};
    $self->{_merge} = undef;
    $self->{_num_seen_section_lines} = 0;
    $self->{_cur_section} = $self->{default_section};
    $self->{_arrayified} = {};
}

sub _read_string {
    my ($self, $str, $cb) = @_;

    my $res = $self->{_res};
    my $cur_section = $self->{_cur_section};

    my $directive_re = $self->{allow_bang_only} ?
        qr/^;?\s*!\s*(\w+)\s*/ :
        qr/^;\s*!\s*(\w+)\s*/;

    my $_raw_val; # only to provide to callback

    my @lines = split /^/, $str;
    local $self->{_linum} = 0;
  LINE:
    for my $line (@lines) {
        $self->{_linum}++;

        # blank line
        if ($line !~ /\S/) {
            next LINE;
        }

        # directive line
        if ($self->{enable_directive} && $line =~ s/$directive_re//) {
            my $directive = $1;
            if ($self->{allow_directives}) {
                $self->_err("Directive '$directive' is not in ".
                                "allow_directives list")
                    unless grep { $_ eq $directive }
                        @{$self->{allow_directives}};
            }
            if ($self->{disallow_directives}) {
                $self->_err("Directive '$directive' is in ".
                                "disallow_directives list")
                    if grep { $_ eq $directive }
                        @{$self->{disallow_directives}};
            }
            my $args = $self->_parse_command_line($line);
            if (!defined($args)) {
                $self->_err("Invalid arguments syntax '$line'");
            }

            if ($cb) {
                $cb->(
                    event => 'directive',
                    linum=>$self->{_linum}, line=>$line, cur_section=>$self->{_cur_section},
                    directive => $directive,
                    args => $args,
                );
            }

            if ($directive eq 'include') {
                my $path;
                if (! @$args) {
                    $self->_err("Missing filename to include");
                } elsif (@$args > 1) {
                    $self->_err("Extraneous arguments");
                } else {
                    $path = $args->[0];
                }
                my $res = $self->_push_include_stack($path);
                if ($res->[0] != 200) {
                    $self->_err("Can't include '$path': $res->[1]");
                }
                $path = $res->[2];
                $self->_read_string($self->_read_file($path, $cb), $cb);
                $self->_pop_include_stack;
            } elsif ($directive eq 'merge') {
                $self->{_merge} = @$args ? $args : undef;
            } elsif ($directive eq 'noop') {
            } else {
                if ($self->{ignore_unknown_directive}) {
                    # assume a regular comment
                    next LINE;
                } else {
                    $self->_err("Unknown directive '$directive'");
                }
            }
            next LINE;
        }

        # comment line
        if ($line =~ /^\s*[;#]/) {

            if ($cb) {
                $cb->(
                    event => 'comment',
                    linum=>$self->{_linum}, line=>$line, cur_section=>$self->{_cur_section},
                );
            }

            next LINE;
        }

        # section line
        if ($line =~ /^\s*\[\s*(.+?)\s*\](?: \s*[;#].*)?/) {
            my $prev_section = $self->{_cur_section};
            $self->{_cur_section} = $cur_section = $1;
            $res->{$cur_section} //= {};
            $self->{_num_seen_section_lines}++;

            # previous section exists? do merging for previous section
            if ($self->{_merge} && $self->{_num_seen_section_lines} > 1) {
                $self->_merge($prev_section);
            }

            if ($cb) {
                $cb->(
                    event => 'section',
                    linum=>$self->{_linum}, line=>$line, cur_section=>$self->{_cur_section},
                    section => $cur_section,
                );
            }

            next LINE;
        }

        # key line
        if ($line =~ /^\s*([^=]+?)\s*=\s*(.*)/) {
            my $key = $1;
            my $val = $2;

            # the common case is that value are not decoded or
            # quoted/bracketed/braced, so we avoid calling _parse_raw_value here
            # to avoid overhead
            if ($val =~ /\A["!\\[\{~]/) {
                $_raw_val = $val if $cb;
                my ($err, $parse_res, $decoded_val) = $self->_parse_raw_value($val);
                $self->_err("Invalid value: " . $err) if $err;
                $val = $decoded_val;
            } else {
                $_raw_val = $val if $cb;
                $val =~ s/\s*[#;].*//; # strip comment
            }

            if (exists $res->{$cur_section}{$key}) {
                if (!$self->{allow_duplicate_key}) {
                    $self->_err("Duplicate key: $key (section $cur_section)");
                } elsif ($self->{_arrayified}{$cur_section}{$key}++) {
                    push @{ $res->{$cur_section}{$key} }, $val;
                } else {
                    $res->{$cur_section}{$key} = [
                        $res->{$cur_section}{$key}, $val];
                }
            } else {
                $res->{$cur_section}{$key} = $val;
            }

            if ($cb) {
                $cb->(
                    event => 'key',
                    linum=>$self->{_linum}, line=>$line, cur_section=>$self->{_cur_section},
                    key => $key,
                    val => $val,
                    raw_val => $_raw_val,
                );
            }

            next LINE;
        }

        $self->_err("Invalid syntax");
    }

    if ($self->{_merge} && $self->{_num_seen_section_lines} > 1) {
        $self->_merge($cur_section);
    }

    $res;
}

1;
# ABSTRACT: Read IOD/INI configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD::Reader - Read IOD/INI configuration files

=head1 VERSION

This document describes version 0.343 of Config::IOD::Reader (from Perl distribution Config-IOD-Reader), released on 2021-06-23.

=head1 SYNOPSIS

 use Config::IOD::Reader;
 my $reader = Config::IOD::Reader->new(
     # list of known attributes, with their default values
     # default_section     => 'GLOBAL',
     # enable_directive    => 1,
     # enable_encoding     => 1,
     # enable_quoting      => 1,
     # enable_backet       => 1,
     # enable_brace        => 1,
     # allow_encodings     => undef, # or ['base64','json',...]
     # disallow_encodings  => undef, # or ['base64','json',...]
     # allow_directives    => undef, # or ['include','merge',...]
     # disallow_directives => undef, # or ['include','merge',...]
     # allow_bang_only     => 1,
     # enable_expr         => 0,
     # allow_duplicate_key => 1,
     # ignore_unknown_directive => 0,
 );
 my $config_hash = $reader->read_file('config.iod');

=head1 DESCRIPTION

This module reads L<IOD> configuration files (IOD is an INI-like format with
more precise specification, some extra features, and 99% compatible with typical
INI format). It is a minimalist alternative to the more fully-featured
L<Config::IOD>. It cannot write IOD files and is optimized for low startup
overhead.

=head1 EXPRESSION

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

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

=head1 ATTRIBUTES

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

Whether to enable C<expr> encoding. By default this is turned off, for safety.
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

=head1 METHODS

=head2 new(%attrs) => obj

=head2 $reader->read_file($filename[ , $callback ]) => hash

Read IOD configuration from a file. Die on errors.

See C<read_string> for more information on C<$callback> argument.

=head2 $reader->read_string($str[ , $callback ]) => hash

Read IOD configuration from a string. Die on errors.

C<$callback> is an optional coderef argument that will be called during various
stages. It can be useful if you want more information (especially ordering). It
will be called with hash argument C<%args>

=over

=item * Found a directive line

Arguments passed: C<event> (str, has the value of 'directive'), C<linum> (int,
line number, starts from 1), C<line> (str, raw line), C<directive> (str,
directive name), C<cur_section> (str, current section name), C<args> (array,
directive arguments).

=item * Found a comment line

Arguments passed: C<event> (str, 'comment'), C<linum>, C<line>, C<cur_section>.

=item * Found a section line

Arguments passed: C<event> (str, 'section'), C<linum>, C<line>, C<cur_section>,
C<section> (str, section name).

=item * Found a key line

Arguments passed: C<event> (str, 'section'), C<linum>, C<line>, C<cur_section>,
C<key> (str, key name), C<val> (any, value name, already decoded if encoded),
C<raw_val> (str, raw value).

=back

TODO: callback when there is merging.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD-Reader>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<IOD> - specification

L<Config::IOD> - round-trip parser for reading as well as writing IOD documents

L<IOD::Examples> - sample documents

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
