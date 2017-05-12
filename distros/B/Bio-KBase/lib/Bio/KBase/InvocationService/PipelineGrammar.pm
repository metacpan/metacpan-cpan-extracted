########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.182.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file 'pipeline.yp' instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package Bio::KBase::InvocationService::PipelineGrammar;
use strict;

push @Bio::KBase::InvocationService::PipelineGrammar::ISA, 'Parse::Eyapp::Driver';




BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  

sub unexpendedInput { defined($_) ? substr($_, (defined(pos $_) ? pos $_ : 0)) : '' }

#line 4 "pipeline.yp"




# Default lexical analyzer
our $LEX = sub {
    my $self = shift;
    my $pos;

    for (${$self->input}) {
      

      /\G([ \t]+)/gc and $self->tokenline($1 =~ tr{\n}{});

      m{\G(2\>\>|2\>|\>\>|\<|\||\>)}gc and return ($1, $1);

      /\G([^"']\S*)/gc and return ('TERM', $1);
      /\G"((?:[^\\"]|\\.)*)"/gc and return ('DQSTRING', $1);
      /\G'((?:[^\\']|\\.)*)'/gc and return ('SQSTRING', $1);


      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      /\G\s*(\S+)/;
      my $near = substr($1,0,10); 

      return($near, $near);

     # die( "Error inside the lexical analyzer near '". $near
     #     ."'. Line: ".$self->line()
     #     .". File: '".$self->YYFilename()."'. No match found.\n");
    }
  }
;


#line 67 Bio/KBase/InvocationService/PipelineGrammar.pm

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@Bio::KBase::InvocationService::PipelineGrammar::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.182',
    yyGRAMMAR  =>
[#[productionNameAndLabel => lhs, [ rhs], bypass]]
  [ '_SUPERSTART' => '$start', [ 'start', '$end' ], 0 ],
  [ 'start_1' => 'start', [ 'pipeline' ], 0 ],
  [ 'pipeline_2' => 'pipeline', [ 'pipe_item' ], 0 ],
  [ 'pipeline_3' => 'pipeline', [ 'pipeline', '|', 'pipe_item' ], 0 ],
  [ 'pipe_item_4' => 'pipe_item', [ 'command', 'args', 'redirections' ], 0 ],
  [ 'command_5' => 'command', [ 'TERM' ], 0 ],
  [ 'args_6' => 'args', [  ], 0 ],
  [ 'args_7' => 'args', [ 'arg' ], 0 ],
  [ 'args_8' => 'args', [ 'args', 'arg' ], 0 ],
  [ 'arg_9' => 'arg', [ 'TERM' ], 0 ],
  [ 'arg_10' => 'arg', [ 'SQSTRING' ], 0 ],
  [ 'arg_11' => 'arg', [ 'DQSTRING' ], 0 ],
  [ 'redirections_12' => 'redirections', [  ], 0 ],
  [ 'redirections_13' => 'redirections', [ 'redirection' ], 0 ],
  [ 'redirections_14' => 'redirections', [ 'redirections', 'redirection' ], 0 ],
  [ 'redirection_15' => 'redirection', [ '<', 'path' ], 0 ],
  [ 'redirection_16' => 'redirection', [ '>', 'path' ], 0 ],
  [ 'redirection_17' => 'redirection', [ '2>', 'path' ], 0 ],
  [ 'redirection_18' => 'redirection', [ '>>', 'path' ], 0 ],
  [ 'redirection_19' => 'redirection', [ '2>>', 'path' ], 0 ],
  [ 'path_20' => 'path', [ 'TERM' ], 0 ],
  [ 'path_21' => 'path', [ 'SQSTRING' ], 0 ],
  [ 'path_22' => 'path', [ 'DQSTRING' ], 0 ],
],
    yyLABELS  =>
{
  '_SUPERSTART' => 0,
  'start_1' => 1,
  'pipeline_2' => 2,
  'pipeline_3' => 3,
  'pipe_item_4' => 4,
  'command_5' => 5,
  'args_6' => 6,
  'args_7' => 7,
  'args_8' => 8,
  'arg_9' => 9,
  'arg_10' => 10,
  'arg_11' => 11,
  'redirections_12' => 12,
  'redirections_13' => 13,
  'redirections_14' => 14,
  'redirection_15' => 15,
  'redirection_16' => 16,
  'redirection_17' => 17,
  'redirection_18' => 18,
  'redirection_19' => 19,
  'path_20' => 20,
  'path_21' => 21,
  'path_22' => 22,
},
    yyTERMS  =>
{ '' => { ISSEMANTIC => 0 },
	'2>' => { ISSEMANTIC => 0 },
	'2>>' => { ISSEMANTIC => 0 },
	'<' => { ISSEMANTIC => 0 },
	'>' => { ISSEMANTIC => 0 },
	'>>' => { ISSEMANTIC => 0 },
	'|' => { ISSEMANTIC => 0 },
	DQSTRING => { ISSEMANTIC => 1 },
	SQSTRING => { ISSEMANTIC => 1 },
	TERM => { ISSEMANTIC => 1 },
	error => { ISSEMANTIC => 0 },
},
    yyFILENAME  => 'pipeline.yp',
    yystates =>
