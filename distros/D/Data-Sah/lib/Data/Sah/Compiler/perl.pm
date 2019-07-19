package Data::Sah::Compiler::perl;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;

use Data::Dmp qw(dmp);
use Mo qw(build default);

extends 'Data::Sah::Compiler::Prog';

our $PP;
our $CORE;
our $CORE_OR_PP;
our $NO_MODULES;

# BEGIN COPIED FROM String::Indent
sub __indent {
    my ($indent, $str, $opts) = @_;
    $opts //= {};

    my $ibl = $opts->{indent_blank_lines} // 1;
    my $fli = $opts->{first_line_indent} // $indent;
    my $sli = $opts->{subsequent_lines_indent} // $indent;
    #say "D:ibl=<$ibl>, fli=<$fli>, sli=<$sli>";

    my $i = 0;
    $str =~ s/^([^\r\n]?)/$i++; !$ibl && !$1 ? "$1" : $i==1 ? "$fli$1" : "$sli$1"/egm;
    $str;
}
# END COPIED FROM String::Indent

sub BUILD {
    my ($self, $args) = @_;

    $self->comment_style('shell');
    $self->indent_character(" " x 4);
    $self->var_sigil('$');
    $self->concat_op(".");
}

sub name { "perl" }

sub literal {
    dmp($_[1]);
}

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->perl($expr);
}

sub compile {
    my ($self, %args) = @_;

    #$self->expr_compiler->compiler->hook_var(
    #    sub {
    #        $_[0];
    #    }
    #);

    #$self->expr_compiler->compiler->hook_func(
    #    sub {
    #        my ($name, @args) = @_;
    #        die "Unknown function $name"
    #            unless $self->main->func_names->{$name};
    #        my $subname = "func_$name";
    #        $self->define_sub_start($subname);
    #        my $meth = "func_$name";
    #        $self->func_handlers->{$name}->$meth;
    #        $self->define_sub_end();
    #        $subname . "(" . join(", ", @args) . ")";
    #    }
    #);

    $args{pp} //= $PP // $ENV{DATA_SAH_PP} // 0;
    $args{core} //= $CORE // $ENV{DATA_SAH_CORE} // 0;
    $args{core_or_pp} //= $CORE_OR_PP // $ENV{DATA_SAH_CORE_OR_PP} // 0;
    $args{no_modules} //= $NO_MODULES // $ENV{DATA_SAH_NO_MODULES} // 0;

    $self->SUPER::compile(%args);
}

sub init_cd {
    my ($self, %args) = @_;

    my $cd = $self->SUPER::init_cd(%args);

    $self->add_runtime_no($cd, 'warnings', ["'void'"]) unless $cd->{args}{no_modules};

    $cd;
}

sub true { "1" }

sub false { "''" }

# quick lookup table, to avoid having to use Module::CoreList or Module::XSOrPP
our %known_modules = (
    'DateTime::Duration'        => {pp=>1, core=>0},
    'DateTime'                  => {pp=>0, core=>0},
    'DateTime::Format::Alami'     => {pp=>1, core=>0},
    'DateTime::Format::Alami::EN' => {pp=>1, core=>0},
    'DateTime::Format::Alami::ID' => {pp=>1, core=>0},
    'DateTime::Format::Natural'   => {pp=>1, core=>0},
    'experimental'              => {pp=>1, core=>0}, # only core in 5.020+, so we note it as 0
    'List::Util'                => {pp=>0, core=>1},
    'Scalar::Util::Numeric'     => {pp=>0, core=>0},
    'Scalar::Util::Numeric::PP' => {pp=>1, core=>0},
    'Scalar::Util'              => {pp=>0, core=>1},
    'Storable'                  => {pp=>0, core=>1},
    'Time::Duration::Parse::AsHash' => {pp=>1, core=>0},
    'Time::Local'               => {pp=>1, core=>1},
    'Time::Moment'              => {pp=>0, core=>0},
    'Time::Piece'               => {pp=>0, core=>1},
    'warnings'                  => {pp=>1, core=>1},
);

