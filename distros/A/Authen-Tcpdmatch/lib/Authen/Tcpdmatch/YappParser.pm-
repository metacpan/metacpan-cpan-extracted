####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Authen::Tcpdmatch::YappParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 4 "grammar.yp"

no strict 'refs'; use NetAddr::IP;
our  ( $found, $e, $side, $remote, $service, $OK_remote, $OK_service)  ;        
sub found     { $OK_service && $OK_remote  or  undef                                 }
sub register  { ${"OK_$side"} = !$e}                                             
sub tally     { register    if  ($_[0]||'') eq ${"$side"}                        }
sub dot_host  { (my $ip = $_[0]) =~ s!\.!\\\.!g;  register if $remote =~ /$ip$/  }
sub ip_dot    { (my $ip = $_[0]) =~ s!\.!\\\.!g;  register if $remote =~ /^$ip/  }
sub ALL       { register                                                         }
sub LOCAL     { register    if $remote !~ /\./                                   }
sub maskit    { my $r = new NetAddr::IP $remote  or return;
                register   if (NetAddr::IP->new(shift)||return)  ->contains($r)  }
sub printOK   { print "OK_service=$OK_service, OK_remote=$OK_remote " }




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		DEFAULT => -1,
		GOTOS => {
			'init' => 1,
			'S' => 2
		}
	},
	{#State 1
		ACTIONS => {
			'COMMENT' => 4
		},
		DEFAULT => -5,
		GOTOS => {
			'line' => 3
		}
	},
	{#State 2
		ACTIONS => {
			'' => 5
		}
	},
	{#State 3
		ACTIONS => {
			'' => -2,
			'EOL' => 6,
			'COMMENT' => 8
		},
		DEFAULT => -3,
		GOTOS => {
			'sside' => 7
		}
	},
	{#State 4
		DEFAULT => -9
	},
	{#State 5
		DEFAULT => -0
	},
	{#State 6
		DEFAULT => -6
	},
	{#State 7
		DEFAULT => -10,
		GOTOS => {
			'list' => 9
		}
	},
	{#State 8
		ACTIONS => {
			'EOL' => 10
		}
	},
	{#State 9
		ACTIONS => {
			'MASK' => 11,
			'LOCAL' => 16,
			'WORD' => 15,
			'EXCEPT' => 12,
			'ALL' => 18,
			'IP_DOT' => 19,
			'COLON' => 13,
			'DOT_HOST' => 14
		},
		GOTOS => {
			'term' => 17
		}
	},
	{#State 10
		DEFAULT => -7
	},
	{#State 11
		DEFAULT => -17
	},
	{#State 12
		DEFAULT => -12,
		GOTOS => {
			'@1-2' => 20
		}
	},
	{#State 13
		DEFAULT => -4,
		GOTOS => {
			'rside' => 21
		}
	},
	{#State 14
		DEFAULT => -18
	},
	{#State 15
		DEFAULT => -14
	},
	{#State 16
		DEFAULT => -16
	},
	{#State 17
		DEFAULT => -11
	},
	{#State 18
		DEFAULT => -15
	},
	{#State 19
		DEFAULT => -19
	},
	{#State 20
		DEFAULT => -10,
		GOTOS => {
			'list' => 22
		}
	},
	{#State 21
		DEFAULT => -10,
		GOTOS => {
			'list' => 23
		}
	},
	{#State 22
		ACTIONS => {
			'MASK' => 11,
			'EXCEPT' => 12,
			'DOT_HOST' => 14,
			'LOCAL' => 16,
			'WORD' => 15,
			'ALL' => 18,
			'IP_DOT' => 19
		},
		DEFAULT => -13,
		GOTOS => {
			'term' => 17
		}
	},
	{#State 23
		ACTIONS => {
			'MASK' => 11,
			'EXCEPT' => 12,
			'DOT_HOST' => 14,
			'LOCAL' => 16,
			'WORD' => 15,
			'ALL' => 18,
			'IP_DOT' => 19
		},
		DEFAULT => -8,
		GOTOS => {
			'term' => 17
		}
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'init', 0,
sub
#line 23 "grammar.yp"
{ $service = $_[0]->{USER}{service}; $remote = $_[0]->{USER}{remote} ; $found=0}
	],
	[#Rule 2
		 'S', 2,
sub
#line 26 "grammar.yp"
{ $found||undef }
	],
	[#Rule 3
		 'sside', 0,
sub
#line 29 "grammar.yp"
{ $side   = 'service', $e=0 ;  $OK_remote = $OK_service =  undef }
	],
	[#Rule 4
		 'rside', 0,
sub
#line 30 "grammar.yp"
{ $side   = 'remote' , $e=0  }
	],
	[#Rule 5
		 'line', 0, undef
	],
	[#Rule 6
		 'line', 2, undef
	],
	[#Rule 7
		 'line', 3, undef
	],
	[#Rule 8
		 'line', 6,
sub
#line 35 "grammar.yp"
{ $found =  1 if found() }
	],
	[#Rule 9
		 'line', 1, undef
	],
	[#Rule 10
		 'list', 0, undef
	],
	[#Rule 11
		 'list', 2, undef
	],
	[#Rule 12
		 '@1-2', 0,
sub
#line 40 "grammar.yp"
{$e^=1}
	],
	[#Rule 13
		 'list', 4, undef
	],
	[#Rule 14
		 'term', 1,
sub
#line 43 "grammar.yp"
{ tally     $_[1] }
	],
	[#Rule 15
		 'term', 1,
sub
#line 44 "grammar.yp"
{ ALL             }
	],
	[#Rule 16
		 'term', 1,
sub
#line 45 "grammar.yp"
{ LOCAL           }
	],
	[#Rule 17
		 'term', 1,
sub
#line 46 "grammar.yp"
{ maskit    $_[1] }
	],
	[#Rule 18
		 'term', 1,
sub
#line 47 "grammar.yp"
{ dot_host  $_[1] }
	],
	[#Rule 19
		 'term', 1,
sub
#line 48 "grammar.yp"
{ ip_dot    $_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 51 "grammar.yp"


1;
