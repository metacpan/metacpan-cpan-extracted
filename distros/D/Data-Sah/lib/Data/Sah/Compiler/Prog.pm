package Data::Sah::Compiler::Prog;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use Mo qw(build default);
extends 'Data::Sah::Compiler';

#use Digest::MD5 qw(md5_hex);

# human compiler, to produce error messages
has hc => (is => 'rw');

# subclass should provide a default, choices: 'shell', 'c', 'ini', 'cpp'
has comment_style => (is => 'rw');

has var_sigil => (is => 'rw');

has concat_op => (is => 'rw');

has logical_and_op => (is => 'rw', default => sub {'&&'});

has logical_not_op => (is => 'rw', default => sub {'!'});

#has logical_or_op => (is => 'rw', default => sub {'||'});

sub init_cd {
    my ($self, %args) = @_;

    my $cd = $self->SUPER::init_cd(%args);
    $cd->{vars} = {};

    my $hc = $self->hc;
    if (!$hc) {
        $hc = $self->main->get_compiler("human");
        $self->hc($hc);
    }

    if (my $ocd = $cd->{outer_cd}) {
        $cd->{vars}    = $ocd->{vars};
        $cd->{modules} = $ocd->{modules};
        $cd->{_hc}     = $ocd->{_hc};
        $cd->{_hcd}    = $ocd->{_hcd};
        $cd->{_subdata_level} = $ocd->{_subdata_level};
        $cd->{use_dpath} = 1 if $ocd->{use_dpath};
    } else {
        $cd->{vars}    = {};
        $cd->{modules} = [];
        $cd->{_hc}     = $hc;
        $cd->{_subdata_level} = 0;
    }

    $cd;
}