sub add_module {
    my ($self, $cd, $name, $extra_keys, $allow_duplicate) = @_;

    if (exists $extra_keys->{core}) {
        $known_modules{$name}{core} = $extra_keys->{core};
    }

    if (exists $extra_keys->{pp}) {
        $known_modules{$name}{pp} = $extra_keys->{pp};
    }

    if ($extra_keys->{phase} eq 'runtime') {
        if ($cd->{args}{no_modules}) {
            die "BUG: Use of module '$name' when compile option no_modules=1";
        }

        if ($cd->{args}{whitelist_modules} && grep { $_ eq $name } @{ $cd->{args}{whitelist_modules} }) {
            goto PASS;
        }

        if ($cd->{args}{pp}) {
            if (!$known_modules{$name}) {
                die "BUG: Haven't noted about Perl module '$name' as being pp/xs";
            } elsif (!$known_modules{$name}{pp}) {
                die "Use of XS module '$name' when compile option pp=1";
            }
        }

        if ($cd->{args}{core}) {
            if (!$known_modules{$name}) {
                die "BUG: Haven't noted about Perl module '$name' as being core/non-core";
            } elsif (!$known_modules{$name}{core}) {
                die "Use of non-core module '$name' when compile option core=1";
            }
        }

        if ($cd->{args}{core_or_pp}) {
            if (!$known_modules{$name}) {
                die "BUG: Haven't noted about Perl module '$name' as being core/non-core or pp/xs";
            } elsif (!$known_modules{$name}{pp} && !$known_modules{$name}{core}) {
                die "Use of non-core XS module '$name' when compile option core_or_pp=1";
            }
        }
    }
  PASS:
    $self->SUPER::add_module($cd, $name, $extra_keys, $allow_duplicate);
}

sub add_runtime_use {
    my ($self, $cd, $name, $import_terms) = @_;
    my $use_statement = "use $name".
        ($import_terms && @$import_terms ? " (".(join ",", @$import_terms).")" : "");

    # avoid duplicate use statement
    for my $mod (@{ $cd->{modules} }) {
        next unless $mod->{phase} eq 'runtime';
        return if $mod->{use_statement} &&
            $mod->{use_statement} eq $use_statement;
    }

    $self->add_runtime_module(
        $cd,
        $name,
        {
            use_statement => $use_statement,
        },
        1, # allow duplicate
    );
}

sub add_runtime_no {
    my ($self, $cd, $name, $import_terms) = @_;

    my $use_statement = "no $name".
        ($import_terms && @$import_terms ? " (".(join ",", @$import_terms).")" : "");

    # avoid duplicate use statement
    for my $mod (@{ $cd->{modules} }) {
        next unless $mod->{phase} eq 'runtime';
        return if $mod->{use_statement} &&
            $mod->{use_statement} eq $use_statement;
    }

    $self->add_runtime_module(
        $cd,
        $name,
        {
            use_statement => $use_statement,
        },
        1, # allow duplicate
    );
}

sub add_runtime_smartmatch_pragma {
    my ($self, $cd) = @_;
    $self->add_runtime_use($cd, 'experimental', ['"smartmatch"']);
}

# add Scalar::Util::Numeric module
sub add_sun_module {
    my ($self, $cd) = @_;
    if ($cd->{args}{pp} || $cd->{args}{core_or_pp} ||
            !eval { require Scalar::Util::Numeric; 1 }) {
        $cd->{_sun_module} = 'Scalar::Util::Numeric::PP';
    } elsif ($cd->{args}{core}) {
        # just to make sure compilation will fail if we mistakenly use a sun
        # module
        $cd->{_sun_module} = 'Foo';
    } else {
        $cd->{_sun_module} = 'Scalar::Util::Numeric';
    }
    $self->add_runtime_module($cd, $cd->{_sun_module});
}

# evaluate all terms, then return the last term. user has to make sure all the
# terms are properly parenthesized if it contains operator with precedence less
# than the list operator.
sub expr_list {
    my ($self, @t) = @_;
    "(".join(", ", @t).")";
}

sub expr_defined {
    my ($self, $t) = @_;
    "defined($t)";
}

sub expr_array {
    my ($self, @t) = @_;
    "[".join(",", @t)."]";
}

sub expr_array_subscript {
    my ($self, $at, $idxt) = @_;
    "$at->\[$idxt]";
}

sub expr_last_elem {
    my ($self, $at, $idxt) = @_;
    "$at->\[-1]";
}

sub expr_push {
    my ($self, $at, $elt) = @_;
    "push(\@{$at}, $elt)";
}

sub expr_pop {
    my ($self, $at, $elt) = @_;
    "pop(\@{$at})";
}

