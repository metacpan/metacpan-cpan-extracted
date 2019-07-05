package Data::Sah::Compiler::human;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any::IfLOG qw($log);

use Data::Dmp qw(dmp);
use Mo qw(build default);
use POSIX qw(locale_h);
use Text::sprintfn;

extends 'Data::Sah::Compiler';

# every type extension is registered here
our %typex; # key = type, val = [clause, ...]

sub name { "human" }

sub _add_msg_catalog {
    my ($self, $cd, $msg) = @_;
    return unless $cd->{args}{format} eq 'msg_catalog';

    my $spath = join("/", @{ $cd->{spath} });
    $cd->{_msg_catalog}{$spath} = $msg;
}

sub check_compile_args {
    use experimental 'smartmatch';

    my ($self, $args) = @_;

    $self->SUPER::check_compile_args($args);

    my @fmts = ('inline_text', 'inline_err_text', 'markdown', 'msg_catalog');
    $args->{format} //= $fmts[0];
    unless ($args->{format} ~~ @fmts) {
        $self->_die({}, "Unsupported format, use one of: ".join(", ", @fmts));
    }
}

sub init_cd {
    my ($self, %args) = @_;

    my $cd = $self->SUPER::init_cd(%args);
    if (($cd->{args}{format} // '') eq 'msg_catalog') {
        $cd->{_msg_catalog} //= $cd->{outer_cd}{_msg_catalog};
        $cd->{_msg_catalog} //= {};
    }
    $cd;
}

sub expr {
    my ($self, $cd, $expr) = @_;

    # for now we dump expression as is. we should probably parse it first to
    # localize number, e.g. "1.1 + 2" should become "1,1 + 2" in id_ID.

    # XXX for nicer output, perhaps say "the expression X" instead of just "X",
    # especially if X has a variable or rather complex.
    $expr;
}

sub literal {
    my ($self, $val) = @_;

    return $val unless ref($val);
    dmp($val);
}

# translate
sub _xlt {
    my ($self, $cd, $text) = @_;

    my $lang = $cd->{args}{lang};

    #$log->tracef("translating text '%s' to '%s'", $text, $lang);

    return $text if $lang eq 'en_US';
    my $translations;
    {
        no strict 'refs';
        $translations = \%{"Data::Sah::Lang::$lang\::translations"};
    }
    return $translations->{$text} if defined($translations->{$text});
    if ($cd->{args}{mark_missing_translation}) {
        return "(no $lang text:$text)";
    } else {
        return $text;
    }
}

# ($cd, 3, "element") -> "3rd element"
sub _ordinate {
    my ($self, $cd, $n, $noun) = @_;

    my $lang = $cd->{args}{lang};

    # we assume _xlt() has been called (and thus the appropriate
    # Data::Sah::Lang::* has been loaded)

    if ($lang eq 'en_US') {
        require Lingua::EN::Numbers::Ordinate;
        return Lingua::EN::Numbers::Ordinate::ordinate($n) . " $noun";
    } else {
        no strict 'refs';
        return "Data::Sah::Lang::$lang\::ordinate"->($n, $noun);
    }
}

sub _add_ccl {
    use experimental 'smartmatch';

    my ($self, $cd, $ccl) = @_;
    #$log->errorf("TMP: add_ccl %s", $ccl);

    $ccl->{xlt} //= 1;

    my $clause = $cd->{clause} // "";
    $ccl->{type} //= "clause";

    my $do_xlt = 1;

    my $hvals = {
        modal_verb     => $self->_xlt($cd, "must"),
        modal_verb_neg => $self->_xlt($cd, "must not"),

        # so they can overriden through hash_values
        field          => $self->_xlt($cd, "field"),
        fields         => $self->_xlt($cd, "fields"),

        %{ $cd->{args}{hash_values} // {} },
    };
    my $mod="";

    # is .human for desired language specified? if yes, use that instead

    {
        my $lang   = $cd->{args}{lang};
        my $dlang  = $cd->{clset_dlang} // "en_US"; # undef if not in clause
        my $suffix = $lang eq $dlang ? "" : ".alt.lang.$lang";
        if ($clause) {
            delete $cd->{uclset}{$_} for
                grep {/\A\Q$clause.human\E(\.|\z)/} keys %{$cd->{uclset}};
            if (defined $cd->{clset}{"$clause.human$suffix"}) {
                $ccl->{type} = 'clause';
                $ccl->{fmt}  = $cd->{clset}{"$clause.human$suffix"};
                goto FILL_FORMAT;
            }
        } else {
            delete $cd->{uclset}{$_} for
                grep {/\A\.name(\.|\z)/} keys %{$cd->{uclset}};
            if (defined $cd->{clset}{".name$suffix"}) {
                $ccl->{type} = 'noun';
                $ccl->{fmt}  = $cd->{clset}{".name$suffix"};
                $ccl->{vals} = undef;
                goto FILL_FORMAT;
            }
        }
    }

    goto TRANSLATE unless $clause;

    my $ie    = $cd->{cl_is_expr};
    my $im    = $cd->{cl_is_multi};
    my $op    = $cd->{cl_op} // "";
    my $cv    = $cd->{clset}{$clause};
    my $vals  = $ccl->{vals} // [$cv];

    # handle .is_expr

    if ($ie) {
        if (!$ccl->{expr}) {
            $ccl->{fmt} = "($clause -> %s" . ($op ? " op=$op" : "") . ")";
            $do_xlt = 0;
            $vals = [$self->expr($cd, $vals)];
        }
        goto ERR_LEVEL;
    }

    # handle .op

    if ($op eq 'not') {
        ($hvals->{modal_verb}, $hvals->{modal_verb_neg}) =
            ($hvals->{modal_verb_neg}, $hvals->{modal_verb});
        $vals = [map {$self->literal($_)} @$vals];
    } elsif ($im && $op eq 'and') {
        if (@$cv == 2) {
            $vals = [sprintf($self->_xlt($cd, "%s and %s"),
                             $self->literal($cv->[0]),
                             $self->literal($cv->[1]))];
        } else {
            $vals = [sprintf($self->_xlt($cd, "all of %s"),
                             $self->literal($cv))];
        }
    } elsif ($im && $op eq 'or') {
        if (@$cv == 2) {
            $vals = [sprintf($self->_xlt($cd, "%s or %s"),
                             $self->literal($cv->[0]),
                             $self->literal($cv->[1]))];
        } else {
            $vals = [sprintf($self->_xlt($cd, "one of %s"),
                             $self->literal($cv))];
        }
    } elsif ($im && $op eq 'none') {
        ($hvals->{modal_verb}, $hvals->{modal_verbneg}) =
            ($hvals->{modal_verb_neg}, $hvals->{modal_verb});
        if (@$cv == 2) {
            $vals = [sprintf($self->_xlt($cd, "%s nor %s"),
                             $self->literal($cv->[0]),
                             $self->literal($cv->[1]))];
        } else {
            $vals = [sprintf($self->_xlt($cd, "any of %s"),
                             $self->literal($cv))];
        }
    } else {
        $vals = [map {$self->literal($_)} @$vals];
    }

  ERR_LEVEL:

    # handle .err_level
    if ($ccl->{type} eq 'clause' && 'constraint' ~~ $cd->{cl_meta}{tags}) {
        if (($cd->{clset}{"$clause.err_level"}//'error') eq 'warn') {
            if ($op eq 'not') {
                $hvals->{modal_verb}     = $self->_xlt($cd, "should not");
                $hvals->{modal_verb_neg} = $self->_xlt($cd, "should");
            } else {
                $hvals->{modal_verb}     = $self->_xlt($cd, "should");
                $hvals->{modal_verb_neg} = $self->_xlt($cd, "should not");
            }
        }
    }
    delete $cd->{uclset}{"$clause.err_level"};

  TRANSLATE:

    if ($ccl->{xlt}) {
        if (ref($ccl->{fmt}) eq 'ARRAY') {
            $ccl->{fmt}  = [map {$self->_xlt($cd, $_)} @{$ccl->{fmt}}];
        } elsif (!ref($ccl->{fmt})) {
            $ccl->{fmt}  = $self->_xlt($cd, $ccl->{fmt});
        }
    }

  FILL_FORMAT:

    if (ref($ccl->{fmt}) eq 'ARRAY') {
        $ccl->{text} = [map {sprintfn($_, (map {$_//""} ($hvals, @$vals)))}
                            @{$ccl->{fmt}}];
    } elsif (!ref($ccl->{fmt})) {
        $ccl->{text} = sprintfn($ccl->{fmt}, (map {$_//""} ($hvals, @$vals)));
    }
    delete $ccl->{fmt} unless $cd->{args}{debug};

  PUSH:
    push @{$cd->{ccls}}, $ccl;

    $self->_add_msg_catalog($cd, $ccl);
}

# add a compiled clause (ccl), which will be combined at the end of compilation
# to be the final result. args is a hashref with these keys:
#
# * type* - str (default 'clause'). either 'noun', 'clause', 'list' (bulleted
#   list, a clause followed by a list of items, each of them is also a ccl)
#
# * fmt* - str/2-element array. human text which can be used as the first
#   argument to sprintf. string. if type=noun, can be a two-element arrayref to
#   contain singular and plural version of noun.
#
# * expr - bool. fmt can handle .is_expr=1. for example, 'len=' => '1+1' can be
#   compiled into 'length must be 1+1'. other clauses cannot handle expression,
#   e.g. 'between=' => '[2, 2*2]'. this clause will be using the generic message
#   'between must [2, 2*2]'
#
# * vals - arrayref (default [clause value]). values to fill fmt with.
#
# * items - arrayref. required if type=list. a single ccl or a list of ccls.
#
# * xlt - bool (default 1). set to 0 if fmt has been translated, and should not
#   be translated again.
#
# add_ccl() is called by clause handlers and handles using .human, translating
# fmt, sprintf(fmt, vals) into 'text', .err_level (adding 'must be %s', 'should
# not be %s'), .is_expr, .op.
sub add_ccl {
    my ($self, $cd, @ccls) = @_;

    my $op     = $cd->{cl_op} // '';

    my $ccl;
    if (@ccls == 1) {
        $self->_add_ccl($cd, $ccls[0]);
    } else {
        my $inner_cd = $self->init_cd(outer_cd => $cd);
        $inner_cd->{args} = $cd->{args};
        $inner_cd->{clause} = $cd->{clause};
        for (@ccls) {
            $self->_add_ccl($inner_cd, $_);
        }

        $ccl = {
            type  => 'list',
            vals  => [],
            items => $inner_cd->{ccls},
            multi => 0,
        };
        if ($op eq 'or') {
            $ccl->{fmt} = 'any of the following %(modal_verb)s be true';
        } elsif ($op eq 'and') {
            $ccl->{fmt} = 'all of the following %(modal_verb)s be true';
        } elsif ($op eq 'none') {
            $ccl->{fmt} = 'none of the following %(modal_verb)s be true';
            # or perhaps, fmt = 'All of the following ...' but set op to 'not'?
        }
        $self->_add_ccl($cd, $ccl);
    }
}

# format ccls to form final result. at the end of compilation, we have a tree of
# ccls. this method accept a single ccl (of type either noun/clause) or an array
# of ccls (which it will join together).
sub format_ccls {
    my ($self, $cd, $ccls) = @_;

    # used internally to determine if the result is a single noun, in which case
    # when format is inline_err_text, we add 'Not of type '. XXX: currently this
    # is the wrong way to count? we shouldn't count children? perhaps count from
    # msg_catalog instead?
    local $cd->{_fmt_noun_count} = 0;
    local $cd->{_fmt_etc_count} = 0;

    my $f = $cd->{args}{format};
    my $res;
    if ($f eq 'inline_text' || $f eq 'inline_err_text' || $f eq 'msg_catalog') {
        $res = $self->_format_ccls_itext($cd, $ccls);
        if ($f eq 'inline_err_text') {
            #$log->errorf("TMP: noun=%d, etc=%d", $cd->{_fmt_noun_count}, $cd->{_fmt_etc_count});
            if ($cd->{_fmt_noun_count} == 1 && $cd->{_fmt_etc_count} == 0) {
                # a single noun (type name), we should add some preamble
                $res = sprintf(
                    $self->_xlt($cd, "Not of type %s"),
                    $res
                );
            } elsif (!$cd->{_fmt_noun_count}) {
                # a clause (e.g. "must be >= 10"), already looks like errmsg
            } else {
                # a noun + clauses (e.g. "integer, must be even"). add preamble
                $res = sprintf(
                    $self->_xlt(
                        $cd, "Does not satisfy the following schema: %s"),
                    $res
                );
            }
        }
    } else {
        $res = $self->_format_ccls_markdown($cd, $ccls);
    }
    $res;
}

sub _format_ccls_itext {
    my ($self, $cd, $ccls) = @_;

    local $cd->{args}{mark_missing_translation} = 0;
    my $c_comma = $self->_xlt($cd, ", ");

    if (ref($ccls) eq 'HASH' && $ccls->{type} =~ /^(noun|clause)$/) {
        if ($ccls->{type} eq 'noun') {
            $cd->{_fmt_noun_count}++;
        } else {
            $cd->{_fmt_etc_count}++;
        }
        # handle a single noun/clause ccl
        my $ccl = $ccls;
        return ref($ccl->{text}) eq 'ARRAY' ? $ccl->{text}[0] : $ccl->{text};
    } elsif (ref($ccls) eq 'HASH' && $ccls->{type} eq 'list') {
        # handle a single list ccl
        my $c_openpar  = $self->_xlt($cd, "(");
        my $c_closepar = $self->_xlt($cd, ")");
        my $c_colon    = $self->_xlt($cd, ": ");
        my $ccl = $ccls;

        my $txt = $ccl->{text}; $txt =~ s/\s+$//;
        my @t = ($txt, $c_colon);
        my $i = 0;
        for (@{ $ccl->{items} }) {
            push @t, $c_comma if $i;
            my $it = $self->_format_ccls_itext($cd, $_);
            if ($it =~ /\Q$c_comma/) {
                push @t, $c_openpar, $it, $c_closepar;
            } else {
                push @t, $it;
            }
            $i++;
        }
        return join("", @t);
    } elsif (ref($ccls) eq 'ARRAY') {
        # handle an array of ccls
        return join($c_comma, map {$self->_format_ccls_itext($cd, $_)} @$ccls);
    } else {
        $self->_die($cd, "Can't format $ccls");
    }
}

sub _format_ccls_markdown {
    my ($self, $cd, $ccls) = @_;

    $self->_die($cd, "Sorry, markdown not yet implemented");
}

sub _load_lang_modules {
    my ($self, $cd) = @_;

    my $lang = $cd->{args}{lang};
    die "Invalid language '$lang', please use letters only"
        unless $lang =~ /\A\w+\z/;

    my @modp;
    unless ($lang eq 'en_US') {
        push @modp, "Data/Sah/Lang/$lang.pm";
        for my $cl (@{ $typex{$cd->{type}} // []}) {
            my $modp = "Data/Sah/Lang/$lang/TypeX/$cd->{type}/$cl.pm";
            $modp =~ s!::!/!g; # $cd->{type} might still contain '::'
            push @modp, $modp;
        }
    }
    my $i;
    for my $modp (@modp) {
        $i++;
        unless (exists $INC{$modp}) {
            if ($i == 1) {
                # test to check whether Data::Sah::Lang::$lang exists. if it
                # does not, we fallback to en_US.
                require Module::Installed::Tiny;
                if (!Module::Installed::Tiny::module_installed($modp)) {
                    #$log->debug("$mod cannot be found, falling back to en_US");
                    $cd->{args}{lang} = 'en_US';
                    last;
                }
            }
            #$log->trace("Loading $modp ...");
            require $modp;

            # negative-cache, so we don't have to try again
            $INC{$modp} = undef;
        }
    }
}

sub before_compile {
    my ($self, $cd) = @_;

    # set locale so that numbers etc are printed according to locale (e.g.
    # sprintf("%s", 1.2) prints '1,2' in id_ID).
    $cd->{_orig_locale} = setlocale(LC_ALL);

    # XXX do we need to set everything? LC_ADDRESS, LC_TELEPHONE, LC_PAPER, ...
    my $res = setlocale(LC_ALL, $cd->{args}{locale} // $cd->{args}{lang});
    warn "Unsupported locale $cd->{args}{lang}"
        if $cd->{args}{debug} && !defined($res);
}

sub before_handle_type {
    my ($self, $cd) = @_;

    $self->_load_lang_modules($cd);
}

sub before_clause {
    my ($self, $cd) = @_;

    # by default, human clause handler can handle multiple values (e.g.
    # "div_by&"=>[2, 3] becomes "must be divisible by 2 and 3" instead of having
    # to be ["must be divisible by 2", "must be divisible by 3"]. some clauses
    # that don't can override this value to 0.
    $cd->{CLAUSE_DO_MULTI} = 1;
}

sub after_clause {
    my ($self, $cd) = @_;

    # reset what we set in before_clause()
    delete $cd->{CLAUSE_DO_MULTI};
}

sub after_all_clauses {
    use experimental 'smartmatch';

    my ($self, $cd) = @_;

    # quantify NOUN (e.g. integer) into 'required integer', 'optional integer',
    # or 'forbidden integer'.

    # my $q;
    # if (!$cd->{clset}{'required.is_expr'} &&
    #         !('required' ~~ $cd->{args}{skip_clause})) {
    #     if ($cd->{clset}{required}) {
    #         $q = 'required %s';
    #     } else {
    #         $q = 'optional %s';
    #     }
    # } elsif ($cd->{clset}{forbidden} && !$cd->{clset}{'forbidden.is_expr'} &&
    #              !('forbidden' ~~ $cd->{args}{skip_clause})) {
    #     $q = 'forbidden %s';
    # }
    # if ($q && @{$cd->{ccls}} && $cd->{ccls}[0]{type} eq 'noun') {
    #     $q = $self->_xlt($cd, $q);
    #     for (ref($cd->{ccls}[0]{text}) eq 'ARRAY' ?
    #              @{ $cd->{ccls}[0]{text} } : $cd->{ccls}[0]{text}) {
    #         $_ = sprintf($q, $_);
    #     }
    # }

    $cd->{result} = $self->format_ccls($cd, $cd->{ccls});
}

sub after_compile {
    my ($self, $cd) = @_;

    setlocale(LC_ALL, $cd->{_orig_locale});

    if ($cd->{args}{format} eq 'msg_catalog') {
        $cd->{result} = $cd->{_msg_catalog};
    }
}

1;
# ABSTRACT: Compile Sah schema to human language

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::human - Compile Sah schema to human language

=head1 VERSION

This document describes version 0.896 of Data::Sah::Compiler::human (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is derived from L<Data::Sah::Compiler>. It generates human language
text.

=for Pod::Coverage ^(name|literal|expr|add_ccl|format_ccls|check_compile_args|handle_.+|before_.+|after_.+)$

=head1 ATTRIBUTES

=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from base class' arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over

=item * format => STR (default: C<inline_text>)

Format of text to generate. Either C<inline_text>, C<inline_err_text>, or
C<markdown>. Note that you can easily convert Markdown to HTML, there are
libraries in Perl, JavaScript, etc to do that.

Sample C<inline_text> output:

 integer, must satisfy all of the following: (divisible by 3, at least 10)

C<inline_err_text> is just like C<inline_text>, except geared towards producing
an error message. Currently, instead of producing "integer" from schema "int",
it produces "Not of type integer". The rest is identical.

Sample C<markdown> output:

 integer, must satisfy all of the following:

 * divisible by 3
 * at least 10

=item * hash_values => hash

Optional, supply more keys to hash value to C<sprintfn> which will be used
during compilation.

=back

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation state:

=over 4

=back

Keys which contain compilation result:

=over 4

=back

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
