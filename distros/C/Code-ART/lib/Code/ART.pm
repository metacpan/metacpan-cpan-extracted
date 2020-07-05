package Code::ART;

use 5.016;
use warnings;
use Carp;
use Scalar::Util 'looks_like_number';
use List::Util   qw< min max uniq>;
use version;

our $VERSION = '0.000005';

# Default naming scheme for refactoring...
my $DEFAULT_SUB_NAME          = '__REFACTORED_SUB__';
my $DEFAULT_LEXICAL_NAME      = '__HOISTED_LEXICAL__';
my $DEFAULT_DATA_PARAM        = '@__EXTRA_DATA__';
my $DEFAULT_AUTO_RETURN_VALUE = '@__RETURN_VALUE__';

# These are the permitted options for refactor_to_sub()...
my %VALID_REFACTOR_OPTION = ( name=>1, from=>1, to=>1, data=>1, return=>1 );

# These are the permitted options for hoist_to_lexical()...
my %VALID_HOIST_OPTION    = ( name=>1, from=>1, to=>1, closure=>1, all=>1 );

# Load the module...
sub import {
    my $package = shift;
    my $opt_ref = shift // {};

    croak("Options argument to 'use $package' must be a hash reference")
        if ref($opt_ref) ne 'HASH';

#    # Remember lexically scoped options...
#    for my $optname (keys %{$opt_ref}) {
#        croak "Unknown option ('$optname') passed to 'use $package'"
#            if !$VALID_REFACTOR_OPTION{$optname} && !$VALID_HOIST_OPTION{$optname};
#        $^H{"Code::ART $optname"} = $opt_ref->{$optname};
#    }

    # Export the API...
    no strict 'refs';
    *{caller().'::refactor_to_sub'}         = \&refactor_to_sub;
    *{caller().'::rename_variable'}         = \&rename_variable;
    *{caller().'::classify_all_vars_in'}    = \&classify_all_vars_in;
    *{caller().'::hoist_to_lexical'}        = \&hoist_to_lexical;
}