sub expr_push_and_pop_dpath_between_expr {
    my ($self, $et) = @_;
    join(
        "",
        "[",
        $self->expr_push('$_sahv_dpath', $self->literal(undef)), ", ", # 0
        "~~", $self->enclose_paren($et), ", ", #1 (~~ to avoid list flattening)
        $self->expr_pop('$_sahv_dpath'), # 2
        "]->[1]",
    );
}

sub expr_prefix_dpath {
    my ($self, $t) = @_;
    '(@$_sahv_dpath ? \'@\'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . ' . $t;
}

# $l = $r
sub expr_set {
    my ($self, $l, $r) = @_;
    "($l = $r)";
}

# $l //= $r
sub expr_setif {
    my ($self, $l, $r) = @_;
    "($l //= $r)";
}

sub expr_set_err_str {
    my ($self, $et, $err_expr) = @_;
    "($et //= $err_expr)";
}

sub expr_set_err_full {
    my ($self, $et, $k, $err_expr) = @_;
    "($et\->{$k}{join('/',\@\$_sahv_dpath)} //= $err_expr)";
}

sub expr_reset_err_str {
    my ($self, $et, $err_expr) = @_;
    "($et = undef, 1)";
}

sub expr_reset_err_full {
    my ($self, $et) = @_;
    "(delete($et\->{errors}{join('/',\@\$_sahv_dpath)}), 1)";
}

# $cond_term ? $true_term : $false_term
sub expr_ternary {
    my ($self, $cond_term, $true_term, $false_term) = @_;
    "$cond_term ? $true_term : $false_term";
}

sub expr_log {
    my ($self, $cd, @expr) = @_;

    "log_trace('[sah validator](spath=%s) %s', " .
        $self->literal($cd->{spath}).", " . join(", ", @expr) . ")";
}

# wrap statements into an expression
sub expr_block {
    my ($self, $code) = @_;
    join(
        "",
        "do {\n",
        __indent(
            $self->indent_character,
            $code,
        ),
        "}",
    );
}

# whether block is implemented using function
sub block_uses_sub { 0 }

sub stmt_declare_local_var {
    my ($self, $v, $vt) = @_;
    if ($vt eq 'undef') {
        "my \$$v;";
    } else {
        "my \$$v = $vt;";
    }
}

sub expr_anon_sub {
    my ($self, $args, $code) = @_;
    join(
        "",
        "sub {\n",
        __indent(
            $self->indent_character,
            join(
                "",
                ("my (".join(", ", @$args).") = \@_;\n") x !!@$args,
                $code,
            ),
        ),
        "}"
    );
}

# enclose $stmt in an eval/try block, return true if succeeds, false if error
# was thrown. XXX error message was not recorded yet.
sub expr_eval {
    my ($self, $stmt) = @_;
    "(eval { $stmt }, !\$@)";
}

sub stmt_require_module {
    my ($self, $mod_record) = @_;

    if ($mod_record->{use_statement}) {
        return "$mod_record->{use_statement};";
    } else {
        "require $mod_record->{name};";
    }
}

sub stmt_require_log_module {
    my ($self) = @_;
    'use Log::ger;';
}

sub stmt_assign_hash_value {
    my ($self, $ht, $kt, $vt) = @_;
    "$ht\->{$kt} = $vt;";
}

sub stmt_return {
    my $self = shift;
    if (@_) {
        "return($_[0]);";
    } else {
        'return;';
    }
}

sub expr_validator_sub {
    my ($self, %args) = @_;

    $self->check_compile_args(\%args);

    my $aref = delete $args{accept_ref};
    if ($aref) {
        $args{var_term}  = '$ref_'.$args{data_name};
        $args{data_term} = '$$ref_'.$args{data_name};
    } else {
        $args{var_term}  = '$'.$args{data_name};
        $args{data_term} = '$'.$args{data_name};
    }

    $self->SUPER::expr_validator_sub(%args);
}

sub _str2reliteral {
    require Regexp::Stringify;

    my ($self, $cd, $str) = @_;

    my $re;
    if (ref($str) eq 'Regexp') {
        $re = $str;
    } else {
        eval { $re = qr/$str/ };
        $self->_die($cd, "Invalid regex $str: $@") if $@;
    }

    Regexp::Stringify::stringify_regexp(regexp=>$re, plver=>5.010);
}

1;
# ABSTRACT: Compile Sah schema to Perl code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl - Compile Sah schema to Perl code