[
	{#State 0
		ACTIONS => {
			'TERM' => 2
		},
		GOTOS => {
			'pipe_item' => 1,
			'pipeline' => 3,
			'start' => 5,
			'command' => 4
		}
	},
	{#State 1
		DEFAULT => -2
	},
	{#State 2
		DEFAULT => -5
	},
	{#State 3
		ACTIONS => {
			"|" => 6
		},
		DEFAULT => -1
	},
	{#State 4
		ACTIONS => {
			'DQSTRING' => 10,
			'SQSTRING' => 11,
			'TERM' => 8
		},
		DEFAULT => -6,
		GOTOS => {
			'arg' => 7,
			'args' => 9
		}
	},
	{#State 5
		ACTIONS => {
			'' => 12
		}
	},
	{#State 6
		ACTIONS => {
			'TERM' => 2
		},
		GOTOS => {
			'pipe_item' => 13,
			'command' => 4
		}
	},
	{#State 7
		DEFAULT => -7
	},
	{#State 8
		DEFAULT => -9
	},
	{#State 9
		ACTIONS => {
			"<" => 14,
			'DQSTRING' => 10,
			'SQSTRING' => 11,
			"2>" => 18,
			'TERM' => 8,
			"2>>" => 19,
			">" => 21,
			">>" => 20
		},
		DEFAULT => -12,
		GOTOS => {
			'arg' => 15,
			'redirections' => 16,
			'redirection' => 17
		}
	},
	{#State 10
		DEFAULT => -11
	},
	{#State 11
		DEFAULT => -10
	},
	{#State 12
		DEFAULT => 0
	},
	{#State 13
		DEFAULT => -3
	},
	{#State 14
		ACTIONS => {
			'TERM' => 25,
			'DQSTRING' => 22,
			'SQSTRING' => 24
		},
		GOTOS => {
			'path' => 23
		}
	},
	{#State 15
		DEFAULT => -8
	},
	{#State 16
		ACTIONS => {
			"<" => 14,
			"2>>" => 19,
			">" => 21,
			">>" => 20,
			"2>" => 18
		},
		DEFAULT => -4,
		GOTOS => {
			'redirection' => 26
		}
	},
	{#State 17
		DEFAULT => -13
	},
	{#State 18
		ACTIONS => {
			'TERM' => 25,
			'DQSTRING' => 22,
			'SQSTRING' => 24
		},
		GOTOS => {
			'path' => 27
		}
	},
	{#State 19
		ACTIONS => {
			'TERM' => 25,
			'DQSTRING' => 22,
			'SQSTRING' => 24
		},
		GOTOS => {
			'path' => 28
		}
	},
	{#State 20
		ACTIONS => {
			'TERM' => 25,
			'DQSTRING' => 22,
			'SQSTRING' => 24
		},
		GOTOS => {
			'path' => 29
		}
	},
	{#State 21
		ACTIONS => {
			'TERM' => 25,
			'DQSTRING' => 22,
			'SQSTRING' => 24
		},
		GOTOS => {
			'path' => 30
		}
	},
	{#State 22
		DEFAULT => -22
	},
	{#State 23
		DEFAULT => -15
	},
	{#State 24
		DEFAULT => -21
	},
	{#State 25
		DEFAULT => -20
	},
	{#State 26
		DEFAULT => -14
	},
	{#State 27
		DEFAULT => -17
	},
	{#State 28
		DEFAULT => -19
	},
	{#State 29
		DEFAULT => -18
	},
	{#State 30
		DEFAULT => -16
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
#line 334 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule start_1
		 'start', 1, undef
#line 338 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule pipeline_2
		 'pipeline', 1,
sub {
#line 21 "pipeline.yp"
my $item = $_[1];  [ $item ] }
#line 345 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule pipeline_3
		 'pipeline', 3,
sub {
#line 22 "pipeline.yp"
my $item = $_[3]; my $pipeline = $_[1];  [ @$pipeline, $item ] }
#line 352 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule pipe_item_4
		 'pipe_item', 3,
sub {
#line 25 "pipeline.yp"
my $redir = $_[3]; my $cmd = $_[1]; my $args = $_[2];  { cmd => $cmd, args => $args, redir => $redir } }
#line 359 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule command_5
		 'command', 1, undef
#line 363 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule args_6
		 'args', 0,
sub {
#line 31 "pipeline.yp"
 [] }
#line 370 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule args_7
		 'args', 1,
sub {
#line 32 "pipeline.yp"
my $arg = $_[1];  [ $arg ] }
#line 377 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule args_8
		 'args', 2,
sub {
#line 33 "pipeline.yp"
my $arg = $_[2]; my $args = $_[1];  [ @$args, $arg ] }
#line 384 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_9
		 'arg', 1, undef
#line 388 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_10
		 'arg', 1, undef
#line 392 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_11
		 'arg', 1, undef
#line 396 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirections_12
		 'redirections', 0,
sub {
#line 41 "pipeline.yp"
 [] }
#line 403 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirections_13
		 'redirections', 1,
sub {
#line 42 "pipeline.yp"
my $item = $_[1];  [ $item ] }
#line 410 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirections_14
		 'redirections', 2,
sub {
#line 43 "pipeline.yp"
my $item = $_[2]; my $list = $_[1];  [ @$list, $item ] }
#line 417 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_15
		 'redirection', 2,
sub {
#line 46 "pipeline.yp"
my $path = $_[2];  [ '<', $path ] }
#line 424 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_16
		 'redirection', 2,
sub {
#line 47 "pipeline.yp"
my $path = $_[2];  [ '>', $path ] }
#line 431 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_17
		 'redirection', 2,
sub {
#line 48 "pipeline.yp"
my $path = $_[2];  [ '2>', $path ] }
#line 438 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_18
		 'redirection', 2,
sub {
#line 49 "pipeline.yp"
my $path = $_[2];  [ '>>', $path ] }
#line 445 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_19
		 'redirection', 2,
sub {
#line 50 "pipeline.yp"
my $path = $_[2];  [ '2>>', $path ] }
#line 452 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule path_20
		 'path', 1, undef
#line 456 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule path_21
		 'path', 1, undef
#line 460 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule path_22
		 'path', 1, undef
#line 464 Bio/KBase/InvocationService/PipelineGrammar.pm
	]
],
#line 467 Bio/KBase/InvocationService/PipelineGrammar.pm
    yybypass       => 0,
    yybuildingtree => 0,
    yyprefix       => '',
    yyaccessors    => {
   },
    yyconflicthandlers => {}
,
    yystateconflict => {  },
    @_,
  );
  bless($self,$class);

  $self->make_node_classes('TERMINAL', '_OPTIONAL', '_STAR_LIST', '_PLUS_LIST', 
         '_SUPERSTART', 
         'start_1', 
         'pipeline_2', 
         'pipeline_3', 
         'pipe_item_4', 
         'command_5', 
         'args_6', 
         'args_7', 
         'args_8', 
         'arg_9', 
         'arg_10', 
         'arg_11', 
         'redirections_12', 
         'redirections_13', 
         'redirections_14', 
         'redirection_15', 
         'redirection_16', 
         'redirection_17', 
         'redirection_18', 
         'redirection_19', 
         'path_20', 
         'path_21', 
         'path_22', );
  $self;
}



=for None

=cut


#line 514 Bio/KBase/InvocationService/PipelineGrammar.pm



1;