# This regex recognizes variables that don't need to be passed in
# even if they're not locally declared...
my $PERL_SPECIAL_VAR = qr{
    \A
    [\$\@%]
    (?:
        [][\d\{!"#\$%&'()*+,./:;<=>?\@\^`|~_-]
    |
        \^ .*
    |
        \{\^ .*
    |
        ACCUMULATOR | ARG | ARGV | ARRAY_BASE | AUTOLOAD | BASETIME | CHILD_ERROR |
        COMPILING | DEBUGGING | EFFECTIVE_GROUP_ID | EFFECTIVE_USER_ID | EGID | ENV |
        ERRNO | EUID | EVAL_ERROR | EXCEPTIONS_BEING_CAUGHT | EXECUTABLE_NAME |
        EXTENDED_OS_ERROR | F | FORMAT_FORMFEED | FORMAT_LINES_LEFT | FORMAT_LINES_PER_PAGE |
        FORMAT_LINE_BREAK_CHARACTERS | FORMAT_NAME | FORMAT_PAGE_NUMBER | FORMAT_TOP_NAME |
        GID | INC | INPLACE_EDIT | INPUT_LINE_NUMBER | INPUT_RECORD_SEPARATOR |
        LAST_MATCH_END | LAST_MATCH_START | LAST_PAREN_MATCH | LAST_REGEXP_CODE_RESULT |
        LAST_SUBMATCH_RESULT | LIST_SEPARATOR | MATCH | NR | OFMT | OFS | OLD_PERL_VERSION |
        ORS | OSNAME | OS_ERROR | OUTPUT_AUTOFLUSH | OUTPUT_FIELD_SEPARATOR |
        OUTPUT_RECORD_SEPARATOR | PERLDB | PERL_VERSION | PID | POSTMATCH | PREMATCH |
        PROCESS_ID | PROGRAM_NAME | REAL_GROUP_ID | REAL_USER_ID | RS | SIG | SUBSCRIPT_SEPARATOR |
        SUBSEP | SYSTEM_FD_MAX | UID | WARNING | a | b
    )
    \Z
}x;

# What a simple variable looks like...
my $SIMPLE_VAR = qr{ \A [\$\@%] [^\W\d] \w* \Z }xms;

# What whitespace look like...
my $OWS = qr{ (?: \s++ | \# [^\n]*+ (?> \n | \Z ))*+ }xms;

# This is where the magic happens: parse the code and extract the undeclared variables...
use PPR::X;
use re 'eval';

# Refactor the code into a subroutine...
sub refactor_to_sub {
    # Unpack args...
    my ($opt_ref) = grep { ref($_) eq 'HASH' } @_, {};
    my ($code, @extras) = grep { !ref($_) } @_;

    # Check raw arguments...
    croak( "'code' argument of refactor_to_sub() must be a string" ) if !defined($code) || ref($code);
    croak( "Unexpected extra argument passed to refactor_to_sub(): '$_'" ) for @extras;
    croak( "'options' argument of refactor_to_sub() must be hash ref, not ", lc(ref($_)), " ref" )
        for grep { ref($_) && ref($_) ne 'HASH' } @_;

    # Apply defaults...
    my $from       = $opt_ref->{from}   // 0;
    my $to         = $opt_ref->{to}     // length($code // q{}) - 1;
    my $subname    = $opt_ref->{name}   // $DEFAULT_SUB_NAME;
    my $data       = $opt_ref->{data}   // $DEFAULT_DATA_PARAM;
       $data =~ s{\A\s*(\w)}{\@$1}xms;
    my $return_expr = $opt_ref->{return};

    # Check processed arguments...
    croak( "Unknown option ('$_') passed to refactor_to_sub()" )
        for grep { !$VALID_REFACTOR_OPTION{$_} } keys %{$opt_ref};
    croak( "'from' option of refactor_to_sub() must be a number" )
        if !looks_like_number($opt_ref->{from});
    croak( "'to' option of refactor_to_sub() must be a number" )
        if !looks_like_number($opt_ref->{to});

    # Extract target code being factored out...
    my $target_code = substr($code, $from, $to-$from+1);

    # Extract any trailing semicolon or comma that may need to be preserved...
    $target_code =~ m{  (?<ows> $OWS )
                        (?<punctuation>
                            (?>  (?<semicolon>   ; )
                            |    (?<comma>      , | => | )
                            )
                       )
                       $OWS \Z
                     }xmso;
    my %trailing = %+;
    $trailing{punctuation} = ($trailing{ows} =~ s/\S/ /gr) . $trailing{punctuation};

    # Check if the end of the target code is the end of the file...
    my $final_semicolon = substr($code, $to) =~ m{ $OWS \S }xmso ? q{} : q{;};

    # Ensure that the code is refactorable...
    local %Code::ART::retloc = ();
    local $Code::ART::insub; $Code::ART::insub = 0;
    my $statement_sequence = qr{
        (?>(?&PerlEntireDocument))

        (?(DEFINE)
            (?<PerlSubroutineDeclaration>
                (?{ $Code::ART::insub++ })
                (?>(?&PerlStdSubroutineDeclaration))
                (?{ $Code::ART::insub-- })
            |
                (?{ $Code::ART::insub-- })
                (?!)
            )

            (?<PerlAnonymousSubroutine>
                (?{ $Code::ART::insub++ })
                (?>(?&PerlStdAnonymousSubroutine))
                (?{ $Code::ART::insub-- })
            |
                (?{ $Code::ART::insub-- })
                (?!)
            )

            (?<PerlReturnExpression>
                (?{ pos() })
                (?&PerlStdReturnExpression)
                (?= (?&PerlOWS) ;? (?&PerlOWS)
                (?{ $Code::ART::retloc{pos()} = $^R if !$Code::ART::insub; }) )
            )
        )

        $PPR::X::GRAMMAR
    }xmso;

    my $test_code = $target_code =~ m{\A (?&PerlOWS) (?&PerlAssignmentOperator) $PPR::X::GRAMMAR }xmso
                        ? '()' . $target_code
                        : $target_code;
    if ($test_code !~ $statement_sequence) {
        return { failed => 'not a valid series of statements',
                 context => $PPR::X::ERROR,
                 args => []
               }
    }

    my $final_return = exists $Code::ART::retloc{length($target_code)};
    my $interim_return = keys %Code::ART::retloc > $final_return;
    if ($interim_return && !$final_return) {
        return { failed => 'the code has an internal return statement',
                 context => $PPR::X::ERROR,
                 args => []
               }
    }

    # Find all variables and scopes in the code (if possible)...
    my $vardata = classify_all_vars_in($code);
    return { %{$vardata}, args => [] } if $vardata->{failed};

    # Extract relevant variables...
    my (@in_vars, @out_vars, @lex_vars);
    for my $decl (sort {$a<=>$b} grep { $_ >= 0 } keys %{$vardata->{vars}}) {
        # No need to consider variables declared after the target...
        last if $decl > $to;

        # Was the variable declared before the target, and used inside it???
        my $used = $vardata->{vars}{$decl}{used_at};
        if ($decl < $from) {
            my @usages = grep { $from <= $_ && $_ <= $to } keys %{$used}
                or next;
            push @in_vars, { %{$vardata->{vars}{$decl}}, used_at => \@usages };
        }

        # Was the variable declared within the target, and used after it???
        else {
            my @usages = grep { $_ <= $to } keys %{$used};
            if (grep { $_ > $to } keys %{$used}) {
                push @out_vars, { %{$vardata->{vars}{$decl}}, used_at => \@usages };
            }
            else {
                push @lex_vars, { %{$vardata->{vars}{$decl}}, used_at => \@usages };
            }
        }
    }

    # Determine minimal version of Perl 5 being used...
    my $use_version = $vardata->{use_version};

    # Convert target code to an independent refactorable equivalent...
    my %convert_opts
        = (from=>$from, to=>$to, in_vars=>\@in_vars, out_vars=>\@out_vars, lex_vars =>\@lex_vars);
    my ($arg_code, $param_code, $refactored_code, $return_candidates)
        = _convert_target_code($target_code, \%convert_opts);

    # Extract any leading whitespace or assignment to be preserved...
    $refactored_code =~ s{ \A (?<leading_ws> (?>(?&PerlOWS)) )
                              (?>
                                    (?<leading_assignment>
                                        (?>(?&PerlAssignmentOperator)) (?>(?&PerlOWS))
                                    )
                                    (?<leading_assignment_expr>
                                        (?>(?&PerlConditionalExpression))
                                    )
                              )?+
                              (?= (?<single_expr> (?>(?&PerlOWS)) ;?+ (?>(?&PerlOWS)) \z | ) )
                              $PPR::X::GRAMMAR
                         }{ ' ' x length($&) }exmso;

    my ($leading_ws, $leading_assignment, $leading_assignment_expr, $single_expr)
        = @+{qw< leading_ws leading_assignment leading_assignment_expr single_expr>};
    $leading_ws         //= q{};
    $leading_assignment //= q{};

    # Insert code to handle trailing arguments (if any)...
    if ($trailing{comma} || !$trailing{semicolon} ) {
        $param_code .= "," if $param_code =~ /\S/;
        $param_code .= " $data";
        $refactored_code =~ s{\s* \Z}{ $data;\n}xms;
    }

    # Reinstate leading assignment (if any) and install return value (if any)...
    if ($leading_assignment) {
        if ($final_return) {
            return { failed => "code has both a leading assignment and an explicit return",
                     args   => [],
                   };
        }
        if ($single_expr) {
            $refactored_code = $leading_ws . $leading_assignment_expr;
        }
        else {
            $refactored_code =~ s{\A \s*}
                                {    my $DEFAULT_AUTO_RETURN_VALUE = wantarray ? ($leading_assignment_expr) : scalar($leading_assignment_expr)}xms;
            $refactored_code =~ s{\s* \Z}
                                {\n   ;\n    return wantarray ? $DEFAULT_AUTO_RETURN_VALUE : shift $DEFAULT_AUTO_RETURN_VALUE;\n}xms;
        }
    }
    elsif (defined $return_expr) {
        my %refactored_name = map { $_->{decl_name} => $_->{new_name} } @in_vars, @out_vars;
        $return_expr
            =~ s{ (?<array> \$\#   (?&PerlOWS)  \K (?<varname> \w++ )
                          | \@     (?&PerlOWS)  \K (?<varname> \w++ )  (?! (?&PerlOWS) \{ )
                          | [\$%]  (?&PerlOWS)  \K (?<varname> \w++ )  (?= (?&PerlOWS) \[ )
                  )
                  |
                  (?<hash>
                            \%     (?&PerlOWS)  \K (?<varname> \w++ )  (?! (?&PerlOWS) \[ )
                          | [\$\@] (?&PerlOWS)  \K (?<varname> \w++ )  (?= (?&PerlOWS) \{ )
                  )
                  |
                  (?<scalar> \$    (?&PerlOWS)  \K (?<varname> \w++ ) (?! (?&PerlOWS) [\{\[] ) )
                  $PPR::X::GRAMMAR
                }
                { my $new_name = $+{array} ? $refactored_name{"\@$+{varname}"}
                               : $+{hash}  ? $refactored_name{ "%$+{varname}"}
                               :             $refactored_name{"\$$+{varname}"};
                  defined($new_name) ? "{$new_name}" : $+{varname};
                }gexmso;
        $refactored_code =~ s{\s* \Z}{\n    ;\n    return $return_expr\n}xms;
    }
    elsif ($final_return) {
        $leading_assignment = 'return ';
    }
    else {
        $refactored_code =~ s{\s* \Z}{\n    ;\n    # RETURN VALUE HERE?\n}xms;
    }

    # Format and wrap refactored code in a subroutine declaration...
    my $min_indent = min map { /^\s*/; length($&) } split(/\n/, $refactored_code);
    $refactored_code =~ s{ ^ [ ]{$min_indent} }{    }gxms;
    $refactored_code = "sub $subname"
                     . ($use_version ge v5.22
                            ? " ($param_code) {\n"
                            : " {\n    my ($param_code) = \@_;\n\n"
                       )
                     . "$refactored_code\n}\n";

    my $call = $leading_ws . $leading_assignment
             . $subname
             . ($trailing{comma} || !$trailing{semicolon} ? " $arg_code" : "($arg_code)")
             . $trailing{punctuation};

    return { code   => $refactored_code,
             call   => $call . $final_semicolon,
             return => $return_candidates,
           };
}

# Refactor the code into a subroutine...
sub hoist_to_lexical {
    # Unpack args...
    my ($opt_ref) = grep { ref($_) eq 'HASH' } @_, {};
    my ($code, @extras) = grep { !ref($_) } @_;

    # Check raw arguments...
    croak( "'code' argument of refactor_to_sub() must be a string" ) if !defined($code) || ref($code);
    croak( "Unexpected extra argument passed to refactor_to_sub(): '$_'" ) for @extras;
    croak( "'options' argument of refactor_to_sub() must be hash ref, not ", lc(ref($_)), " ref" )
        for grep { ref($_) && ref($_) ne 'HASH' } @_;

    # Apply defaults...
    my $varname    = $opt_ref->{name}   // $DEFAULT_LEXICAL_NAME;
    my $from       = $opt_ref->{from}   // 0;
    my $to         = $opt_ref->{to}     // length($code // q{}) - 1;
    my $all        = $opt_ref->{all};
    my $closure    = $opt_ref->{closure};

    # Check processed arguments...
    croak( "Unknown option ('$_') passed to refactor_to_sub()" )
        for grep { !$VALID_HOIST_OPTION{$_} } keys %{$opt_ref};
    croak( "'from' option of hoist_to_lexical() must be a number" )
        if !looks_like_number($opt_ref->{from});
    croak( "'to' option of hoist_to_lexical() must be a number" )
        if !looks_like_number($opt_ref->{to});

    # Analyze the file to locate replaceable instances of the expression...
    my $expr_scope = find_expr_scope($code, $from, $to, $all);
    return $expr_scope if $expr_scope->{failed};

    # Extract target code...
    my $target = $expr_scope->{target};

    # Handle mutators...
    $closure ||= $expr_scope->{mutators} > 0 && @{$expr_scope->{matches}} > 1;

    # Convert the name and the "call" name to the correct syntax...
    my $varsubst = $varname;
    my $vardecl;
    if ($varname !~ /^[\$\@%]/) {
        if (!$closure) {
            $varsubst = $varname = '$'.$varname;
            $vardecl = "my $varname = $target;\n";
        }
        elsif ($expr_scope->{use_version} lt v5.26) {
            $varname = '$'.$varname;
            $varsubst = $varname . '->()';
            $vardecl = "my $varname = sub { $target };\n";
        }
        else {
            $varsubst = $varname.'()';
            $vardecl = "my sub $varname { $target }\n";
        }
    }

    # Return analysis...
    return { code      => $vardecl,
             call      => $varsubst,
             %{$expr_scope},
           };
}

my $SPACE_MARKER = "\1\0\1\0\1\0";
my $SPACE_FINDER = quotemeta $SPACE_MARKER;
sub find_expr_scope {
    my ($source, $from, $to, $match_all) = @_;

    my $target = substr($source, $from, $to-$from+1);
       $target =~ s{ \A (?>(?&PerlOWS)) | (?>(?&PerlOWS)) \Z  $PPR::X::GRAMMAR }{}gxmso;

    # Verify it's a valid target...
    use re 'eval';
    our %ws_locs;
    our $mutators = 0;
    my $valid_target = qr{
       \A (?>(?&PerlConditionalExpression)) \Z

       (?(DEFINE)
           (?<PerlOWS> (?{pos()}) (?&PerlStdOWS) (?{ $ws_locs{$^R} = pos()-$^R; }) )

           (?<PerlPrefixUnaryOperator>
                (?> \+\+ (?{$mutators++}) | -- (?{$mutators++ })
                |   [!\\+~]
                |   - (?! (?&PPR_X_filetest_name) \b )
                )
           )

           (?<PerlPostfixUnaryOperator>
                (?> \+\+  |  -- ) (?{ $mutators++ })
           )
       )

       $PPR::X::GRAMMAR
    }xms;

    if ($target !~ $valid_target) {
        return { failed => "it's not a simple expression", target => $target };
        return;
    }

    # Convert the target text into a whitespace-tolerant literal search pattern
    # and whitespace-minimized rvalue for initializing hoist variable...
    my $rvalue = $target;
    for my $loc (sort {$b<=>$a} grep { $_ < length($target) } keys %ws_locs) {
        substr($target, $loc, $ws_locs{$loc}, $SPACE_MARKER);

        my $raw_ws = substr($rvalue, $loc, $ws_locs{$loc});
        substr($rvalue, $loc, $ws_locs{$loc}, $raw_ws =~ /\s/ ? q{ } : q{});
    }
    $target = quotemeta $target;
    $target =~ s{\Q$SPACE_FINDER\E}{\\s*+}gxms;

    # Locate all target instances...
    my @matches;
    while ($source =~ m{(?{pos()}) (?<match> $target)}gcxms) {
        push @matches, {from => $^R, length => length($+{match}) };
    }

    # Determine every variable in scope for the target expression...
    my $var_info = classify_all_vars_in($source);
    my @target_vars = grep { $_->{declared_at} >= 0
                             && grep { $_ >= $from && $_ < $to } keys %{$_->{used_at} } }
                      values %{$var_info->{vars}};

    # Identify matches that use target variables...
    @matches = grep {
        my $match_from  = $_->{from};
        my $match_to    = $match_from + $_->{length};
        @target_vars == grep { grep { $match_all ? $match_from <= $_ && $_ <= $match_to
                                                 : $match_from == $from  }
                                    keys %{$_->{used_at}}
                             } @target_vars;
    } @matches;

    # Identify earliest position where hoist could be placed...
    my $hoistloc = min map { $_->{start_of_scope} } @target_vars;

    return {
                target      => $rvalue,
                hoistloc    => $hoistloc,
                matches     => \@matches,
                mutators    => $mutators,
                use_version => $var_info->{use_version},
           };
}

sub _convert_target_code {
    my ($target_code, $opts_ref) = @_;
    my $from = $opts_ref->{from};

    # Label out-parameters...
    $_->{out} = 1 for @{$opts_ref->{out_vars}};

    # Build name translation for each variable...
    my @param_vars = (@{$opts_ref->{in_vars}}, @{$opts_ref->{out_vars}});
    our %rename_at;
    our %is_state_var;
    for my $var (@param_vars) {
        # Construct name of scalar parameter...
        my $out = $var->{out} ? 'o' : q{};
        my $new_name
            = $var->{new_name}
            = '$'.$var->{raw_name}
            . ( $var->{sigil} eq '@'                         ?  "_${out}aref"
              : $var->{sigil} eq '%'                         ?  "_${out}href"
              : $var->{raw_name} =~ /_o?(?:[ahs]ref|sval)$/  ?  "_${out}sval"
              :                                                 "_${out}sref"
              );

        # Add "undeclarations" to renaming map and track internal state variables...
        my $local_decl = ($var->{declared_at} // -1) - $from;
        if ($local_decl >= 0) {
            $rename_at{$local_decl} = $new_name;
            $is_state_var{$local_decl} = $var->{declarator} eq 'state';
        }

        # Add all usages to renaming map...
        for my $usage (@{$var->{used_at}}) {
            $rename_at{$usage - $from} = $new_name;
        }
    }

    # Build argument list and parameter list for call...
    my $args_code = join(', ',
                        map( { "\\$_->{decl_name}" }                  @{$opts_ref->{in_vars}}  ),
                        map( { "\\$_->{declarator} $_->{decl_name}" } @{$opts_ref->{out_vars}} )
                    );

    my $param_code = join(', ', map { "$_->{new_name}" } @param_vars);

    # Rename parameters within refactored code...
    $target_code =~ s{ (?: (?> my | our | state )      (?&PerlOWS) )?+
                       (?(?{$rename_at{pos()}})|(?!))
                       (?{pos()})
                       (?<sigil>  (?> \$\#?+ | [\@%] ) (?&PerlOWS) )
                       (?<braced> \{                   (?&PerlOWS) | )
                       \w++
                       $PPR::X::GRAMMAR
                     }
                     { ( $is_state_var{$^R} ? "$&=" : q{} )
                     . $+{sigil}
                     . (length($+{braced}) ? "\{$rename_at{$^R}" : "{$rename_at{$^R}}")
                     }egxmso;

    # Rewrite list declarations to allow hoisting (skipping quoted ones)...
    $target_code =~ s{ (\A|\W) (?&PerlQuotelike)
                     | (?<list_decl>
                            (?<declarator> (?> my | our | state ) )      (?&PerlOWS)
                            \(                                           (?&PerlOWS)
                            (?<var_list>             (?&PerlVariable)?+  (?&PerlOWS)
                                   (?: , (?&PerlOWS) (?&PerlVariable)    (?&PerlOWS) )*+
                                       ,?+                               (?&PerlOWS)
                            )
                            \)
                       )
                       $PPR::X::GRAMMAR
                     }
                     {
                       if ($+{list_decl}) {
                           '('.join(', ', map { "$+{declarator} $_" } split /,\s*/, $+{var_list}).')'
                       }
                       else {
                           $&;
                       }
                     }egxmso;

    # Build old->name mapping...
    my $varname_mapping = {
        map( { $_->{decl_name} => $_->{decl_name} }
             grep { $_->{end_of_scope} >= $opts_ref->{to} }        @{$opts_ref->{lex_vars}} ),
        map( { $_->{decl_name} => $_->{sigil}."{$_->{new_name}}" } @param_vars ),
    };

    return ($args_code, $param_code, $target_code, $varname_mapping);
}


sub rename_variable {
    my ($source, $varpos, $new_name) = @_;

    my $extraction = _classify_var_at($source, $varpos);

    my ($varname, $declared_at, $used_at, $failed)
        = @{ $extraction }{'raw_name', 'declared_at', 'used_at', 'failed'};

    return { failed => $failed } if $failed;

    for my $index (sort { $b <=> $a} keys %{$used_at}) {
        substr($source,$index)
            =~ s{\A (?: \$\#? | [\@%] ) (?&PerlOWS)
                    \{? (?&PerlOWS)
                    \K $varname          $PPR::X::GRAMMAR
                }{$new_name}xms
                    or warn "Internal usage rename error at position $index: '...",
                        substr($source, $index, 20), "...'\n";
    }
    if ($declared_at >= 0) {
        substr($source,$declared_at)
            =~ s{\A (?: \$\#? | [\@%] ) (?&PerlOWS)
                    \{? (?&PerlOWS)
                    \K $varname          $PPR::X::GRAMMAR
                }{$new_name}xms
                    or warn "Internal declaration rename error at position $declared_at: '...",
                        substr($source, $declared_at, 20), "...'\n";
    }

    return { source => $source };
}



# Convert fancy vars ($# { name }) to simple ones (@name)...
sub _normalize_var {
    my ($var, $accessor) = @_;

    # Remove decorations...
    $var =~ tr/{} \t\n\f\r//d;

    # Convert maxindex ($#a) to array (@a)
    return '@'.substr($var,2) if length($var) > 2 && substr($var,0,2) eq '$#';

    # Convert derefs (@$s or %$s) to scalar ($s)
    return substr($var,1) if length($var) > 2
                          && (substr($var,0,2) eq '@$' || substr($var,0,2) eq '%$');

    # Return entire variables as-are...
    return $var               if !$accessor;

    # Convert array and hash look-ups to arrays and hashes...
    return '@'.substr($var,1) if $accessor eq '[';
    return '%'.substr($var,1) if $accessor eq '{';

    # "This can never happen" ;-)
    die "Internal error: unexpected accessor after $var: '$accessor'";
}

# Extract variables from a for loop declaration...
sub _extract_vars {
    my ($decl) = @_;

    return map  { _normalize_var($_) }
           $decl =~ m{ [\$\@%] \w+ }xmsg;
}

# Remove 'use experimental' declarations if not requested...
sub _de_experiment {
    my ($code) = @_;
    $code =~ s{ ^ $OWS
                  use \s+ experimental\b $OWS
                  (?>(?&PerlExpression)) $OWS
                  ; $OWS \n?
              }{}gxmso;
    return $code;
}

# How to recognize a variable...
my $VAR_PAT = qr{
    \A
    (?<full>
        (?<sigil> [\@\$%] )  (?<name> \$ )  (?! [\$\{\w] )
    |
        (?<sigil> (?> \$ (?: [#] (?= (?> [\$^\w\{:+] | - (?! > ) ) ))?+ | [\@%] ) )
        (?>(?&PerlOWS))
        (?>                        (?<name> (?&_varname) )
            | \{  (?>(?&PerlOWS))  (?<name> (?&_varname) )  (?>(?&PerlOWS))  \}
        )
    |
        (?<sigil> [\@\$%] )  (?<name> \# )
    )

    (?(DEFINE)
        (?<_varname> \d++
                    | \^ [][A-Z^_?\\]
                    | (?>(?&PerlOldQualifiedIdentifier)) (?: :: )?+
                    | [][!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-]
        )
    )

    $PPR::X::GRAMMAR
}xms;

sub _classify_var_at {
    my ($source, $varpos) = @_;

    # Locate the variable...
    my $orig_varpos = $varpos;
    my $orig_sigil  = q{};
    my %var;

    POSITION:
    while ($varpos >= 0) {
        # Walk backwards, looking for the variable...
        if (substr($source, $varpos) =~ $VAR_PAT) {
            %var = %+;
            $orig_sigil = $var{sigil};

            # Handle the very special case of $; (need to be sure it's not part of $$;)
            next POSITION
                if $varpos > 0 && $var{name} eq ';' && substr($source, $varpos-1, 1) =~ /[\$\@%]/;

            # Return a special value if we fail to match a variable at the specified position
            if ($varpos + length($var{full}) <= $orig_varpos) {
                return { failed => "No variable at specified location", at => $orig_varpos }
            }

            # Otherwise, we found it...
            last POSITION;
        }
    }
    continue { $varpos-- }

    # Did we run off the start of the input?
    return { failed => "No variable at specified location", at => $orig_varpos }
        if $varpos < 0;

    # Locate and classify every variable in the source code...
    my $analysis = classify_all_vars_in($source);

    # Return a failure report if unable to process source code...
    return $analysis if $analysis->{failed};

    # Attempt to locate and report information about the requested variable...
    my $allvars = $analysis->{vars};
    for my $varid (keys %{$analysis->{vars}}) {
        return $allvars->{$varid}
            if $varid == $varpos || $allvars->{$varid}{used_at}{$varpos};
    }

    return { failed => 'Apparent variable is not actually a variable' };
}

# Descriptions of built-in and other "standard" variables...
my %STD_VAR_DESC = (
    "\$!" => {
        aliases => { "\$ERRNO" => 1, "\$OS_ERROR" => 1 },
        desc    => "Status from most recent system call (including I/O)",
    },
    "\$\"" => {
        aliases => { "\$LIST_SEPARATOR" => 1 },
        desc    => "List separator for array interpolation",
    },
    "\$#" => {
        aliases => { "\$OFMT" => 1 },
        desc    => "Output number format [deprecated: use printf() instead]",
    },
    "\$\$" => {
        aliases => { "\$PID" => 1, "\$PROCESS_ID" => 1 },
        desc    => "Process ID",
    },
    "\$%" => {
        aliases => { "\$FORMAT_PAGE_NUMBER" => 1 },
        desc    => "Page number of the current output page",
    },
    "\$&" => {
        aliases => { "\$MATCH" => 1 },
        desc    => "Most recent regex match string",
    },
    "\$'" => {
        aliases => { "\$POSTMATCH" => 1 },
        desc    => "String following most recent regex match",
    },
    "\$(" => {
        aliases => { "\$GID" => 1, "\$REAL_GROUP_ID" => 1 },
        desc    => "Real group ID of the current process",
    },
    "\$)" => {
        aliases => { "\$EFFECTIVE_GROUP_ID" => 1, "\$EGID" => 1 },
        desc    => "Effective group ID of the current process",
    },
    "\$*" => {
        aliases => {},
        desc    => "Regex multiline matching flag [removed: use /m instead]",
    },
    "\$+" => {
        aliases => { "\$LAST_PAREN_MATCH" => 1 },
        desc    => "Final capture group of most recent regex match",
    },
    "\$," => {
        aliases => { "\$OFS" => 1, "\$OUTPUT_FIELD_SEPARATOR" => 1 },
        desc    => "Output field separator for print() and say()",
    },
    "\$-" => {
        aliases => { "\$FORMAT_LINES_LEFT" => 1 },
        desc    => "Number of lines remaining in current output page",
    },
    "\$." => {
        aliases => { "\$INPUT_LINE_NUMBER" => 1, "\$NR" => 1 },
        desc    => "Line number of last input line",
    },
    "\$/" => {
        aliases => { "\$INPUT_RECORD_SEPARATOR" => 1, "\$RS" => 1 },
        desc    => "Input record separator (end-of-line marker on inputs)",
    },
    "\$0" => { aliases => { "\$PROGRAM_NAME" => 1 }, desc => "Program name" },
    "\$1" => {
        aliases => {},
        desc    => "First capture group from most recent regex match",
    },
    "\$2" => {
        aliases => {},
        desc    => "Second capture group from most recent regex match",
    },
    "\$3" => {
        aliases => {},
        desc    => "Third capture group from most recent regex match",
    },
    "\$4" => {
        aliases => {},
        desc    => "Fourth capture group from most recent regex match",
    },
    "\$5" => {
        aliases => {},
        desc    => "Fifth capture group from most recent regex match",
    },
    "\$6" => {
        aliases => {},
        desc    => "Sixth capture group from most recent regex match",
    },
    "\$7" => {
        aliases => {},
        desc    => "Seventh capture group from most recent regex match",
    },
    "\$8" => {
        aliases => {},
        desc    => "Eighth capture group from most recent regex match",
    },
    "\$9" => {
        aliases => {},
        desc    => "Ninth capture group from most recent regex match",
    },
    "\$:" => {
        aliases => { "\$FORMAT_LINE_BREAK_CHARACTERS" => 1 },
        desc    => "Break characters for format() lines",
    },
    "\$;" => {
        aliases => { "\$SUBSCRIPT_SEPARATOR" => 1, "\$SUBSEP" => 1 },
        desc    => "Hash subscript separator for key concatenation",
    },
    "\$<" => {
        aliases => { "\$REAL_USER_ID" => 1, "\$UID" => 1 },
        desc    => "Real uid of the current process",
    },
    "\$=" => {
        aliases => { "\$FORMAT_LINES_PER_PAGE" => 1 },
        desc    => "Page length of selected output channel",
    },
    "\$>" => {
        aliases => { "\$EFFECTIVE_USER_ID" => 1, "\$EUID" => 1 },
        desc    => "Effective uid of the current process",
    },
    "\$?" => {
        aliases => { "\$CHILD_ERROR" => 1 },
        desc    => "Status from most recent system call (including I/O)",
    },
    "\$\@" => {
        aliases => { "\$EVAL_ERROR" => 1 },
        desc    => "Current propagating exception",
    },
    "\$[" => {
        aliases => { "\$ARRAY_BASE" => 1 },
        desc    => "Array index origin [deprecated]",
    },
    "\$\\" => {
        aliases => { "\$ORS" => 1, "\$OUTPUT_RECORD_SEPARATOR" => 1 },
        desc    => "Output record separator (appended to every print())",
    },
    "\$]" => {
        aliases => {},
        desc    => "Perl interpreter version [deprecated: use \$^V]",
    },
    "\$^" => {
        aliases => { "\$FORMAT_TOP_NAME" => 1 },
        desc    => "Name of top-of-page format for selected output channel",
    },
    "\$^A" => {
        aliases => { "\$ACCUMULATOR" => 1 },
        desc    => "Accumulator for format() lines",
    },
    "\$^C" => {
        aliases => { "\$COMPILING" => 1 },
        desc    => "Is the program still compiling?",
    },
    "\$^D" =>
        { aliases => { "\$DEBUGGING" => 1 }, desc => "Debugging flags" },
    "\$^E" => {
        aliases => { "\$EXTENDED_OS_ERROR" => 1 },
        desc    => "O/S specific error information",
    },
    "\$^F" => {
        aliases => { "\$SYSTEM_FD_MAX" => 1 },
        desc    => "Maximum system file descriptor",
    },
    "\$^H" =>
        { aliases => {}, desc => "Internal compile-time lexical hints" },
    "\$^I" => {
        aliases => { "\$INPLACE_EDIT" => 1 },
        desc    => "In-place editing value",
    },
    "\$^L" => {
        aliases => { "\$FORMAT_FORMFEED" => 1 },
        desc    => "Form-feed sequence for format() pages",
    },
    "\$^M" => { aliases => {}, desc => "Emergency memory pool" },
    "\$^N" => {
        aliases => { "\$LAST_SUBMATCH_RESULT" => 1 },
        desc    => "Most recent capture group (within regex)",
    },
    "\$^O" =>
        { aliases => { "\$OSNAME" => 1 }, desc => "Operating system name" },
    "\$^P" =>
        { aliases => { "\$PERLDB" => 1 }, desc => "Internal debugging flags" },
    "\$^R" => {
        aliases => { "\$LAST_REGEXP_CODE_RESULT" => 1 },
        desc    => "Result of last successful code block (within regex)",
    },
    "\$^S" => {
        aliases => { "\$EXCEPTIONS_BEING_CAUGHT" => 1 },
        desc    => "Current eval() state",
    },
    "\$^T" =>
        { aliases => { "\$BASETIME" => 1 }, desc => "Program start time" },
    "\$^V" => {
        aliases => { "\$PERL_VERSION" => 1 },
        desc    => "Perl interpreter version",
    },
    "\$^W" =>
        { aliases => { "\$WARNING" => 1 }, desc => "Global warning flags" },
    "\$^X" => {
        aliases => { "\$EXECUTABLE_NAME" => 1 },
        desc    => "Perl interpreter invocation name",
    },
    "\$_" => {
        aliases => { "\$ARG" => 1 },
        desc =>
        "Topic variable: default argument for matches and many builtins",
    },
    "\$`" => {
        aliases => { "\$PREMATCH" => 1 },
        desc    => "String preceding most recent regex match",
    },
    "\$a" => {
        aliases => {},
        desc    => "Block parameter: automatically provided to sort blocks",
    },
    "\$ACCUMULATOR" => {
        aliases => { "\$^A" => 1 },
        desc    => "Accumulator for format() lines",
    },
    "\$ARG" => {
        aliases => { "\$_" => 1 },
        desc =>
        "Topic variable: default argument for matches and many builtins",
    },
    "\$ARGV" => {
        aliases => {},
        desc    => "Name of file being read by readline() or <>",
    },
    "\$ARRAY_BASE" => {
        aliases => { "\$[" => 1 },
        desc    => "Array index origin [deprecated]",
    },
    "\$b" => {
        aliases => {},
        desc    => "Block parameter: automatically provided to sort blocks",
    },
    "\$BASETIME" =>
        { aliases => { "\$^T" => 1 }, desc => "Program start time" },
    "\$CHILD_ERROR" => {
        aliases => { "\$?" => 1 },
        desc    => "Status from most recent system call (including I/O)",
    },
    "\$COMPILING" => {
        aliases => { "\$^C" => 1 },
        desc    => "Is the program still compiling?",
    },
    "\$DEBUGGING" =>
        { aliases => { "\$^D" => 1 }, desc => "Debugging flags" },
    "\$EFFECTIVE_GROUP_ID" => {
        aliases => { "\$)" => 1, "\$EGID" => 1 },
        desc    => "Effective group ID of the current process",
    },
    "\$EFFECTIVE_USER_ID" => {
        aliases => { "\$>" => 1, "\$EUID" => 1 },
        desc    => "Effective uid of the current process",
    },
    "\$EGID" => {
        aliases => { "\$)" => 1, "\$EFFECTIVE_GROUP_ID" => 1 },
        desc    => "Effective group ID of the current process",
    },
    "\$ERRNO" => {
        aliases => { "\$!" => 1, "\$OS_ERROR" => 1 },
        desc    => "Status from most recent system call (including I/O)",
    },
    "\$EUID" => {
        aliases => { "\$>" => 1, "\$EFFECTIVE_USER_ID" => 1 },
        desc    => "Effective uid of the current process",
    },
    "\$EVAL_ERROR" =>
        { aliases => { "\$\@" => 1 }, desc => "Current propagating exception" },
    "\$EXCEPTIONS_BEING_CAUGHT" =>
        { aliases => { "\$^S" => 1 }, desc => "Current eval() state" },
    "\$EXECUTABLE_NAME" => {
        aliases => { "\$^X" => 1 },
        desc    => "Perl interpreter invocation name",
    },
    "\$EXTENDED_OS_ERROR" => {
        aliases => { "\$^E" => 1 },
        desc    => "O/S specific error information",
    },
    "\$FORMAT_FORMFEED" => {
        aliases => { "\$^L" => 1 },
        desc    => "Form-feed sequence for format() pages",
    },
    "\$FORMAT_LINE_BREAK_CHARACTERS" => {
        aliases => { "\$:" => 1 },
        desc    => "Break characters for format() lines",
    },
    "\$FORMAT_LINES_LEFT" => {
        aliases => { "\$-" => 1 },
        desc    => "Number of lines remaining in current output page",
    },
    "\$FORMAT_LINES_PER_PAGE" => {
        aliases => { "\$=" => 1 },
        desc    => "Page length of selected output channel",
    },
    "\$FORMAT_NAME" => {
        aliases => { "\$~" => 1 },
        desc    => "Name of format for selected output channel",
    },
    "\$FORMAT_PAGE_NUMBER" => {
        aliases => { "\$%" => 1 },
        desc    => "Page number of the current output page",
    },
    "\$FORMAT_TOP_NAME" => {
        aliases => { "\$^" => 1 },
        desc    => "Name of top-of-page format for selected output channel",
    },
    "\$GID" => {
        aliases => { "\$(" => 1, "\$REAL_GROUP_ID" => 1 },
        desc    => "Real group ID of the current process",
    },
    "\$INPLACE_EDIT" =>
        { aliases => { "\$^I" => 1 }, desc => "In-place editing value" },
    "\$INPUT_LINE_NUMBER" => {
        aliases => { "\$." => 1, "\$NR" => 1 },
        desc    => "Line number of last input line",
    },
    "\$INPUT_RECORD_SEPARATOR" => {
        aliases => { "\$/" => 1, "\$RS" => 1 },
        desc    => "Input record separator (end-of-line marker on inputs)",
    },
    "\$LAST_PAREN_MATCH" => {
        aliases => { "\$+" => 1 },
        desc    => "Final capture group of most recent regex match",
    },
    "\$LAST_REGEXP_CODE_RESULT" => {
        aliases => { "\$^R" => 1 },
        desc    => "Result of last successful code block (within regex)",
    },
    "\$LAST_SUBMATCH_RESULT" => {
        aliases => { "\$^N" => 1 },
        desc    => "Most recent capture group (within regex)",
    },
    "\$LIST_SEPARATOR" => {
        aliases => { "\$\"" => 1 },
        desc    => "List separator for array interpolation",
    },
    "\$MATCH" =>
        { aliases => { "\$&" => 1 }, desc => "Most recent regex match string" },
    "\$NR" => {
        aliases => { "\$." => 1, "\$INPUT_LINE_NUMBER" => 1 },
        desc    => "Line number of last input line",
    },
    "\$OFMT" => {
        aliases => { "\$#" => 1 },
        desc    => "Output number format [deprecated: use printf() instead]",
    },
    "\$OFS" => {
        aliases => { "\$," => 1, "\$OUTPUT_FIELD_SEPARATOR" => 1 },
        desc    => "Output field separator for print() and say()",
    },
    "\$ORS" => {
        aliases => { "\$\\" => 1, "\$OUTPUT_RECORD_SEPARATOR" => 1 },
        desc    => "Output record separator (appended to every print())",
    },
    "\$OS_ERROR" => {
        aliases => { "\$!" => 1, "\$ERRNO" => 1 },
        desc    => "Status from most recent system call (including I/O)",
    },
    "\$OSNAME" =>
        { aliases => { "\$^O" => 1 }, desc => "Operating system name" },
    "\$OUTPUT_AUTOFLUSH" => {
        aliases => { "\$|" => 1 },
        desc    => "Autoflush status of selected output filehandle",
    },
    "\$OUTPUT_FIELD_SEPARATOR" => {
        aliases => { "\$," => 1, "\$OFS" => 1 },
        desc    => "Output field separator for print() and say()",
    },
    "\$OUTPUT_RECORD_SEPARATOR" => {
        aliases => { "\$\\" => 1, "\$ORS" => 1 },
        desc    => "Output record separator (appended to every print())",
    },
    "\$PERL_VERSION" =>
        { aliases => { "\$^V" => 1 }, desc => "Perl interpreter version" },
    "\$PERLDB" =>
        { aliases => { "\$^P" => 1 }, desc => "Internal debugging flags" },
    "\$PID" => {
        aliases => { "\$\$" => 1, "\$PROCESS_ID" => 1 },
        desc    => "Process ID",
    },
    "\$POSTMATCH" => {
        aliases => { "\$'" => 1 },
        desc    => "String following most recent regex match",
    },
    "\$PREMATCH" => {
        aliases => { "\$`" => 1 },
        desc    => "String preceding most recent regex match",
    },
    "\$PROCESS_ID" =>
        { aliases => { "\$\$" => 1, "\$PID" => 1 }, desc => "Process ID" },
    "\$PROGRAM_NAME" => { aliases => { "\$0" => 1 }, desc => "Program name" },
    "\$REAL_GROUP_ID" => {
        aliases => { "\$(" => 1, "\$GID" => 1 },
        desc    => "Real group ID of the current process",
    },
    "\$REAL_USER_ID" => {
        aliases => { "\$<" => 1, "\$UID" => 1 },
        desc    => "Real uid of the current process",
    },
    "\$RS" => {
        aliases => { "\$/" => 1, "\$INPUT_RECORD_SEPARATOR" => 1 },
        desc    => "Input record separator (end-of-line marker on inputs)",
    },
    "\$SUBSCRIPT_SEPARATOR" => {
        aliases => { "\$;" => 1, "\$SUBSEP" => 1 },
        desc    => "Hash subscript separator for key concatenation",
    },
    "\$SUBSEP" => {
        aliases => { "\$;" => 1, "\$SUBSCRIPT_SEPARATOR" => 1 },
        desc    => "Hash subscript separator for key concatenation",
    },
    "\$SYSTEM_FD_MAX" => {
        aliases => { "\$^F" => 1 },
        desc    => "Maximum system file descriptor",
    },
    "\$UID" => {
        aliases => { "\$<" => 1, "\$REAL_USER_ID" => 1 },
        desc    => "Real uid of the current process",
    },
    "\$WARNING" =>
        { aliases => { "\$^W" => 1 }, desc => "Global warning flags" },
    "\${^CHILD_ERROR_NATIVE}" => {
        aliases => {},
        desc    => "Native status from most recent system-level call",
    },
    "\${^ENCODING}" => {
        aliases => {},
        desc    => "Encode object for source conversion to Unicode",
    },
    "\${^GLOBAL_PHASE}" =>
        { aliases => {}, desc => "Current interpreter phase" },
    "\${^MATCH}" =>
        { aliases => {}, desc => "Most recent regex match string (under /p)" },
    "\${^OPEN}"      => { aliases => {}, desc => "PerlIO I/O layers" },
    "\${^POSTMATCH}" => {
        aliases => {},
        desc    => "String following most recent regex match (under /p)",
    },
    "\${^PREMATCH}" => {
        aliases => {},
        desc    => "String preceding most recent regex match (under /p)",
    },
    "\${^RE_DEBUG_FLAGS}" =>
        { aliases => {}, desc => "Regex debugging flags" },
    "\${^RE_TRIE_MAXBUF}" =>
        { aliases => {}, desc => "Cache limit on regex optimizations" },
    "\${^TAINT}"   => { aliases => {}, desc => "Taint mode" },
    "\${^UNICODE}" => { aliases => {}, desc => "Unicode settings" },
    "\${^UTF8CACHE}" =>
        { aliases => {}, desc => "Internal UTF-8 offset caching controls" },
    "\${^UTF8LOCALE}"   => { aliases => {}, desc => "UTF-8 locale" },
    "\${^WARNING_BITS}" => { aliases => {}, desc => "Lexical warning flags" },
    "\${^WIN32_SLOPPY_STAT}" =>
        { aliases => {}, desc => "Use non-opening stat() under Windows" },
    "\$|" => {
        aliases => { "\$OUTPUT_AUTOFLUSH" => 1 },
        desc    => "Autoflush status of selected output filehandle",
    },
    "\$~" => {
        aliases => { "\$FORMAT_NAME" => 1 },
        desc    => "Name of format for selected output channel",
    },
    "%!" => {
        aliases => { "%ERRNO" => 1, "%OS_ERROR" => 1 },
        desc => "Status of all possible errors from most recent system call",
    },
    "%+" => {
        aliases => {},
        desc    => "Named captures of most recent regex match (as strings)",
    },
    "%-" => {
        aliases => { "%LAST_MATCH_START" => 1 },
        desc =>
        "Named captures of most recent regex match (as arrays of strings)",
    },
    "%^H"    => { aliases => {}, desc => "Lexical hints hash" },
    "%ENV"   => { aliases => {}, desc => "The current shell environment" },
    "%ERRNO" => {
        aliases => { "%!" => 1, "%OS_ERROR" => 1 },
        desc => "Status of all possible errors from most recent system call",
    },
    "%INC" => { aliases => {}, desc => "Filepaths of loaded modules" },
    "%LAST_MATCH_START" => {
        aliases => { "%-" => 1 },
        desc =>
        "Named captures of most recent regex match (as arrays of strings)",
    },
    "%OS_ERROR" => {
        aliases => { "%!" => 1, "%ERRNO" => 1 },
        desc => "Status of all possible errors from most recent system call",
    },
    "%SIG" => { aliases => {}, desc => "Signal handlers" },
    "\@+"  => {
        aliases => { "\@LAST_PAREN_MATCH" => 1 },
        desc =>
        "Offsets of ends of capture groups of most recent regex match",
    },
    "\@-" => {
        aliases => { "\@LAST_MATCH_START" => 1 },
        desc =>
        "Offsets of starts of capture groups of most recent regex match",
    },
    "\@_" => { aliases => { "\@ARG" => 1 }, desc => "Subroutine arguments" },
    "\@ARG" => { aliases => { "\@_" => 1 }, desc => "Subroutine arguments" },
    "\@ARGV" => { aliases => {}, desc => "Command line arguments" },
    "\@F"    => {
        aliases => {},
        desc    => "Fields of the current input line (under autosplit mode)",
    },
    "\@INC" => { aliases => {}, desc => "Search path for loading modules" },
    "\@LAST_MATCH_START" => {
        aliases => { "\@-" => 1 },
        desc =>
        "Offsets of starts of capture groups of most recent regex match",
    },
    "\@LAST_PAREN_MATCH" => {
        aliases => { "\@+" => 1 },
        desc =>
        "Offsets of ends of capture groups of most recent regex match",
    },
);


# Build pattern to detect "unhelpful" variable and subroutine names

my @CACOGRAMS = qw<
    in(put)
    out(put)
    get
    put
    (re)set
    clear
    update

    array
    data
    dict(ionary)
    dictionaries
    elem(ent)
    hash
    heap
    idx
    indices
    key[]
    list
    node
    num(ber)
    obj(ect)
    queue
    rec(ord)
    scalar
    set
    stack
    str(ing)
    tree
    val(ue)[]
    opt(ion)
    arg(ument)
    range
    var(iable)

    desc(riptor)
    alt(ernate)
    item
    prev(ious)
    next
    last
    other
    res(ult)
    target
    name
    count
    size
    optional

    foo
    bar
    baz
>;

sub _inflect {
    my ($word) = @_;

    my $singular = $word =~ s{ \[ .* \]}{}rxms;
    my $sing     = $singular =~ s{ \( .* \) }{}grxms;
       $singular =~ s/[()]//g;

    my $plur     = ($word =~ s{ \( .* \) | \[ .* \]}{}grxms) .'s';
    my $plural   =  $word =~ s{ \[ (.*?) \] | \Z }{ $1 // 's'}erxms
                          =~ s{ [()] }{}grxms;

    return $plural, $plur, $singular, $sing;
}

my $CACOGRAMS_PAT
    = '\b(?!_\z)(?:'.join('|', reverse(sort(uniq(map { _inflect($_) } @CACOGRAMS, '_')))).')+\b';


# Build tools to detect parograms (similar, but not identical variable and sub names)...

my $VOWEL = '[aeiou]';
my @DOUBLE_CONSONANT
    = map {("$_$_(?=$VOWEL)"          => { "$_$_" => "$_$_?", $_ => "$_$_?" },
            "(?<=$VOWEL)$_(?=$VOWEL)" => { "$_$_" => "$_$_?", $_ => "$_$_?" },
          )}
          qw< b c d f g h j k l m n p q r s t v w x y z >;

my %VARIANT_SPELLING = (
    'ou?r'              => {  or   => 'ou?r',         our   => 'ou?r',        },
    'en[cs](?=e)'       => {  enc  => 'en[cs]',       ens   => 'en[cs]',      },
    '\B(?:er|re)'       => {  er   => '(?:er|re)',    re    => '(?:er|re)',   },
    '(?:x|ct)ion'       => {  xion => '(?:x|ct)ion',  ction => '(?:x|ct)ion', },
    'ae'                => {  ae   => 'a?e',                                  },
    'oe'                => {  oe   => 'o?e',                                  },
    'i[sz](?=e)'        => {  is   => 'i[sz]',        iz    => 'i[sz]',       },
    'y[sz](?=e)'        => {  ys   => 'y[sz]',        yz    => 'y[sz]',       },
    'og(?:ue)?'         => {  og   => 'og(?:ue)?',    ogue  => 'og(?:ue)?',   },
    'e?abl'             => {  eabl => 'e?abl',        abl   => 'e?abl',       },
    @DOUBLE_CONSONANT,
);
my %VARIANT_PAT = map { %{$_}; } values %VARIANT_SPELLING;
my $VARIANT_SPELLING = join('|', reverse sort keys %VARIANT_SPELLING);

my @CONFLATION_GROUPS = ('aeiou', 'bdfhklt', 'cmnrsvwxz', 'gjpqy');
my %CONFLATION_CHARS;
for my $group (@CONFLATION_GROUPS) {
    for my $letter (split('', $group)) {
        $CONFLATION_CHARS{$letter} = "[$group]" =~ s/$letter//gr;
    }
}

sub _parograms_of {
    my ($word) = @_;

    my $typos = join '|',
                map { our $pos = $_;
                      $word =~ s{(??{pos==$pos?'':'(?!)'}) .}{$CONFLATION_CHARS{$&} // $&}eixmsr;
                    }
                    0..length($word)-1;

    my $spelling = $word =~ s{$VARIANT_SPELLING}{$VARIANT_PAT{lc $&}//$&}egixmsr;

    return $spelling ne $word ? "(?i:$spelling|$typos)" : "(?i:$typos)";
}


# Determine if two variables overlap in scope...
sub _share_scope {
    my ($var1, $var2) = @_;
    my $from_delta = $var1->{start_of_scope} - $var2->{start_of_scope};
    my $to_delta   = $var1->{end_of_scope}   - $var2->{end_of_scope};
    return $from_delta * $to_delta <= 0;
}

# Locate all mentions of all variable in the specified code...
sub classify_all_vars_in {
    my ($source) = @_;

    # A stack to track the scope of each variable
    no warnings 'once';
    local @Code::ART::varscope = { ids => {}, decls => [] };

    # Hashes to track their variable descriptions and uses
    # (Variables are identified by the offset of their declaration from the start of the source)...
    local %Code::ART::varinfo     = ();
    local %Code::ART::varuse      = ();
    local $Code::ART::use_version = 0;

    # Detect and record all instances of variable within the source code...
    my $matched = $source =~ m{
            \A
            (?&_push_scope)
            (?&PerlDocument)
            (?&_pop_scope)
            \Z

            (?(DEFINE)
                (?<PerlUseStatement>
                    (?>
                        use (?>(?&PerlOWS))
                        (?<version>  \d++ (?: \. \d++)?+ | v\d++ (?: \. \d++)*+ )
                            (?{ $Code::ART::use_version = version->parse("$+{version}") })
                    |
                        (?&PerlStdUseStatement)
                    )
                )

                (?<PerlBlock>
                    (?>
                        (?&_push_scope)
                        (?&PerlStdBlock)
                        (?&_pop_scope)
                    |
                        (?&_revert_scope_on_failure)
                    )
                )

                (?<PerlAnonymousHash>
                    (?>
                        (?&_push_scope)
                        (?&PerlStdAnonymousHash)
                        (?&_pop_scope)
                    |
                        (?&_revert_scope_on_failure)
                    )
                )

                (?<PerlStatement>
                    (?>
                        (?&PerlStdStatement)
                        (?&_install_pending_decls)
                    |
                        (?&_clear_pending_declaration)
                    )
                )

                (?<PerlControlBlock>
                    (?&_push_scope)
                    (?>
                        # Conditionals can have var declarations in their conditions...
                        (?> if | unless ) \b                 (?>(?&PerlOWS))
                        (?>(?&PerlParenthesesList))          (?>(?&PerlOWS))
                        (?= [^\n]*
                            (?<! \$    | \b [mysq]  )
                            (?<! \b tr | \b q[qwrx] )
                            \h* \# \h*
                            (?<desc> [^\n]* )
                        |
                            (?<desc>)
                        )
                        (?&_install_pending_decls)
                        (?>(?&PerlBlock))
                        (?&_pop_scope)

                        (?:
                                                            (?>(?&PerlOWS))
                            (?>(?&PerlPodSequence))
                            elsif \b                         (?>(?&PerlOWS))
                            (?>
                                (?&_push_scope)
                                (?>(?&PerlParenthesesList))      (?>(?&PerlOWS))
                                (?= [^\n]*
                                    (?<! \$    | \b [mysq]  )
                                    (?<! \b tr | \b q[qwrx] )
                                    \h* \# \h*
                                    (?<desc> [^\n]* )
                                |
                                    (?<desc>)
                                )
                                (?&_install_pending_decls)
                                (?&PerlBlock)
                                (?&_pop_scope)
                            |
                                (?&_revert_scope_on_failure)
                            )
                        )*+

                        (?:
                                                            (?>(?&PerlOWS))
                            (?>(?&PerlPodSequence))
                            else \b                          (?>(?&PerlOWS))
                            (?&PerlBlock)
                        )?+
                    |
                        # Have to handle loops specially (may have var declarations)...
                        (?>
                            (?<declarator> for(?:each)?+ \b )
                            (?>(?&PerlOWS))
                            (?>
                                (?&_allow_decls)
                                (?> # Explicitly aliased iterator variable...
                                    (?>
                                        \\ (?>(?&PerlOWS))
                                        (?<declarator> (?> my | our | state ) )
                                    |
                                        (?<declarator> (?> my | our | state ) )
                                        (?>(?&PerlOWS)) \\
                                    )
                                    (?>(?&PerlOWS))
                                    (?<var>
                                        (?> (?&PerlVariableScalar)
                                        |   (?&PerlVariableArray)
                                        |   (?&PerlVariableHash)
                                        )
                                    )
                                |
                                    # Implicitly aliased iterator variable...
                                    (?> (?<declarator> my | our | state ) (?>(?&PerlOWS)) )?+
                                    (?<var> (?&PerlVariableScalar) )
                                )?+
                                (?= [^\n]*
                                    (?<! \$    | \b [mysq]  )
                                    (?<! \b tr | \b q[qwrx] )
                                    \h* \# \h*
                                    (?<desc> [^\n]* )
                                |
                                    (?<desc>)
                                )
                                (?&_record_and_disallow_decls)

                                (?>(?&PerlOWS))
                                (?: (?> (?&PerlParenthesesList) | (?&PerlQuotelikeQW) ) )
                            )
                        |
                            (?> while | until) \b (?>(?&PerlOWS))
                            (?&_allow_decls)
                            (?&PerlParenthesesList)
                            (?= [^\n]*
                                (?<! \$    | \b [mysq]  )
                                (?<! \b tr | \b q[qwrx] )
                                \h* \# \h*
                                (?<desc> [^\n]* )
                            |
                                (?<desc>)
                            )
                            (?&_record_and_disallow_decls)
                        )

                        (?>(?&PerlOWS))
                        (?&_install_pending_decls)
                        (?>(?&PerlBlock))

                        (?:
                            (?>(?&PerlOWS))   continue
                            (?>(?&PerlOWS))   (?&PerlBlock)
                        )?+
                        (?&_pop_scope)
                    |
                        (?> given | when ) \b                (?>(?&PerlOWS))
                        (?>(?&PerlParenthesesList))          (?>(?&PerlOWS))
                        (?&_install_pending_decls)
                        (?&PerlBlock)
                        (?&_pop_scope)
                    |
                        (?&PerlStdControlBlock)
                        (?&_pop_scope)
                    |
                        (?&_revert_scope_on_failure)
                    )
                )

                (?<PerlSubroutineDeclaration>
                    (?&_push_scope)
                    (?>
                    (?> (?> my | state | our ) \b  (?>(?&PerlOWS)) )?+
                        (?<declarator> sub \b )            (?>(?&PerlOWS))
                        (?>(?&PerlOldQualifiedIdentifier))    (?&PerlOWS)
                    |
                        AUTOLOAD                              (?&PerlOWS)
                    |
                        DESTROY                               (?&PerlOWS)
                    )

                    (?&_allow_decls)
                    (?>
                        # Perl pre 5.028
                        (?:
                            (?>
                                (?&PerlParenthesesList)    # Parameter list
                            |
                                \( [^)]*+ \)               # Prototype (
                            )
                            (?&PerlOWS)
                        )?+
                        (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
                        (?&_record_and_disallow_decls)
                    |
                        # Perl post 5.028
                        (?: (?>(?&PerlAttributes))       (?&PerlOWS) )?+
                        (?: (?>(?&PerlParenthesesList))  (?&PerlOWS) )?+     # Parameter list
                        (?&_record_and_disallow_decls)
                    )?+
                    (?&_install_pending_decls)
                    (?> ; | (?&PerlBlock))
                    (?&_pop_scope)
                |
                    (?&_revert_scope_on_failure)
                )

                (?<PerlAnonymousSubroutine>
                    (?&_push_scope)
                    (?<declarator> sub \b )
                    (?>(?&PerlOWS))

                    (?&_allow_decls)
                    (?:
                        # Perl pre 5.028
                        (?:
                            (?>
                                (?&PerlParenthesesList)    # Parameter list
                            |
                                \( [^)]*+ \)               # Prototype (
                            )
                            (?&PerlOWS)
                        )?+
                        (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
                        (?= [^\n]*
                            (?<! \$    | \b [mysq]  )
                            (?<! \b tr | \b q[qwrx] )
                            \h* \# \h*
                            (?<desc> [^\n]* )
                        |
                            (?<desc>)
                        )
                        (?&_record_and_disallow_decls)
                    |
                        # Perl post 5.028
                        (?: (?>(?&PerlAttributes))   (?&PerlOWS) )?+
                        (?: (?&PerlParenthesesList)  (?&PerlOWS) )?+    # Parameter list
                        (?= [^\n]*
                            (?<! \$    | \b [mysq]  )
                            (?<! \b tr | \b q[qwrx] )
                            \h* \# \h*
                            (?<desc> [^\n]* )
                        |
                            (?<desc>)
                        )
                        (?&_record_and_disallow_decls)
                    )?+
                    (?&_install_pending_decls)
                    (?&PerlBlock)
                    (?&_pop_scope)
                |
                    (?&_revert_scope_on_failure)
                )

                (?<PerlVariableDeclaration>
                    (?> (?<declarator> my | state | our ) ) \b   (?>(?&PerlOWS))
                    (?: (?&PerlQualifiedIdentifier)                 (?&PerlOWS)  )?+
                    (?&_allow_decls)
                    (?:
                        (?&PerlLvalue)
                        (?= [^\n]*
                            (?<! \$    | \b [mysq]  )
                            (?<! \b tr | \b q[qwrx] )
                            \h* \# \h*
                            (?<desc> [^\n]* )
                        |
                            (?<desc>)
                        )
                        (?&_record_and_disallow_decls)
                    |
                        (?&_record_and_disallow_decls)
                        (?!)
                    )
                    (?>(?&PerlOWS))
                    (?&PerlAttributes)?+
                )

                (?<PerlLvalue>
                    (?>
                        \\?+
                        (?:
                            (?<var> (?> \$\#? | [@%] ) (?>(?&PerlOWS)) (?&PerlIdentifier) )
                            (?&_save_var_after_ows)
                        )
                    |
                        \(
                            (?>(?&PerlOWS))
                            (?> \\?+
                                (?<var> (?> \$\#? | [@%] ) (?>(?&PerlOWS)) (?&PerlIdentifier) )
                                (?&_save_var_after_ows)
                            |
                                undef
                            )
                            (?>(?&PerlOWS))
                            (?:
                                (?>(?&PerlComma))
                                (?>(?&PerlOWS))
                                (?> \\?+
                                    (?<var> (?> \$\#? | [@%] ) (?>(?&PerlOWS)) (?&PerlIdentifier) )
                                    (?&_save_var_after_ows)
                                |
                                    undef
                                )
                                (?>(?&PerlOWS))
                            )*+
                            (?: (?>(?&PerlComma)) (?&PerlOWS) )?+
                        \)
                    )
                )

                (?<PerlTerm>
                    (?> (?<declarator> my | state | our ) ) \b  (?>(?&PerlOWS))
                    (?: (?&PerlQualifiedIdentifier)                (?&PerlOWS)  )?+
                    (?&_allow_decls)
                    (?:
                        (?&PerlLvalue)
                        (?= [^\n]*
                            (?<! \$    | \b [mysq]  )
                            (?<! \b tr | \b q[qwrx] )
                            \h* \# \h*
                            (?<desc> [^\n]* )
                        |
                            (?<desc>)
                        )
                        (?&_record_and_disallow_decls)
                    |
                        (?&_disallow_decls)
                        (?!)
                    )
                    (?>(?&PerlOWS))
                    (?&PerlAttributes)?+
                |
                    (?&PerlStdTerm)
                )

                (?<PerlVariableScalar> (?<var> (?&PerlStdVariableScalar) ) (?&_save_var_after_ows) )
                (?<PerlVariableArray>  (?<var> (?&PerlStdVariableArray)  ) (?&_save_var_after_ows) )
                (?<PerlVariableHash>   (?<var> (?&PerlStdVariableHash)   ) (?&_save_var_after_ows) )

                (?<PerlVariableScalarNoSpace>
                    (?<var> (?&PerlStdVariableScalarNoSpace) )   (?&_save_var_no_ows)
                )
                (?<PerlVariableArrayNoSpace>
                    (?<var> (?&PerlStdVariableArrayNoSpace)  )   (?&_save_var_no_ows)
                )

                (?<PerlString>
                    "  [^"\$\@\\]*+
                    (?: (?> \\. | (?&PerlScalarAccessNoSpace) | (?&PerlArrayAccessNoSpace) )
                        [^"\$\@\\]*+
                    )*+
                    "
                |
                    (?&PerlStdString)
                )

                # Test and record instances of any variable encountered...
                (?<_save_var_after_ows>
                    (?{ my $var = (grep {defined} @{$-{var}})[-1]; [$var, pos() - length($var) ] })
                    (?= (?>(?&PerlOWS)) (?> (?<array> \[ ) | (?<hash> \{ ) | ) )
                    (?&_save_var)
                )

                (?<_save_var_no_ows>
                    (?{ my $var = (grep {defined} @{$-{var}})[-1]; [$var, pos() - length($var) ] })
                    (?= (?<array> \[ ) | (?<hash> \{ ) | )
                    (?&_save_var)
                )

                (?<_save_var>
                    (?{
                        my ($var, $varid) = @{$^R};
                        if (length($var) > 2) {
                            while (1) {
                                last if substr($var,1,1) ne '$';
                                substr($var, 0, 1, q{});
                                $varid++;
                            }
                        }

                        # Update the scope's information if this variable is being declared...
                        if ($Code::ART::varscope[-1]{allow_decls}) {
                            push @{$Code::ART::varscope[-1]{decls}},
                                 { id => $varid, decl_name => $var, raw_name => substr($var,1) };
                        }

                        # Otherwise record its usage in the appropriate slot (if any)...
                        else {
                            my $varlen = length($var);
                            my $sigil  = substr($var, 0, 1, q{});
                            my $twigil = $varlen > 1 && substr($var, 0, 1) eq '#'
                                            ? substr($var, 0, 1, q{})
                                            : q{};
                            (my $cleanvar = $var) =~ s/[^\w:'^]+//g;
                            $var = $cleanvar if length($cleanvar) > 0;
                            $var = ( $+{array} || $twigil ? '@'
                                   : $+{hash}             ? '%'
                                   :                      $sigil) . $var;
                            $Code::ART::varuse
                                {$Code::ART::varscope[-1]{ids}{$var} // $var}
                                    {$varid} = $varlen;
                        }
                    })
                )

                # Set up a new nested scope replicating the surrounding scope...
                (?<_push_scope>
                    (?{ push @Code::ART::varscope, {
                            ids => {%{$Code::ART::varscope[-1]{ids}}},
                            decls => [],
                        };
                    })
                )

                # Tear down a nested scope...
                (?<_pop_scope>
                    (?{
                        $Code::ART::oldscope = pop @Code::ART::varscope;
                        $Code::ART::end_of_scope = pos();
                        for my $id (values %{$Code::ART::oldscope->{ids}}) {
                            $Code::ART::varinfo{$id}{end_of_scope}
                              = $Code::ART::end_of_scope;
                        }
                    })
                )

                # Clean up a scope that's closing, but also propagate failure...
                (?<_revert_scope_on_failure>
                    (?{ pop @Code::ART::varscope; })
                    (?!)
                )

                # Allow/disallow variables to be recorded as declarations...
                (?<_allow_decls>
                    (?{ $Code::ART::varscope[-1]{allow_decls} = 1; })
                )

                (?<_disallow_decls>
                    (?{ $Code::ART::varscope[-1]{allow_decls} = 0; })
                )

                # Disallow declarations but remember the ones that were already found...
                (?<_record_and_disallow_decls>
                    (?{
                        for my $decl (@{$Code::ART::varscope[-1]{decls}}) {
                            my $decl_name = $decl->{decl_name} // $+{var};
                            @{$decl}{'declarator', 'sigil', 'desc', 'decl_name', 'raw_name', 'aliases'}
                                = ( (grep {defined} @{$-{declarator}})[-1] // q{},
                                    substr($_, $decl->{id}, 1),
                                    $+{desc} // q{},
                                    $decl_name,
                                    $decl->{raw_name},
                                    []
                                );
                        }
                        $Code::ART::varscope[-1]{allow_decls} = 0;
                    })
                )

                # Make new variable declarations effective in the current scope...
                (?<_install_pending_decls>
                    (?: (?&PerlOWS) \{ )?+
                    (?{
                        for my $decl (@{$Code::ART::varscope[-1]{decls}}) {
                            $Code::ART::varscope[-1]{ids}{$decl->{decl_name}} = $decl->{id};
                            @{$Code::ART::varinfo{$decl->{id}}}
                             {'declarator', 'sigil', 'desc', 'decl_name', 'raw_name'}
                                = @{$decl}{'declarator', 'sigil', 'desc', 'decl_name', 'raw_name'};
                            $Code::ART::varinfo{$decl->{id}}->{sigil}
                                //= substr($_, $decl->{id},1);
                            $Code::ART::varinfo{$decl->{id}}->{start_of_scope} = pos();
                            $Code::ART::varuse{$decl->{id}} = {};
                        }
                        $Code::ART::varscope[-1]{decls} = [];
                    })
                    (?!)  # Backtrack to unwind matching the trailing block delimiter
                |
                    (?=)  # Then match anyway, but at the original position
                )

                # Reset pending variable declarations in current scope...
                (?<_clear_pending_declaration>
                    (?{ $Code::ART::varscope[-1]{decls} = []; })
                )
            )

            $PPR::X::GRAMMAR
    }xmso;

    # Return a failure report if unable to process source code...
    return { failed => 'invalid source code', context => $PPR::X::ERROR }
        if !$matched;

    # Install usages and declaration locations...
    my $undecl_id = -1;
    for my $id (keys %Code::ART::varuse) {
        if ($id !~ /^\d+$/) {
            $Code::ART::varinfo{$undecl_id--}
                = { decl_name      => $id,
                    sigil          => substr($id,0,1),
                    raw_name       => substr($id,1),
                    declarator     => "",
                    desc           => "",
                    declared_at    => -1,
                    used_at        => $Code::ART::varuse{$id} // [],
                    start_of_scope => -1,
                    end_of_scope   => length($source),
                  };
        }
        else {
            $Code::ART::varinfo{$id}{declared_at}      = $id;
            $Code::ART::varinfo{$id}{used_at}          = $Code::ART::varuse{$id} // [];
            $Code::ART::varinfo{$id}{start_of_scope} //= -1,
            $Code::ART::varinfo{$id}{end_of_scope}   //= length($source);
        }
    }

    # Install standard descriptions and apply analyses...
    my %var_at;
    for my $varid (keys %Code::ART::varinfo) {
        my $var = $Code::ART::varinfo{$varid};
        my $var_name = $var->{raw_name};

        # Invert usages...
        for my $startpos (keys %{$var->{used_at}}) {
            for my $offset (0 .. $var->{used_at}{$startpos}) {
                $var_at{ $startpos + $offset } = $varid;
            }
        }

        # Check whether variable is a built-in...
        $var->{is_builtin} = 0;
        if (my $std_desc = $STD_VAR_DESC{$var->{decl_name}}) {
            @{$var}{'desc', 'aliases'} = @{$std_desc}{'desc', 'aliases'};
            $var->{is_builtin} = 1;
        }

        # Check whether its name is unhelpful...
        $var->{is_cacogram} = $var_name =~ /\A$CACOGRAMS_PAT\Z/ ? 1 : 0;

        # Check for homograms and parograms...
        my $parograms_pat = _parograms_of($var_name);
        $var->{homograms} = {};
        $var->{parograms} = {};
        for my $other_var (values %Code::ART::varinfo) {
            next if $var == $other_var || !_share_scope($var, $other_var);

            my $other_name = $other_var->{raw_name};
            my ($gram_type, $matcher) = $other_name eq $var_name ? ('homograms', $var_name)
                                                                 : ('parograms', $parograms_pat);
            if ($other_name =~ /\A$matcher\z/) {
                $var->{$gram_type}{$other_name}
                    //= { from=>$var->{declared_at}, to=>$var->{end_of_scope} };
                $var->{$gram_type}{$other_name}{from}
                    = min $var->{$gram_type}{$other_name}{from}, $other_var->{declared_at};
                $var->{$gram_type}{$other_name}{to}
                    = max $var->{$gram_type}{$other_name}{to},   $other_var->{end_of_scope};
            }
        }

        # Measure its scope...
        $var->{scope_scale}
            = ($var->{end_of_scope} - ($var->{declared_at} // 0)) / length($source);
    }

    # Return all the information acquired...
    return {
        vars        => \%Code::ART::varinfo,
        var_at      => \%var_at,
        use_version => $Code::ART::use_version,
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Code::ART - Analyze/Rename/Track Perl source code


=head1 VERSION

This document describes Code::ART version 0.000005


=head1 SYNOPSIS

    use Code::ART;

    # Convert source code fragment to sub and call...
    $refactored = refactor_to_sub( $source_code, \%options );

    # or:
    $refactored = hoist_to_lexical( $source_code, \%options );

    # Source code of sub or lexical...
    $sub_definition  = $refactored->{code};

    # Code to call sub with args, or to evaluate lexical...
    $sub_call_syntax = $refactored->{call};

    # Array of arg names (as strings, only for refactor_to_sub() )...
    @sub_arg_list    = @{ $refactored->{args} };

    # Only if refactoring failed...
    $failure_message = $refactored->{failed};


=head1 DESCRIPTION

This module provides a range of subroutines to help you refactor
valid Perl source into cleaner, better decomposed code.

The module also comes with a Vim plugin to plumb those
refactoring behaviours directly into that editor (see L<"Vim integration">).

For example, the module provides a subroutine (C<refactor_to_sub()>)
that takes a source code fragment as a string, analyzes it to determine
the unbound variables within it, then constructs the source code of an
equivalent subroutine (with the unbound variables converted to
parameters) plus the source code of a suitable call to that subroutine.

It is useful when hooked into an editor, allowing you to
(semi-)automatically convert functional code like:

    my @heatmap =
        map  { $config{$_} }
        sort {
               my $a_key = $a =~ /(\d+)/ ? $1 : undef;
               my $b_key = $b =~ /(\d+)/ ? $1 : undef;
               defined $a_key && defined $b_key
                  ? $a_key <=> $b_key
                  : $a     cmp $b;
             }
        grep { /^heatmap/ }
        keys %config;

into a much cleaner:

    my @heatmap =
        map  { $config{$_} }
        nsort
        grep { /^heatmap/ }
        keys %config;

plus:

    sub nsort {
        sort {
               my $a_key = $a =~ /(\d+)/ ? $1 : undef;
               my $b_key = $b =~ /(\d+)/ ? $1 : undef;
               defined $a_key && defined $b_key
                  ? $a_key <=> $b_key
                  : $a     cmp $b;
        }, @_;
    }

Or to replace something long and imperative like:

    my @heatmap_keys;

    for my $key (keys %config) {
        next if $key !~ /^heatmap/;
        push @heatmap_keys, $key;
    }

    @heatmap_keys
        = sort {
                my $a_key = $a =~ /(\d+)/ ? $1 : undef;
                my $b_key = $b =~ /(\d+)/ ? $1 : undef;
                defined $a_key && defined $b_key
                    ? $a_key <=> $b_key
                    : $a     cmp $b;
            } @heatmap_keys;

    my @heatmap;

    for (@heatmap_keys) {
        push @heatmap, $config{$_};
    }

with something short and imperative:

    my @heatmap;

    for ( get_heatmap_keys(\%config ) ) {
        push @heatmap, $config{$_};
    }

plus:

    sub get_heatmap_keys {
        my ($config_href) = @_;

        my @heatmap_keys;

        for my $key (keys %{$config_href}) {
            next if $key !~ /^heatmap/;
            push @heatmap_keys, $key;
        }

        @heatmap_keys = sort {
                            my $a_key = $a =~ /(\d+)/ ? $1 : undef;
                            my $b_key = $b =~ /(\d+)/ ? $1 : undef;
                            defined $a_key && defined $b_key
                                ? $a_key <=> $b_key
                                : $a     cmp $b;
                        } @heatmap_keys;

        return @heatmap_keys;
    }




=head1 INTERFACE

=head2 Refactoring a fragment of Perl code

To refactor some Perl code, call the C<refactor_to_sub()>
subroutine, which is automatically exported when the
module is loaded.

    my $refactored = refactor_to_sub( $source_code_string, \%options );

Note that this subroutine does not actually rewrite the source code
with the refactoring; it merely returns the components with which you
could transform the original source yourself.

The subroutine takes a single required argument:
a string containing the complete source code within which
some element is to be refactored.

The options specify where and how to refactor that code element, as follows:

=over

=item C<< from => $starting_string_index >>

=item C<<   to => $ending_string_index >>

These two options are actually required. They must be non-negative integer
values that represent the indexes in the string where the fragment you 
wish to refactor begins and ends.


=item C<< name => $name_of_new_sub >>

This option allows you to specify the name of the new subroutine.
If it is not provided, the module uses a bad generic name instead
(C<__REFACTORED_SUB__>), which you'll have to change anyway,
so passing the option is strongly recommended.


=item C<< data => $name_of_the_var_to_hold_any_trailing_data >>

This option allows you to specify the name of the slurpy variable into
which any trailing arguments for the new subroutine (i.e. in addition to
those the refactorer determines are required) will be placed.

If it is not provided, the module uses a generic name instead
(C<@__EXTRA_DATA__>).


=item C<< return => $source_of_the_expr_to_be_returned >>

If this option is specified, the refactorer places its value in a 
C<return> statement at the end of the refactored subroutine.

If it is not provided, no extra return statement is added.

=back

The return value of C<refactor_to_sub()> in all contexts and in all cases
is a hash reference containing one or more of the following keys:

=over

=item C<'code'>

The value for this key will be a string representing the source code for
the new subroutine into which the original code was refactored.

=item C<'call'>

The value for this key will be a string representing the source code for
the specific call to the new subroutine (including it's arguments)
that can be used to replace the original code.

=item C<'return'>

The value of this key will be a reference to an hash, whose keys are
the names of the variables present inside the original code that was
refactored, and whose values are the equivalent names of those variables
in the refactored code.

The purpose of these information is to allow your code to present the
user with a list of possible return values to select from (i.e. the keys
of the hash) and then install a suitable return statement (i.e. the
value of the selected key).


=item C<'failed'>

This key will be present only when the attempt to refactor the code failed
for some reason. The value of this key will be a string containing the
reason that the original code could not be refactored.
See L<"DIAGNOSTICS"> for a list of these error messages.

Note that, if the C<'failed'> key is present in the returned hash, then
the hash may not contain entries for C<'code'>, C<'call'>, or C<'return'>.

=back

Hence a generic usage might be:

    my $refactoring = refactor_to_sub( $original_code );

    if (exists $refactoring->{failed}) {
        warn $refactoring->{failed}
    }
    else {
        replace_original_code_with( $refactoring->{call} );
        add_subroutine_definition(  $refactoring->{code} );
    }


=head2 Hoisting an expression to a variable or closure

To refactor a single Perl expression into a scalar variable or
a lexical closure, call the C<hoist_to_lexical()>
subroutine, which is automatically exported when the
module is loaded:

    my $refactored = hoist_to_lexical( $source_code_string, \%options );

Note that this subroutine does not actually rewrite the source code
with the hoisting; it merely returns the components with which you
could transform the original source yourself.

The subroutine takes a single required argument:
a string containing the complete source code within which
some expression is to be refactored.

The options specify where and how to refactor that expression, as follows:

=over

=item C<< from => $starting_string_index >>

=item C<<   to => $ending_string_index >>

These two options are actually required. They must be non-negative integer
values that represent the indexes in the string where the expression you 
wish to refactor begins and ends.


=item C<< name => $name_of_new_lexical >>

This option allows you to specify the name of the new lexical variable or closure.
If it is not provided, the module uses a bad generic name instead
(C<__REFACTORED_LEXICAL>), which you'll have to change anyway,
so passing the option is strongly recommended.


=item C<< all => $boolean >>

This option allows you to specify whether the refactorer should attempt to
hoist every instance of the specified expression (if the option is true)
or just the selected instance (if the option is false or omitted).

=item C<< closure => $boolean >>

This option allows you to specify whether the refactorer should attempt to
hoist the specified expression into a closure (if the option is true),
instead of into a lexical variable (if the option is false or omitted).

Closures are a better choice whenever the expression has side-effects,
otherwise the behaviour of the refactored code will most likely change.
The C<hoist_to_lexical()> subroutine can detect some types of side-effects
automatically, and will automatically use a closure in those cases, regardless
of the value of this option.

=back

The return value of C<hoist_to_lexical()> in all contexts and in all cases
is a hash reference containing one or more of the following keys:

=over

=item C<'code'>

The value for this key will be a string representing the source code for
the new variable of closure declaration into which the original expression was
refactored.

=item C<'call'>

The value for this key will be a string representing the source code for
the specific call to the new closure, or use of the new variable,
that can be used to replace the original expression.

=item C<'hoistloc'>

The string index into the source string at which the C<'code'> declaration
should be installed.


=item C<'matches'>

A reference to an array of hashes. Each hash represents one location where
the specified expression was found, and the number of characters it occupies
in the string.

For example:

    matches => [
                 { from => 140, length => 24 },
                 { from => 180, length => 22 },
                 { from => 299, length => 26 },
               ],


=item C<'mutators'>

The number of mutation operators detected in the expression.
If this number is not zero, refactoring into a variable instead
of the closure will usually change the behaviour of the entire code.
C<hoist_to_lexical()> tries its darnedest to prevent that.

=item C<'target'>

The actual selected expression that was hoisted.

=item C<'use_version'>

A C<version> object representing the version that the source
code claimed to require (via an embedded C<use VERSION> statement).

=item C<'failed'>

This key will be present only when the attempt to refactor the code failed
for some reason. The value of this key will be a string containing the
reason that the original code could not be refactored.
See L<"DIAGNOSTICS"> for a list of these error messages.

Note that, if the C<'failed'> key is present in the returned hash, then
the hash may not contain entries for C<'code'>, C<'call'>, or the other
keys listed above.

=back


=head2 Analysing variable usage within some source code

To detect and analyse the declaration and usage of variables in
a piece of source code, call the C<classify_all_vars_in()>
subroutine which is exported by default when the module is used.

The subroutine takes a single argument: a string containing the
source code to be analysed.

It returns a hash containing two keys:

=over

=item C<'use_version'>

The value of this key is a C<version> object representing the
version that the source code claimed it required, via an 
embedded C<use VERSION> statement.

=item C<'vars'>

A hash of hashes, each of which represents one distinct variable
in the source code. The key of each subhash is the string index within
the source at which the variable was declared (or a unique negative number)
if the variable wasn't declared. Each subhash has the following structure:

    {
      decl_name      => '$name_and_sigil_with_which_the_variable_was_declared',
      sigil          => '$|@|%',
      aliases        => \%hash_of_any_known_aliases_for_the_variable,

      declarator     => "my|our|state|for|sub",
      declared_at    => $string_index_where_declared,
      used_at        => \%hash_of_indexes_within_source_string_where_variable_used,

      desc           => "text of any comment on the same line as the declaration",

      start_of_scope => $string_index_where_variable_came_into_scope,
      end_of_scope   => $string_index_where_variable_went_out_of_scope,
      scope_scale    => $fraction_of_the_complete_source_where_variable_is_in_scope,

      is_builtin     => $true_if_variable_is_a_standard_Perl_built_in,

      homograms      => \%hash_of_names_and_keys_of_other_variables_with_the_same_name,
      parograms      => \%hash_of_names_and_keys_of_other_variables_with_similar_names,
      is_cacogram    => $true_if_variable_name_is_pitifully_generic_and_uninformative,
    }

=back


=head2 Renaming a variable

To rename a variable throughout the source code, call the C<rename_variable()>
subroutine, which is exported by default.

The subroutine expects three arguments:

=over

=item *

The original source code (as a string),

=item *

A string index at which some usage of the variable is located
(i.e. a point in the source where a hypothetical cursor would be "over" the variable).

=item *

The new name of the variable.

=back

The subroutine returns a hash with a single entry:

    { source => $copy_of_source_string_with_the_variable_renamed }

If the specified string index does not cover a variable, a hash is
still returned, but with the single entry:

    { failed => "reason_for_failure" }


=head2 Vim integration

The module distribution includes a Vim plugin: F<vim/perlart.vim>

This plugin sets up a series of mappings that refactor or rename
code elements that have been visually selected or on which the
cursor is sitting.

For example, the <CTRL-S> mapping yanks the visual selection, refactors the
code into a subroutine, requests a name for the new subroutine, requests
a return value (if one seems needed), and then pastes the resulting
subroutine call over the original selected text.

The mapping also places the resulting subroutine definition code in the
unnamed register, as well as in register C<"s> (for "B<s>ubroutine"),
so that the definition is easy to paste back into your source somewhere.

The following Normal mode mappings re also available:

=over

=item <CTRL-N>

Rename the variable under the cursor.

=item <CTRL-S>

Search for all instances of the variable under the cursor.

B<I<WARNING>>: In some environments, C<CTRL-S> will suspend terminal
interactions. If your terminal locks up when you use this mapping,
hit C<CTRL-Q> to restart terminal interactions. In this case, 
you will need to either change the behaviour of C<CTRL-S> in
your terminal (for example:
L<https://coderwall.com/p/ltiqsq/disable-ctrl-s-and-ctrl-q-on-terminal>,
or L<https://stackoverflow.com/questions/3446320/in-vim-how-to-map-save-to-ctrl-s>),
or else change this mapping to something else.>

=item gd

Jump to the declaration of the variable under the cursor.

=item E<0x2a>

Jump to the next usage of the variable under the cursor.

=back

The following Visual mode mappings are also available:

=over

=item <CTRL-M>

Match all instances of the variable under the cursor.

=item <CTRL-H>

Hoist all instances of the visually selected code into a lexical variable.

=item <CTRL-C>

Hoist all instances of the visually selected code into a lexical closure.

=item <CTRL-R>

Refactor all instances of the visually selected code into a parameterized subroutine.

=item <CTRL-H><CTRL-H>

=item <CTRL-C><CTRL-C>

=item <CTRL-R><CTRL-R>

Same as the single-control-character versions above, but these only refactor
the code actually selected, rather than every equivalent instance throughout
the buffer.

=back


=head1 DIAGNOSTICS

The analysis and refactoring subroutines all return a hash, in all
cases. However, if any subroutine cannot perform its task (usually
because the code it has been given is invalid), then the returned hash
will contain the key 'failed', and the corresponding value will give a
reason for the failure (if possible).

The following failure messages may be encountered:

=over

=item C<< failed => 'invalid source code' >>

The code you passed in as the first argument could not be recognized
by PPR as a valid Perl.

There is a small chance this was caused by a bug in PPR,
but it's more likely that something was wrong with the code you passed in.


=item C<< failed => 'not a valid series of statements' >>

The subset of the code you asked C<refactor_to_sub()> to refactor
could not be recognized by PPR as a refactorable sequence of Perl statements.

Check whether you caught an extra unmatched opening or closing brace, or
started in the middle of a string.


=item C<< failed => 'the code has an internal return statement' >>

If the code you're trying to put into a subroutine contains a (conditional) return
statement anywhere but at the end of the fragment, then there's no way to refactor it
cleanly into another subroutine, because the internal return will return from the newly
refactored subroutine, I<not> from the place where you'll be replacing the original 
code with a call tothe newly refactored subroutine. So C<refactor_to_sub()> doesn't try.


=item C<< failed => "code has both a leading assignment and an explicit return" >>

If you're attempting to refactor a fragment of code that starts with the
rvalue of an assignment, and ends in a return, there's no way to put
both into a new subroutine and still have the previous behaviour of the 
original code preserved. So C<refactor_to_sub()> doesn't try.


=item C<< failed => "because the target code is not a simple expression" >>

Only simple expressions (not full statements) can be hoisted into a lexical
variable or closure. You tried to hoist something "bigger" than that.


=item C<< failed => "because there is no variable at the specified location" >>

You called C<classify_var_at()> but gave it a position in the source code
where there was no variable. If you're doing that from within some editor,
you may have an out-by-one error if the buffer positions you're detecting
and passing back to the module start at 1 instead of zero.


=item C<< failed => 'because the apparent variable is not actually a variable' >>

You called C<classify_var_at()> but gave it a position in the source code
where there was no variable. It I<looks> like there is a variable there,
but there isn't. Is the apparent variable actually in an uninterpolated
string, or a comment, or some POD, or after the C<__DATA__> or C<__END__>
marker?

=back

API errors are signalled by throwing an exception:

=over

=item C<< "%s argument of %s must be a %s" >>

You called the specified subroutine with the wrong kind of argument.
The error message will specify which argument and what kind of value it requires.

=item C<< "Unexpected extra argument passed to %s" >>

You called the specified subroutine with an extra unexpected argument.
Did you mean to put that argument in the subroutine's options hash instead?

=item C<< "Unknown option (%s) passed to %s" >>

You passed an unexpected named argument via the specified subroutine's
options hash. Did you misspell it, perhaps?

=back


=head1 CONFIGURATION AND ENVIRONMENT

Code::ART requires no configuration files or environment variables.


=head1 DEPENDENCIES

The PPR module (version 0.000027 or later)


=head1 INCOMPATIBILITIES

Because this module relies on the PPR module,
it will not run under Perl 5.20
(because regexes are broken in that version of Perl).


=head1 BUGS AND LIMITATIONS

These refactoring and analysis algorithms are not intelligent or
self-aware. They do not understand the code they are processing, and
especially not the purpose or intent of that code. They are merely
applying a set of heuristics (i.e. informed guessing) to try to
determine what you actually wanted the replacement code to do. Sometimes
they will guess wrong. Treat them as handy-but-dumb tools, not as
magical A.I. superfriends. Trust...but verify.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-code-art@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
