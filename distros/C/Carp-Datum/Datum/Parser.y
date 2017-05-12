/* -*- Mode: perl -*-
 *
 * $Id: Parser.y,v 0.1 2001/03/31 10:04:36 ram Exp $
 *
 *  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
 *  
 *  You may redistribute only under the terms of the Artistic License,
 *  as specified in the README file that comes with the distribution.
 *
 * HISTORY
 * $Log: Parser.y,v $
 * Revision 0.1  2001/03/31 10:04:36  ram
 * Baseline for first Alpha release.
 *
 * $EndLog$
 */

%{
package Carp::Datum::Parser;

use Carp::Datum::Flags;

BEGIN {

    sub TRUE ()  {1};
    sub FALSE () {0};
}

%}

%token FLAGS DEFAULT FILE ROUTINE USE TYPE ALIAS
%token STRING T_WORD T_NUM

%token FLOW REQUIRE ASSERT ENSURE RETURN STACK CLUSTER PANIC PROPAGATE
%token EXEC TRACE EMERGENCY ALERT CRITICAL ERROR 
%token AUTOMARK INVARIANT
%token WARNING NOTICE INFO DEBUG TEST DUMP ALL USR1 USR2
%token MEMORY OBJECT STATE STARTUP
%token YES NO LEQ GEQ AS
%token ARGS


%start root
%%


root
    :
            {
                $expect = yy_top;

                # allocate the object that is gonna be returned
                $result = {};
            }
        statements
            {
                $$ = $result;
            }
    ;

statements
    :    /* empty */
    |    statements statement
    ;

statement
    :    flags_definition
    |    default_setting
    |    alias_setting
    |    file_definition
    |    cluster_definition
    |    type_definition
    # routine_definition rule is shared. 
    # Its processing must not always modify the $result variable. 
    |    routine_definition
            {
                my $new = $1;
                if (defined $result->{routine}) {
                    for my $key (keys %{$new}) {
                        $result->{routine}->{$key} = $new->{$key};
                    }
                }
                else {
                    $result->{routine} = $new;
                }
            }
    ;

flags_definition
    :    FLAGS ident '{' flags_list '}'
            {
                if ($4 != 0) {
                    $result->{define}->{$2} = $4;
                }
            }
    ;

default_setting
    :    DEFAULT ident ';'
            {
                $result->{default} = {};
                if (defined $result->{define}->{$2}) {
                    merge_flag($result->{default},$result->{define}->{$2}); 
                }
            }
    |    DEFAULT '{' flags_list '}'
            {
                if ($3 != 0) {
                    $result->{default} = $3;
                }
            }
    ;

alias_setting
    :    ALIAS STRING AS STRING ';'
            {
                push @{$result->{alias}}, [$2, $4];
            }


file_definition
    :    FILE string_list '{' flags_or_routines_list '}'
            {
                if ($4 != 0) {
                    for my $string (@{$2}) {
                        $result->{file}->{$string} = $4;
                    }
                }
            }
    ;

cluster_definition
    :    CLUSTER string_list '{' flags_list '}'
            {
                if ($4 != 0) {
                    for my $string (@{$2}) {
                        $result->{cluster}->{$string}->{flags} = $4;
                    }
                }
            }
    ;

routine_definition
    :    ROUTINE string_list '{' flags_list '}'
            {
                my $hash = {};
                if ($4 != 0) {
                    for my $string (@{$2}) {
                        $hash->{$string}->{flags} = $4;
                    }
                }
                $$ = $hash;
           }
    ;

type_definition
    :    TYPE string_list '{' flags_or_routines_list '}'
            {
                if ($4 != 0) {
                    for my $string (@{$2}) {
                        $result->{type}->{$string} = $4;
                    }
                }
            }
    ;

