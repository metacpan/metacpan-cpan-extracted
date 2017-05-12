# @(#)yaccpar 1.8 (Berkeley) 01/20/91 (JAKE-P5BP-0.6 04/26/98)
package Parser;
#line 22 "./Parser.y"
package Carp::Datum::Parser;

use Carp::Datum::Flags;

BEGIN {

    sub TRUE ()  {1};
    sub FALSE () {0};
}

#line 14 "Parser.pm"
$FLAGS=257;
$DEFAULT=258;
$FILE=259;
$ROUTINE=260;
$USE=261;
$TYPE=262;
$ALIAS=263;
$STRING=264;
$T_WORD=265;
$T_NUM=266;
$FLOW=267;
$REQUIRE=268;
$ASSERT=269;
$ENSURE=270;
$RETURN=271;
$STACK=272;
$CLUSTER=273;
$PANIC=274;
$PROPAGATE=275;
$EXEC=276;
$TRACE=277;
$EMERGENCY=278;
$ALERT=279;
$CRITICAL=280;
$ERROR=281;
$AUTOMARK=282;
$INVARIANT=283;
$WARNING=284;
$NOTICE=285;
$INFO=286;
$DEBUG=287;
$TEST=288;
$DUMP=289;
$ALL=290;
$USR1=291;
$USR2=292;
$MEMORY=293;
$OBJECT=294;
$STATE=295;
$STARTUP=296;
$YES=297;
$NO=298;
$LEQ=299;
$GEQ=300;
$AS=301;
$ARGS=302;
$YYERRCODE=256;
@yylhs = (                                               -1,
    2,    0,    1,    1,    3,    3,    3,    3,    3,    3,
    3,    4,    5,    5,    6,    7,    8,   10,    9,   14,
   14,   14,   15,   15,   12,   12,   12,   16,   16,   16,
   16,   16,   18,   23,   23,   24,   24,   25,   25,   27,
   27,   27,   27,   26,   26,   26,   26,   26,   26,   26,
   26,   26,   19,   20,   29,   29,   21,   21,   30,   22,
   22,   28,   28,   28,   28,   28,   28,   28,   28,   17,
   17,   11,   13,   13,   31,
);
@yylen = (                                                2,
    0,    2,    0,    2,    1,    1,    1,    1,    1,    1,
    1,    5,    3,    4,    5,    5,    5,    5,    5,    0,
    1,    2,    2,    1,    0,    2,    3,    2,    1,    1,
    1,    1,    5,    0,    2,    1,    3,    1,    2,    1,
    1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
    1,    1,    4,    4,    1,    1,    1,    3,    4,    1,
    1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
    3,    1,    1,    3,    1,
);
@yydefred = (                                             1,
    0,    3,    0,    0,    0,    0,    0,    0,    0,    0,
    4,    5,    6,    7,    8,    9,   10,   11,   72,    0,
    0,    0,   75,    0,   73,    0,    0,    0,    0,    0,
    0,   63,   65,   66,   67,   64,   69,   68,    0,    0,
   62,    0,    0,    0,   29,   30,   31,   32,    0,    0,
   13,    0,    0,    0,    0,    0,    0,    0,   70,    0,
    0,    0,    0,   14,    0,   26,    0,    0,   24,    0,
   21,    0,   74,    0,    0,    0,    0,   12,    0,   60,
   61,    0,    0,   56,   55,    0,   27,    0,   58,   16,
   22,   23,   18,   19,   15,   17,   71,    0,   59,   54,
   53,    0,   33,   45,   46,   47,   48,   49,   50,   51,
   52,   44,   40,   41,   42,   43,    0,   36,   38,    0,
    0,   39,   37,
);
@yydgoto = (                                              1,
    3,    2,   11,   12,   13,   14,   15,   16,   17,   69,
   20,   43,   24,   70,   71,   44,   60,   45,   46,   47,
   48,   82,  103,  117,  118,  119,  120,   49,   86,   50,
   25,
);
@yysindex = (                                             0,
    0,    0, -156, -249, -116, -238, -238, -238, -236, -238,
    0,    0,    0,    0,    0,    0,    0,    0,    0,  -92,
 -224,  -24,    0,  -41,    0,  -40,  -39, -262,  -38, -224,
 -249,    0,    0,    0,    0,    0,    0,    0,    1,    2,
    0,    9,  -74,    3,    0,    0,    0,    0,   20,    5,
    0, -250, -238, -224, -250, -200, -224,  -26,    0,   21,
 -283, -283, -243,    0,    8,    0, -283, -196,    0, -124,
    0,   10,    0,   -9, -100,   12,   17,    0, -249,    0,
    0,   31,   33,    0,    0,   34,    0,   36,    0,    0,
    0,    0,    0,    0,    0,    0,    0,   22,    0,    0,
    0,  -60,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   35,    0,    0, -166,
  -60,    0,    0,
);
@yyrindex = (                                             0,
    0,    0,   81,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
  -36,    0,    0,    0,    0,    0,    0,    0,    0,  -36,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,   28,
    0,  -35,    0,  -36,  -35,    0,  -36,    0,    0,   32,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,   37,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   38,    0,    0,    0,
    0,    0,    0,
);
@yygindex = (                                             0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,   91,
    7,  -21,   49,   43,  -62,   18,    0,    0,    0,    0,
    0,  -33,    0,    0,  -16,  -20,    0,    0,    0,    0,
   55,
);
$YYTABLESIZE=319;
@yytable = (                                            116,
   90,  115,   53,   53,   53,   53,   21,   91,   58,    7,
   31,   22,   91,   80,   81,   19,   32,   33,   34,   35,
   36,   37,   84,   38,   94,   23,   39,   28,   83,   85,
   30,   40,   74,   88,   51,   77,   31,   59,   56,   41,
   61,   62,   32,   33,   34,   35,   36,   37,   63,   38,
   64,   42,   39,   80,   81,   26,   27,   40,   29,   67,
   65,   66,   68,   76,   79,   41,   87,   89,   92,   72,
   95,   98,   72,   99,  100,   65,  101,   42,  121,  102,
    2,   52,   54,   55,   57,   97,   57,   72,   25,   20,
   28,   65,   72,   18,   65,   34,   35,   75,   78,  122,
    4,    5,    6,    7,  123,    8,    9,   73,    0,    0,
    0,  104,  105,  106,  107,   93,   10,  108,  109,  110,
  111,    0,    0,  112,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    7,   31,    0,    0,    0,
    0,   96,   32,   33,   34,   35,   36,   37,   19,   38,
    0,    0,   39,    0,    0,    0,    0,   40,    0,    7,
   31,    0,    0,    0,    0,   41,   32,   33,   34,   35,
   36,   37,    0,   38,    0,    0,   39,   42,    0,    0,
    0,   40,    0,    0,    0,    0,   31,    0,    0,   41,
    0,    0,   32,   33,   34,   35,   36,   37,    0,   38,
    0,   42,   39,    0,    0,    0,    0,   40,    0,    0,
    0,    0,    0,    0,    0,   41,    0,  104,  105,  106,
  107,    0,    0,  108,  109,  110,  111,   42,    0,  112,
    0,    0,    0,    0,   31,    0,    0,    0,  113,  114,
   32,   33,   34,   35,   36,   37,    0,   38,    0,    0,
   39,   31,    0,    0,    0,   40,    0,   32,   33,   34,
   35,   36,   37,   41,   38,    0,    0,   39,    0,    0,
    0,    0,   40,    0,    0,   42,    0,   31,    0,    0,
   41,    0,    0,   32,   33,   34,   35,   36,   37,    0,
   38,    0,   42,   39,    0,    0,    0,    0,   40,    0,
    0,    0,    0,    0,    0,    0,   41,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   42,
);
@yycheck = (                                             60,
  125,   62,   44,   44,   44,   44,  123,   70,   30,  260,
  261,    5,   75,  297,  298,  265,  267,  268,  269,  270,
  271,  272,  266,  274,  125,  264,  277,  264,   62,   63,
  123,  282,   54,   67,   59,   57,  261,   31,  301,  290,
   40,   40,  267,  268,  269,  270,  271,  272,   40,  274,
  125,  302,  277,  297,  298,    7,    8,  282,   10,   40,
   43,   59,   58,  264,   44,  290,   59,  264,   59,   52,
   59,   41,   55,   41,   41,   58,   41,  302,   44,   58,
    0,  123,  123,  123,  123,   79,   59,   70,  125,  125,
   59,   74,   75,    3,   77,   59,   59,   55,  125,  120,
  257,  258,  259,  260,  121,  262,  263,   53,   -1,   -1,
   -1,  278,  279,  280,  281,  125,  273,  284,  285,  286,
  287,   -1,   -1,  290,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,  260,  261,   -1,   -1,   -1,
   -1,  125,  267,  268,  269,  270,  271,  272,  265,  274,
   -1,   -1,  277,   -1,   -1,   -1,   -1,  282,   -1,  260,
  261,   -1,   -1,   -1,   -1,  290,  267,  268,  269,  270,
  271,  272,   -1,  274,   -1,   -1,  277,  302,   -1,   -1,
   -1,  282,   -1,   -1,   -1,   -1,  261,   -1,   -1,  290,
   -1,   -1,  267,  268,  269,  270,  271,  272,   -1,  274,
   -1,  302,  277,   -1,   -1,   -1,   -1,  282,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,  290,   -1,  278,  279,  280,
  281,   -1,   -1,  284,  285,  286,  287,  302,   -1,  290,
   -1,   -1,   -1,   -1,  261,   -1,   -1,   -1,  299,  300,
  267,  268,  269,  270,  271,  272,   -1,  274,   -1,   -1,
  277,  261,   -1,   -1,   -1,  282,   -1,  267,  268,  269,
  270,  271,  272,  290,  274,   -1,   -1,  277,   -1,   -1,
   -1,   -1,  282,   -1,   -1,  302,   -1,  261,   -1,   -1,
  290,   -1,   -1,  267,  268,  269,  270,  271,  272,   -1,
  274,   -1,  302,  277,   -1,   -1,   -1,   -1,  282,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,  290,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,  302,
);
$YYFINAL=1;
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
$YYMAXTOKEN=302;
#if YYDEBUG
@yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','',"'('","')'",'','',"','",'','','','','','','','','','','','','',"':'","';'","'<'",'',
"'>'",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','',"'{'",'',"'}'",'','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'',"FLAGS","DEFAULT","FILE","ROUTINE","USE","TYPE","ALIAS","STRING","T_WORD",
"T_NUM","FLOW","REQUIRE","ASSERT","ENSURE","RETURN","STACK","CLUSTER","PANIC",
"PROPAGATE","EXEC","TRACE","EMERGENCY","ALERT","CRITICAL","ERROR","AUTOMARK",
"INVARIANT","WARNING","NOTICE","INFO","DEBUG","TEST","DUMP","ALL","USR1","USR2",
"MEMORY","OBJECT","STATE","STARTUP","YES","NO","LEQ","GEQ","AS","ARGS",
);
@yyrule = (
"\$accept : root",
"\$\$1 :",
"root :\$\$1 statements",
"statements :",
"statements : statements statement",
"statement : flags_definition",
"statement : default_setting",
"statement : alias_setting",
"statement : file_definition",
"statement : cluster_definition",
"statement : type_definition",
"statement : routine_definition",
"flags_definition : FLAGS ident '{' flags_list '}'",
"default_setting : DEFAULT ident ';'",
"default_setting : DEFAULT '{' flags_list '}'",
"alias_setting : ALIAS STRING AS STRING ';'",
"file_definition : FILE string_list '{' flags_or_routines_list '}'",
"cluster_definition : CLUSTER string_list '{' flags_list '}'",
"routine_definition : ROUTINE string_list '{' flags_list '}'",
"type_definition : TYPE string_list '{' flags_or_routines_list '}'",
"flags_or_routines_list :",
"flags_or_routines_list : flags_or_routines",
"flags_or_routines_list : flags_or_routines_list flags_or_routines",
"flags_or_routines : flags_spec ';'",
"flags_or_routines : routine_definition",
"flags_list :",
"flags_list : flags_spec ';'",
"flags_list : flags_list flags_spec ';'",
"flags_spec : USE ident_list",
"flags_spec : trace_spec",
"flags_spec : flag_spec",
"flags_spec : args_spec",
"flags_spec : automark_spec",
"trace_spec : TRACE '(' yes_or_no ')' trace_flags",
"trace_flags :",
"trace_flags : ':' trace_flag_list",
"trace_flag_list : trace_flag",
"trace_flag_list : trace_flag_list ',' trace_flag",
"trace_flag : trace_flag_token",
"trace_flag : cmp_tag trace_flag_token",
"cmp_tag : LEQ",
"cmp_tag : GEQ",
"cmp_tag : '>'",
"cmp_tag : '<'",
"trace_flag_token : ALL",
"trace_flag_token : EMERGENCY",
"trace_flag_token : ALERT",
"trace_flag_token : CRITICAL",
"trace_flag_token : ERROR",
"trace_flag_token : WARNING",
"trace_flag_token : NOTICE",
"trace_flag_token : INFO",
"trace_flag_token : DEBUG",
"flag_spec : flag '(' yes_or_no ')'",
"args_spec : ARGS '(' args_level ')'",
"args_level : yes_or_no",
"args_level : T_NUM",
"automark_spec : automark_flag",
"automark_spec : automark_flag ':' STRING",
"automark_flag : AUTOMARK '(' yes_or_no ')'",
"yes_or_no : YES",
"yes_or_no : NO",
"flag : ALL",
"flag : FLOW",
"flag : RETURN",
"flag : REQUIRE",
"flag : ASSERT",
"flag : ENSURE",
"flag : PANIC",
"flag : STACK",
"ident_list : ident",
"ident_list : ident_list ',' ident",
"ident : T_WORD",
"string_list : string",
"string_list : string_list ',' string",
"string : STRING",
);
#endif
sub yyclearin {
  my  $p;
  ($p) = @_;
  $p->{yychar} = -1;
}
sub yyerrok {
  my  $p;
  ($p) = @_;
  $p->{yyerrflag} = 0;
}
sub new {
  my $p = bless {}, $_[0];
  $p->{yylex} = $_[1];
  $p->{yyerror} = $_[2];
  $p->{yydebug} = $_[3];
  return $p;
}
sub YYERROR {
  my  $p;
  ($p) = @_;
  ++$p->{yynerrs};
  $p->yy_err_recover;
}
sub yy_err_recover {
  my  $p;
  ($p) = @_;
  if ($p->{yyerrflag} < 3)
  {
    $p->{yyerrflag} = 3;
    while (1)
    {
      if (($p->{yyn} = $yysindex[$p->{yyss}->[$p->{yyssp}]]) && 
          ($p->{yyn} += $YYERRCODE) >= 0 && 
          $p->{yyn} <= $#yycheck &&
          $yycheck[$p->{yyn}] == $YYERRCODE)
      {
        warn("yydebug: state " . 
                     $p->{yyss}->[$p->{yyssp}] . 
                     ", error recovery shifting to state" . 
                     $yytable[$p->{yyn}] . "\n") 
                       if $p->{yydebug};
        $p->{yyss}->[++$p->{yyssp}] = 
          $p->{yystate} = $yytable[$p->{yyn}];
        $p->{yyvs}->[++$p->{yyvsp}] = $p->{yylval};
        next yyloop;
      }
      else
      {
        warn("yydebug: error recovery discarding state ".
              $p->{yyss}->[$p->{yyssp}]. "\n") 
                if $p->{yydebug};
        return(undef) if $p->{yyssp} <= 0;
        --$p->{yyssp};
        --$p->{yyvsp};
      }
    }
  }
  else
  {
    return (undef) if $p->{yychar} == 0;
    if ($p->{yydebug})
    {
      $p->{yys} = '';
      if ($p->{yychar} <= $YYMAXTOKEN) { $p->{yys} = 
        $yyname[$p->{yychar}]; }
      if (!$p->{yys}) { $p->{yys} = 'illegal-symbol'; }
      warn("yydebug: state " . $p->{yystate} . 
                   ", error recovery discards " . 
                   "token " . $p->{yychar} . "(" . 
                   $p->{yys} . ")\n");
    }
    $p->{yychar} = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse {
  my  $p;
  my $s;
  ($p, $s) = @_;
  if ($p->{yys} = $ENV{'YYDEBUG'})
  {
    $p->{yydebug} = int($1) if $p->{yys} =~ /^(\d)/;
  }

  $p->{yynerrs} = 0;
  $p->{yyerrflag} = 0;
  $p->{yychar} = (-1);

  $p->{yyssp} = 0;
  $p->{yyvsp} = 0;
  $p->{yyss}->[$p->{yyssp}] = $p->{yystate} = 0;

yyloop: while(1)
  {
    yyreduce: {
      last yyreduce if ($p->{yyn} = $yydefred[$p->{yystate}]);
      if ($p->{yychar} < 0)
      {
        if ((($p->{yychar}, $p->{yylval}) = 
            &{$p->{yylex}}($s)) < 0) { $p->{yychar} = 0; }
        if ($p->{yydebug})
        {
          $p->{yys} = '';
          if ($p->{yychar} <= $#yyname) 
             { $p->{yys} = $yyname[$p->{yychar}]; }
          if (!$p->{yys}) { $p->{yys} = 'illegal-symbol'; };
          warn("yydebug: state " . $p->{yystate} . 
                       ", reading " . $p->{yychar} . " (" . 
                       $p->{yys} . ")\n");
        }
      }
      if (($p->{yyn} = $yysindex[$p->{yystate}]) && 
          ($p->{yyn} += $p->{yychar}) >= 0 && 
          $p->{yyn} <= $#yycheck &&
          $yycheck[$p->{yyn}] == $p->{yychar})
      {
        warn("yydebug: state " . $p->{yystate} . 
                     ", shifting to state " .
              $yytable[$p->{yyn}] . "\n") if $p->{yydebug};
        $p->{yyss}->[++$p->{yyssp}] = $p->{yystate} = 
          $yytable[$p->{yyn}];
        $p->{yyvs}->[++$p->{yyvsp}] = $p->{yylval};
        $p->{yychar} = (-1);
        --$p->{yyerrflag} if $p->{yyerrflag} > 0;
        next yyloop;
      }
      if (($p->{yyn} = $yyrindex[$p->{yystate}]) && 
          ($p->{yyn} += $p->{'yychar'}) >= 0 &&
          $p->{yyn} <= $#yycheck &&
          $yycheck[$p->{yyn}] == $p->{yychar})
      {
        $p->{yyn} = $yytable[$p->{yyn}];
        last yyreduce;
      }
      if (! $p->{yyerrflag}) {
        &{$p->{yyerror}}('syntax error', $s);
        ++$p->{yynerrs};
      }
      return(undef) if $p->yy_err_recover;
    } # yyreduce
    warn("yydebug: state " . $p->{yystate} . 
                 ", reducing by rule " . 
                 $p->{yyn} . " (" . $yyrule[$p->{yyn}] . 
                 ")\n") if $p->{yydebug};
    $p->{yym} = $yylen[$p->{yyn}];
    $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}+1-$p->{yym}];
if ($p->{yyn} == 1) {
#line 52 "./Parser.y"
{
                $expect = yy_top;

                # allocate the object that is gonna be returned
                $result = {};
            }
}
if ($p->{yyn} == 2) {
#line 59 "./Parser.y"
{
                $p->{yyval} = $result;
            }
}
if ($p->{yyn} == 11) {
#line 79 "./Parser.y"
{
                my $new = $p->{yyvs}->[$p->{yyvsp}-0];
                if (defined $result->{routine}) {
                    for my $key (keys %{$new}) {
                        $result->{routine}->{$key} = $new->{$key};
                    }
                }
                else {
                    $result->{routine} = $new;
                }
            }
}
if ($p->{yyn} == 12) {
#line 94 "./Parser.y"
{
                if ($p->{yyvs}->[$p->{yyvsp}-1] != 0) {
                    $result->{define}->{$p->{yyvs}->[$p->{yyvsp}-3]} = $p->{yyvs}->[$p->{yyvsp}-1];
                }
            }
}
if ($p->{yyn} == 13) {
#line 103 "./Parser.y"
{
                $result->{default} = {};
                if (defined $result->{define}->{$p->{yyvs}->[$p->{yyvsp}-1]}) {
                    merge_flag($result->{default},$result->{define}->{$p->{yyvs}->[$p->{yyvsp}-1]}); 
                }
            }
}
if ($p->{yyn} == 14) {
#line 110 "./Parser.y"
{
                if ($p->{yyvs}->[$p->{yyvsp}-1] != 0) {
                    $result->{default} = $p->{yyvs}->[$p->{yyvsp}-1];
                }
            }
}
if ($p->{yyn} == 15) {
#line 119 "./Parser.y"
{
                push @{$result->{alias}}, [$p->{yyvs}->[$p->{yyvsp}-3], $p->{yyvs}->[$p->{yyvsp}-1]];
            }
}
if ($p->{yyn} == 16) {
#line 126 "./Parser.y"
{
                if ($p->{yyvs}->[$p->{yyvsp}-1] != 0) {
                    for my $string (@{$p->{yyvs}->[$p->{yyvsp}-3]}) {
                        $result->{file}->{$string} = $p->{yyvs}->[$p->{yyvsp}-1];
                    }
                }
            }
}
if ($p->{yyn} == 17) {
#line 137 "./Parser.y"
{
                if ($p->{yyvs}->[$p->{yyvsp}-1] != 0) {
                    for my $string (@{$p->{yyvs}->[$p->{yyvsp}-3]}) {
                        $result->{cluster}->{$string}->{flags} = $p->{yyvs}->[$p->{yyvsp}-1];
                    }
                }
            }
}
if ($p->{yyn} == 18) {
#line 148 "./Parser.y"
{
                my $hash = {};
                if ($p->{yyvs}->[$p->{yyvsp}-1] != 0) {
                    for my $string (@{$p->{yyvs}->[$p->{yyvsp}-3]}) {
                        $hash->{$string}->{flags} = $p->{yyvs}->[$p->{yyvsp}-1];
                    }
                }
                $p->{yyval} = $hash;
           }
}
if ($p->{yyn} == 19) {
#line 161 "./Parser.y"
{
                if ($p->{yyvs}->[$p->{yyvsp}-1] != 0) {
                    for my $string (@{$p->{yyvs}->[$p->{yyvsp}-3]}) {
                        $result->{type}->{$string} = $p->{yyvs}->[$p->{yyvsp}-1];
                    }
                }
            }
}
if ($p->{yyn} == 20) {
#line 171 "./Parser.y"
{ $p->{yyval} = 0; }
}
if ($p->{yyn} == 21) {
#line 172 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 22) {
#line 174 "./Parser.y"
{
                my $current = $p->{yyvs}->[$p->{yyvsp}-1];
                my $new = $p->{yyvs}->[$p->{yyvsp}-0];

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

                $p->{yyval} = $current;
            }
}
if ($p->{yyn} == 23) {
#line 212 "./Parser.y"
{
                my $flag = {};

                $flag->{flags} = $p->{yyvs}->[$p->{yyvsp}-1];
                $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 24) {
#line 219 "./Parser.y"
{
                my $routine = {};

                $routine->{routine} = $p->{yyvs}->[$p->{yyvsp}-0];
                $p->{yyval} = $routine;
            }
}
if ($p->{yyn} == 25) {
#line 228 "./Parser.y"
{ $p->{yyval} = 0; }
}
if ($p->{yyn} == 26) {
#line 229 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-1]; }
}
if ($p->{yyn} == 27) {
#line 231 "./Parser.y"
{
                my $flag = $p->{yyvs}->[$p->{yyvsp}-2];
                my $new  = $p->{yyvs}->[$p->{yyvsp}-1];

                merge_flag($flag, $new);
                $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 28) {
#line 242 "./Parser.y"
{
                my $flag = {};

                for my $ident (@{$p->{yyvs}->[$p->{yyvsp}-0]}) {
                    if (defined $result->{define}->{$ident}) {
                        merge_flag($flag, $result->{define}->{$ident});
                    }
                }

                $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 29) {
#line 254 "./Parser.y"
{
               my $flag = {};
               $flag->{trace} = $p->{yyvs}->[$p->{yyvsp}-0];

               # If at least one trace flag is set, we need to activate
               # tracing. If no flag is set and all are clear, we deactivate
               # tracing alltogether.

               if ($flag->{trace}->[DTM_SET]) {
                   $flag->{debug} = [DBG_TRACE, 0];
               }
               elsif ($flag->{trace}->[DTM_CLEAR] == TRC_ALL) {
                   $flag->{debug} = [0, DBG_TRACE];
               }
               $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 30) {
#line 271 "./Parser.y"
{
               my $flag = {};
               $flag->{debug} = $p->{yyvs}->[$p->{yyvsp}-0];

               $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 31) {
#line 278 "./Parser.y"
{
               my $flag = {};
               $flag->{args} = $p->{yyvs}->[$p->{yyvsp}-0];

               $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 32) {
#line 285 "./Parser.y"
{
                ;
            }
}
if ($p->{yyn} == 33) {
#line 292 "./Parser.y"
{
                # create a new flag                
                $flag = [0, 0];
                if ($p->{yyvs}->[$p->{yyvsp}-2]) {
                    $flag->[DTM_SET] = $p->{yyvs}->[$p->{yyvsp}-0];
                }
                else {
                    $flag->[DTM_CLEAR] = $p->{yyvs}->[$p->{yyvsp}-0];
                }
                $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 34) {
#line 306 "./Parser.y"
{ $p->{yyval} = TRC_ALL; }
}
if ($p->{yyn} == 35) {
#line 307 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 36) {
#line 311 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 37) {
#line 312 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2] | $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 38) {
#line 317 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 39) {
#line 318 "./Parser.y"
{ $p->{yyval} = &{$p->{yyvs}->[$p->{yyvsp}-1]}($p->{yyvs}->[$p->{yyvsp}-0]); }
}
if ($p->{yyn} == 40) {
#line 322 "./Parser.y"
{ $p->{yyval} = \&less_or_equal; }
}
if ($p->{yyn} == 41) {
#line 323 "./Parser.y"
{ $p->{yyval} = \&greater_or_equal; }
}
if ($p->{yyn} == 42) {
#line 324 "./Parser.y"
{ $p->{yyval} = \&greater; }
}
if ($p->{yyn} == 43) {
#line 325 "./Parser.y"
{ $p->{yyval} = \&less; }
}
if ($p->{yyn} == 44) {
#line 329 "./Parser.y"
{ $p->{yyval} = TRC_ALL; }
}
if ($p->{yyn} == 45) {
#line 330 "./Parser.y"
{ $p->{yyval} = TRC_EMERGENCY; }
}
if ($p->{yyn} == 46) {
#line 331 "./Parser.y"
{ $p->{yyval} = TRC_ALERT; }
}
if ($p->{yyn} == 47) {
#line 332 "./Parser.y"
{ $p->{yyval} = TRC_CRITICAL; }
}
if ($p->{yyn} == 48) {
#line 333 "./Parser.y"
{ $p->{yyval} = TRC_ERROR; }
}
if ($p->{yyn} == 49) {
#line 334 "./Parser.y"
{ $p->{yyval} = TRC_WARNING; }
}
if ($p->{yyn} == 50) {
#line 335 "./Parser.y"
{ $p->{yyval} = TRC_NOTICE; }
}
if ($p->{yyn} == 51) {
#line 336 "./Parser.y"
{ $p->{yyval} = TRC_INFO; }
}
if ($p->{yyn} == 52) {
#line 337 "./Parser.y"
{ $p->{yyval} = TRC_DEBUG; }
}
if ($p->{yyn} == 53) {
#line 342 "./Parser.y"
{
                # create a new flag                
                $flag = [0, 0];
                if ($p->{yyvs}->[$p->{yyvsp}-1]) {
                    $flag->[DTM_SET] = $p->{yyvs}->[$p->{yyvsp}-3];
                }
                else {
                    $flag->[DTM_CLEAR] = $p->{yyvs}->[$p->{yyvsp}-3];
                }
                $p->{yyval} = $flag;
            }
}
if ($p->{yyn} == 54) {
#line 356 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-1]; }
}
if ($p->{yyn} == 55) {
#line 360 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0] ? -1 : 0; }
}
if ($p->{yyn} == 56) {
#line 361 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 57) {
#line 367 "./Parser.y"
{
                ;
            }
}
if ($p->{yyn} == 58) {
#line 371 "./Parser.y"
{
                ;
            }
}
if ($p->{yyn} == 59) {
#line 378 "./Parser.y"
{
                ;
            }
}
if ($p->{yyn} == 60) {
#line 384 "./Parser.y"
{ $p->{yyval} = TRUE; }
}
if ($p->{yyn} == 61) {
#line 385 "./Parser.y"
{ $p->{yyval} = FALSE; }
}
if ($p->{yyn} == 62) {
#line 389 "./Parser.y"
{ $p->{yyval} = DBG_ALL; }
}
if ($p->{yyn} == 63) {
#line 390 "./Parser.y"
{ $p->{yyval} = DBG_FLOW; }
}
if ($p->{yyn} == 64) {
#line 391 "./Parser.y"
{ $p->{yyval} = DBG_RETURN; }
}
if ($p->{yyn} == 65) {
#line 392 "./Parser.y"
{ $p->{yyval} = DBG_REQUIRE; }
}
if ($p->{yyn} == 66) {
#line 393 "./Parser.y"
{ $p->{yyval} = DBG_ASSERT; }
}
if ($p->{yyn} == 67) {
#line 394 "./Parser.y"
{ $p->{yyval} = DBG_ENSURE; }
}
if ($p->{yyn} == 68) {
#line 395 "./Parser.y"
{ $p->{yyval} = DBG_PANIC; }
}
if ($p->{yyn} == 69) {
#line 396 "./Parser.y"
{ $p->{yyval} = DBG_STACK; }
}
if ($p->{yyn} == 70) {
#line 400 "./Parser.y"
{ $p->{yyval} = [$p->{yyvs}->[$p->{yyvsp}-0]];}
}
if ($p->{yyn} == 71) {
#line 402 "./Parser.y"
{
                push @{$p->{yyvs}->[$p->{yyvsp}-2]}, $p->{yyvs}->[$p->{yyvsp}-0];
                $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2];
            }
}
if ($p->{yyn} == 72) {
#line 409 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 73) {
#line 413 "./Parser.y"
{ $p->{yyval} = [$p->{yyvs}->[$p->{yyvsp}-0]]; }
}
if ($p->{yyn} == 74) {
#line 415 "./Parser.y"
{
                push @{$p->{yyvs}->[$p->{yyvsp}-2]}, $p->{yyvs}->[$p->{yyvsp}-0];
                $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2];
            }
}
if ($p->{yyn} == 75) {
#line 422 "./Parser.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
#line 896 "Parser.pm"
    $p->{yyssp} -= $p->{yym};
    $p->{yystate} = $p->{yyss}->[$p->{yyssp}];
    $p->{yyvsp} -= $p->{yym};
    $p->{yym} = $yylhs[$p->{yyn}];
    if ($p->{yystate} == 0 && $p->{yym} == 0)
    {
      warn("yydebug: after reduction, shifting from state 0 ",
            "to state $YYFINAL\n") if $p->{yydebug};
      $p->{yystate} = $YYFINAL;
      $p->{yyss}->[++$p->{yyssp}] = $YYFINAL;
      $p->{yyvs}->[++$p->{yyvsp}] = $p->{yyval};
      if ($p->{yychar} < 0)
      {
        if ((($p->{yychar}, $p->{yylval}) = 
            &{$p->{yylex}}($s)) < 0) { $p->{yychar} = 0; }
        if ($p->{yydebug})
        {
          $p->{yys} = '';
          if ($p->{yychar} <= $#yyname) 
            { $p->{yys} = $yyname[$p->{yychar}]; }
          if (!$p->{yys}) { $p->{yys} = 'illegal-symbol'; }
          warn("yydebug: state $YYFINAL, reading " . 
               $p->{yychar} . " (" . $p->{yys} . ")\n");
        }
      }
      return ($p->{yyvs}->[1]) if $p->{yychar} == 0;
      next yyloop;
    }
    if (($p->{yyn} = $yygindex[$p->{yym}]) && 
        ($p->{yyn} += $p->{yystate}) >= 0 && 
        $p->{yyn} <= $#yycheck && 
        $yycheck[$p->{yyn}] == $p->{yystate})
    {
        $p->{yystate} = $yytable[$p->{yyn}];
    } else {
        $p->{yystate} = $yydgoto[$p->{yym}];
    }
    warn("yydebug: after reduction, shifting from state " . 
        $p->{yyss}->[$p->{yyssp}] . " to state " . 
        $p->{yystate} . "\n") if $p->{yydebug};
    $p->{yyss}[++$p->{yyssp}] = $p->{yystate};
    $p->{yyvs}[++$p->{yyvsp}] = $p->{yyval};
  } # yyloop
} # yyparse
#line 426 "./Parser.y"
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
#line 1267 "Parser.pm"
1;