=head1 VERSION

This document describes version 0.897 of Data::Sah::Compiler::perl (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 SYNOPSIS

 # see Data::Sah

=head1 DESCRIPTION

Derived from L<Data::Sah::Compiler::Prog>.

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr|true|false|literal|expr_.+|stmt_.+|block_uses_sub)$

=head1 VARIABLES

=head2 $PP => bool

Set default for C<pp> compile argument. Takes precedence over environment
C<DATA_SAH_PP>.

=head2 $CORE => bool

Set default for C<core> compile argument. Takes precedence over environment
C<DATA_SAH_CORE>.

=head2 $CORE_OR_PP => bool

Set default for C<core_or_pp> compile argument. Takes precedence over
environment C<DATA_SAH_CORE_OR_PP>.

=head2 $NO_MODULES => bool

Set default for C<no_modules> compile argument. Takes precedence over
environment C<DATA_SAH_NO_MODULES>.

=head1 DEVELOPER NOTES

To generate expression code that says "all subexpression must be true", you can
do:

 !defined(List::Util::first(sub { blah($_) }, "value", ...))

This is a bit harder to read than:

 !grep { !blah($_) } "value", ...

but has the advantage of the ability to shortcut on the first item that fails.

Similarly, to say "at least one subexpression must be true":

 defined(List::Util::first(sub { blah($_) }, "value", ...))

which can shortcut in contrast to:

 grep { blah($_) } "value", ...

=head1 METHODS

=head2 new() => OBJ

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation result:

=over

=back

=head2 $c->comment($cd, @args) => STR

Generate a comment. For example, in perl compiler:

 $c->comment($cd, "123"); # -> "# 123\n"

Will return an empty string if compile argument C<comment> is set to false.

=head2 $c->compile(%args) => RESULT

Aside from Prog's arguments, this class supports these arguments:

=over

=item * pp => bool (default: 0)

If set to true, will avoid the use of XS modules in the generated code and will
opt instead to use pure-perl modules.

=item * core => bool (default: 0)

If set to true, will avoid the use of non-core modules in the generated code and
will opt instead to use core modules.

=item * core_or_pp => bool (default: 0)

If set to true, will stick to using only core or PP modules in the generated
code.

=item * whitelist_modules => array {of=>'str'}

When C<pp>/C<core>/C<core_or_pp> option is set to true, the use of
non-appropriate modules will cause failure. However, you can pass a list of
modules that are allowed nevertheless.

=back

=head2 $c->add_runtime_use($cd, $module [, \@import_terms ])

This is like C<add_runtime_module()>, but indicate that C<$module> needs to be
C<use>-d in the generated code (for example, Perl pragmas). Normally if
C<add_runtime_module()> is used, the generated code will use C<require>.

If you use C<< $c->add_runtime_use($cd, 'foo') >>, this code will be generated:

 use foo;

If you use C<< $c->add_runtime_use($cd, 'foo', ["'a'", "'b'", "123"]) >>, this code will
be generated:

 use foo ('a', 'b', 123);

If you use C<< $c->add_runtime_use($cd, 'foo', []) >>, this code will be generated:

 use foo ();

The generated statement will be added at the top (top-level lexical scope) and
duplicates are ignored. To generate multiple and lexically-scoped C<use> and
C<no> statements, e.g. like below, currently you can generate them manually:

 if (blah) {
     no warnings;
     ...
 }

=head2 $c->add_runtime_no($cd, $module [, \@import_terms ])

This is the counterpart of C<add_runtime_use()>, to generate C<no foo> statement.

See also: C<add_runtime_use()>.

=head2 $c->add_runtime_smartmatch_pragma($cd)

Equivalent to:

 $c->add_runtime_use($cd, 'experimental', ["'smartmatch'"]);

=head2 $c->add_sun_module($cd)

Add L<Scalar::Util::Numeric> module, or L<Scalar::Util::Numeric::PP> when C<pp>
compile argument is true.

=head1 ENVIRONMENT

=head2 DATA_SAH_PP => bool

Set default for C<pp> compile argument.

=head2 DATA_SAH_CORE => bool

Set default for C<core> compile argument.

=head2 DATA_SAH_CORE_OR_PP => bool

Set default for C<core_or_pp> compile argument.

=head2 DATA_SAH_NO_MODULES => bool

Set default for C<no_modules> compile argument.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