flags_or_routines_list
    :    /* empty */                { $$ = 0; }
    |    flags_or_routines          { $$ = $1; }
    |    flags_or_routines_list flags_or_routines
            {
                my $current = $1;
                my $new = $2;

                #
                # If new node holds flags, merge them.
                #
                if (defined $new->{flags}) {
                    if (defined $current->{flags}) {
                        merge_flag($current->{flags}, $new->{flags});
                    }
                    else {
                        $current->{flags} = $new->{flags};
                    }
                }

                #
                # If new node holds routine, merge them.
                #
                if (defined $new->{routine}) {
                    if (defined $current->{routine}) {
                        for my $key (keys %{$new->{routine}}) {
                            $current->{routine}->{$key} = 
                              $new->{routine}->{$key};
                        }
                    }
                    else {
                        $current->{routine} = $new->{routine};
                    }
                }

                $$ = $current;
            }
    ;


flags_or_routines
    :    flags_spec ';'
            {
                my $flag = {};

                $flag->{flags} = $1;
                $$ = $flag;
            }
    |    routine_definition
            {
                my $routine = {};

                $routine->{routine} = $1;
                $$ = $routine;
            }
    ;

flags_list
    :    /* empty */                    { $$ = 0; }
    |    flags_spec ';'                 { $$ = $1; }
    |    flags_list flags_spec ';'
            {
                my $flag = $1;
                my $new  = $2;

                merge_flag($flag, $new);
                $$ = $flag;
            }
    ;

flags_spec
    :    USE ident_list
            {
                my $flag = {};

                for my $ident (@{$2}) {
                    if (defined $result->{define}->{$ident}) {
                        merge_flag($flag, $result->{define}->{$ident});
                    }
                }

                $$ = $flag;
            }
    |    trace_spec
           {
               my $flag = {};
               $flag->{trace} = $1;

               # If at least one trace flag is set, we need to activate
               # tracing. If no flag is set and all are clear, we deactivate
               # tracing alltogether.

               if ($flag->{trace}->[DTM_SET]) {
                   $flag->{debug} = [DBG_TRACE, 0];
               }
               elsif ($flag->{trace}->[DTM_CLEAR] == TRC_ALL) {
                   $flag->{debug} = [0, DBG_TRACE];
               }
               $$ = $flag;
            }
    |    flag_spec
            {
               my $flag = {};
               $flag->{debug} = $1;

               $$ = $flag;
            }
    |    args_spec
            {
               my $flag = {};
               $flag->{args} = $1;

               $$ = $flag;
            }
    |    automark_spec
            {
                ;
            }
    ;

trace_spec
    :    TRACE '(' yes_or_no ')' trace_flags
            {
                # create a new flag                
                $flag = [0, 0];
                if ($3) {
                    $flag->[DTM_SET] = $5;
                }
                else {
                    $flag->[DTM_CLEAR] = $5;
                }
                $$ = $flag;
            }
    ;

trace_flags
    :    /* empty */                            { $$ = TRC_ALL; }
    |    ':' trace_flag_list                    { $$ = $2; }
    ;

trace_flag_list
    :    trace_flag                            { $$ = $1; }
    |    trace_flag_list ',' trace_flag        { $$ = $1 | $3; }
    ;


trace_flag
    : trace_flag_token         { $$ = $1; }
    | cmp_tag trace_flag_token    { $$ = &{$1}($2); } 
    ;

cmp_tag
    : LEQ { $$ = \&less_or_equal; }
    | GEQ { $$ = \&greater_or_equal; }
    | '>' { $$ = \&greater; }
    | '<' { $$ = \&less; }
    ;
    
trace_flag_token
    :    ALL                    { $$ = TRC_ALL; }
    |    EMERGENCY              { $$ = TRC_EMERGENCY; }
    |    ALERT                  { $$ = TRC_ALERT; }
    |    CRITICAL               { $$ = TRC_CRITICAL; }
    |    ERROR                  { $$ = TRC_ERROR; }
    |    WARNING                { $$ = TRC_WARNING; };
    |    NOTICE                 { $$ = TRC_NOTICE; }
    |    INFO                   { $$ = TRC_INFO; }
    |    DEBUG                  { $$ = TRC_DEBUG; }
    ;