sub check_compile_args {
    my ($self, $args) = @_;

    return if $args->{_args_checked_Prog}++;

    $self->SUPER::check_compile_args($args);

    my $ct = ($args->{code_type} //= 'validator');
    if ($ct ne 'validator') {
        $self->_die({}, "code_type currently can only be 'validator'");
    }
    my $rt = ($args->{return_type} //= 'bool');
    if ($rt !~ /\A(bool\+val|bool|str\+val|str|full)\z/) {
        $self->_die({}, "Invalid value for return_type, ".
                        "use bool|bool+val|str|str+val|full");
    }
    $args->{var_prefix} //= "_sahv_";
    $args->{sub_prefix} //= "_sahs_";
    $args->{data_term}  //= $self->var_sigil . $args->{data_name};
    $args->{data_term_is_lvalue} //= 1;
    $args->{tmp_data_name} //= "tmp_$args->{data_name}";
    $args->{tmp_data_term} //= $self->var_sigil . $args->{tmp_data_name};
    $args->{comment}    //= 1;
    $args->{err_term}   //= $self->var_sigil . "err_$args->{data_name}";
    $args->{coerce}     //= 1;
}

sub comment {
    my ($self, $cd, @args) = @_;
    return '' unless $cd->{args}{comment};

    my $content = join("", @args);
    $content =~ s/\n+/ /g;

    my $style = $self->comment_style;
    if ($style eq 'shell') {
        return join("", "# ", $content, "\n");
    } elsif ($style eq 'shell2') {
        return join("", "## ", $content, "\n");
    } elsif ($style eq 'cpp') {
        return join("", "// ", $content, "\n");
    } elsif ($style eq 'c') {
        return join("", "/* ", $content, '*/');
    } elsif ($style eq 'ini') {
        return join("", "; ", $content, "\n");
    } else {
        $self->_die($cd, "BUG: Unknown comment style: $style");
    }
}

# enclose expression with parentheses, unless it already is
sub enclose_paren {
    my ($self, $expr, $force) = @_;
    if ($expr =~ /\A(\s*)(\(.+\)\s*)\z/os) {
        return $expr if !$force;
        return "$1($2)";
    } else {
        $expr =~ /\A(\s*)(.*)/os;
        return "$1($2)";
    }
}

sub add_var {
    my ($self, $cd, $name, $value) = @_;

    return if exists $cd->{vars}{$name};
    #$log->tracef("TMP: add_var %s", $name);
    $cd->{vars}{$name} = $value;
}

# naming convention: expr_NOUN(), stmt_VERB(_NOUN)?()

# XXX requires: expr_list

# XXX requires: expr_defined

# XXX requires: expr_array

# XXX requires: expr_array_subscript

# XXX requires: expr_last_elem

# XXX requires: expr_push

# XXX requires: expr_pop

# XXX requires: expr_push_and_pop_dpath_between_expr

# XXX requires: expr_prefix_dpath

# XXX requires: expr_set

# XXX requires: expr_setif

# XXX requires: expr_set_err_str

# XXX requires: expr_set_err_full

# XXX requires: expr_reset_err_str

# XXX requires: expr_reset_err_full

# XXX requires: expr_ternary

# XXX requires: expr_log

# XXX requires: expr_block

# XXX requires: expr_anon_sub

# XXX requires: expr_eval

# XXX requires: stt_declare_local_var

# TODO XXX requires: expr_declare_lexical_var

# XXX requires: stmt_require_module

# XXX requires: stmt_require_log_module

# XXX requires: stmt_assign_hash_value

# XXX requires: stmt_return

# assign value to a variable
sub expr_assign {
    my ($self, $v, $t) = @_;
    "$v = $t";
}

sub _xlt {
    my ($self, $cd, $text) = @_;

    my $hc  = $cd->{_hc};
    my $hcd = $cd->{_hcd};
    #$log->tracef("(Prog) Translating text %s ...", $text);
    $hc->_xlt($hcd, $text);
}

# concatenate strings
sub expr_concat {
    my ($self, @t) = @_;
    join(" " . $self->concat_op . " ", @t);
}

# variable
sub expr_var {
    my ($self, $v) = @_;
    $self->var_sigil. $v;
}

sub expr_preinc {
    my ($self, $t) = @_;
    "++$t";
}

sub expr_preinc_var {
    my ($self, $v) = @_;
    "++" . $self->var_sigil. $v;
}

# expr_postinc
# expr_predec
# expr_postdec

# args: log_result, var_term, err_term. the rest is the same/supplied to
# compile().
sub expr_validator_sub {
    my ($self, %args) = @_;

    my $log_result = delete $args{log_result};
    my $dt         = $args{data_term};
    my $vt         = delete($args{var_term}) // $dt;
    my $do_log     = $args{debug_log} // $args{debug};
    my $rt         = $args{return_type} // 'bool';

    $args{indent_level} = 1;

    my $cd = $args{cd} // $self->compile(%args);
    my $et = $cd->{args}{err_term};

    if ($rt !~ /\Abool/) {
        my ($ev) = $et =~ /(\w+)/; # to remove sigil
        $self->add_var($cd, $ev, $rt =~ /\Astr/ ? undef : {});
    }
    my $resv = '_sahv_res';
    my $rest = $self->var_sigil . $resv;

    my $needs_expr_block = (grep {$_->{phase} eq 'runtime'} @{ $cd->{modules} })
                                || $do_log;

    my $code = join(
        "",
        ($self->stmt_require_log_module."\n") x !!$do_log,
        (map { $self->stmt_require_module($_)."\n" }
             grep { $_->{phase} eq 'runtime' } @{ $cd->{modules} }),
        $self->expr_anon_sub(
            [$vt],
            join(
                "",
                (map {$self->stmt_declare_local_var(
                    $_, $self->literal($cd->{vars}{$_}))."\n"}
                     sort keys %{ $cd->{vars} }),
                #$log->tracef('-> (validator)(%s) ...', $dt);\n";
                $self->stmt_declare_local_var($resv, "\n\n" . $cd->{result})."\n\n",

                # when rt=bool, return true/false result
                #(";\n\n\$log->tracef('<- validator() = %s', \$res)")
                #    x !!($do_log && $rt eq 'bool'),
                ($self->stmt_return($rest)."\n")
                    x !!($rt eq 'bool'),

                # when rt=str, return string error message
                #($log->tracef('<- validator() = %s', ".
                #     "\$err_data);\n\n";
                #    x !!($do_log && $rt eq 'str'),
                ($self->expr_set_err_str($et, $self->literal('')).";",
                 "\n\n".$self->stmt_return($et)."\n")
                    x !!($rt eq 'str'),

                # when rt=bool+val, return true/false result as well as final
                # input value
                ($self->stmt_return($self->expr_array($rest, $dt))."\n")
                    x !!($rt eq 'bool+val'),

                # when rt=str+val, return string error message as well as final
                # input value
                ($self->expr_set_err_str($et, $self->literal('')).";",
                 "\n\n".$self->stmt_return($self->expr_array($et, $dt))."\n")
                    x !!($rt eq 'str+val'),

                # when rt=full, return error hash
                ($self->stmt_assign_hash_value($et, $self->literal('value'), $dt),
                 "\n".$self->stmt_return($et)."\n")
                    x !!($rt eq 'full'),
            )
        ),
    );

    if ($needs_expr_block) {
        $code = $self->expr_block($code);
    }

    if ($log_result && log_is_trace()) {
        log_trace("validator code:\n%s",
                     ($ENV{LINENUM} // 1) ?
                         Data::Sah::Compiler::__linenum($code) :
                           $code);
    }

    $code;
}

# add compiled clause to ccls, along with extra information useful for joining
# later (like error level, code for adding error message, etc). available
# options:
#
# - err_level (str, the default will be taken from current clause's .err_level
# if not specified),
#
# - err_expr (str, a string expression in the target language that evaluates to
# an error message, the more general and dynamic alternative to err_msg.
#
# - err_msg (str, the default will be produced by human compiler if not
# supplied, or taken from current clause's .err_msg),
#
# - subdata (bool, default false, if set to true then this means we are
# delving into subdata, e.g. array elements or hash pair values, and appropriate
# things must be done to adjust for this [e.g. push_dpath/pop_dpath at the end
# so that error message can show the proper data path].
#
# - assert (bool, default false, if set to true means this ccl is an assert ccl,
# meaning it always returns true and is not translated from an actual clause. it
# will not affect number of errors nor produce error messages.)
sub add_ccl {
    my ($self, $cd, $ccl, $opts) = @_;
    $opts //= {};
    my $clause = $cd->{clause} // "";
    my $op     = $cd->{cl_op} // "";
    #$log->errorf("TMP: adding ccl %s, current ccls=%s", $ccl, $cd->{ccls});

    my $el = $opts->{err_level} // $cd->{clset}{"$clause.err_level"} // "error";
    my $err_expr = $opts->{err_expr};
    my $err_msg  = $opts->{err_msg};

    if (defined $err_expr) {
        $self->add_var($cd, '_sahv_dpath', []) if $cd->{use_dpath};
        $err_expr = $self->expr_prefix_dpath($err_expr) if $cd->{use_dpath};
    } else {
        unless (defined $err_msg) { $err_msg = $cd->{clset}{"$clause.err_msg"} }
        unless (defined $err_msg) {
            # XXX how to invert on op='none' or op='not'?

            my @msgpath = @{$cd->{spath}};
            my $msgpath;
            my $hc  = $cd->{_hc};
            my $hcd = $cd->{_hcd};
            while (1) {
                # search error message, use more general one if the more
                # specific one is not available
                last unless @msgpath;
                $msgpath = join("/", @msgpath);
                my $ccls = $hcd->{result}{$msgpath};
                pop @msgpath;
                if ($ccls) {
                    local $hcd->{args}{format} = 'inline_err_text';
                    $err_msg = $hc->format_ccls($hcd, $ccls);
                    # show path when debugging
                    $err_msg = "(msgpath=$msgpath) $err_msg"
                        if $cd->{args}{debug};
                    last;
                }
            }
            if (!$err_msg) {
                $err_msg = "ERR (clause=".($cd->{clause} // "").")";
            } else {
                $err_msg = ucfirst($err_msg);
            }
        }
        if ($err_msg) {
            $self->add_var($cd, '_sahv_dpath', []) if $cd->{use_dpath};
            $err_expr = $self->literal($err_msg);
            $err_expr = $self->expr_prefix_dpath($err_expr) if $cd->{use_dpath};
        }
    }

    my $rt = $cd->{args}{return_type};
    my $et = $cd->{args}{err_term};
    my $err_code;
    if ($rt eq 'full') {
        $self->add_var($cd, '_sahv_dpath', []) if $cd->{use_dpath};
        my $k = $el eq 'warn' ? 'warnings' : 'errors';
        $err_code = $self->expr_set_err_full($et, $k, $err_expr) if $err_expr;
    } elsif ($rt =~ /\Astr/) {
        if ($el ne 'warn') {
            $err_code = $self->expr_set_err_str($et, $err_expr) if $err_expr;
        }
    }

    my $res = {
        ccl             => $ccl,
        err_level       => $el,
        err_code        => $err_code,
        (_debug_ccl_note => $cd->{_debug_ccl_note}) x !!$cd->{_debug_ccl_note},
        subdata         => $opts->{subdata},
    };
    push @{ $cd->{ccls} }, $res;
    delete $cd->{uclset}{"$clause.err_level"};
    delete $cd->{uclset}{"$clause.err_msg"};
}

# join ccls to handle .op and insert error messages. opts = op
sub join_ccls {
    my ($self, $cd, $ccls, $opts) = @_;
    $opts //= {};
    my $op = $opts->{op} // "and";
    #$log->errorf("TMP: joining ccl %s", $ccls);
    #warn "join_ccls"; #TMP

    my ($min_ok, $max_ok, $min_nok, $max_nok);
    if ($op eq 'and') {
        $max_nok = 0;
    } elsif ($op eq 'or') {
        $min_ok = 1;
    } elsif ($op eq 'none') {
        $max_ok = 0;
    } elsif ($op eq 'not') {

    }
    my $dmin_ok  = defined($min_ok);
    my $dmax_ok  = defined($max_ok);
    my $dmin_nok = defined($min_nok);
    my $dmax_nok = defined($max_nok);

    return "" unless @$ccls;

    my $rt      = $cd->{args}{return_type};
    my $vp      = $cd->{args}{var_prefix};

    my $aop = $self->logical_and_op;
    my $nop = $self->logical_not_op;

    my $true = $self->true;

    # insert comment, error message, and $ok/$nok counting. $which is 0 by
    # default (normal), or 1 (reverse logic, for 'not' or 'none'), or 2 (for
    # $ok/$nok counting), or 3 (like 2, but for the last clause).
    my $_ice = sub {
        my ($ccl, $which) = @_;

        return $self->enclose_paren($ccl->{ccl}) if $ccl->{assert};

        my $res = "";

        if ($ccl->{_debug_ccl_note}) {
            if ($cd->{args}{debug_log} // $cd->{args}{debug}) {
                $res .= $self->expr_log(
                    $cd, $self->literal($ccl->{_debug_ccl_note})) . " $aop\n";
            } else {
                $res .= $self->comment($cd, $ccl->{_debug_ccl_note});
            }
        }

        $which //= 0;
        # clause code
        my $cc = ($which == 1 ? $nop:"") . $self->enclose_paren($ccl->{ccl});
        my ($ec, $oec);
        my ($ret, $oret);
        if ($which >= 2) {
            my @chk;
            if ($ccl->{err_level} eq 'warn') {
                $oret = 1;
                $ret  = 1;
            } elsif ($ccl->{err_level} eq 'fatal') {
                $oret = 1;
                $ret  = 0;
            } else {
                $oret = $self->expr_preinc_var("${vp}ok");
                $ret  = $self->expr_preinc_var("${vp}nok");
                push @chk, $self->expr_var("${vp}ok"). " <= $max_ok"
                    if $dmax_ok;
                push @chk, $self->expr_var("${vp}nok")." <= $max_nok"
                    if $dmax_nok;
                if ($which == 3) {
                    push @chk, $self->expr_var("${vp}ok"). " >= $min_ok"
                        if $dmin_ok;
                    push @chk, $self->expr_var("${vp}nok")." >= $min_nok"
                        if $dmin_nok;

                    # we need to clear the error message previously set
                    if ($rt !~ /\Abool/) {
                        my $et = $cd->{args}{err_term};
                        my $clerrc;
                        if ($rt eq 'full') {
                            $clerrc = $self->expr_reset_err_full($et);
                        } else {
                            $clerrc = $self->expr_reset_err_str($et);
                        }
                        push @chk, $clerrc;
                    }
                }
            }
            $res .= "($cc ? $oret : $ret)";
            $res .= " $aop " . join(" $aop ", @chk) if @chk;
        } else {
            $ec = $ccl->{err_code};
            $ret =
                $ccl->{err_level} eq 'fatal' ? 0 :
                    # this must not be done because it messes up ok/nok counting
                    #$rt eq 'full' ? 1 :
                        $ccl->{err_level} eq 'warn' ? 1 : 0;
            if ($rt =~ /\Abool/ && $ret) {
                $res .= $true;
            } elsif ($rt =~ /\Abool/ || !$ec) {
                $res .= $self->enclose_paren($cc);
            } else {
                $res .= $self->enclose_paren(
                    $self->enclose_paren($cc). " ? $true : ($ec,$ret)",
                    "force");
            }
        }

        # insert dpath handling
        $res = $self->expr_push_and_pop_dpath_between_expr($res)
            if $cd->{use_dpath} && $ccl->{subdata};
        $res;

    };

    my $j = "\n\n$aop\n\n";
    if ($op eq 'not') {
        return $_ice->($ccls->[0], 1);
    } elsif ($op eq 'and') {
        return join $j, map { $_ice->($_) } @$ccls;
    } elsif ($op eq 'none') {
        return join $j, map { $_ice->($_, 1) } @$ccls;
    } else {
        my $jccl = join $j, map {$_ice->($ccls->[$_], $_ == @$ccls-1 ? 3:2)}
            0..@$ccls-1;
        {
            local $cd->{ccls} = [];
            local $cd->{_debug_ccl_note} = "op=$op";
            $self->add_ccl(
                $cd,
                $self->expr_block(
                    join(
                        "",
                        $self->stmt_declare_local_var("${vp}ok" , "0"), "\n",
                        $self->stmt_declare_local_var("${vp}nok", "0"), "\n",
                        "\n",
                        $self->block_uses_sub ?
                            $self->stmt_return($jccl) : $jccl,
                    )
                ),
            );
            $_ice->($cd->{ccls}[0]);
        }
    }
}

sub before_compile {
    my ($self, $cd) = @_;

    if ($cd->{args}{data_term_is_lvalue}) {
        $cd->{data_term} = $cd->{args}{data_term};
    } else {
        my $v = $cd->{args}{var_prefix} . $cd->{args}{data_name};
        push @{ $cd->{vars} }, $v; # XXX unless already there
        $cd->{data_term} = $self->var_sigil . $v;
        die "BUG: support for non-perl compiler not yet added here"
            unless $cd->{compiler_name} eq 'perl';
        push @{ $cd->{ccls} }, ["(local($cd->{data_term} = $cd->{args}{data_term}), 1)"];
    }
}

sub before_handle_type {
    my ($self, $cd) = @_;

    # do a human compilation first to collect all the error messages

    unless ($cd->{is_inner}) {
        my $hc = $cd->{_hc};
        my %hargs = %{$cd->{args}};
        $hargs{format}               = 'msg_catalog';
        $hargs{schema_is_normalized} = 1;
        $hargs{schema}               = $cd->{nschema};
        $hargs{on_unhandled_clause}  = 'ignore';
        $hargs{on_unhandled_attr}    = 'ignore';
        $hargs{hash_values}          = $cd->{args}{human_hash_values};
        $cd->{_hcd} = $hc->compile(%hargs);
    }
}

sub before_all_clauses {
    my ($self, $cd) = @_;

    my $rt = $cd->{args}{return_type};
    my $rt_is_full = $rt =~ /\Afull/;
    my $rt_is_str  = $rt =~ /\Astr/;

    $cd->{use_dpath} //= (
        $rt_is_full ||
        ($rt_is_str && $cd->{has_subschema})
    );

    # handle ok/default/coercion/prefilters/req/forbidden clauses and type check

    my $c      = $cd->{compiler};
    my $cname  = $c->name;
    my $dt     = $cd->{data_term};
    my $et     = $cd->{args}{err_term};
    my $clsets = $cd->{clsets};

    # handle ok, this is very high priority because !ok=>1 should fail undef
    # too. we need to handle its .op=not here.
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        next unless exists $clset->{ok};
        my $op = $clset->{"ok.op"} // "";
        if ($op && $op ne 'not') {
            $self->_die($cd, "ok can only be combined with .op=not");
        }
        if ($op eq 'not') {
            local $cd->{_debug_ccl_note} = "!ok #$i";
            $self->add_ccl($cd, $self->false);
        } else {
            local $cd->{_debug_ccl_note} = "ok #$i";
            $self->add_ccl($cd, $self->true);
        }
        delete $cd->{uclsets}[$i]{"ok"};
        delete $cd->{uclsets}[$i]{"ok.is_expr"};
    }

    # handle default
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        my $def    = $clset->{default};
        my $defie  = $clset->{"default.is_expr"};
        if (defined $def) {
            local $cd->{_debug_ccl_note} = "default #$i";
            my $ct = $defie ?
                $self->expr($def) : $self->literal($def);
            $self->add_ccl(
                $cd,
                $self->expr_list(
                    $self->expr_setif($dt, $ct),
                    $self->true,
                ),
                {err_msg => ""},
            );
        }
        delete $cd->{uclsets}[$i]{"default"};
        delete $cd->{uclsets}[$i]{"default.is_expr"};
    }

    # handle req
    my $has_req;
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        my $req    = $clset->{req};
        my $reqie  = $clset->{"req.is_expr"};
        my $req_err_msg = $self->_xlt($cd, "Required but not specified");
        local $cd->{_debug_ccl_note} = "req #$i";
        if ($req && !$reqie) {
            $has_req++;
            $self->add_ccl(
                $cd, $self->expr_defined($dt),
                {
                    err_msg   => $req_err_msg,
                    err_level => 'fatal',
                },
            );
        } elsif ($reqie) {
            $has_req++;
            my $ct = $self->expr($req);
            $self->add_ccl(
                $cd, "!($ct) || ".$self->expr_defined($dt),
                {
                    err_msg   => $req_err_msg,
                    err_level => 'fatal',
                },
            );
        }
        delete $cd->{uclsets}[$i]{"req"};
        delete $cd->{uclsets}[$i]{"req.is_expr"};
    }

    # handle forbidden
    my $has_fbd;
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        my $fbd    = $clset->{forbidden};
        my $fbdie  = $clset->{"forbidden.is_expr"};
        my $fbd_err_msg = $self->_xlt($cd, "Forbidden but specified");
        local $cd->{_debug_ccl_note} = "forbidden #$i";
        if ($fbd && !$fbdie) {
            $has_fbd++;
            $self->add_ccl(
                $cd, "!".$self->expr_defined($dt),
                {
                    err_msg   => $fbd_err_msg,
                    err_level => 'fatal',
                },
            );
        } elsif ($fbdie) {
            $has_fbd++;
            my $ct = $self->expr($fbd);
            $self->add_ccl(
                $cd, "!($ct) || !".$self->expr_defined($dt),
                {
                    err_msg   => $fbd_err_msg,
                    err_level => 'fatal',
                },
            );
        }
        delete $cd->{uclsets}[$i]{"forbidden"};
        delete $cd->{uclsets}[$i]{"forbidden.is_expr"};
    }

    if (!$has_req && !$has_fbd) {
        $cd->{_skip_undef} = 1;
        $cd->{_ccls_idx1} = @{$cd->{ccls}};
    }

    my $coerce_expr;
    my $coerce_might_fail;
    my $coerce_ccl_note;
  GEN_COERCE_EXPR:
    {
        last unless $cd->{args}{coerce};

        require Data::Sah::CoerceCommon;

        my @coerce_rules;
        for my $i (0..@$clsets-1) {
            my $clset = $clsets->[$i];
            push @coerce_rules,
                @{ $clset->{"x.$cname.coerce_rules"} // [] },
                @{ $clset->{'x.coerce_rules'} // [] };
        }

        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler => $self->name,
            type => $cd->{type},
            data_term => $dt,
            coerce_to => $cd->{coerce_to},
            coerce_rules => \@coerce_rules,
        );
        last unless @$rules;

        $coerce_might_fail = 1 if grep { $_->{meta}{might_fail} } @$rules;

        my $prev_term;
        for my $i (reverse 0..$#{$rules}) {
            my $rule = $rules->[$i];

            $self->add_compile_module(
                $cd, "Data::Sah::Coerce::$cname\::$cd->{type}::$rule->{name}",
                {category => 'coerce'},
            );

            if ($rule->{modules}) {
                for my $mod (keys %{ $rule->{modules} }) {
                    my $modspec = $rule->{modules}{$mod};
                    $modspec = {version=>$modspec} unless ref $modspec eq 'HASH';
                    $self->add_runtime_module($cd, $mod, {category=>'coerce', %$modspec});
                }
            }

            if ($i == $#{$rules}) {
                if ($coerce_might_fail) {
                    $prev_term = $self->expr_array($self->literal(undef), $dt);
                } else {
                    $prev_term = $dt;
                }
            } else {
                $prev_term = "($coerce_expr)";
            }

            my $ec;
            if ($coerce_might_fail && !$rule->{meta}{might_fail}) {
                $ec = $self->expr_array($self->literal(undef), $rule->{expr_coerce});
            } else {
                $ec = "($rule->{expr_coerce})";
            }

            $coerce_expr = $self->expr_ternary(
                "($rule->{expr_match})",
                $ec,
                $prev_term,
            );
        }
        $coerce_ccl_note = "coerce rule(s): ".
            join(", ", map {$_->{name}} @$rules) .
            ($cd->{coerce_to} ? " # coerce to: $cd->{coerce_to}" : "");
    } # GEN_COERCE_EXPR

  HANDLE_TYPE_CHECK:
    {
        $self->_die($cd, "BUG: type handler did not produce _ccl_check_type")
            unless defined($cd->{_ccl_check_type});
        local $cd->{_debug_ccl_note};

        # XXX handle prefilters

        # handle coercion
        if ($coerce_expr) {
            $cd->{_debug_ccl_note} = $coerce_ccl_note;
            if ($coerce_might_fail) {
                # XXX rather hackish: to avoid adding another temporary
                # variable, we reuse data term to hold coercion result (which
                # contains error message string as well coerced data) then set
                # the data term to the coerced data again. this might fail in
                # languages or setting that is stricter (e.g. data term must be
                # of certain type).

                my $expr_fail;
                if ($rt_is_full) {
                    $expr_fail = $self->expr_list(
                        $self->expr_set_err_full($et, 'errors', $self->expr_array_subscript($dt, 0)),
                        $self->expr_set($dt, $self->literal(undef)),
                        $self->false,
                    );
                } elsif ($rt_is_str) {
                    $expr_fail = $self->expr_list(
                        $self->expr_set_err_str($et, $self->expr_array_subscript($dt, 0)),
                        $self->false,
                    );
                } else {
                    $expr_fail = $self->false;
                }

                $self->add_ccl(
                    $cd,
                    $self->expr_list(
                        $self->expr_set($dt, $coerce_expr),
                        $self->expr_ternary(
                            $self->expr_defined($self->expr_array_subscript($dt, 0)),
                            $expr_fail,
                            $self->expr_list(
                                $self->expr_set($dt, $self->expr_array_subscript($dt, 1)),
                                $self->true,
                            )
                        ),
                    ),
                    {
                        err_msg => "",
                        err_level => "fatal",
                    },
                );
            } else {
                $self->add_ccl(
                    $cd,
                    $self->expr_list(
                        $self->expr_set($dt, $coerce_expr),
                        $self->true,
                    ),
                    {
                        err_msg => "",
                        err_level => "fatal",
                    },
                );
            }
        }

        $cd->{_debug_ccl_note} = "check type '$cd->{type}'";
        $self->add_ccl(
            $cd, $cd->{_ccl_check_type},
            {
                err_msg   => sprintf(
                    $self->_xlt($cd, "Not of type %s"),
                    $self->_xlt(
                        $cd,
                        $cd->{_hc}->get_th(name=>$cd->{type})->name //
                            $cd->{type}
                        ),
                ),
                err_level => 'fatal',
            },
        );
    }
}

