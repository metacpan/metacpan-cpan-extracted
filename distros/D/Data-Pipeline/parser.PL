#!/usr/local/bin/perl

eval 'exec /usr/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
#
# yapp -- Front end to the Parse::Yapp module
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#
#

# converted to handle the Pipeline parser so we don't depend on install
# paths for scrips

require 5.004;

use File::Basename;
use Getopt::Std;
use Config;

BEGIN {
    eval "require Parse::Yapp;";
    if($@) {
        warn "You will need to install Parse::Yapp before you can regenerate\nthe Pipeline parser.\n";
        exit 0;
    }
}

use strict;

use vars qw ( $opt_n $opt_m $opt_V $opt_v $opt_o $opt_h $opt_s $opt_t $opt_b);

sub Usage {
	my($prog)=(fileparse($0,'\..*'))[0];
	die <<EOF;

Usage:	$prog [options] grammar[.yp]
  or	$prog -V
  or	$prog -h

    -m module   Give your parser module the name <module>
                default is <grammar>
    -v          Create a file <grammar>.output describing your parser
    -s          Create a standalone module in which the driver is included
    -n          Disable source file line numbering embedded in your parser
    -o outfile  Create the file <outfile> for your parser module
                Default is <grammar>.pm or, if -m A::Module::Name is
                specified, Name.pm
    -t filename Uses the file <filename> as a template for creating the parser
                module file.  Default is to use internal template defined
                in Parse::Yapp::Output
    -b shebang  Adds '#!<shebang>' as the very first line of the output file

    grammar     The grammar file. If no suffix is given, and the file
                does not exists, .yp is added

    -V          Display current version of Parse::Yapp and gracefully exits
    -h          Display this help screen

EOF
}

$opt_o = 'lib/Data/Pipeline/Parser.pm';
$opt_s = 1;
$opt_m = 'Data::Pipeline::Parser';
$opt_v = 1;


my($nbargs)=@ARGV;

#	getopts('Vhvsnb:m:t:o:')
#or	Usage;
#
#   (  ($opt_V and $nbargs > 1)
#    or $opt_h)
#and Usage;
#
#	$opt_V
#and do {
#
#    @ARGV == 0 or  Usage;
#
#    print "This is Parse::Yapp version $Parse::Yapp::Driver::VERSION.\n";
#    exit(0);
#
#};


# -t <filename> ($opt_t) option allows a file to be specified which 
# contains a 'template' to be used when generating the parser; 
# if defined, we open and read the file.   

#	$opt_t
#and do {
#    local $/ = undef;
#    local *TFILE;
#    open(TFILE, $opt_t)
#	or die "Cannot open template file $opt_t: $!\n";
#    $opt_t = <TFILE>;
#    close(TFILE);
#};

#    @ARGV == 1
#or  Usage;

#my($filename)=$ARGV[0];
my($filename)='parser.yp';
my($base,$path,$sfx)=fileparse($filename,'\..*');

#	-r "$filename"
#or	do {
#		$sfx eq '.yp'
#	or	$filename.='.yp';
#
#		-r "$filename"
#	or	die "Cannot open $filename for reading.\n";
#};

my $input;
{ local($/) = undef;
  $input = <DATA>;
}

#my($parser)=new Parse::Yapp(inputfile => $filename);
my($parser)=new Parse::Yapp(input => $input);

my($warnings)=$parser->Warnings();

	$warnings
and	print STDERR $warnings;

	$opt_v
and	do {
	my($output)="$path$base.output";
	my($tmp);

		open(OUT,">$output")
	or	die "Cannot create $base.output for writing.\n";

		$tmp=$parser->Warnings()
	and	print	OUT "Warnings:\n---------\n$tmp\n";
		$tmp=$parser->Conflicts()
	and	print	OUT "Conflicts:\n----------\n$tmp\n";
	print	OUT "Rules:\n------\n";
	print	OUT $parser->ShowRules()."\n";
	print	OUT "States:\n-------\n";
	print	OUT $parser->ShowDfa()."\n";
	print	OUT "Summary:\n--------\n";
	print	OUT $parser->Summary();

	close(OUT);
};

my($outfile)="$path$base.pm";
my($package)="$base";

	$opt_m
and	do {
    $package=$opt_m;
    $package=~/^(?:(?:[^:]|:(?!:))*::)*(.*)$/;
    $outfile="$1.pm";
};

	$opt_o
and	$outfile=$opt_o;

$opt_s = $opt_s ? 1 : 0;

