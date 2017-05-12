####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Biblio::Thesaurus::ModRewrite::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"

=head1 NAME

Biblio::Thesaurus::ModRewrite::Parser - this module implements the parser
for OML programs

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

my $File;
my $t;
### Reg exp for blocks

my $bl0 = qr((?:\\[{}]|[^{}])*);
my $bl1 = qr(\{$bl0\});
my $bl2 = qr(\{$bl0(?:$bl1*$bl0)*\});
my $bl3 = qr(\{$bl0(?:$bl2*$bl0)*\});
my $bl4 = qr(\{$bl0(?:$bl3*$bl0)*\});
my $blmidle = qr($bl0(?:$bl4*$bl0)*);



=head1 DESCRIPTION

This module implements the parser used in Biblio::Thesaurus::ModRewrite
to execute programs written in OML. OML is a domain specific language
to describe operations to execut eon ontologies.

=head1 FUNCTIONS

=cut

=head2 new

Create a new object.

=cut


sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		DEFAULT => -3,
		GOTOS => {
			'statement_list' => 1,
			'program' => 2
		}
	},
	{#State 1
		ACTIONS => {
			'REL' => 4,
			'VAR' => 8,
			'TERM' => 9,
			'DO' => 10,
			'STRING' => 5
		},
		DEFAULT => -1,
		GOTOS => {
			'cond_block' => 3,
			'statement' => 7,
			'token' => 11,
			'term' => 6
		}
	},
	{#State 2
		ACTIONS => {
			'' => 12
		}
	},
	{#State 3
		ACTIONS => {
			'ARROW' => 13
		}
	},
	{#State 4
		ACTIONS => {
			'OPEN' => 14
		}
	},
	{#State 5
		DEFAULT => -11
	},
	{#State 6
		ACTIONS => {
			'VAR' => 16,
			'STRING' => 15
		},
		GOTOS => {
			'relation' => 17
		}
	},
	{#State 7
		ACTIONS => {
			'DOT' => 18
		}
	},
	{#State 8
		DEFAULT => -12
	},
	{#State 9
		ACTIONS => {
			'OPEN' => 19
		}
	},
	{#State 10
		ACTIONS => {
			'ARROW' => 20
		}
	},
	{#State 11
		ACTIONS => {
			'AND' => 21,
			'OR' => 23
		},
		DEFAULT => -6,
		GOTOS => {
			'oper' => 22
		}
	},
	{#State 12
		DEFAULT => 0
	},
	{#State 13
		DEFAULT => -19,
		GOTOS => {
			'action_block' => 24,
			'action_list' => 25
		}
	},
	{#State 14
		ACTIONS => {
			'VAR' => 16,
			'STRING' => 15
		},
		GOTOS => {
			'relation' => 26
		}
	},
	{#State 15
		DEFAULT => -13
	},
	{#State 16
		DEFAULT => -14
	},
	{#State 17
		ACTIONS => {
			'VAR' => 8,
			'STRING' => 5
		},
		GOTOS => {
			'term' => 27
		}
	},
	{#State 18
		DEFAULT => -2
	},
	{#State 19
		ACTIONS => {
			'VAR' => 8,
			'STRING' => 5
		},
		GOTOS => {
			'term' => 28
		}
	},
	{#State 20
		DEFAULT => -19,
		GOTOS => {
			'action_block' => 29,
			'action_list' => 25
		}
	},
	{#State 21
		DEFAULT => -15
	},
	{#State 22
		ACTIONS => {
			'REL' => 4,
			'VAR' => 8,
			'TERM' => 9,
			'STRING' => 5
		},
		GOTOS => {
			'cond_block' => 30,
			'token' => 11,
			'term' => 6
		}
	},
	{#State 23
		DEFAULT => -16
	},
	{#State 24
		DEFAULT => -4
	},
	{#State 25
		ACTIONS => {
			'SUB' => 31,
			'ACTION' => 32
		},
		DEFAULT => -17,
		GOTOS => {
			'action' => 33
		}
	},
	{#State 26
		ACTIONS => {
			'CLOSE' => 34
		}
	},
	{#State 27
		DEFAULT => -8
	},
	{#State 28
		ACTIONS => {
			'CLOSE' => 35
		}
	},
	{#State 29
		DEFAULT => -5
	},
	{#State 30
		DEFAULT => -7
	},
	{#State 31
		ACTIONS => {
			'CODE' => 36
		}
	},
	{#State 32
		ACTIONS => {
			'OPEN' => 37
		}
	},
	{#State 33
		DEFAULT => -18
	},
	{#State 34
		DEFAULT => -10
	},
	{#State 35
		DEFAULT => -9
	},
	{#State 36
		DEFAULT => -21
	},
	{#State 37
		ACTIONS => {
			'REL' => 4,
			'VAR' => 8,
			'TERM' => 9,
			'STRING' => 5
		},
		GOTOS => {
			'token' => 38,
			'term' => 6
		}
	},
	{#State 38
		ACTIONS => {
			'CLOSE' => 39
		}
	},
	{#State 39
		DEFAULT => -20
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'program', 1,
sub
#line 47 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{ program=>$_[1] } }
	],
	[#Rule 2
		 'statement_list', 3,
sub
#line 51 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{
             my $n = keys %{$_[1]};
             +{ %{$_[1]}, $n=>$_[2]}
           }
	],
	[#Rule 3
		 'statement_list', 0,
sub
#line 55 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{} }
	],
	[#Rule 4
		 'statement', 3,
sub
#line 58 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{cond=>$_[1],action=>$_[3]} }
	],
	[#Rule 5
		 'statement', 3,
sub
#line 59 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{cond=>'true',action=>$_[3]} }
	],
	[#Rule 6
		 'cond_block', 1, undef
	],
	[#Rule 7
		 'cond_block', 3,
sub
#line 63 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{$_[2] => [$_[1],$_[3]]} }
	],
	[#Rule 8
		 'token', 3,
sub
#line 66 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ [ $_[1], $_[2], $_[3] ]  }
	],
	[#Rule 9
		 'token', 4,
sub
#line 67 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{'term'=>$_[3]} }
	],
	[#Rule 10
		 'token', 4,
sub
#line 68 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{'rel'=>$_[3]} }
	],
	[#Rule 11
		 'term', 1,
sub
#line 71 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{'term'=>$_[1]} }
	],
	[#Rule 12
		 'term', 1,
sub
#line 72 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{'var'=>$_[1]} }
	],
	[#Rule 13
		 'relation', 1,
sub
#line 75 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{'relation'=>$_[1]} }
	],
	[#Rule 14
		 'relation', 1,
sub
#line 76 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{'var',$_[1]} }
	],
	[#Rule 15
		 'oper', 1,
sub
#line 79 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ 'and' }
	],
	[#Rule 16
		 'oper', 1,
sub
#line 80 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ 'or' }
	],
	[#Rule 17
		 'action_block', 1, undef
	],
	[#Rule 18
		 'action_list', 2,
sub
#line 87 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{
                 my $n = keys %{$_[1]};
                 +{ %{$_[1]}, $n=>$_[2] }
               }
	],
	[#Rule 19
		 'action_list', 0,
sub
#line 91 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{} }
	],
	[#Rule 20
		 'action', 4,
sub
#line 94 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{ $_[1] => $_[3] } }
	],
	[#Rule 21
		 'action', 2,
sub
#line 95 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"
{ +{ $_[1] => $_[2] } }
	]
],
                                  @_);
    bless($self,$class);
}