sub before_clause {
    my ($self, $cd) = @_;

    $self->_die($cd, "Sorry, .op + .is_expr not yet supported ".
                    "(found in clause $cd->{clause})")
        if $cd->{cl_is_expr} && $cd->{cl_op};

    if ($cd->{args}{debug}) {
        state $json = do {
            require JSON;
            JSON->new->allow_nonref;
        };
        my $clset = $cd->{clset};
        my $cl    = $cd->{clause};
        my $res   = $json->encode({
            map { $_ => $clset->{$_}}
                grep {/\A\Q$cl\E(?:\.|\z)/}
                    keys %$clset });
        $res =~ s/\n+/ /g;
        # a one-line dump of the clause, suitable for putting in generated
        # code's comment
        $cd->{_debug_ccl_note} = "clause: $res";
    } else {
        $cd->{_debug_ccl_note} = "clause: $cd->{clause}";
    }

    # we save ccls to save_ccls and empty ccls for each clause, to let clause
    # join and do stuffs to ccls. at after_clause(), we push the clause's result
    # as a single ccl to the original ccls.

    push @{ $cd->{_save_ccls} }, $cd->{ccls};
    $cd->{ccls} = [];
}

sub after_clause {
    my ($self, $cd) = @_;

    if ($cd->{args}{debug}) {
        delete $cd->{_debug_ccl_note};
    }

    my $save = pop @{ $cd->{_save_ccls} };
    if (@{ $cd->{ccls} }) {
        push @$save, {
            ccl       => $self->join_ccls($cd, $cd->{ccls}, {op=>$cd->{cl_op}}),
            err_level => $cd->{clset}{"$cd->{clause}.err_level"} // "error",
        }
    }
    $cd->{ccls} = $save;
}