$opt_n = $opt_n ? 0 : 1;

	open(OUT,">$outfile")
or	die "Cannot open $outfile for writing.\n";

    defined($opt_b)
and do {
        $opt_b
    or  $opt_b = $Config{perlpath};
    print OUT "#!$opt_b\n";
};

print OUT $parser->Output(classname  => $package,
                          standalone => $opt_s,
                          linenumbers => $opt_n,
                          template    => $opt_t,
                         );


close(OUT);
__END__

%{
=head1

Data::Pipeline::Parser - DSL for pipelines

=head1 DESCRIPTION

=cut
%}

%token QNAME
%token LITERAL
%token NUMBER
%token POS_INTEGER
%token NEG_INTEGER
%token TRUE
%token FALSE

%left ARROW
%token COLON
%left COLON_COLON
%right SLASH_SLASH
%token QR
%token QW
%token S
%token TR
%token LC
%token RC
%token LB
%token RB
%token TO_DONE
%token TILDE

%token PIPELINE
%token DOES
%token IN
%token ORDER
%token DONE
%token MACHINE
%token STDOUT
%token STDIN
%token FILE
%token MAPPING
%token REDUCTION

%start program

%%

program:
   program_segment 
   | program program_segment { my($a, $b) = @_[1,2]; 
        sub { $a -> (); $b -> () }
   }
   ;

program_segment:
   body { my($body) = $_[1];
        sub {
              $_ -> () for @{$body -> [0]};
              $_ -> () for @{$body -> [1]};
            }
   }
   | machine 
   ;

machine:
   MACHINE machine_name DOES COLON body DONE {
       # evaluate body in the context of the named machine
       print "MACHINE machine_name DOES COLON body DONE\n";
       my($p, $m, $body) = @_[0,2,5];
       sub { $p -> _eval_in_m($m, sub {
           $_ -> () for @{$body -> [0]};
           $_ -> () for @{$body -> [1]};
       }) };
   }
   ;

machine_name: /* no sub returned */
   QNAME { $_[1] }
   | machine_name COLON_COLON QNAME { $_[1] . '::' . $_[3] }
   ;

body:
   /* empty */ { [ [], [] ] }
   | body decl_stmt { my($b, $d) = @_[1,2];
       [ [ @{$b->[0]}, $d ], $b->[1] ]
   }
   | body pipeline_def { my($b, $p) = @_[1,2];
       [ $b->[0], [ @{$b->[1]}, $p ] ]
   }
   ;

decl_stmt:
   let_stmt 
   | use_stmt
   | import_stmt
   | io_stmt
   | filter_def
   ;

qname_list:
   QNAME { [ $_[1] ] }
   | qname_list QNAME { [ @{$_[1]}, $_[2] ] }
   ;

opt_qname:
   /* empty */
   | qname
   ;

integer:
   POS_INTEGER
   | NEG_INTEGER 
   ;

string_literal:
    LITERAL { my $l = $_[1]; sub { $l } }
    | DOLLAR_QNAME { my($p, $v) = @_[0,1]; 
          sub { $p -> _e -> {vars} -> {$v} }
    }
    | DOLLAR_QNAME SLASH_SLASH const_action_expr { my($p, $v, $d) = @_[0,1,3]; 
          sub {
              defined($p -> _e -> {vars} -> {$v})
              ? $p -> _e -> {vars} -> {$v}
              : $d -> ()
          }
    }
    ;

string:
    string_literal { $_[1] }
    | string TILDE string_literal { my($l, $r) = @_[1,3]; sub {  $l->() . $r -> () } }
    ;


literal:
   string { $_[1] }
   | NUMBER { my $s = $_[1]; sub { $s } }
   | integer { my $s = $_[1]; sub { $s } }
   | QR REGEX { my $s = $_[2];  sub { qr/$s/ } }
   | S REGEX { my($l,$r) = @{$_[2]}; 
            $l =~ s[([^\\]){][$1\\{]g; 
            $l =~ s[([^\\])}][$1\\}]g; 
            $r =~ s[([^\\]){][$1\\{]g; 
            $r =~ s[([^\\])}][$1\\}]g; 
            sub { eval "sub { s{$l}{$r}gs }" }
    }
   | TR REGEX { my($l,$r) = @{$_[2]}; 
            $l =~ s[([^\\]){][$1\\{]g; 
            $l =~ s[([^\\])}][$1\\}]g; 
            $r =~ s[([^\\]){][$1\\{]g; 
            $r =~ s[([^\\])}][$1\\}]g; 
            sub { eval "sub { tr{$l}{$r} }" }
    }
   | TRUE { sub { 1 } }
   | FALSE { sub { 0 } }
   | perl_method { $_[1] }
   | LP literal RP { $_[2] }
   ;