#line 98 "lib/Biblio/Thesaurus/ModRewrite/Parser.yp"


=head2 lex

Function used to tokenize source code.

=cut

sub lex {
    for ($File) {
        s!^\s+!!;
        s!^\#.*?\n!!;
        ($_ eq '')    and return ('',undef);

        s!^(\=\>)!!    and return('ARROW',$1);
        s!^(and|\&\&|∧)!!i    and return('AND',$1);
        s!^(or|\|\||∨)!!i    and return('OR',$1);
        s!^(not|\!)!!i    and return('NOT',$1);
        s!^(do|begin|end)!!i    and return('DO',$1);
        s!^(\=\>|⇒)!!    and return('ARROW',$1);
        s!^(\:)!!    and return('COLON',$1);
        s!^(\()!!    and return('OPEN',$1);
        s!^(\))!!    and return('CLOSE',$1);
        s!^(\,)!!    and return('COMMA',$1);
        s!^(\.)!!    and return('DOT',$1);
        s!^(sub)!!    and return('SUB',$1);
        #s!^\{(.*)\}!!s    and print "|$1|\n" and return('CODE',$1);
        #s!^\{([^{}]*(\{[^{}]*\}[^{}]*)*)\}!!s and return('CODE',$1);
        s!^\{($blmidle)\}!!s and return('CODE',$1);

        s!^(term)!!    and return('TERM',$1);
        s!^(rel)!!    and return('REL',$1);
        s!^(add|del)!!    and return('ACTION',$1);
        if (s!^(\w+|\'.*?\'|\".*?\")!!) {
            my $zbr = $1;
            $zbr =~ s/\'|\"//g;
            return('STRING',$zbr);
        }
        s!^\$([a-z]+)!!    and return('VAR',$1);
    }
}

=head2 yyerror

Function used to report errors.

=cut

sub yyerror {
  if ($_[0]->YYCurtok) {
      printf STDERR ('Error: a "%s" (%s) was found where %s was expected'."\n",
         $_[0]->YYCurtok, $_[0]->YYCurval, $_[0]->YYExpect)
  }
  else { print  STDERR "Expecting one of ",join(", ",$_[0]->YYExpect),"\n";
  }
}

=head2 init_lex

Function used to initialize everything we need.

=cut

sub init_lex {
    my $self = shift;
    $File = shift;

    local $/;
    undef $/;
    #$File = <>
}

=head1 AUTHOR

Nuno Carvalho, C<< <smash@cpan.org> >>

J.Joao Almeida, C<< <jj@di.uminho.pt> >>

Alberto Simoes, C<< <albie@alfarrabio.di.uminho.pt> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nuno Carvalho, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: set filetype=perl

1;
