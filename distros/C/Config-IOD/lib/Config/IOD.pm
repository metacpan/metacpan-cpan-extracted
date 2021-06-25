package Config::IOD;

our $DATE = '2021-06-23'; # DATE
our $VERSION = '0.352'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Config::IOD::Base);

sub _init_read {
    my $self = shift;

    $self->{_cur_section} = $self->{default_section};

    # for checking when allow_duplicate_key=0
    $self->{_key_mem} = {}; # key=section name, value=hash of key->1

    $self->SUPER::_init_read;
}

our $re_directive_abo =
    qr/^(;?)(\s*)!
       (\s*)(\w+)(\s*)(.*)
       (\R?)\z/x;
our $re_directive =
    qr/^(;)(\s*)!
       (\s*)(\w+)(\s*)(.*)
       (\R?)\z/x;

sub _read_string {
    my ($self, $str) = @_;

    my $res = [];

    my $directive_re = $self->{allow_bang_only} ?
        $re_directive_abo : $re_directive;

    my @lines = split /^/, $str;
    local $self->{_linum} = 0;
  LINE:
    for my $line (@lines) {
        $self->{_linum}++;

        # blank line
        if ($line !~ /\S/) {
            push @$res, [
                'B',
                $line, # RAW
            ];
            next LINE;
        }

        # section line
        if ($line =~ /^(\s*)\[(\s*)(.+?)(\s*)\]
                      (?: (\s*)([;#])(.*))?
                      (\R?)\z/x) {
            push @$res, [
                'S',
                $1, # COL_S_WS1
                $2, # COL_S_WS2
                $3, # COL_S_SECTION
                $4, # COL_S_WS3
                $5, # COL_S_WS4
                $6, # COL_S_COMMENT_CHAR
                $7, # COL_S_COMMENT
                $8, # COL_S_NL
            ];
            $self->{_cur_section} = $3;
            next LINE;
        }

        # directive line
        my $line0 = $line;
        if ($self->{enable_directive} && $line =~ s/$directive_re//) {
            push @$res, [
                'D',
                $1, # COL_D_COMMENT_CHAR
                $2, # COL_D_WS1
                $3, # COL_D_WS2
                $4, # COL_D_DIRECTIVE
                $5, # COL_D_WS3
                $6, # COL_D_ARGS_RAW
                $7, # COL_D_NL
            ];
            my $directive = $4;
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
            my $args = $self->_parse_command_line($6);
            if (!defined($args)) {
                $self->_err("Invalid arguments syntax '$6'");
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
                $self->_read_string($self->_read_file($path));
                $self->_pop_include_stack;
            } elsif ($directive eq 'merge') {
            } elsif ($directive eq 'noop') {
            } else {
                if ($self->{ignore_unknown_directive}) {
                } else {
                    $self->_err("Unknown directive '$directive'");
                }
            }
            next LINE;
        }

      L1:
        # comment line
        if ($line =~ /^(\s*)([;#])(.*?)
                      (\R?)\z/x) {
            push @$res, [
                'C',
                $1, # COL_C_WS1
                $2, # COL_C_COMMENT_CHAR
                $3, # COL_C_COMMENT
                $4, # COL_C_NL
            ];
            next LINE;
        }

        # key line
        if ($line =~ /^(\s*)([^=]+?)(\s*)=
                      (\s*)(.*?)
                      (\R?)\z/x) {
            push @$res, [
                'K',
                $1, # COL_K_WS1
                $2, # COL_K_KEY
                $3, # COL_K_WS2
                $4, # COL_K_WS3
                $5, # COL_K_VALUE_RAW
                $6, # COL_K_NL
            ];
            if (!$self->{allow_duplicate_key}) {
                my $kmem = $self->{_key_mem};
                if ($kmem->{$self->{_cur_section}}{$2}) {
                    $self->_err(
                        "Duplicate key: $2 (section $self->{_cur_section})");
                }
                $kmem->{$self->{_cur_section}}{$2} = 1;
            }
            next LINE;
        }

        $self->_err("Invalid syntax");
    }

    # make sure we always end with newline
    if (@$res) {
        $res->[-1][-1] .= "\n"
            unless $res->[-1][-1] =~ /\R\z/;
    }

    require Config::IOD::Document;
    Config::IOD::Document->new(_parser=>$self, _parsed=>$res);
}

1;
# ABSTRACT: Read and write IOD/INI configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD - Read and write IOD/INI configuration files

=head1 VERSION

This document describes version 0.352 of Config::IOD (from Perl distribution Config-IOD), released on 2021-06-23.

=head1 SYNOPSIS

 use Config::IOD;
 my $iod = Config::IOD->new(
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

Read IOD/INI document from a file or string, return L<Config::IOD::Document>
object:

 my $doc = $iod->read_file("/path/to/some.iod");
 my $doc = $iod->read_string("...");

See Config::IOD::Document for methods available for C<$doc>.

=head1 DESCRIPTION

This module is a round-trip parser for L<IOD> configuration format (IOD is an
INI-like format with more precise specification, some extra features, and 99%
compatible with typical INI format). Round-trip means all whitespaces and
comments are preserved, so you get byte-by-byte equivalence if you dump back the
parsed document into string.

Aside from parsing, methods for modifying IOD documents (add/delete sections &
keys, etc) are also provided.

If you only need to read IOD configuration files, you might want to use
L<Config::IOD::Reader> instead.

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

=head2 $reader->read_file($filename) => obj

Read IOD configuration from a file. Return L<Config::IOD::Document> instance.
Die on errors.

=head2 $reader->read_string($str) => obj

Read IOD configuration from a string. Return L<Config::IOD::Document> instance.
Die on errors.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<IOD> - specification

L<Config::IOD::Reader> - if you just need to read a configuration file, you
should probably use this module instead. It's lighter, faster, and has a simpler
interface.

L<IOD::Examples> - sample documents

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