in_file:
   STDIN { sub { \*STDIN } }
   | FILE string { my $fname = $_[2]; sub { my $fn = $fname -> (); print "opening $fn\n"; open my $fh, "<", ($fn); print "fh: $fh\n"; $fh } }
   | FILE DOLLAR_QNAME SLASH_SLASH STDIN { my($p, $v) = @_[0,2];
       sub {
           if(defined($p -> _e -> {vars} -> {$v})) {
               my $fname = $p -> _e -> {vars} -> {$v};
               open my $fh, "<", ($fname);
               return $fh;
           }
           return \*STDIN;
       }
   }
   ;

out_file:
   STDOUT { sub { \*STDOUT } }
   | FILE string { my $fname = $_[2]; sub { open my $fh, ">", ($fname -> ()); $fh } }
   | FILE DOLLAR_QNAME SLASH_SLASH STDOUT { my($p, $v) = @_[0,2];
       sub {
           if(defined($p -> _e -> {vars} -> {$v})) {
               my $fname = $p -> _e -> {vars} -> {$v};
               open my $fh, ">", ($fname);
               return $fh;
           }
           return \*STDOUT;
       }
   }
   ;

perl_method:
   perl_class {
        my($p, $class, $method) = (@_[0,1], 'new');
        sub {
            $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
            $class -> can($method) or die "Unable to find '$method' for '$class'\n";

            $class -> $method(); 
       }
   }
   | perl_class DOES COLON action_args DONE {
        my($p, $class, $method, $args) = ($_[0], $_[1], 'new', $_[4]);
        sub {
            $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
            $class -> can($method) or die "Unable to find '$method' for '$class'\n";
            $class -> $method(%{$args -> ()});
       }
   }
   | perl_class does_in_order COLON ordered_action_args DONE {
        my($p, $class, $method, $args) = ($_[0], $_[1], 'new', $_[4]);
        sub {
            $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
            $class -> can($method) or die "Unable to find '$method' for '$class'\n";
            $class -> $method(@{$args->()});  
       }
   }
   | perl_class DOES QNAME { 
         my($p, $class, $method) = (@_[0,1,3]);
         sub {
             $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
             $class -> can($method) or die "Unable to find '$method' for '$class'\n";

             $class -> $method();  
        }
   }
   | perl_class DOES QNAME COLON action_args DONE { 
         my($p, $class, $method, $args) = (@_[0,1,3,5]);
         sub {
             $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
             $class -> can($method) or die "Unable to find '$method' for '$class'\n";
             $class -> $method(%{$args->()})  
        }
   }
   | perl_class DOES QNAME IN ORDER COLON ordered_action_args DONE { 
         my($p, $class, $method, $args) = (@_[0,1,3,7]);
         sub {
             $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
             $class -> can($method) or die "Unable to find '$method' for '$class'\n";
             $class-> $method(@{$args -> ()}); 
        }
   }
   ;

let_stmt:
   LET QNAME COLON literal { 
           my($p, $var, $val) = @_[0,2,4];
           sub { $p -> _vars -> {$var} = $val -> (); }
       }
   | LET QNAME COLON       { 
           my($p, $var) = @_[0,2];
           sub { $p -> _vars -> {$var} = undef; }
       }
   ;

use_stmt:
   USE COLON qname_list {
           my($p, $list) = @_[0,3];
           sub { $p -> load_actions("Action", @{$list}); }
       }
   | IN COLON qname_list {
           my($p, $list) = @_[0,3];
           sub { $p -> load_actions("Adapter", @{$list}); }
       }
   | OUT COLON qname_list {
           my($p, $list) = @_[0,3];
           sub { $p -> load_actions("Adapter", @{$list}); }
       }
   ;

import_stmt:
   IMPORT COLON perl_class_list {
        my($p,$list) = @_[0,3];
        sub {
            my $loaded = $p -> _perl_classes;
            foreach my $class (@{$list}) {
                next if $loaded->{$class};
                eval "require $class";
                if($@) {
                    warn "Unable to import '$class'\n";
                }
                else {
                    $loaded->{$class}++;
                }
            }
        }
    }
    ;
            