sub after_clause_sets {
    my ($self, $cd) = @_;

    # simply join them together with &&
    $cd->{result} = $self->indent(
        $cd,
        $self->join_ccls($cd, $cd->{ccls}, {err_msg => ''}),
    );
}

sub after_all_clauses {
    my ($self, $cd) = @_;

    # XXX also handle postfilters here

    if (delete $cd->{_skip_undef}) {
        my $jccl = $self->join_ccls(
            $cd,
            [splice(@{ $cd->{ccls} }, $cd->{_ccls_idx1})],
        );
        local $cd->{_debug_ccl_note} = "skip if undef";
        $self->add_ccl(
            $cd,
            "!".$self->expr_defined($cd->{data_term})." ? ".$self->true." : \n\n".
                $self->enclose_paren($jccl),
            {err_msg => ''},
        );
    }

    # simply join them together with &&
    $cd->{result} = $self->indent(
        $cd,
        $self->join_ccls($cd, $cd->{ccls}, {err_msg => ''}),
    );
}

1;
# ABSTRACT: Base class for programming language compilers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::Prog - Base class for programming language compilers

=head1 VERSION

This document describes version 0.897 of Data::Sah::Compiler::Prog (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is derived from L<Data::Sah::Compiler>. It is used as base class for
compilers which compile schemas into code (validator) in several programming
languages, Perl (L<Data::Sah::Compiler::perl>) and JavaScript
(L<Data::Sah::Compiler::js>) being two of them. (Other similar programming
languages like PHP and Ruby might also be supported later on if needed).

Compilers using this base class are flexible in the kind of code they produce:

=over 4

=item * configurable validator return type

Can generate validator that returns a simple bool result, str, or full data
structure (containing errors, warnings, and potentially other information).

=item * configurable data term

For flexibility in combining the validator code with other code, e.g. putting
inside subroutine wrapper (see L<Perinci::Sub::Wrapper>) or directly embedded to
your source code (see L<Dist::Zilla::Plugin::Rinci::Validate>).

=back

=for Pod::Coverage ^(after_.+|before_.+|add_var|add_ccl|join_ccls|check_compile_args|enclose_paren|init_cd|expr|expr_.+|stmt_.+)$

=head1 HOW IT WORKS

The compiler generates code in the following form:

 EXPR && EXPR2 && ...

where C<EXPR> can be a single expression or multiple expressions joined by the
list operator (which Perl and JavaScript support). Each C<EXPR> is typically
generated out of a single schema clause. Some pseudo-example of generated
JavaScript code:

 (data >= 0)  # from clause: min => 0
 &&
 (data <= 10) # from clause: max => 10

Another example, a fuller translation of schema C<< [int => {min=>0, max=>10}]
>> to Perl, returning string result (error message) instead of boolean:

 # from clause: req => 0
 !defined($data) ? 1 : (

     # type check
     ($data =~ /^[+-]?\d+$/ ? 1 : ($err //= "Data is not an integer", 0))

     &&

     # from clause: min => 0
     ($data >=  0 ? 1 : ($err //= "Must be at least 0", 0))

     &&

     # from clause: max => 10
     ($data <= 10 ? 1 : ($err //= "Must be at most 10", 0))

 )

The final validator code will add enclosing subroutine and variable declaration,
loading of modules, etc.

Note: Current assumptions/hard-coded things for the supported languages: ternary
operator (C<? :>), semicolon as statement separator.

=head1 COMPILATION DATA KEYS

=over

=item * use_dpath => bool

Convenience. This is set when code needs to track data path, which is when
C<return_type> argument is set to something other than C<bool> or C<bool+val>,
and when schema has subschemas. Data path is used when generating error message
string, to help point to the item in the data structure (an array element, a
hash value) which fails the validation. This is not needed when we want the
validator to only return true/false, and also not needed when we do not recurse
into subschemas.

=item * data_term => ARRAY

Input data term. Set to C<< $cd->{args}{data_term} >> or a temporary variable
(if C<< $cd->{args}{data_term_is_lvalue} >> is false). Hooks should use this
instead of C<< $cd->{args}{data_term} >> directly, because aside from the
aforementioned temporary variable, data term can also change, for example if
C<default.temp> or C<prefilters.temp> attribute is set, where generated code
will operate on another temporary variable to avoid modifying the original data.
Or when C<.input> attribute is set, where generated code will operate on
variable other than data.

=item * subs => ARRAY

Contains pairs of subroutine names and definition code string, e.g. C<< [
[_sahs_zero => 'sub _sahs_zero { $_[0] == 0 }'], [_sahs_nonzero => 'sub
_sah_s_nonzero { $_[0] != 0 }'] ] >>. For flexibility, you'll need to do this
bit of arranging yourself to get the final usable code you can compile in your
chosen programming language.

=item * vars => HASH

=item * coerce_to => str

Retrieved from the schema's C<x.$COMPILER.coerce_to> attribute. Each type
handler might have its own default value.

=back

=head1 INTERNAL VARIABLES IN THE GENERATED CODE

The generated code maintains the following variables. C<_sahv_> prefix stands
for "Sah validator", it is used to minimize clash with data_term.

=over

=item * _sahv_dpath => ARRAY

Analogous to C<spath> in compilation data, this variable stands for "data path"
and is used to track location within data. If a clause is checking each element
of an array (like the 'each_elem' or 'elems' array clause), this variable will
be adjusted accordingly. Error messages thus can be more informative by pointing
more exactly where in the data the problem lies.

=item * tmp_data_term => ANY

As explained in the C<compile()> method, this is used to store temporary value
when checking against clauses.

=item * _sahv_stack => ARRAY

This variable is used to store validation result of subdata. It is only used if
the validator is returning a string or full structure, not a single boolean
value. See C<Data::Sah::Compiler::js::TH::hash> for an example.

=item * _sahv_x

Usually used as temporary variable in short, anonymous functions.

=back

=head1 ATTRIBUTES

These usually need not be set/changed by users.

=head2 hc => OBJ

Instance of L<Data::Sah::Compiler::human>, to generate error messages.

=head2 comment_style => STR

Specify how comments are written in the target language. Either 'cpp' (C<//
comment>), 'shell' (C<# comment>), 'c' (C</* comment */>), or 'ini' (C<;
comment>). Each programming language subclass will set this, for example, the
perl compiler sets this to 'shell' while js sets this to 'cpp'.

=head2 var_sigil => STR

=head2 concat_op => STR

=head2 logical_and_op => STR

=head2 logical_not_op => STR

=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from base class' arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over

=item * data_term => STR

A variable name or an expression in the target language that contains the data,
defaults to I<var_sigil> + C<name> if not specified.

=item * data_term_is_lvalue => BOOL (default: 1)

Whether C<data_term> can be assigned to.

=item * tmp_data_name => STR

Normally need not be set manually, as it will be set to "tmp_" . data_name. Used
to store temporary data during clause evaluation.

=item * tmp_data_term => STR

Normally need not be set manually, as it will be set to var_sigil .
tmp_data_name. Used to store temporary data during clause evaluation. For
example, in JavaScript, the 'int' and 'float' type pass strings in the type
check. But for further checking with the clauses (like 'min', 'max',
'divisible_by') the string data needs to be converted to number first. Likewise
with prefiltering. This variable holds the temporary value. The clauses compare
against this value. At the end of clauses, the original data_term is restored.
So the output validator code for schema C<< [int => min => 1] >> will look
something like:

 // type check 'int'
 type(data)=='number' && Math.round(data)==data || parseInt(data)==data)

 &&

 // convert to number
 (tmp_data = type(data)=='number' ? data : parseFloat(data), true)

 &&

 // check clause 'min'
 (tmp_data >= 1)

=item * err_term => STR

A variable name or lvalue expression to store error message(s), defaults to
I<var_sigil> + C<err_NAME> (e.g. C<$err_data> in the Perl compiler).

=item * var_prefix => STR (default: _sahv_)

Prefix for variables declared by generated code.

=item * sub_prefix => STR (default: _sahs_)

Prefix for subroutines declared by generated code.

=item * code_type => STR (default: validator)

The kind of code to generate. For now the only valid (and default) value is
'validator'. Compiler can perhaps generate other kinds of code in the future.

=item * return_type => STR (default: bool)

Specify what kind of return value the generated code should produce. Either
C<bool>, C<bool+val>, C<str>, C<str+val>, or C<full>.

C<bool> means generated validator code should just return true/false depending
on whether validation succeeds/fails.

C<bool+val> is like C<bool>, but instead of just C<bool> the validator code will
return a two-element arrayref C<< [bool, val] >> where C<val> is the final value
of data (after setting of default, coercion, etc.)

C<str> means validation should return an error message string (the first one
encountered) if validation fails and an empty string/undef if validation
succeeds.

C<str+val> is like C<str>, but instead of just C<str> the validator code will
return a two-element arrayref C<< [str, val] >> where C<val> is the final value
of data (after setting of default, coercion, etc.)

C<full> means validation should return a full data structure. From this
structure you can check whether validation succeeds, retrieve all the collected
errors/warnings, etc.

=item * coerce => bool (default: 1)

If set to false, will not include coercion code.

=item * debug => BOOL (default: 0)

This is a general debugging option which should turn on all debugging-related
options, e.g. produce more comments in the generated code, etc. Each compiler
might have more specific debugging options.

If turned on, specific debugging options can be explicitly turned off
afterwards, e.g. C<< debug=>1, debug_log=>0 >> will turn on all debugging
options but turn off the C<debug_log> setting.

Currently turning on C<debug> means:

=over

=item - Turning on the other debug_* options, like debug_log

=item - Prefixing error message with msgpath

=back

=item * debug_log => BOOL (default: 0)

Whether to add logging to generated code. This aids in debugging generated code
specially for more complex validation.

=item * comment => BOOL (default: 1)

If set to false, generated code will be devoid of comments.

=item * human_hash_values => hash

Optional. Will be passed to C<hash_values> argument during C<compile()> by human
compiler.

=back

=head2 $c->comment($cd, @args) => STR

Generate a comment. For example, in perl compiler:

 $c->comment($cd, "123"); # -> "# 123\n"

Will return an empty string if compile argument C<comment> is set to false.

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
