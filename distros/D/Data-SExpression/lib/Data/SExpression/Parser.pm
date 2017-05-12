####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Data::SExpression::Parser;
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


#line 9 "lib/Data/SExpression/Parser.yp"

use Data::SExpression::Cons;
use Scalar::Util qw(weaken);


sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 7,
			'sexpression' => 6,
			'quoted' => 2,
			'list' => 9
		}
	},
	{#State 1
		DEFAULT => -3
	},
	{#State 2
		DEFAULT => -6
	},
	{#State 3
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 10,
			'quoted' => 2,
			'list' => 9
		}
	},
	{#State 4
		DEFAULT => -4
	},
	{#State 5
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		DEFAULT => -11,
		GOTOS => {
			'expression' => 11,
			'quoted' => 2,
			'list_interior' => 12,
			'list' => 9
		}
	},
	{#State 6
		ACTIONS => {
			'' => 13
		}
	},
	{#State 7
		DEFAULT => -1
	},
	{#State 8
		DEFAULT => -2
	},
	{#State 9
		DEFAULT => -5
	},
	{#State 10
		DEFAULT => -12
	},
	{#State 11
		ACTIONS => {
			'SYMBOL' => 1,
			'STRING' => 4,
			'QUOTE' => 3,
			"(" => 5,
			'NUMBER' => 8,
			"." => 15
		},
		DEFAULT => -10,
		GOTOS => {
			'expression' => 11,
			'quoted' => 2,
			'list_interior' => 14,
			'list' => 9
		}
	},
	{#State 12
		ACTIONS => {
			")" => 16
		}
	},
	{#State 13
		DEFAULT => 0
	},
	{#State 14
		DEFAULT => -9
	},
	{#State 15
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 17,
			'quoted' => 2,
			'list' => 9
		}
	},
	{#State 16
		DEFAULT => -7
	},
	{#State 17
		DEFAULT => -8
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'sexpression', 1,
sub
#line 16 "lib/Data/SExpression/Parser.yp"
{ $_[0]->YYAccept; return $_[1]; }
	],
	[#Rule 2
		 'expression', 1, undef
	],
	[#Rule 3
		 'expression', 1,
sub
#line 20 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_symbol($_[1]) }
	],
	[#Rule 4
		 'expression', 1,
sub
#line 21 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_string($_[1]) }
	],
	[#Rule 5
		 'expression', 1, undef
	],
	[#Rule 6
		 'expression', 1, undef
	],
	[#Rule 7
		 'list', 3,
sub
#line 27 "lib/Data/SExpression/Parser.yp"
{ $_[2] }
	],
	[#Rule 8
		 'list_interior', 3,
sub
#line 32 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[1], $_[3]) }
	],
	[#Rule 9
		 'list_interior', 2,
sub
#line 33 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[1], $_[2]) }
	],
	[#Rule 10
		 'list_interior', 1,
sub
#line 34 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[1], undef) }
	],
	[#Rule 11
		 'list_interior', 0,
sub
#line 35 "lib/Data/SExpression/Parser.yp"
{ undef }
	],
	[#Rule 12
		 'quoted', 2,
sub
#line 40 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[0]->handler->new_symbol($_[1]),
                                                                    $_[0]->handler->new_cons($_[2], undef))}
	]
],
                                  @_);
    bless($self,$class);
}

#line 44 "lib/Data/SExpression/Parser.yp"


sub set_input {
    my $self = shift;
    my $input = shift;
    die(__PACKAGE__ . "::set_input called with 0 arguments") unless defined($input);
    $self->YYData->{INPUT} = $input;
}

sub set_handler {
    my $self = shift;
    my $handler = shift or die(__PACKAGE__ . "::set_handler called with 0 arguments");
    $self->YYData->{HANDLER} = $handler;
    weaken $self->YYData->{HANDLER};
}

sub handler {
    my $self = shift;
    return $self->YYData->{HANDLER};
}

sub unparsed_input {
    my $self = shift;
    return substr($self->YYData->{INPUT}, pos($self->YYData->{INPUT}));
}


my %quotes = (q{'} => 'quote',
              q{`} => 'quasiquote',
              q{,} => 'unquote');


sub lexer {
    my $self = shift;

    defined($self->YYData->{INPUT}) or return ('', undef);

    my $symbol_char = qr{[*!\$[:alpha:]\?<>=/+:_{}-]};

    for($self->YYData->{INPUT}) {
        $_ =~ /\G \s* (?: ; .* \s* )* /gcx;

        /\G ([+-]? \d+ (?:[.]\d*)?) /gcx
        || /\G ([+-]? [.] \d+) /gcx
          and return ('NUMBER', $1);

        /\G ($symbol_char ($symbol_char | \d | [.] )*)/gcx
          and return ('SYMBOL', $1);

        /\G (\| [^|]* \|) /gcx
          and return ('SYMBOL', $1);

        /\G " ([^"\\]* (?: \\. [^"\\]*)*) "/gcx
          and return ('STRING', defined($1) ? $1 : "");

        /\G ([().])/gcx
          and return ($1, $1);

        /\G ([`',]) /gcx
          and return ('QUOTE', $quotes{$1});

        return ('', undef);
    }
}

sub error {
    my $self = shift;
    my ($tok, $val) = $self->YYLexer->($self);
    die("Parse error near: '" . $self->unparsed_input . "'");
    return undef;
}

sub parse {
    my $self = shift;
    return $self->YYParse(yylex => \&lexer, yyerror => \&error);
}

1;