io_stmt:
    TO COLON action_arg {
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {to} = [ %{$v -> ()} ] }
    }
    | TO COLON out_file {
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {to} = [ $v -> () ] }
    }
    | TO DOES COLON action_args DONE {
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {to} = [ %{$v -> ()} ] }
    }
    | TO does_in_order COLON ordered_action_args DONE {
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {to} = $v -> () }
    }
    | FROM COLON in_action_arg {
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {from} = [ %{$v -> ()} ] }
    }
    | FROM COLON in_file {
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {from} = [ $v -> () ] }
    }
    | FROM DOES COLON in_action_args DONE {
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {from} = [ %{$v -> ()} ] }
    }
    | FROM does_in_order COLON ordered_in_action_args DONE {
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {from} = $v -> () }
    }
    ;

#
# TODO: allow filters to be defined using other languages such as XSLT or LUA
#

filter_type:
    MAPPING { 'any' }
    | REDUCTION { 'all' }
    ;

filter_def:
    filter_type QNAME USING QNAME DOES COLON { 
        $_[0] -> in_freeform_until_done; 
        [ @_[2,4,1] ]
    } TO_DONE DONE { 
        my($p,$info, $code) = @_[0,7,8];
        sub { $p -> compile_ext_lang(@$info, $code) }
    }
    ;

perl_class:
    QNAME COLON_COLON QNAME { $_[1] . '::' . $_[3] }
    | perl_class COLON_COLON QNAME { $_[1] . '::' . $_[3] }
    ;

perl_class_list:
    perl_class { [ $_[1] ] }
    | perl_class_list perl_class { [ @{$_[1]}, $_[2] ] }
    ;

does_in_order:
    DOES IN ORDER
    ;

pipeline_def:
    PIPELINE opt_qname does_in_order COLON actions DONE {
            my($p, $n, $a) = @_[0,2,5];
            sub {
                $a = $a -> ();
                $a = $a->[0] if @$a == 1;
                $p->_m->add_pipeline((defined($n)?$n:'finally'), $a);
            }
        }
    | PIPELINE opt_qname DOES COLON action_list DONE {
            my($p, $n, $a) = @_[0,2,5];
            sub {
                $p->_m->add_pipeline((defined($n)?$n:'finally'), 
                    Data::Pipeline::Aggregator::Union -> new(
                        actions => $a -> ()
                    )
                )
            }
        }
    ;

actions:
    action { my($a) = $_[1]; sub { [ $a -> () ] } }
    | PIPELINE does_in_order COLON action_list DONE { $_[4] }
    | actions ARROW PIPELINE does_in_order COLON action_list DONE { my($a, $b) = @_[1,6];
        sub { [ @{$a -> ()}, @{$b -> ()} ] }
    }
    | actions ARROW action { my($a, $b) = @_[1,3];
        sub { [ @{$a -> ()}, $b -> () ] }
    }
    ;

action_list:
    action { my($a) = $_[1]; sub { [ $a -> () ] } }
    | PIPELINE does_in_order COLON action_list DONE { $_[4] }
    #| action_list action  
    | action_list action { my($a, $b) = @_[1,3];
        sub { [ @{$a -> ()}, $b -> () ] }
    }
    | action_list PIPELINE does_in_order COLON action_list DONE { my($a, $b) = @_[1,5];
        sub { [ @{$a -> ()}, @{$b -> ()} ] }
    }
    ;

action:
    QNAME {
        my($p, $qname, $class) = @_[0,1];
        sub {
            if( $class = $p -> _e -> {filters} -> {$qname} ) {
                return $class -> new;
            }
            else {
                die "Unable to find an action '$qname'\n";
            }
        }
    }
    | QNAME COLON action_arg {
        my($p, $qname, $arg, $class) = @_[0,1,3];
        sub {
            if( $class = $p -> _filters -> {$qname} ) {
                $class -> new( %{$arg->()} );
            }
            else {
                die "Unable to find an action '$qname'\n";
            }
        }
    }
    | QNAME DOES COLON action_args DONE {
        my($p, $qname, $args, $class) = @_[0,1,4];
        sub {
            if( $class = $p-> _filters -> {$qname} ) {
                $class -> new( %{$args->()} );
            }
            else {
                die "Unable to find an action '$qname'\n";
            }
        }
    }
    | QNAME does_in_order COLON ordered_action_args DONE {
        my($p, $qname, $args, $class) = @_[0,1,4];
        sub {
            if( $class = $p -> _filters -> {$qname} ) {
                $class -> new( @{$args->()} );
            }
            else {
                die "Unable to find an action '$qname'\n";
            }
        }
    }
    | PIPELINE DOES COLON action_list DONE {
        my($args) = $_[4];
        sub {
            Data::Pipeline::Aggregator::Union -> new(
                actions => $args->()
            );
        }
    }
    ;