flag_spec
    :    flag '(' yes_or_no ')'
            {
                # create a new flag                
                $flag = [0, 0];
                if ($3) {
                    $flag->[DTM_SET] = $1;
                }
                else {
                    $flag->[DTM_CLEAR] = $1;
                }
                $$ = $flag;
            }
    ;

args_spec
    :    ARGS '(' args_level ')'   { $$ = $3; }
    ;

args_level
    :    yes_or_no                 { $$ = $1 ? -1 : 0; }
    |    T_NUM                     { $$ = $1; }
    ;
             
      
automark_spec
    :    automark_flag
            {
                ;
            }
    |    automark_flag ':' STRING
            {
                ;
            }
    ;

automark_flag
    :    AUTOMARK '(' yes_or_no ')'
            {
                ;
            }
    ;

yes_or_no
    :    YES                    { $$ = TRUE; }
    |    NO                     { $$ = FALSE; }
    ;

flag
    :    ALL                    { $$ = DBG_ALL; }
    |    FLOW                   { $$ = DBG_FLOW; }
    |    RETURN                 { $$ = DBG_RETURN; }
    |    REQUIRE                { $$ = DBG_REQUIRE; }
    |    ASSERT                 { $$ = DBG_ASSERT; }
    |    ENSURE                 { $$ = DBG_ENSURE; }
    |    PANIC                  { $$ = DBG_PANIC; }
    |    STACK                  { $$ = DBG_STACK; }
    ;

ident_list
    :    ident                        { $$ = [$1];}
    |    ident_list ',' ident
            {
                push @{$1}, $3;
                $$ = $1;
            }
    ;

ident
    :    T_WORD                { $$ = $1; }
    ;

string_list
    :    string                        { $$ = [$1]; }
    |    string_list ',' string
            {
                push @{$1}, $3;
                $$ = $1;
            }
    ;

string
    :    STRING                { $$ = $1; }
    ;

%%
# Print semantic error
sub yywrong {
    my ($msg) = @_;
    print STDERR "file $file, line $yylineno: ERROR: $msg\n";
    #confess "trace:\n";
    yyerror("syntax error");
}

# Print warning
sub yywarn {
    my ($msg) = @_;
    print STDERR "file $file line $yylineno: WARNING: $msg\n";
}

# Print warning without line number
sub yytell {
    my ($msg) = @_;
    print STDERR "WARNING: $msg\n";
}

sub yy_lineno {
    $yylineno += $yylval =~ tr/\n/\n/;
}

# Print parsing error, trying to give at least next two tokens
sub yyerror {
    my ($msg) = @_;
    my ($near) = /^\s*(\S+[ \t]*\w*)/;
    ($near) = /^\s*(\w+[ \t]*\w*)/ if $near eq '';
    $near =~ tr/\n\t/  /;
    $near =~ tr/ //s;
    $near =~ s/\s*$//;
    print STDERR "$msg at line $yylineno in file $file";
    my ($after) = $yylast =~ /(\w+\s+\w+)$/;
    ($after) = $yylast =~/(\S+\s*\w+)$/ if $after eq '';
    ($after) = $yylast =~/(\S+)$/ if $after eq '';
    print STDERR " after \"$after\"" unless $after eq '';
    print STDERR " near \"$near\"" unless $near eq '';
    print STDERR "\n";
    die "Abort processing\n";
}

sub yy_top {
    &yy_comment if m!/(/|\*)!;     # Discard comments
      my $kw;
    return $kw if defined ($kw = &yy_keyword);
    return &yy_dflt;
}

