####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Data::Pipeline::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------


#line 2 "unkown"

=head1

Data::Pipeline::Parser - DSL for pipelines

=head1 DESCRIPTION

=cut


sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'MACHINE' => 2
		},
		DEFAULT => -8,
		GOTOS => {
			'body' => 1,
			'program_segment' => 4,
			'machine' => 3,
			'program' => 5
		}
	},
	{#State 1
		ACTIONS => {
			'PIPELINE' => 15,
			'LET' => 6,
			'MAPPING' => 19,
			'OUT' => 18,
			'IN' => 20,
			'IMPORT' => 8,
			'FROM' => 23,
			'USE' => 22,
			'REDUCTION' => 11,
			'TO' => 13
		},
		DEFAULT => -3,
		GOTOS => {
			'pipeline_def' => 16,
			'use_stmt' => 17,
			'let_stmt' => 7,
			'decl_stmt' => 9,
			'io_stmt' => 10,
			'import_stmt' => 21,
			'filter_type' => 12,
			'filter_def' => 14
		}
	},
	{#State 2
		ACTIONS => {
			'QNAME' => 25
		},
		GOTOS => {
			'machine_name' => 24
		}
	},
	{#State 3
		DEFAULT => -4
	},
	{#State 4
		DEFAULT => -1
	},
	{#State 5
		ACTIONS => {
			'' => 26,
			'MACHINE' => 2
		},
		DEFAULT => -8,
		GOTOS => {
			'body' => 1,
			'program_segment' => 27,
			'machine' => 3
		}
	},
	{#State 6
		ACTIONS => {
			'QNAME' => 28
		}
	},
	{#State 7
		DEFAULT => -11
	},
	{#State 8
		ACTIONS => {
			'COLON' => 29
		}
	},
	{#State 9
		DEFAULT => -9
	},
	{#State 10
		DEFAULT => -14
	},
	{#State 11
		DEFAULT => -64
	},
	{#State 12
		ACTIONS => {
			'QNAME' => 30
		}
	},
	{#State 13
		ACTIONS => {
			'COLON' => 31,
			'DOES' => 33
		},
		GOTOS => {
			'does_in_order' => 32
		}
	},
	{#State 14
		DEFAULT => -15
	},
	{#State 15
		ACTIONS => {
			'qname' => 35
		},
		DEFAULT => -18,
		GOTOS => {
			'opt_qname' => 34
		}
	},
	{#State 16
		DEFAULT => -10
	},
	{#State 17
		DEFAULT => -12
	},
	{#State 18
		ACTIONS => {
			'COLON' => 36
		}
	},
	{#State 19
		DEFAULT => -63
	},
	{#State 20
		ACTIONS => {
			'COLON' => 37
		}
	},
	{#State 21
		DEFAULT => -13
	},
	{#State 22
		ACTIONS => {
			'COLON' => 38
		}
	},
	{#State 23
		ACTIONS => {
			'COLON' => 39,
			'DOES' => 41
		},
		GOTOS => {
			'does_in_order' => 40
		}
	},
	{#State 24
		ACTIONS => {
			'COLON_COLON' => 42,
			'DOES' => 43
		}
	},
	{#State 25
		DEFAULT => -6
	},
	{#State 26
		DEFAULT => 0
	},
	{#State 27
		DEFAULT => -2
	},
	{#State 28
		ACTIONS => {
			'COLON' => 44
		}
	},
	{#State 29
		ACTIONS => {
			'QNAME' => 46
		},
		GOTOS => {
			'perl_class' => 45,
			'perl_class_list' => 47
		}
	},
	{#State 30
		ACTIONS => {
			'USING' => 48
		}
	},
	{#State 31
		ACTIONS => {
			'FILE' => 49,
			'STDOUT' => 51,
			'QNAME' => 53
		},
		GOTOS => {
			'out_file' => 52,
			'action_arg' => 50
		}
	},
	{#State 32
		ACTIONS => {
			'COLON' => 54
		}
	},
	{#State 33
		ACTIONS => {
			'COLON' => 55,
			'IN' => 56
		}
	},
	{#State 34
		ACTIONS => {
			'DOES' => 58
		},
		GOTOS => {
			'does_in_order' => 57
		}
	},
	{#State 35
		DEFAULT => -19
	},
	{#State 36
		ACTIONS => {
			'QNAME' => 60
		},
		GOTOS => {
			'qname_list' => 59
		}
	},
	{#State 37
		ACTIONS => {
			'QNAME' => 60
		},
		GOTOS => {
			'qname_list' => 61
		}
	},
	{#State 38
		ACTIONS => {
			'QNAME' => 60
		},
		GOTOS => {
			'qname_list' => 62
		}
	},
	{#State 39
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67
		},
		GOTOS => {
			'in_file' => 65,
			'in_action_arg' => 64
		}
	},
	{#State 40
		ACTIONS => {
			'COLON' => 68
		}
	},
	{#State 41
		ACTIONS => {
			'COLON' => 69,
			'IN' => 56
		}
	},
	{#State 42
		ACTIONS => {
			'QNAME' => 70
		}
	},
	{#State 43
		ACTIONS => {
			'COLON' => 71
		}
	},
	{#State 44
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'DOLLAR_QNAME' => 85,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 46,
			'QR' => 88
		},
		DEFAULT => -50,
		GOTOS => {
			'literal' => 78,
			'perl_class' => 77,
			'integer' => 79,
			'string' => 74,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 45
		ACTIONS => {
			'COLON_COLON' => 89
		},
		DEFAULT => -69
	},
	{#State 46
		ACTIONS => {
			'COLON_COLON' => 90
		}
	},
	{#State 47
		ACTIONS => {
			'QNAME' => 46
		},
		DEFAULT => -54,
		GOTOS => {
			'perl_class' => 91
		}
	},
	{#State 48
		ACTIONS => {
			'QNAME' => 92
		}
	},
	{#State 49
		ACTIONS => {
			'DOLLAR_QNAME' => 94,
			'LITERAL' => 75
		},
		GOTOS => {
			'string' => 93,
			'string_literal' => 84
		}
	},
	{#State 50
		DEFAULT => -55
	},
	{#State 51
		DEFAULT => -40
	},
	{#State 52
		DEFAULT => -56
	},
	{#State 53
		ACTIONS => {
			'COLON' => 95,
			'DOES' => 97
		},
		GOTOS => {
			'does_in_order' => 96
		}
	},
	{#State 54
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 98,
			'action_arg' => 99
		}
	},
	{#State 55
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 100,
			'action_arg' => 101
		}
	},
	{#State 56
		ACTIONS => {
			'ORDER' => 102
		}
	},
	{#State 57
		ACTIONS => {
			'COLON' => 103
		}
	},
	{#State 58
		ACTIONS => {
			'COLON' => 104,
			'IN' => 56
		}
	},
	{#State 59
		ACTIONS => {
			'QNAME' => 105
		},
		DEFAULT => -53
	},
	{#State 60
		DEFAULT => -16
	},
	{#State 61
		ACTIONS => {
			'QNAME' => 105
		},
		DEFAULT => -52
	},
	{#State 62
		ACTIONS => {
			'QNAME' => 105
		},
		DEFAULT => -51
	},
	{#State 63
		ACTIONS => {
			'DOLLAR_QNAME' => 107,
			'LITERAL' => 75
		},
		GOTOS => {
			'string' => 106,
			'string_literal' => 84
		}
	},
	{#State 64
		DEFAULT => -59
	},
	{#State 65
		DEFAULT => -60
	},
	{#State 66
		ACTIONS => {
			'COLON' => 108,
			'DOES' => 110
		},
		GOTOS => {
			'does_in_order' => 109
		}
	},
	{#State 67
		DEFAULT => -37
	},
	{#State 68
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67
		},
		GOTOS => {
			'ordered_in_action_args' => 112,
			'in_file' => 113,
			'in_action_arg' => 111
		}
	},
	{#State 69
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67
		},
		GOTOS => {
			'in_action_args' => 115,
			'in_file' => 113,
			'in_action_arg' => 114
		}
	},
	{#State 70
		DEFAULT => -7
	},
	{#State 71
		DEFAULT => -8,
		GOTOS => {
			'body' => 116
		}
	},
	{#State 72
		ACTIONS => {
			'REGEX' => 117
		}
	},
	{#State 73
		DEFAULT => -33
	},
	{#State 74
		ACTIONS => {
			'TILDE' => 118
		},
		DEFAULT => -27
	},
	{#State 75
		DEFAULT => -22
	},
	{#State 76
		DEFAULT => -35
	},
	{#State 77
		ACTIONS => {
			'COLON_COLON' => 89,
			'DOES' => 120
		},
		DEFAULT => -43,
		GOTOS => {
			'does_in_order' => 119
		}
	},
	{#State 78
		DEFAULT => -49
	},
	{#State 79
		DEFAULT => -29
	},
	{#State 80
		DEFAULT => -34
	},
	{#State 81
		DEFAULT => -21
	},
	{#State 82
		ACTIONS => {
			'REGEX' => 121
		}
	},
	{#State 83
		DEFAULT => -28
	},
	{#State 84
		DEFAULT => -25
	},
	{#State 85
		ACTIONS => {
			'SLASH_SLASH' => 122
		},
		DEFAULT => -23
	},
	{#State 86
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'DOLLAR_QNAME' => 85,
			'LITERAL' => 75,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 46,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'QR' => 88,
			'NUMBER' => 83
		},
		GOTOS => {
			'literal' => 123,
			'perl_class' => 77,
			'integer' => 79,
			'string' => 74,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 87
		DEFAULT => -20
	},
	{#State 88
		ACTIONS => {
			'REGEX' => 124
		}
	},
	{#State 89
		ACTIONS => {
			'QNAME' => 125
		}
	},
	{#State 90
		ACTIONS => {
			'QNAME' => 126
		}
	},
	{#State 91
		ACTIONS => {
			'COLON_COLON' => 89
		},
		DEFAULT => -70
	},
	{#State 92
		ACTIONS => {
			'DOES' => 127
		}
	},
	{#State 93
		ACTIONS => {
			'TILDE' => 118
		},
		DEFAULT => -41
	},
	{#State 94
		ACTIONS => {
			'SLASH_SLASH' => 128
		},
		DEFAULT => -23
	},
	{#State 95
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'PIPELINE' => 136,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 138,
			'QNAME' => 139,
			'QR' => 88,
			'DOES' => 141
		},
		DEFAULT => -113,
		GOTOS => {
			'string' => 74,
			'perl_method' => 76,
			'const_action_expr' => 130,
			'does_in_order' => 129,
			'literal' => 131,
			'perl_class' => 77,
			'named_expr' => 133,
			'integer' => 79,
			'action_arg' => 134,
			'const_array_expr' => 135,
			'action' => 140,
			'action_expr' => 142,
			'string_literal' => 84
		}
	},
	{#State 96
		ACTIONS => {
			'COLON' => 143
		}
	},
	{#State 97
		ACTIONS => {
			'COLON' => 144,
			'IN' => 56
		}
	},
	{#State 98
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 146
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 99
		DEFAULT => -100
	},
	{#State 100
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 148
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 101
		DEFAULT => -91
	},
	{#State 102
		DEFAULT => -71
	},
	{#State 103
		ACTIONS => {
			'PIPELINE' => 150,
			'QNAME' => 151
		},
		GOTOS => {
			'actions' => 149,
			'action' => 152
		}
	},
	{#State 104
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 153
		}
	},
	{#State 105
		DEFAULT => -17
	},
	{#State 106
		ACTIONS => {
			'TILDE' => 118
		},
		DEFAULT => -38
	},
	{#State 107
		ACTIONS => {
			'SLASH_SLASH' => 156
		},
		DEFAULT => -23
	},
	{#State 108
		ACTIONS => {
			'S' => 72,
			'FILE' => 63,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'PIPELINE' => 136,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 138,
			'QNAME' => 158,
			'STDIN' => 67,
			'QR' => 88,
			'DOES' => 141
		},
		DEFAULT => -113,
		GOTOS => {
			'in_file' => 113,
			'string' => 74,
			'in_action_arg' => 157,
			'perl_method' => 76,
			'const_action_expr' => 130,
			'does_in_order' => 129,
			'literal' => 131,
			'perl_class' => 77,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'action' => 140,
			'action_expr' => 159,
			'string_literal' => 84
		}
	},
	{#State 109
		ACTIONS => {
			'COLON' => 160
		}
	},
	{#State 110
		ACTIONS => {
			'COLON' => 161,
			'IN' => 56
		}
	},
	{#State 111
		DEFAULT => -102
	},
	{#State 112
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67,
			'DONE' => 163
		},
		GOTOS => {
			'in_file' => 113,
			'in_action_arg' => 162
		}
	},
	{#State 113
		DEFAULT => -97
	},
	{#State 114
		DEFAULT => -98
	},
	{#State 115
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67,
			'DONE' => 165
		},
		GOTOS => {
			'in_file' => 113,
			'in_action_arg' => 164
		}
	},
	{#State 116
		ACTIONS => {
			'PIPELINE' => 15,
			'DONE' => 166,
			'LET' => 6,
			'OUT' => 18,
			'MAPPING' => 19,
			'IN' => 20,
			'IMPORT' => 8,
			'USE' => 22,
			'FROM' => 23,
			'REDUCTION' => 11,
			'TO' => 13
		},
		GOTOS => {
			'pipeline_def' => 16,
			'use_stmt' => 17,
			'let_stmt' => 7,
			'io_stmt' => 10,
			'decl_stmt' => 9,
			'import_stmt' => 21,
			'filter_type' => 12,
			'filter_def' => 14
		}
	},
	{#State 117
		DEFAULT => -31
	},
	{#State 118
		ACTIONS => {
			'DOLLAR_QNAME' => 85,
			'LITERAL' => 75
		},
		GOTOS => {
			'string_literal' => 167
		}
	},
	{#State 119
		ACTIONS => {
			'COLON' => 168
		}
	},
	{#State 120
		ACTIONS => {
			'QNAME' => 170,
			'COLON' => 169,
			'IN' => 56
		}
	},
	{#State 121
		DEFAULT => -32
	},
	{#State 122
		ACTIONS => {
			'S' => 72,
			'FALSE' => 80,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QR' => 88,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'QNAME' => 172
		},
		DEFAULT => -113,
		GOTOS => {
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'string' => 74,
			'const_action_expr' => 171,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 123
		ACTIONS => {
			'RP' => 173
		}
	},
	{#State 124
		DEFAULT => -30
	},
	{#State 125
		DEFAULT => -68
	},
	{#State 126
		DEFAULT => -67
	},
	{#State 127
		ACTIONS => {
			'COLON' => 174
		}
	},
	{#State 128
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'STDOUT' => 175,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 172,
			'QR' => 88
		},
		DEFAULT => -113,
		GOTOS => {
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'string' => 74,
			'const_action_expr' => 171,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 129
		ACTIONS => {
			'COLON' => 176
		}
	},
	{#State 130
		DEFAULT => -104
	},
	{#State 131
		DEFAULT => -114
	},
	{#State 132
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'DOLLAR_QNAME' => 180,
			'LITERAL' => 75,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'LB' => 132,
			'QNAME' => 46,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'QW' => 182,
			'TR' => 82,
			'QR' => 88,
			'NUMBER' => 83
		},
		DEFAULT => -120,
		GOTOS => {
			'const_expr' => 181,
			'const_expr_list' => 177,
			'string' => 74,
			'perl_method' => 76,
			'literal' => 178,
			'perl_class' => 77,
			'integer' => 79,
			'const_array_expr' => 179,
			'string_literal' => 84
		}
	},
	{#State 133
		DEFAULT => -118
	},
	{#State 134
		DEFAULT => -88
	},
	{#State 135
		DEFAULT => -117
	},
	{#State 136
		ACTIONS => {
			'QNAME' => 183,
			'DOES' => 184
		}
	},
	{#State 137
		ACTIONS => {
			'SLASH_SLASH' => 185
		},
		DEFAULT => -23
	},
	{#State 138
		ACTIONS => {
			'SLASH_SLASH' => 186
		},
		DEFAULT => -20
	},
	{#State 139
		ACTIONS => {
			'SLASH_SLASH' => 187,
			'COLON' => 188,
			'COLON_COLON' => 90,
			'DOES' => 190
		},
		DEFAULT => -82,
		GOTOS => {
			'does_in_order' => 189
		}
	},
	{#State 140
		DEFAULT => -105
	},
	{#State 141
		ACTIONS => {
			'COLON' => 191,
			'IN' => 56
		}
	},
	{#State 142
		DEFAULT => -87
	},
	{#State 143
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 192,
			'action_arg' => 99
		}
	},
	{#State 144
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 193,
			'action_arg' => 101
		}
	},
	{#State 145
		DEFAULT => -101
	},
	{#State 146
		DEFAULT => -58
	},
	{#State 147
		DEFAULT => -92
	},
	{#State 148
		DEFAULT => -57
	},
	{#State 149
		ACTIONS => {
			'ARROW' => 194,
			'DONE' => 195
		}
	},
	{#State 150
		ACTIONS => {
			'DOES' => 197
		},
		GOTOS => {
			'does_in_order' => 196
		}
	},
	{#State 151
		ACTIONS => {
			'COLON' => 198,
			'DOES' => 200
		},
		DEFAULT => -82,
		GOTOS => {
			'does_in_order' => 199
		}
	},
	{#State 152
		DEFAULT => -74
	},
	{#State 153
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 202
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 154
		ACTIONS => {
			'DOES' => 197
		},
		GOTOS => {
			'does_in_order' => 204
		}
	},
	{#State 155
		DEFAULT => -78
	},
	{#State 156
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 172,
			'STDIN' => 205,
			'QR' => 88
		},
		DEFAULT => -113,
		GOTOS => {
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'string' => 74,
			'const_action_expr' => 171,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 157
		DEFAULT => -94
	},
	{#State 158
		ACTIONS => {
			'SLASH_SLASH' => 187,
			'COLON' => 206,
			'COLON_COLON' => 90,
			'DOES' => 208
		},
		DEFAULT => -82,
		GOTOS => {
			'does_in_order' => 207
		}
	},
	{#State 159
		DEFAULT => -93
	},
	{#State 160
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67
		},
		GOTOS => {
			'ordered_in_action_args' => 209,
			'in_file' => 113,
			'in_action_arg' => 111
		}
	},
	{#State 161
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67
		},
		GOTOS => {
			'in_action_args' => 210,
			'in_file' => 113,
			'in_action_arg' => 114
		}
	},
	{#State 162
		DEFAULT => -103
	},
	{#State 163
		DEFAULT => -62
	},
	{#State 164
		DEFAULT => -99
	},
	{#State 165
		DEFAULT => -61
	},
	{#State 166
		DEFAULT => -5
	},
	{#State 167
		DEFAULT => -26
	},
	{#State 168
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 211,
			'action_arg' => 99
		}
	},
	{#State 169
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 212,
			'action_arg' => 101
		}
	},
	{#State 170
		ACTIONS => {
			'COLON' => 213,
			'IN' => 214
		},
		DEFAULT => -46
	},
	{#State 171
		DEFAULT => -24
	},
	{#State 172
		ACTIONS => {
			'COLON_COLON' => 90,
			'COLON' => 215
		}
	},
	{#State 173
		DEFAULT => -36
	},
	{#State 174
		DEFAULT => -65,
		GOTOS => {
			'@1-6' => 216
		}
	},
	{#State 175
		DEFAULT => -42
	},
	{#State 176
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 217,
			'action_arg' => 99
		}
	},
	{#State 177
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'RB' => 218,
			'DOLLAR_QNAME' => 180,
			'LITERAL' => 75,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'LB' => 132,
			'QNAME' => 46,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'QW' => 220,
			'TR' => 82,
			'QR' => 88,
			'NUMBER' => 83
		},
		GOTOS => {
			'const_expr' => 219,
			'string' => 74,
			'perl_method' => 76,
			'literal' => 178,
			'perl_class' => 77,
			'integer' => 79,
			'const_array_expr' => 179,
			'string_literal' => 84
		}
	},
	{#State 178
		DEFAULT => -125
	},
	{#State 179
		DEFAULT => -126
	},
	{#State 180
		ACTIONS => {
			'SLASH_SLASH' => 122
		},
		DEFAULT => -23
	},
	{#State 181
		DEFAULT => -121
	},
	{#State 182
		ACTIONS => {
			'REGEX' => 221
		}
	},
	{#State 183
		ACTIONS => {
			'DOES' => 222
		},
		DEFAULT => -110
	},
	{#State 184
		ACTIONS => {
			'COLON' => 223
		}
	},
	{#State 185
		ACTIONS => {
			'S' => 72,
			'FALSE' => 80,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QR' => 88,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'QNAME' => 172
		},
		DEFAULT => -113,
		GOTOS => {
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'string' => 74,
			'const_action_expr' => 224,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 186
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 172,
			'QR' => 88
		},
		DEFAULT => -113,
		GOTOS => {
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'string' => 74,
			'const_action_expr' => 225,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 187
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 172,
			'QR' => 88
		},
		DEFAULT => -113,
		GOTOS => {
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'integer' => 79,
			'const_array_expr' => 135,
			'string' => 74,
			'const_action_expr' => 226,
			'perl_method' => 76,
			'string_literal' => 84
		}
	},
	{#State 188
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 228,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'PIPELINE' => 136,
			'LC' => 233,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 138,
			'QNAME' => 139,
			'QR' => 88,
			'DOES' => 141
		},
		DEFAULT => -113,
		GOTOS => {
			'string' => 74,
			'perl_method' => 76,
			'const_action_expr' => 130,
			'does_in_order' => 129,
			'literal' => 227,
			'perl_class' => 77,
			'named_expr' => 133,
			'action_arg' => 230,
			'integer' => 79,
			'expr' => 229,
			'const_array_expr' => 135,
			'hash_expr' => 231,
			'string_literal' => 84,
			'array_expr' => 232,
			'action' => 140,
			'action_expr' => 142
		}
	},
	{#State 189
		ACTIONS => {
			'COLON' => 234
		}
	},
	{#State 190
		ACTIONS => {
			'COLON' => 235,
			'IN' => 56
		}
	},
	{#State 191
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 236,
			'action_arg' => 101
		}
	},
	{#State 192
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 237
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 193
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 238
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 194
		ACTIONS => {
			'PIPELINE' => 239,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 240
		}
	},
	{#State 195
		DEFAULT => -72
	},
	{#State 196
		ACTIONS => {
			'COLON' => 241
		}
	},
	{#State 197
		ACTIONS => {
			'COLON' => 242,
			'IN' => 56
		}
	},
	{#State 198
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_arg' => 243
		}
	},
	{#State 199
		ACTIONS => {
			'COLON' => 244
		}
	},
	{#State 200
		ACTIONS => {
			'COLON' => 245,
			'IN' => 56
		}
	},
	{#State 201
		ACTIONS => {
			'DOES' => 197
		},
		GOTOS => {
			'does_in_order' => 246
		}
	},
	{#State 202
		DEFAULT => -73
	},
	{#State 203
		DEFAULT => -80
	},
	{#State 204
		ACTIONS => {
			'COLON' => 247
		}
	},
	{#State 205
		DEFAULT => -39
	},
	{#State 206
		ACTIONS => {
			'S' => 72,
			'FILE' => 63,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 228,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'PIPELINE' => 136,
			'LC' => 233,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 138,
			'QNAME' => 248,
			'STDIN' => 67,
			'QR' => 88,
			'DOES' => 141
		},
		DEFAULT => -113,
		GOTOS => {
			'string' => 74,
			'perl_method' => 76,
			'in_action_arg' => 157,
			'const_action_expr' => 130,
			'does_in_order' => 129,
			'perl_class' => 77,
			'literal' => 227,
			'named_expr' => 133,
			'expr' => 229,
			'action_arg' => 243,
			'integer' => 79,
			'const_array_expr' => 135,
			'hash_expr' => 231,
			'string_literal' => 84,
			'array_expr' => 232,
			'in_file' => 113,
			'action' => 140,
			'action_expr' => 159
		}
	},
	{#State 207
		ACTIONS => {
			'COLON' => 249
		}
	},
	{#State 208
		ACTIONS => {
			'COLON' => 250,
			'IN' => 56
		}
	},
	{#State 209
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67,
			'DONE' => 251
		},
		GOTOS => {
			'in_file' => 113,
			'in_action_arg' => 162
		}
	},
	{#State 210
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 66,
			'STDIN' => 67,
			'DONE' => 252
		},
		GOTOS => {
			'in_file' => 113,
			'in_action_arg' => 164
		}
	},
	{#State 211
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 253
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 212
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 254
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 213
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 255,
			'action_arg' => 101
		}
	},
	{#State 214
		ACTIONS => {
			'ORDER' => 256
		}
	},
	{#State 215
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LC' => 233,
			'DOLLAR_QNAME' => 85,
			'LITERAL' => 75,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'LB' => 258,
			'QNAME' => 46,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'QR' => 88
		},
		GOTOS => {
			'array_expr' => 232,
			'string' => 74,
			'perl_method' => 76,
			'literal' => 257,
			'perl_class' => 77,
			'expr' => 229,
			'integer' => 79,
			'hash_expr' => 231,
			'string_literal' => 84
		}
	},
	{#State 216
		ACTIONS => {
			'TO_DONE' => 259
		}
	},
	{#State 217
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 260
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 218
		DEFAULT => -119
	},
	{#State 219
		DEFAULT => -124
	},
	{#State 220
		ACTIONS => {
			'REGEX' => 261
		}
	},
	{#State 221
		DEFAULT => -122
	},
	{#State 222
		ACTIONS => {
			'COLON' => 262
		}
	},
	{#State 223
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 263
		}
	},
	{#State 224
		DEFAULT => -24
	},
	{#State 225
		DEFAULT => -109
	},
	{#State 226
		DEFAULT => -108
	},
	{#State 227
		ACTIONS => {
			'LITERAL' => -129
		},
		DEFAULT => -114
	},
	{#State 228
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 228,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'LC' => 233,
			'DOLLAR_QNAME' => 180,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 46,
			'QW' => 265,
			'QR' => 88
		},
		DEFAULT => -120,
		GOTOS => {
			'array_expr' => 232,
			'const_expr_list' => 177,
			'const_expr' => 181,
			'string' => 74,
			'perl_method' => 76,
			'perl_class' => 77,
			'literal' => 264,
			'expr' => 266,
			'integer' => 79,
			'const_array_expr' => 179,
			'hash_expr' => 231,
			'expr_list' => 267,
			'string_literal' => 84
		}
	},
	{#State 229
		DEFAULT => -137,
		GOTOS => {
			'@2-3' => 268
		}
	},
	{#State 230
		DEFAULT => -83
	},
	{#State 231
		DEFAULT => -131
	},
	{#State 232
		DEFAULT => -130
	},
	{#State 233
		ACTIONS => {
			'QNAME' => 271
		},
		DEFAULT => -139,
		GOTOS => {
			'named_expr' => 270,
			'named_expr_list' => 269
		}
	},
	{#State 234
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 272,
			'action_arg' => 99
		}
	},
	{#State 235
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 273,
			'action_arg' => 101
		}
	},
	{#State 236
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 274
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 237
		DEFAULT => -90
	},
	{#State 238
		DEFAULT => -89
	},
	{#State 239
		ACTIONS => {
			'DOES' => 197
		},
		GOTOS => {
			'does_in_order' => 275
		}
	},
	{#State 240
		DEFAULT => -77
	},
	{#State 241
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 276
		}
	},
	{#State 242
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 277
		}
	},
	{#State 243
		DEFAULT => -83
	},
	{#State 244
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 278,
			'action_arg' => 99
		}
	},
	{#State 245
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 279,
			'action_arg' => 101
		}
	},
	{#State 246
		ACTIONS => {
			'COLON' => 280
		}
	},
	{#State 247
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 281
		}
	},
	{#State 248
		ACTIONS => {
			'SLASH_SLASH' => 187,
			'COLON' => 283,
			'COLON_COLON' => 90,
			'DOES' => 284
		},
		DEFAULT => -82,
		GOTOS => {
			'does_in_order' => 282
		}
	},
	{#State 249
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 285,
			'STDIN' => 67
		},
		GOTOS => {
			'ordered_action_args' => 278,
			'ordered_in_action_args' => 209,
			'in_file' => 113,
			'action_arg' => 99,
			'in_action_arg' => 111
		}
	},
	{#State 250
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 285,
			'STDIN' => 67
		},
		GOTOS => {
			'in_action_args' => 210,
			'action_args' => 279,
			'in_file' => 113,
			'action_arg' => 101,
			'in_action_arg' => 114
		}
	},
	{#State 251
		DEFAULT => -96
	},
	{#State 252
		DEFAULT => -95
	},
	{#State 253
		DEFAULT => -45
	},
	{#State 254
		DEFAULT => -44
	},
	{#State 255
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 286
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 256
		ACTIONS => {
			'COLON' => 287
		}
	},
	{#State 257
		DEFAULT => -129
	},
	{#State 258
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 258,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'LC' => 233,
			'DOLLAR_QNAME' => 85,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 46,
			'QW' => 288,
			'QR' => 88
		},
		DEFAULT => -128,
		GOTOS => {
			'array_expr' => 232,
			'string' => 74,
			'perl_method' => 76,
			'literal' => 257,
			'perl_class' => 77,
			'expr' => 266,
			'integer' => 79,
			'hash_expr' => 231,
			'expr_list' => 267,
			'string_literal' => 84
		}
	},
	{#State 259
		ACTIONS => {
			'DONE' => 289
		}
	},
	{#State 260
		DEFAULT => -107
	},
	{#State 261
		DEFAULT => -123
	},
	{#State 262
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'action_args' => 290,
			'action_arg' => 101
		}
	},
	{#State 263
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 291
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 264
		ACTIONS => {
			'LC' => -129
		},
		DEFAULT => -125
	},
	{#State 265
		ACTIONS => {
			'REGEX' => 292
		}
	},
	{#State 266
		DEFAULT => -133
	},
	{#State 267
		ACTIONS => {
			'S' => 72,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 258,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'LC' => 233,
			'RB' => 293,
			'DOLLAR_QNAME' => 85,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QNAME' => 46,
			'QW' => 294,
			'QR' => 88
		},
		GOTOS => {
			'array_expr' => 232,
			'string' => 74,
			'perl_method' => 76,
			'literal' => 257,
			'perl_class' => 77,
			'expr' => 295,
			'integer' => 79,
			'hash_expr' => 231,
			'string_literal' => 84
		}
	},
	{#State 268
		ACTIONS => {
			'LITERAL' => 296
		}
	},
	{#State 269
		ACTIONS => {
			'QNAME' => 271,
			'RC' => 298
		},
		GOTOS => {
			'named_expr' => 297
		}
	},
	{#State 270
		DEFAULT => -140
	},
	{#State 271
		ACTIONS => {
			'COLON' => 215
		}
	},
	{#State 272
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 299
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 273
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 300
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 274
		DEFAULT => -106
	},
	{#State 275
		ACTIONS => {
			'COLON' => 301
		}
	},
	{#State 276
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 302
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 277
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 303
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 278
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 304
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 279
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 305
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 280
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 306
		}
	},
	{#State 281
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 307
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 282
		ACTIONS => {
			'COLON' => 308
		}
	},
	{#State 283
		ACTIONS => {
			'S' => 72,
			'FILE' => 63,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 228,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'PIPELINE' => 136,
			'LC' => 233,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 138,
			'QNAME' => 248,
			'STDIN' => 67,
			'QR' => 88,
			'DOES' => 141
		},
		DEFAULT => -113,
		GOTOS => {
			'string' => 74,
			'perl_method' => 76,
			'in_action_arg' => 157,
			'const_action_expr' => 130,
			'does_in_order' => 129,
			'perl_class' => 77,
			'literal' => 227,
			'named_expr' => 133,
			'action_arg' => 230,
			'expr' => 229,
			'integer' => 79,
			'const_array_expr' => 135,
			'hash_expr' => 231,
			'string_literal' => 84,
			'array_expr' => 232,
			'in_file' => 113,
			'action' => 140,
			'action_expr' => 309
		}
	},
	{#State 284
		ACTIONS => {
			'COLON' => 310,
			'IN' => 56
		}
	},
	{#State 285
		ACTIONS => {
			'COLON' => 312,
			'DOES' => 313
		},
		GOTOS => {
			'does_in_order' => 311
		}
	},
	{#State 286
		DEFAULT => -47
	},
	{#State 287
		ACTIONS => {
			'QNAME' => 53
		},
		GOTOS => {
			'ordered_action_args' => 314,
			'action_arg' => 99
		}
	},
	{#State 288
		ACTIONS => {
			'REGEX' => 315
		}
	},
	{#State 289
		DEFAULT => -66
	},
	{#State 290
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 316
		},
		GOTOS => {
			'action_arg' => 147
		}
	},
	{#State 291
		DEFAULT => -86
	},
	{#State 292
		ACTIONS => {
			'LC' => -134
		},
		DEFAULT => -122
	},
	{#State 293
		DEFAULT => -142
	},
	{#State 294
		ACTIONS => {
			'REGEX' => 317
		}
	},
	{#State 295
		DEFAULT => -136
	},
	{#State 296
		ACTIONS => {
			'COLON' => 318
		}
	},
	{#State 297
		DEFAULT => -141
	},
	{#State 298
		DEFAULT => -143
	},
	{#State 299
		DEFAULT => -85
	},
	{#State 300
		DEFAULT => -84
	},
	{#State 301
		ACTIONS => {
			'PIPELINE' => 154,
			'QNAME' => 151
		},
		GOTOS => {
			'action' => 155,
			'action_list' => 319
		}
	},
	{#State 302
		DEFAULT => -75
	},
	{#State 303
		DEFAULT => -86
	},
	{#State 304
		DEFAULT => -85
	},
	{#State 305
		DEFAULT => -84
	},
	{#State 306
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 320
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 307
		DEFAULT => -79
	},
	{#State 308
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 285,
			'STDIN' => 67
		},
		GOTOS => {
			'ordered_action_args' => 272,
			'ordered_in_action_args' => 209,
			'in_file' => 113,
			'action_arg' => 99,
			'in_action_arg' => 111
		}
	},
	{#State 309
		DEFAULT => -87
	},
	{#State 310
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 285,
			'STDIN' => 67
		},
		GOTOS => {
			'in_action_args' => 210,
			'action_args' => 273,
			'in_file' => 113,
			'action_arg' => 101,
			'in_action_arg' => 114
		}
	},
	{#State 311
		ACTIONS => {
			'COLON' => 321
		}
	},
	{#State 312
		ACTIONS => {
			'S' => 72,
			'FILE' => 63,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 132,
			'FALSE' => 80,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'PIPELINE' => 136,
			'DOLLAR_QNAME' => 137,
			'LP' => 86,
			'POS_INTEGER' => 138,
			'QNAME' => 248,
			'STDIN' => 67,
			'QR' => 88,
			'DOES' => 141
		},
		DEFAULT => -113,
		GOTOS => {
			'in_file' => 113,
			'string' => 74,
			'perl_method' => 76,
			'in_action_arg' => 157,
			'const_action_expr' => 130,
			'does_in_order' => 129,
			'perl_class' => 77,
			'literal' => 131,
			'named_expr' => 133,
			'action_arg' => 134,
			'integer' => 79,
			'const_array_expr' => 135,
			'action' => 140,
			'action_expr' => 309,
			'string_literal' => 84
		}
	},
	{#State 313
		ACTIONS => {
			'COLON' => 322,
			'IN' => 56
		}
	},
	{#State 314
		ACTIONS => {
			'QNAME' => 53,
			'DONE' => 323
		},
		GOTOS => {
			'action_arg' => 145
		}
	},
	{#State 315
		DEFAULT => -134
	},
	{#State 316
		DEFAULT => -111
	},
	{#State 317
		DEFAULT => -135
	},
	{#State 318
		ACTIONS => {
			'S' => 72,
			'FALSE' => 80,
			'LC' => 233,
			'DOLLAR_QNAME' => 85,
			'LP' => 86,
			'POS_INTEGER' => 87,
			'QR' => 88,
			'TRUE' => 73,
			'LITERAL' => 75,
			'LB' => 258,
			'NEG_INTEGER' => 81,
			'TR' => 82,
			'NUMBER' => 83,
			'QNAME' => 46
		},
		DEFAULT => -128,
		GOTOS => {
			'array_expr' => 232,
			'string' => 74,
			'perl_method' => 76,
			'literal' => 257,
			'perl_class' => 77,
			'expr' => 324,
			'integer' => 79,
			'hash_expr' => 231,
			'string_literal' => 84
		}
	},
	{#State 319
		ACTIONS => {
			'PIPELINE' => 201,
			'QNAME' => 151,
			'DONE' => 325
		},
		GOTOS => {
			'action' => 203
		}
	},
	{#State 320
		DEFAULT => -81
	},
	{#State 321
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 285,
			'STDIN' => 67
		},
		GOTOS => {
			'ordered_action_args' => 192,
			'ordered_in_action_args' => 209,
			'in_file' => 113,
			'action_arg' => 99,
			'in_action_arg' => 111
		}
	},
	{#State 322
		ACTIONS => {
			'FILE' => 63,
			'QNAME' => 285,
			'STDIN' => 67
		},
		GOTOS => {
			'in_action_args' => 210,
			'action_args' => 193,
			'in_file' => 113,
			'action_arg' => 101,
			'in_action_arg' => 114
		}
	},
	{#State 323
		DEFAULT => -48
	},
	{#State 324
		DEFAULT => -138
	},
	{#State 325
		DEFAULT => -76
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'program', 1, undef
	],
	[#Rule 2
		 'program', 2,
sub
#line 53 "unkown"
{ my($a, $b) = @_[1,2]; 
        sub { $a -> (); $b -> () }
   }
	],
	[#Rule 3
		 'program_segment', 1,
sub
#line 59 "unkown"
{ my($body) = $_[1];
        sub {
              $_ -> () for @{$body -> [0]};
              $_ -> () for @{$body -> [1]};
            }
   }
	],
	[#Rule 4
		 'program_segment', 1, undef
	],
	[#Rule 5
		 'machine', 6,
sub
#line 69 "unkown"
{
       # evaluate body in the context of the named machine
       print "MACHINE machine_name DOES COLON body DONE\n";
       my($p, $m, $body) = @_[0,2,5];
       sub { $p -> _eval_in_m($m, sub {
           $_ -> () for @{$body -> [0]};
           $_ -> () for @{$body -> [1]};
       }) };
   }
	],
	[#Rule 6
		 'machine_name', 1,
sub
#line 81 "unkown"
{ $_[1] }
	],
	[#Rule 7
		 'machine_name', 3,
sub
#line 82 "unkown"
{ $_[1] . '::' . $_[3] }
	],
	[#Rule 8
		 'body', 0,
sub
#line 86 "unkown"
{ [ [], [] ] }
	],
	[#Rule 9
		 'body', 2,
sub
#line 87 "unkown"
{ my($b, $d) = @_[1,2];
       [ [ @{$b->[0]}, $d ], $b->[1] ]
   }
	],
	[#Rule 10
		 'body', 2,
sub
#line 90 "unkown"
{ my($b, $p) = @_[1,2];
       [ $b->[0], [ @{$b->[1]}, $p ] ]
   }
	],
	[#Rule 11
		 'decl_stmt', 1, undef
	],
	[#Rule 12
		 'decl_stmt', 1, undef
	],
	[#Rule 13
		 'decl_stmt', 1, undef
	],
	[#Rule 14
		 'decl_stmt', 1, undef
	],
	[#Rule 15
		 'decl_stmt', 1, undef
	],
	[#Rule 16
		 'qname_list', 1,
sub
#line 104 "unkown"
{ [ $_[1] ] }
	],
	[#Rule 17
		 'qname_list', 2,
sub
#line 105 "unkown"
{ [ @{$_[1]}, $_[2] ] }
	],
	[#Rule 18
		 'opt_qname', 0, undef
	],
	[#Rule 19
		 'opt_qname', 1, undef
	],
	[#Rule 20
		 'integer', 1, undef
	],
	[#Rule 21
		 'integer', 1, undef
	],
	[#Rule 22
		 'string_literal', 1,
sub
#line 119 "unkown"
{ my $l = $_[1]; sub { $l } }
	],
	[#Rule 23
		 'string_literal', 1,
sub
#line 120 "unkown"
{ my($p, $v) = @_[0,1]; 
          sub { $p -> _e -> {vars} -> {$v} }
    }
	],
	[#Rule 24
		 'string_literal', 3,
sub
#line 123 "unkown"
{ my($p, $v, $d) = @_[0,1,3]; 
          sub {
              defined($p -> _e -> {vars} -> {$v})
              ? $p -> _e -> {vars} -> {$v}
              : $d -> ()
          }
    }
	],
	[#Rule 25
		 'string', 1,
sub
#line 133 "unkown"
{ $_[1] }
	],
	[#Rule 26
		 'string', 3,
sub
#line 134 "unkown"
{ my($l, $r) = @_[1,3]; sub {  $l->() . $r -> () } }
	],
	[#Rule 27
		 'literal', 1,
sub
#line 139 "unkown"
{ $_[1] }
	],
	[#Rule 28
		 'literal', 1,
sub
#line 140 "unkown"
{ my $s = $_[1]; sub { $s } }
	],
	[#Rule 29
		 'literal', 1,
sub
#line 141 "unkown"
{ my $s = $_[1]; sub { $s } }
	],
	[#Rule 30
		 'literal', 2,
sub
#line 142 "unkown"
{ my $s = $_[2];  sub { qr/$s/ } }
	],
	[#Rule 31
		 'literal', 2,
sub
#line 143 "unkown"
{ my($l,$r) = @{$_[2]}; 
            $l =~ s[([^\\]){][$1\\{]g; 
            $l =~ s[([^\\])}][$1\\}]g; 
            $r =~ s[([^\\]){][$1\\{]g; 
            $r =~ s[([^\\])}][$1\\}]g; 
            sub { eval "sub { s{$l}{$r}gs }" }
    }
	],
	[#Rule 32
		 'literal', 2,
sub
#line 150 "unkown"
{ my($l,$r) = @{$_[2]}; 
            $l =~ s[([^\\]){][$1\\{]g; 
            $l =~ s[([^\\])}][$1\\}]g; 
            $r =~ s[([^\\]){][$1\\{]g; 
            $r =~ s[([^\\])}][$1\\}]g; 
            sub { eval "sub { tr{$l}{$r} }" }
    }
	],
	[#Rule 33
		 'literal', 1,
sub
#line 157 "unkown"
{ sub { 1 } }
	],
	[#Rule 34
		 'literal', 1,
sub
#line 158 "unkown"
{ sub { 0 } }
	],
	[#Rule 35
		 'literal', 1,
sub
#line 159 "unkown"
{ $_[1] }
	],
	[#Rule 36
		 'literal', 3,
sub
#line 160 "unkown"
{ $_[2] }
	],
	[#Rule 37
		 'in_file', 1,
sub
#line 164 "unkown"
{ sub { \*STDIN } }
	],
	[#Rule 38
		 'in_file', 2,
sub
#line 165 "unkown"
{ my $fname = $_[2]; sub { my $fn = $fname -> (); print "opening $fn\n"; open my $fh, "<", ($fn); print "fh: $fh\n"; $fh } }
	],
	[#Rule 39
		 'in_file', 4,
sub
#line 166 "unkown"
{ my($p, $v) = @_[0,2];
       sub {
           if(defined($p -> _e -> {vars} -> {$v})) {
               my $fname = $p -> _e -> {vars} -> {$v};
               open my $fh, "<", ($fname);
               return $fh;
           }
           return \*STDIN;
       }
   }
	],
	[#Rule 40
		 'out_file', 1,
sub
#line 179 "unkown"
{ sub { \*STDOUT } }
	],
	[#Rule 41
		 'out_file', 2,
sub
#line 180 "unkown"
{ my $fname = $_[2]; sub { open my $fh, ">", ($fname -> ()); $fh } }
	],
	[#Rule 42
		 'out_file', 4,
sub
#line 181 "unkown"
{ my($p, $v) = @_[0,2];
       sub {
           if(defined($p -> _e -> {vars} -> {$v})) {
               my $fname = $p -> _e -> {vars} -> {$v};
               open my $fh, ">", ($fname);
               return $fh;
           }
           return \*STDOUT;
       }
   }
	],
	[#Rule 43
		 'perl_method', 1,
sub
#line 194 "unkown"
{
        my($p, $class, $method) = (@_[0,1], 'new');
        sub {
            $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
            $class -> can($method) or die "Unable to find '$method' for '$class'\n";

            $class -> $method(); 
       }
   }
	],
	[#Rule 44
		 'perl_method', 5,
sub
#line 203 "unkown"
{
        my($p, $class, $method, $args) = ($_[0], $_[1], 'new', $_[4]);
        sub {
            $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
            $class -> can($method) or die "Unable to find '$method' for '$class'\n";
            $class -> $method(%{$args -> ()});
       }
   }
	],
	[#Rule 45
		 'perl_method', 5,
sub
#line 211 "unkown"
{
        my($p, $class, $method, $args) = ($_[0], $_[1], 'new', $_[4]);
        sub {
            $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
            $class -> can($method) or die "Unable to find '$method' for '$class'\n";
            $class -> $method(@{$args->()});  
       }
   }
	],
	[#Rule 46
		 'perl_method', 3,
sub
#line 219 "unkown"
{ 
         my($p, $class, $method) = (@_[0,1,3]);
         sub {
             $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
             $class -> can($method) or die "Unable to find '$method' for '$class'\n";

             $class -> $method();  
        }
   }
	],
	[#Rule 47
		 'perl_method', 6,
sub
#line 228 "unkown"
{ 
         my($p, $class, $method, $args) = (@_[0,1,3,5]);
         sub {
             $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
             $class -> can($method) or die "Unable to find '$method' for '$class'\n";
             $class -> $method(%{$args->()})  
        }
   }
	],
	[#Rule 48
		 'perl_method', 8,
sub
#line 236 "unkown"
{ 
         my($p, $class, $method, $args) = (@_[0,1,3,7]);
         sub {
             $p -> _perl_classes -> {$class} or die "Unable to find '$class'\n";
             $class -> can($method) or die "Unable to find '$method' for '$class'\n";
             $class-> $method(@{$args -> ()}); 
        }
   }
	],
	[#Rule 49
		 'let_stmt', 4,
sub
#line 247 "unkown"
{ 
           my($p, $var, $val) = @_[0,2,4];
           sub { $p -> _vars -> {$var} = $val -> (); }
       }
	],
	[#Rule 50
		 'let_stmt', 3,
sub
#line 251 "unkown"
{ 
           my($p, $var) = @_[0,2];
           sub { $p -> _vars -> {$var} = undef; }
       }
	],
	[#Rule 51
		 'use_stmt', 3,
sub
#line 258 "unkown"
{
           my($p, $list) = @_[0,3];
           sub { $p -> load_actions("Action", @{$list}); }
       }
	],
	[#Rule 52
		 'use_stmt', 3,
sub
#line 262 "unkown"
{
           my($p, $list) = @_[0,3];
           sub { $p -> load_actions("Adapter", @{$list}); }
       }
	],
	[#Rule 53
		 'use_stmt', 3,
sub
#line 266 "unkown"
{
           my($p, $list) = @_[0,3];
           sub { $p -> load_actions("Adapter", @{$list}); }
       }
	],
	[#Rule 54
		 'import_stmt', 3,
sub
#line 273 "unkown"
{
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
	],
	[#Rule 55
		 'io_stmt', 3,
sub
#line 292 "unkown"
{
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {to} = [ %{$v -> ()} ] }
    }
	],
	[#Rule 56
		 'io_stmt', 3,
sub
#line 296 "unkown"
{
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {to} = [ $v -> () ] }
    }
	],
	[#Rule 57
		 'io_stmt', 5,
sub
#line 300 "unkown"
{
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {to} = [ %{$v -> ()} ] }
    }
	],
	[#Rule 58
		 'io_stmt', 5,
sub
#line 304 "unkown"
{
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {to} = $v -> () }
    }
	],
	[#Rule 59
		 'io_stmt', 3,
sub
#line 308 "unkown"
{
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {from} = [ %{$v -> ()} ] }
    }
	],
	[#Rule 60
		 'io_stmt', 3,
sub
#line 312 "unkown"
{
        my($p, $v) = @_[0,3];
        sub { $p -> _e -> {from} = [ $v -> () ] }
    }
	],
	[#Rule 61
		 'io_stmt', 5,
sub
#line 316 "unkown"
{
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {from} = [ %{$v -> ()} ] }
    }
	],
	[#Rule 62
		 'io_stmt', 5,
sub
#line 320 "unkown"
{
        my($p, $v) = @_[0,4];
        sub { $p -> _e -> {from} = $v -> () }
    }
	],
	[#Rule 63
		 'filter_type', 1,
sub
#line 331 "unkown"
{ 'any' }
	],
	[#Rule 64
		 'filter_type', 1,
sub
#line 332 "unkown"
{ 'all' }
	],
	[#Rule 65
		 '@1-6', 0,
sub
#line 336 "unkown"
{ 
        $_[0] -> in_freeform_until_done; 
        [ @_[2,4,1] ]
    }
	],
	[#Rule 66
		 'filter_def', 9,
sub
#line 339 "unkown"
{ 
        my($p,$info, $code) = @_[0,7,8];
        sub { $p -> compile_ext_lang(@$info, $code) }
    }
	],
	[#Rule 67
		 'perl_class', 3,
sub
#line 346 "unkown"
{ $_[1] . '::' . $_[3] }
	],
	[#Rule 68
		 'perl_class', 3,
sub
#line 347 "unkown"
{ $_[1] . '::' . $_[3] }
	],
	[#Rule 69
		 'perl_class_list', 1,
sub
#line 351 "unkown"
{ [ $_[1] ] }
	],
	[#Rule 70
		 'perl_class_list', 2,
sub
#line 352 "unkown"
{ [ @{$_[1]}, $_[2] ] }
	],
	[#Rule 71
		 'does_in_order', 3, undef
	],
	[#Rule 72
		 'pipeline_def', 6,
sub
#line 360 "unkown"
{
            my($p, $n, $a) = @_[0,2,5];
            sub {
                $a = $a -> ();
                $a = $a->[0] if @$a == 1;
                $p->_m->add_pipeline((defined($n)?$n:'finally'), $a);
            }
        }
	],
	[#Rule 73
		 'pipeline_def', 6,
sub
#line 368 "unkown"
{
            my($p, $n, $a) = @_[0,2,5];
            sub {
                $p->_m->add_pipeline((defined($n)?$n:'finally'), 
                    Data::Pipeline::Aggregator::Union -> new(
                        actions => $a -> ()
                    )
                )
            }
        }
	],
	[#Rule 74
		 'actions', 1,
sub
#line 381 "unkown"
{ my($a) = $_[1]; sub { [ $a -> () ] } }
	],
	[#Rule 75
		 'actions', 5,
sub
#line 382 "unkown"
{ $_[4] }
	],
	[#Rule 76
		 'actions', 7,
sub
#line 383 "unkown"
{ my($a, $b) = @_[1,6];
        sub { [ @{$a -> ()}, @{$b -> ()} ] }
    }
	],
	[#Rule 77
		 'actions', 3,
sub
#line 386 "unkown"
{ my($a, $b) = @_[1,3];
        sub { [ @{$a -> ()}, $b -> () ] }
    }
	],
	[#Rule 78
		 'action_list', 1,
sub
#line 392 "unkown"
{ my($a) = $_[1]; sub { [ $a -> () ] } }
	],
	[#Rule 79
		 'action_list', 5,
sub
#line 393 "unkown"
{ $_[4] }
	],
	[#Rule 80
		 'action_list', 2,
sub
#line 395 "unkown"
{ my($a, $b) = @_[1,3];
        sub { [ @{$a -> ()}, $b -> () ] }
    }
	],
	[#Rule 81
		 'action_list', 6,
sub
#line 398 "unkown"
{ my($a, $b) = @_[1,5];
        sub { [ @{$a -> ()}, @{$b -> ()} ] }
    }
	],
	[#Rule 82
		 'action', 1,
sub
#line 404 "unkown"
{
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
	],
	[#Rule 83
		 'action', 3,
sub
#line 415 "unkown"
{
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
	],
	[#Rule 84
		 'action', 5,
sub
#line 426 "unkown"
{
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
	],
	[#Rule 85
		 'action', 5,
sub
#line 437 "unkown"
{
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
	],
	[#Rule 86
		 'action', 5,
sub
#line 448 "unkown"
{
        my($args) = $_[4];
        sub {
            Data::Pipeline::Aggregator::Union -> new(
                actions => $args->()
            );
        }
    }
	],
	[#Rule 87
		 'action_arg', 3,
sub
#line 459 "unkown"
{ my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
	],
	[#Rule 88
		 'action_arg', 3,
sub
#line 460 "unkown"
{ my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
	],
	[#Rule 89
		 'action_arg', 5,
sub
#line 461 "unkown"
{ my($q,$a) = @_[1,4]; sub { +{$q => $a->()} } }
	],
	[#Rule 90
		 'action_arg', 5,
sub
#line 462 "unkown"
{my($q,$a) = @_[1,4]; sub { +{ $q => $a->() } } }
	],
	[#Rule 91
		 'action_args', 1, undef
	],
	[#Rule 92
		 'action_args', 2,
sub
#line 467 "unkown"
{ my($a,$b) = @_[1,2]; sub { +{ %{$a->()}, %{$b->()} } } }
	],
	[#Rule 93
		 'in_action_arg', 3,
sub
#line 471 "unkown"
{ my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
	],
	[#Rule 94
		 'in_action_arg', 3,
sub
#line 472 "unkown"
{ my($q, $a) = @_[1,3]; sub { +{$q => $a->()} } }
	],
	[#Rule 95
		 'in_action_arg', 5,
sub
#line 473 "unkown"
{ my($q,$a) = @_[1,4]; sub { +{$q => $a->()} } }
	],
	[#Rule 96
		 'in_action_arg', 5,
sub
#line 474 "unkown"
{my($q,$a) = @_[1,4]; sub { +{ $q => $a->() } } }
	],
	[#Rule 97
		 'in_action_arg', 1, undef
	],
	[#Rule 98
		 'in_action_args', 1, undef
	],
	[#Rule 99
		 'in_action_args', 2,
sub
#line 480 "unkown"
{ my($a,$b) = @_[1,2]; sub { +{ %{$a->()}, %{$b->()} } } }
	],
	[#Rule 100
		 'ordered_action_args', 1,
sub
#line 484 "unkown"
{ my $a = $_[1]; sub { [ %{$a -> ()} ] } }
	],
	[#Rule 101
		 'ordered_action_args', 2,
sub
#line 485 "unkown"
{ my($a,$b) = @_[1,2]; sub { [ @{$a->()}, %{$b->()}]} }
	],
	[#Rule 102
		 'ordered_in_action_args', 1,
sub
#line 489 "unkown"
{ my $a = $_[1]; sub { [ %{$a -> ()} ] } }
	],
	[#Rule 103
		 'ordered_in_action_args', 2,
sub
#line 490 "unkown"
{ my($a,$b) = @_[1,2]; sub { [ @{$a->()}, %{$b->()}]} }
	],
	[#Rule 104
		 'action_expr', 1, undef
	],
	[#Rule 105
		 'action_expr', 1, undef
	],
	[#Rule 106
		 'action_expr', 4,
sub
#line 496 "unkown"
{ $_[3] }
	],
	[#Rule 107
		 'action_expr', 4,
sub
#line 497 "unkown"
{ $_[3] }
	],
	[#Rule 108
		 'action_expr', 3,
sub
#line 498 "unkown"
{ 
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
	],
	[#Rule 109
		 'action_expr', 3,
sub
#line 509 "unkown"
{
          my($opt,$default) = @_[2,4];
          sub {
              Data::Pipeline::Iterator -> new( coded_source => sub {
                  to_IteratorSource( defined($ARGV[$opt]) ?
                      $ARGV[$opt] : $default -> ()
                  );
              });
          }
    }
	],
	[#Rule 110
		 'action_expr', 2,
sub
#line 519 "unkown"
{ 
          my($p, $qname) = @_[0,2];

          sub {
             Data::Pipeline::Machine::Surrogate -> new(
                 machine => $p->_m,
                 named_pipeline => $qname,
                 options => { }
             );
          }
        }
	],
	[#Rule 111
		 'action_expr', 6,
sub
#line 530 "unkown"
{
        my($p,$qname,$args) = @_[0,2,5];

        sub {
             Data::Pipeline::Machine::Surrogate -> new(
                 machine => $p->_m,
                 named_pipeline => $qname,
                 options => $args
             );
        }
    }
	],
	[#Rule 112
		 'action_expr', 5,
sub
#line 541 "unkown"
{
        my($args) = $_[4];

        sub {
            Data::Pipeline::Aggregator::Union -> new(
                actions => $args -> ()
            );
        }
    }
	],
	[#Rule 113
		 'const_action_expr', 0,
sub
#line 553 "unkown"
{ sub { } }
	],
	[#Rule 114
		 'const_action_expr', 1,
sub
#line 554 "unkown"
{ $_[1] }
	],
	[#Rule 115
		 'const_action_expr', 1,
sub
#line 555 "unkown"
{ my($p, $v) = @_; 
          sub { $p -> _vars -> {$v} }
    }
	],
	[#Rule 116
		 'const_action_expr', 3,
sub
#line 558 "unkown"
{ my($p, $v, $d) = @_[0,1,3]; 
          sub {
              defined($p -> _vars -> {$v})
              ? $p -> _vars -> {$v}
              : $d
          }
    }
	],
	[#Rule 117
		 'const_action_expr', 1,
sub
#line 565 "unkown"
{ $_[1] }
	],
	[#Rule 118
		 'const_action_expr', 1,
sub
#line 566 "unkown"
{ $_[1] }
	],
	[#Rule 119
		 'const_array_expr', 3,
sub
#line 570 "unkown"
{ $_[2] }
	],
	[#Rule 120
		 'const_expr_list', 0,
sub
#line 574 "unkown"
{ sub { [] } }
	],
	[#Rule 121
		 'const_expr_list', 1,
sub
#line 575 "unkown"
{ my $a = $_[1]; sub { [ $a -> () ] } }
	],
	[#Rule 122
		 'const_expr_list', 2,
sub
#line 576 "unkown"
{ my($a) = $_[2];
        sub {[ split(/\s+/, $a) ]} 
    }
	],
	[#Rule 123
		 'const_expr_list', 3,
sub
#line 579 "unkown"
{ my($a, $b) = @_[1,3];
        sub {[ @{$a -> ()}, split(/\s+/, $b) ] }
    }
	],
	[#Rule 124
		 'const_expr_list', 2,
sub
#line 582 "unkown"
{ my($a,$b) = @_[1,2];
        sub { [ @{$a -> ()}, @{$b -> ()} ] }
    }
	],
	[#Rule 125
		 'const_expr', 1,
sub
#line 588 "unkown"
{ $_[1] }
	],
	[#Rule 126
		 'const_expr', 1,
sub
#line 589 "unkown"
{ $_[1] }
	],
	[#Rule 127
		 'const_expr', 1,
sub
#line 590 "unkown"
{
          my($p, $v) = @_[0,1];
          sub { $p -> _vars -> {$v} }
      }
	],
	[#Rule 128
		 'expr', 0,
sub
#line 597 "unkown"
{ sub { } }
	],
	[#Rule 129
		 'expr', 1,
sub
#line 598 "unkown"
{ $_[1] }
	],
	[#Rule 130
		 'expr', 1,
sub
#line 599 "unkown"
{ $_[1] }
	],
	[#Rule 131
		 'expr', 1,
sub
#line 600 "unkown"
{ $_[1] }
	],
	[#Rule 132
		 'expr_list', 0,
sub
#line 604 "unkown"
{ sub {[]} }
	],
	[#Rule 133
		 'expr_list', 1,
sub
#line 605 "unkown"
{ my($a) = $_[1]; sub { [ $a -> () ] } }
	],
	[#Rule 134
		 'expr_list', 2,
sub
#line 606 "unkown"
{ my $r = $_[2]; sub { [ split(/\s+/, $r) ] } }
	],
	[#Rule 135
		 'expr_list', 3,
sub
#line 607 "unkown"
{ my($e,$r) = @_[1,3]; sub { [ @{$e->()}, split(/\s+/, $r) ] } }
	],
	[#Rule 136
		 'expr_list', 2,
sub
#line 608 "unkown"
{ my($a,$b) = @_[1,2]; sub { [ @{$a -> ()}, @{$b->()} ] } }
	],
	[#Rule 137
		 '@2-3', 0,
sub
#line 612 "unkown"
{ my($l,$r) = @_[1,3]; sub { +{ $l => $r->() } } }
	],
	[#Rule 138
		 'named_expr', 7,
sub
#line 613 "unkown"
{ my($l,$r) = @_[1,3]; sub { +{ $l => $r->() } } }
	],
	[#Rule 139
		 'named_expr_list', 0,
sub
#line 617 "unkown"
{ sub { +{ } } }
	],
	[#Rule 140
		 'named_expr_list', 1,
sub
#line 618 "unkown"
{ $_[1] }
	],
	[#Rule 141
		 'named_expr_list', 2,
sub
#line 619 "unkown"
{ my($a, $b) = @_[1,2];
        sub { +{ %{$a -> ()}, %{$b -> ()} } }
    }
	],
	[#Rule 142
		 'array_expr', 3,
sub
#line 625 "unkown"
{ $_[2] }
	],
	[#Rule 143
		 'hash_expr', 3,
sub
#line 629 "unkown"
{ $_[2] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 631 "unkown"



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

1;