action_arg:
    QNAME COLON action_expr { my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
    | QNAME COLON action_arg { my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
    | QNAME DOES COLON action_args DONE { my($q,$a) = @_[1,4]; sub { +{$q => $a->()} } }
    | QNAME does_in_order COLON ordered_action_args DONE {my($q,$a) = @_[1,4]; sub { +{ $q => $a->() } } }
    ;

action_args:
    action_arg 
    | action_args action_arg { my($a,$b) = @_[1,2]; sub { +{ %{$a->()}, %{$b->()} } } }
    ;

in_action_arg:
    QNAME COLON action_expr { my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
    | QNAME COLON in_action_arg { my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
    | QNAME DOES COLON in_action_args DONE { my($q,$a) = @_[1,4]; sub { +{$q => $a->()} } }
    | QNAME does_in_order COLON ordered_in_action_args DONE {my($q,$a) = @_[1,4]; sub { +{ $q => $a->() } } }
    | in_file
    ;

in_action_args:
    in_action_arg 
    | in_action_args in_action_arg { my($a,$b) = @_[1,2]; sub { +{ %{$a->()}, %{$b->()} } } }
    ;

ordered_action_args:
    action_arg { my $a = $_[1]; sub { [ %{$a -> ()} ] } }
    | ordered_action_args action_arg { my($a,$b) = @_[1,2]; sub { [ @{$a->()}, %{$b->()}]} }
    ;

ordered_in_action_args:
    in_action_arg { my $a = $_[1]; sub { [ %{$a -> ()} ] } }
    | ordered_in_action_args in_action_arg { my($a,$b) = @_[1,2]; sub { [ @{$a->()}, %{$b->()}]} }
    ;

action_expr:
    const_action_expr
    | action
    | DOES COLON action_args DONE  { $_[3] }
    | does_in_order COLON ordered_action_args DONE { $_[3] }
    | QNAME SLASH_SLASH const_action_expr { 
          my($name,$default) = @_[1,3];
          sub {
              Data::Pipeline::Iterator -> new( coded_source => sub {
                  to_IteratorSource( Data::Pipeline::Machine::has_option($name) ?
                      Data::Pipeline::Machine::get_option($name) :
                      $default -> ()
                  );
              } )
          }
    }
    | POS_INTEGER SLASH_SLASH const_action_expr {
          my($opt,$default) = @_[2,4];
          sub {
              Data::Pipeline::Iterator -> new( coded_source => sub {
                  to_IteratorSource( defined($ARGV[$opt]) ?
                      $ARGV[$opt] : $default -> ()
                  );
              });
          }
    }
    | PIPELINE QNAME { 
          my($p, $qname) = @_[0,2];

          sub {
             Data::Pipeline::Machine::Surrogate -> new(
                 machine => $p->_m,
                 named_pipeline => $qname,
                 options => { }
             );
          }
        }
    | PIPELINE QNAME DOES COLON action_args DONE {
        my($p,$qname,$args) = @_[0,2,5];

        sub {
             Data::Pipeline::Machine::Surrogate -> new(
                 machine => $p->_m,
                 named_pipeline => $qname,
                 options => $args
             );
        }
    }
    | PIPELINE DOES COLON action_list DONE {
        my($args) = $_[4];

        sub {
            Data::Pipeline::Aggregator::Union -> new(
                actions => $args -> ()
            );
        }
    }
    ;

const_action_expr:
    /* empty? */ { sub { } }
    | literal { $_[1] }
    | DOLLAR_QNAME { my($p, $v) = @_; 
          sub { $p -> _vars -> {$v} }
    }
    | DOLLAR_QNAME SLASH_SLASH const_action_expr { my($p, $v, $d) = @_[0,1,3]; 
          sub {
              defined($p -> _vars -> {$v})
              ? $p -> _vars -> {$v}
              : $d
          }
    }
    | const_array_expr { $_[1] }
    | named_expr { $_[1] }
    ;

const_array_expr:
    LB const_expr_list RB { $_[2] }
    ;

const_expr_list:
    /* empty */ { sub { [] } }
    | const_expr { my $a = $_[1]; sub { [ $a -> () ] } }
    | QW REGEX { my($a) = $_[2];
        sub {[ split(/\s+/, $a) ]} 
    }
    | const_expr_list QW REGEX { my($a, $b) = @_[1,3];
        sub {[ @{$a -> ()}, split(/\s+/, $b) ] }
    }
    | const_expr_list const_expr { my($a,$b) = @_[1,2];
        sub { [ @{$a -> ()}, @{$b -> ()} ] }
    }
    ;

const_expr:
    literal { $_[1] }
    | const_array_expr { $_[1] }
    | DOLLAR_QNAME {
          my($p, $v) = @_[0,1];
          sub { $p -> _vars -> {$v} }
      }
    ;

expr:
    /* empty */ { sub { } }
    | literal { $_[1] }
    | array_expr { $_[1] }
    | hash_expr { $_[1] }
    ;

expr_list:
    /* empty */ { sub {[]} }
    | expr { my($a) = $_[1]; sub { [ $a -> () ] } }
    | QW REGEX { my $r = $_[2]; sub { [ split(/\s+/, $r) ] } }
    | expr_list QW REGEX { my($e,$r) = @_[1,3]; sub { [ @{$e->()}, split(/\s+/, $r) ] } }
    | expr_list expr { my($a,$b) = @_[1,2]; sub { [ @{$a -> ()}, @{$b->()} ] } }
    ;

named_expr:
    QNAME COLON expr { my($l,$r) = @_[1,3]; sub { +{ $l => $r->() } } }
    LITERAL COLON expr { my($l,$r) = @_[1,3]; sub { +{ $l => $r->() } } }
    ;

named_expr_list:
    /* empty */ { sub { +{ } } }
    | named_expr { $_[1] }
    | named_expr_list named_expr { my($a, $b) = @_[1,2];
        sub { +{ %{$a -> ()}, %{$b -> ()} } }
    }
    ;

array_expr:
    LB expr_list RB { $_[2] }
    ;

hash_expr:
    LC named_expr_list RC { $_[2] }
    ;
%%


use Carp;
use Class::MOP;

use Data::Pipeline::Types qw(IteratorSource);
use Data::Pipeline::Machine ();
use MooseX::Types::Moose qw(HashRef ArrayRef CodeRef);

my @reserved_words = (qw(
    DOES 
    DONE 
    FROM
    IN
    LET
    OUT
    PIPELINE 
    TO
    USE
    ORDER
    S
    QR
    QW
    TR
    TRUE
    FALSE
    IMPORT
    STDOUT
    STDIN
    FILE
    USING
    MAPPING
    REDUCTION
));

my %tokens = (qw(
    =>       ARROW
    :        COLON
    ::       COLON_COLON
    //       SLASH_SLASH
    [        LB
    ]        RB
    {        LC
    }        RC
    ~        TILDE
));
    


my $simple_tokens =
    join "|",
         map
             quotemeta,
             reverse
                 sort {
                     length $a <=> length $b
                 } keys %tokens;

%tokens = (%tokens,  map { ($_ => $_) } @reserved_words);

my $reserved_words = 
    join "|", 
    reverse 
    sort { length $a <=> length $b } 
    @reserved_words;

my $NCName = "(?:[a-zA-Z_][a-zA-Z0-9_]*\\??)";

sub debugging() { 0 }

my %balancing_delims = (qw-
    < >
    > <
    ( )
    ) (
    { }
    } {
    [ ]
    ] [
-);

sub in_freeform_until_done { $_[0] -> {in_freeform_until} = 'DONE' }

sub lex {
    my( $p ) = @_;

    my $d = $p -> {USER};
    my $input = \$d->{Input};

    if( ( pos( $$input ) || 0 ) == length $$input ) {
        $d -> {LastToken} = undef;
        return ( '', undef );
    }

    my($token, $val);

    if( defined($d -> {LastToken}) && ($d -> {LastToken} eq 'QR' || $d -> {LastToken} eq 'QW' ) ) { # REGEX
        $$input =~ m{\G(.)}gc;
        my $delim = $1;
        my $bdelim = $balancing_delims{$delim} || $delim;
        $$input =~ m{\G((([^$delim$bdelim]*)(\\[$delim$bdelim])?)+)[$bdelim]\s*}gc;
        ( $token, $val ) = ( 'REGEX', $1 );
    }
    elsif( $d -> {LastToken} eq 'S' || $d -> {LastToken} eq 'TR' ) {
        $$input =~ m{\G(.)}gc;
        my @bits;
        my $delim = $1;
        my $bdelim = $balancing_delims{$delim} || $delim;
        if($bdelim ne $delim) { # need to balance delimiters
            ## for now, we just assume the delimiters have to be escaped
            $$input =~ m{\G((([^$delim$bdelim]*)(\\[$delim$bdelim])?)+)[$bdelim]\s*}gc;
            push @bits, $1;
            $$input =~ m{\G(.)}gc;
            my $delim = $1;
            my $bdelim = $balancing_delims{$delim} || $delim;
            $$input =~ m{\G((([^$delim$bdelim]*)(\\[$delim$bdelim])?)+)[$bdelim]\s*}gc;
            push @bits, $1;
        }
        else {
            $$input =~ m{\G((([^$delim$bdelim]*)(\\[$delim$bdelim])?)+)[$bdelim]((([^$delim$bdelim]*)(\\[$delim$bdelim])?)+)[$bdelim]}gc;
            @bits = ($1, $5);
        }
        ( $token, $val ) = ( 'REGEX', \@bits );
    }

    unless ( defined $token ) {
        if($p -> {in_freeform_until}) {
            my $pat = $p -> {in_freeform_until};
            my $pos = pos $$input;
            my $done;
            do {
                $done = 1;
                $pos = index $$input, $pat, $pos;
                $val = substr($$input, pos($$input), $pos - pos($$input));
                my $bit = rindex $$input, "\n", $pos;
                if( substr($$input, $bit+1, $pos-$bit-1) !~ /^\s*$/ ) {
                    $done = 0;
                }
                $bit = index $$input, "\n", ($pos + length($pat));
                if( defined($bit) && substr($$input, $pos + length($pat), $bit - $pos - length($pat)) !~ /^\s*$/ ) {
                    $done = 0;
                }
            } until $done;
            
            pos($$input) = $pos;
            $token = 'TO_DONE';
            $p -> {in_freeform_until} = undef;
        }
    }

    unless(defined $token) {
        while( $$input =~ m{\G\s*(?:#.*)$}gmc ) {
            # skip comments
        }
        if( ( pos( $$input ) || 0 ) == length $$input ) {
            $d -> {LastToken} = undef;
            return ( '', undef );
        }
    }

    unless(defined $token) {
        if( $$input =~ m{\G^__END__$}gcm ) {
            $d -> {LastToken} = undef;
            pos( $$input ) = length $$input;
            return ( '', undef );
        }

        $$input =~ m{\G\s*(?:
            ((?:$simple_tokens)|(?:(?:$reserved_words)\b))
            |(\\?$NCName)            #QNAME
            |('[^']*'|"[^"]*")       #LITERAL
            |(-?\d+\.\d+|\.\d+)      #NUMBER
            |(\d+)                   #POS_INTEGER
            |(-\d+)                  #NEG_INTEGER
            |\$($NCName)             #DOLLAR_QNAME
        )\s*}igcx;

        ( $token, $val ) =
            defined $1 ? ( $tokens{uc $1} => uc $1 ) :
            defined $2 ? (QNAME => do { my $q = $2; $q =~ s/^\\//; $q }) :
            defined $3 ? (LITERAL => do {
                my $s = substr( $3, 1, -1);
                $s =~ s/([\\'])/\\$1/g;
                $s;
            }) :
            defined $4 ? ( NUMBER => $4 ) :
            defined $5 ? ( POS_INTEGER => $5 ) :
            defined $6 ? ( NEG_INTEGER => $6 ) :
            defined $7 ? ( DOLLAR_QNAME => $7 ) :
            die "Failed to parse '$$input' at ", pos $$input, "\n";
    }

    $d -> {LastTokenType} = $token;
    $d -> {LastToken} = $val;

#    print "lexer: [$token] => [$val]\n";

    return( $token, $val );
}

sub error {
    my( $p ) = @_;

    return if $p -> {USER} -> {Input} =~ m{^\s*$};
    #print join(", ", caller), "\n";
    my $pos = pos $p -> {USER} -> {Input};
    my $before_error = substr($p->{USER}{Input}, 0, $pos);
    my $after_error = substr($p->{USER}{Input}, $pos);
    my $line = ($before_error =~ tr/\n/\n/) + 1;
    $before_error =~ s{.*\n}{}s;
    $after_error =~ s{\n.*$}{}s;
    #warn "Couldn't parse '$p->{USER}{Input}' at position ", pos $p->{USER}->{Input}, " (line $line, pos ", length($before_error), ")\n";
    $line++;
    warn "Syntax error on line $line:\n";
    warn "$before_error$after_error\n";
    warn " "x length($before_error), "^\n";
}

sub parse {
    my $self = shift;
    my( $e, $expr, $action_code ) = @_;

    $expr =~ s{^\s*}{};
    $expr =~ s{\s*$}{};

    my $p = Data::Pipeline::Parser -> new(
       yylex => \&lex,
       yyerror => \&error,
       yydebug => 0
         #  |  0x01        # Token reading (useful for Lexer debugging)
         #  |  0x02        # States information
         #  |  0x04        # Driver actions (shifts, reduces, accept...)
           #|  0x08        # Parse Stack dump
           #|  0x10        # Error Recovery tracing
           ,
    );

    $p->{USER}->{Input} = $expr;
    $p->{USER}->{e} = $e;

    $p->{USER}->{e} -> {machine} = [ ];
    $p->{USER}->{e} -> {es} = { '' => { vars => { %{$p->{USER}->{e} -> {vars}||{} } } } };

    my $code;
    eval { $code = $p -> YYParse( ); };

    die $@ if $@;

    die map "$_\n", @{$p->{USER}->{NONONO}}
        if $p -> {USER} -> {NONONO};

    $p -> _eval_in_m('', $code) if $code;

    return $p;
    #return $code; # useful stuff is in $e
}

sub _e { 
    my($p,$m) = ($_[0], $_[0]->_m_);

    if(!defined $p -> {USER} -> {e} -> {es} -> {$m}) {
        $p->{USER}->{e} -> {es}->{$m} = {
            filters => +{ %{ $p->{USER}->{e} -> {es}->{$p->_pm_}->{filters}||{} } },
            perl_classes => +{ %{ $p->{USER}->{e} -> {es}->{$p->_pm_}->{perl_classes}||{} } },
            vars => { },
        }
    }
    return $p -> {USER} ->{e} ->  {es} -> {$m};
}

sub _m_ { ($_[0]->{USER}->{e}->{machine}||=[])->[0] || '' }

sub _pm_ { 
    my $ms = ($_[0]->{USER}->{e}->{machine}||=[]);
    return '' if scalar(@$ms) < 2;
    return $ms->[$#$ms-1];
}

sub _m { $_[0] -> _e->{machine} ||= Data::Pipeline::Aggregator::Machine->new() };

sub compile_ext_lang {
    my($self, $qname, $language, $scope, $code) = @_;

    my $mname = $self -> _m_;

    if(lc($language) eq 'perl') {
        # print "We're doing something in Perl!\n";
    }
    else {
        die "'$language' unsupported for filters\n";
    }
}

sub run { my $self = shift;

    return unless $self -> _e -> {machine};

    my %opts = @_;

    my(@from, @to);

    my($from, $to) = (
        $self -> _e -> {from} || $self -> {e} -> {from} || $opts{from},
        $self -> _e -> {to}   || $self -> {e} -> {to} || $opts{to}
    );

    $from = $from -> () while is_CodeRef($from);
    $to = $to -> ()     while is_CodeRef($to);

    if(is_HashRef($from)) {
        @from = %{$from};
    }
    elsif(is_ArrayRef($from)) {
        @from = @{$from};
    }
    else {
        @from = ($from);
    }

    if(is_HashRef($to)) {
        @to = %{$to};
    }
    elsif(is_ArrayRef($to)) {
        @to = @{$to};
    }
    else {
        @to = ($to);
    }

    #print "From: ", join(", ", @from), "\n";
    #print "  To: ", join(", ", @to), "\n";

    $self -> _e 
          -> {machine} 
          -> from(@from)
          -> to(@to);
}

sub _perl_classes { $_[0] -> _e -> {perl_classes} ||= {} }
sub _vars { $_[0] -> _e -> {vars} }

sub _filters { $_[0] -> _e -> {filters} }

sub _eval_in_m { 
    my($p, $m, $code) = @_;
    push @{$p->{USER}->{e}->{machine}||=[]}, $m;
    $code->();
    pop @{$p->{USER}->{e}->{machine}};
}

sub load_actions {
    my($p, $type, @filters) = @_;

    my $class;

    foreach my $filter (@filters) {
         if($class = $p -> _load_filter($type, $filter)) {
             $p -> _e -> {filters} -> {$filter} = $class;
         }
         else {
             print STDERR "Unable to load '$filter'\n";
         }
    }
}

sub _load_filter($$) {
    my(undef, $type, $filter) = @_;

    my $class;
    for my $p ($type, $type.'X') {

        $class="Data::Pipeline::${p}::${filter}";

        return $class if eval { Class::MOP::load_class($class) };
    }
}

1;