sub yy_skip {
    my $in_comment = 0;
    $yylval = "";
    
    while ($_ ne '') {
        
        if (!$in_comment) {
            my $sp = "";

            if ($skip_mode == 0) { # leave what matches for next turn
                if (s/^(\s*)($skip_to)/$2/) {
                    $yylval .= $1;

                    $sp = $yylval;
                    $sl = $sp =~ tr/\n/\n/;    # Count newlines seen
                    $yylineno += $sl;    # Keep track of line number

                    return $K_FIND;
                }
            }
            elsif (s/^(\s*)($skip_to)//) {
                $yylval .= $1;

                $sp = $yylval;
                $sl = $sp =~ tr/\n/\n/;    # Count newlines seen
                $yylineno += $sl;    # Keep track of line number
                
                return $K_FIND;
            }
        }
        
        # skip comment
        if (s/^(\/\*)//) {
            $in_comment = 1;
            $yylval .= $1;
        }
        if (s/^(.*\*\/)//) {
            $in_comment = 0;
            $yylval .= $1;
        }
        
        
        s/^(.*)//;
        $yylval .= $1;
        s/^(\s*)//;
        $yylval .= $1;
    }
    
    return 0;    # Should not reach that point, but if we do...
    
}


# Strip comment on current lines and subsequent ones, updating $yylineno
# This takes care of comments appearing within lexical parts, whilst global
# ones starting at the beginning of a line are taken care of by &yylex.
# The routine handles both // and /* */ comments.
sub yy_comment {
    while (s!^(//.*)!! || s!^(/\*(?:.|\n)*?\*/)!!) {
        my $com = $1;
        print "yylex: tokener stripped '$com' at line $yylineno\n" if $yydebug;
        $yylineno += $com =~ tr/\n/\n/;        # Count lines
        s/^(\s*)//;
        my $sl = $1;
        $yylineno += $sl =~ tr/\n/\n/;        # Count lines
    }
}

sub yy_keyword {


    %Keyword = (
                'alert'        => $ALERT,
                'alias'        => $ALIAS,
                'all'          => $ALL,
                'args'         => $ARGS,
                'assert'       => $ASSERT,
                'automark'     => $AUTOMARK,
                'cluster'      => $CLUSTER,
                'critical'     => $CRITICAL,
                'debug'        => $DEBUG,
                'default'      => $DEFAULT,
                'dump'         => $DUMP,
                'error'        => $ERROR,
                'emergency'    => $EMERGENCY,
                'ensure'       => $ENSURE,
                'exec'         => $EXEC,
                'file'         => $FILE,
                'flags'        => $FLAGS,
                'flow'         => $FLOW,
                'info'         => $INFO,
                'memory'       => $MEMORY,
                'no'           => $NO,
                'notice'       => $NOTICE,
                'object'       => $OBJECT,
                'panic'        => $PANIC,
                'propagate'    => $PROPAGATE,
                'require'      => $REQUIRE,
                'return'       => $RETURN,
                'routine'      => $ROUTINE,
                'severe'       => $SEVERE,
                'stack'        => $STACK,
                'startup'      => $STARTUP,
                'state'        => $STATE,
                'test'         => $TEST,
                'trace'        => $TRACE,
                'type'         => $TYPE,
                'use'          => $USE,
                'usr1'         => $USR1,
                'usr2'         => $USR2,
                'warning'      => $WARNING,
                'yes'          => $YES
               ) unless defined %Keyword;
    return undef unless /^(\w+)/ && exists $Keyword{$1};
    my $word = $1;
    s/^\w+//;
    $yylval = $word;
    return $Keyword{$word};
}

sub yy_dflt {
    &yy_comment if m!/(/|\*)!;     # Discard comments
    
    if (s/^(>=)//) { return $GEQ; }
    if (s/^(<=)//) { return $LEQ; }
    if (s/^(=>)//) { return $AS; }

    # Characters standing for themselves
    if (s/^([{}!<>:=;,()\[\]])//) {
        return $yylval = ord($1);
    }
    
    # Handle special tokens
    if (s/^(\*)//)             { $yylval = $1; return $T_POINTER  }
    
    # handle string
    if (s/^\"(.*?)\"//)        { $yylval = $1; return $STRING;  }

    # Handle numbers
    if (s/^(0\d+)\b//)         { $yylval = oct($1); return $T_NUM;  }
    if (s/^(0b[01]+)\b//i)     { $yylval = bin($1); return $T_NUM }
    if (s/^(0x[\da-f]+)\b//i)  { $yylval = hex($1); return $T_NUM }
    if (s/^(\d+)\b//)          { $yylval = int($1); return $T_NUM }
    
    # Words
    if (s/^(\w+)//)            { $yylval = $1; return $T_WORD }
    
    # Default action: return whatever character we are facing
    s/^(.)// and return $yylval = ord($1);
    
    return 0;    # Should not reach that point, but if we do...
}

# Lexical parser of the $_ string, along with line count tracking. In order
# to simplify processing of lines, the parsed string must have a leading
# new-line prepended to it before firing off the gramatical analysis.
sub yylex {
    my $sp = '';        # Amount of spaces stripped of
    my $sl = 0;            # True if at the start of a line
    
    if ($expect ne "yy_skip") {
        for (;;) {
            s/^(\s*)// and $sp = $1;          # Spaces are not significant
            $sl = $sp =~ tr/\n/\n/;           # Count newlines seen
            $yylineno += $sl;                 # Keep track of line number
            next if $sl && s|^\s*\//.*\n|\n|;  # Skip comments
            last;
        }
    }
    
    if ($yydebug) {
        my ($trace) = /^((?:.*)\n*(?:.*)\n*)/m;    # Next two lines at most
          my $more = length($trace) < length($_) ? "...more...\n" : '';
        $trace =~ tr/\n/\n/s;            # Avoid succession of new-lines
          print "yylex: [line $yylineno] $trace$more";
        print "yylex: calling $expect\n";
    }
    
    my $ret = $_ ne '' ? &$expect : 0;    # 0 signals EOF to yyparse
    
    # Remember last read token for yyerror. Dont forget that it might be
    # an ASCII number and convert it back to a char in that case...
    $yylast = $yylval eq $ret ? chr($yylval) : $yylval;
    $yylast = '<EOF>' unless $ret;
    
    print "yylex: tokener read '$yylast'\n" if $yydebug;
    return ($ret, $yylval);
}

sub init_parser {
    my ($p) = shift;
    $file = shift;    # for error message and to store in attribute card info
    $yylineno = 0;
}


#################################################################
#
# Routines usefull during the parsing
#
#################################################################

#
# -> merge_flag
#

sub merge_flag {
    my ($flag, $new) = @_;
    
    # merge the debug
    unless (defined $flag->{debug}) {
        $flag->{debug} = [0, 0];
    }
    
    if (defined $new->{debug}) {
        
        my $set = ($flag->{debug}->[DTM_SET] &
                   ~$new->{debug}->[DTM_CLEAR]) |
                     $new->{debug}->[DTM_SET];
        my $clear = ($flag->{debug}->[DTM_CLEAR] & 
                     ~$new->{debug}->[DTM_SET]) |
                       $new->{debug}->[DTM_CLEAR];
        
        $flag->{debug}->[DTM_SET] = $set;
        $flag->{debug}->[DTM_CLEAR] = $clear;
    }
    
    # merge the trace
    unless (defined $flag->{trace}) {
        $flag->{trace} = [0, 0];
    }
    
    if (defined $new->{trace}) {
        
        my $set = ($flag->{trace}->[DTM_SET] &
                   ~$new->{trace}->[DTM_CLEAR]) |
                     $new->{trace}->[DTM_SET];
        my $clear = ($flag->{trace}->[DTM_CLEAR] & 
                     ~$new->{trace}->[DTM_SET]) |
                       $new->{trace}->[DTM_CLEAR];
        
        $flag->{trace}->[DTM_SET] = $set;
        $flag->{trace}->[DTM_CLEAR] = $clear;
    }

    # merge args level
    unless (defined $flag->{args}) {
        $flag->{args} = -1;
    }
    
    if (defined $new->{args}) {
        $flag->{args} = $new->{args};
    }
}


sub less {
    my $flag = shift;
    return ($flag - 1);
}

sub less_or_equal {
    my $flag = shift;
    return less($flag) | $flag;
}

sub greater {
    return ~(less_or_equal(@_));
}

sub greater_or_equal {
    my $flag = shift;
    return greater_or_equal($flag) | $flag;
}

1;
