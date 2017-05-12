####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Alvis::NLPPlatform::ParseConstituents;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 12 "lib/Alvis/NLPPlatform/ParseConstituents.yp"

    use Alvis::NLPPlatform;
    use Data::Dumper;
    use warnings;


    our $VERSION=$Alvis::NLPPlatform::VERSION;

    my $doc_hash;
    my $decal_phrase_idx;

    my $debug_mode=0;
    my $lconst = 0;
    my $nconst;

    my @tab_nconst;
#     my @tab_type;
#     my @tab_string;
    my $tab_type_ref;
    my $tab_string_ref;

    my $lastword="";

    my $word_id_np_ref;

    my $word_count;



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
			'input' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 4,
			'OPEN' => 2,
			"\n" => 6,
			'error' => 7
		},
		GOTOS => {
			'open' => 3,
			'constituent' => 5,
			'line' => 8
		}
	},
	{#State 2
		DEFAULT => -12
	},
	{#State 3
		ACTIONS => {
			'OPEN' => 2,
			'WORD' => 9,
			'error' => 13
		},
		GOTOS => {
			'open' => 3,
			'constituent' => 10,
			'word' => 11,
			'constituent_content' => 12,
			'chunk' => 14
		}
	},
	{#State 4
		DEFAULT => 0
	},
	{#State 5
		ACTIONS => {
			"\n" => 15
		}
	},
	{#State 6
		DEFAULT => -3
	},
	{#State 7
		ACTIONS => {
			"\nline: " => 17,
			"\nconstituents: " => 16,
			"\nopen: " => 18
		}
	},
	{#State 8
		DEFAULT => -2
	},
	{#State 9
		DEFAULT => -19
	},
	{#State 10
		DEFAULT => -9
	},
	{#State 11
		ACTIONS => {
			'OPEN' => -17,
			'WORD' => 9,
			'error' => 19,
			'CLOSE' => -17
		},
		GOTOS => {
			'word' => 11,
			'chunk' => 20
		}
	},
	{#State 12
		ACTIONS => {
			'OPEN' => 2,
			'WORD' => 9,
			'error' => 24,
			'CLOSE' => 21
		},
		GOTOS => {
			'open' => 3,
			'close' => 22,
			'constituent' => 10,
			'word' => 11,
			'constituent_content' => 23,
			'chunk' => 14
		}
	},
	{#State 13
		ACTIONS => {
			"\nchunk: " => 26,
			"\nconstituents: " => 16,
			"\nconstituent_content: " => 27,
			"\nopen: " => 18,
			"\nword: " => 25
		}
	},
	{#State 14
		DEFAULT => -8
	},
	{#State 15
		DEFAULT => -4
	},
	{#State 16
		DEFAULT => -7
	},
	{#State 17
		DEFAULT => -5
	},
	{#State 18
		DEFAULT => -13
	},
	{#State 19
		ACTIONS => {
			"\nchunk: " => 26,
			"\nword: " => 25
		}
	},
	{#State 20
		DEFAULT => -16
	},
	{#State 21
		DEFAULT => -14
	},
	{#State 22
		DEFAULT => -6
	},
	{#State 23
		ACTIONS => {
			'OPEN' => 2,
			'WORD' => 9,
			'error' => 13,
			'CLOSE' => -10
		},
		GOTOS => {
			'open' => 3,
			'constituent' => 10,
			'word' => 11,
			'constituent_content' => 23,
			'chunk' => 14
		}
	},
	{#State 24
		ACTIONS => {
			"\nchunk: " => 26,
			"\nconstituents: " => 16,
			"\nclose: " => 28,
			"\nconstituent_content: " => 27,
			"\nopen: " => 18,
			"\nword: " => 25
		}
	},
	{#State 25
		DEFAULT => -20
	},
	{#State 26
		DEFAULT => -18
	},
	{#State 27
		DEFAULT => -11
	},
	{#State 28
		DEFAULT => -15
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'input', 0, undef
	],
	[#Rule 2
		 'input', 2,
sub
#line 43 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ push(@{$_[1]},$_[2]); $_[1] }
	],
	[#Rule 3
		 'line', 1,
sub
#line 46 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[1] }
	],
	[#Rule 4
		 'line', 2, undef
	],
	[#Rule 5
		 'line', 2,
sub
#line 48 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 6
		 'constituent', 3, undef
	],
	[#Rule 7
		 'constituent', 2,
sub
#line 52 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 8
		 'constituent_content', 1,
sub
#line 56 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{$_[1];}
	],
	[#Rule 9
		 'constituent_content', 1, undef
	],
	[#Rule 10
		 'constituent_content', 2, undef
	],
	[#Rule 11
		 'constituent_content', 2,
sub
#line 59 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 12
		 'open', 1,
sub
#line 63 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{
	    # open constituent
	    if($lconst>0){
		push @{$$tab_string_ref[$tab_nconst[$lconst]]} , "phrase" . ($decal_phrase_idx+$$nconst+1) ;
	    }
	    $lconst++;
	    $$nconst++;
	    $tab_nconst[$lconst]=$$nconst;

	    # get type
	    $$tab_type_ref[$tab_nconst[$lconst]]=$_[1];

	    print STDERR "*** DEBUG *** Opened constituent $$nconst with type ".$_[1]."\n" unless ($debug_mode==0);

	}
	],
	[#Rule 13
		 'open', 2,
sub
#line 78 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 14
		 'close', 1,
sub
#line 81 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{
	    # check type
    print STDERR $_[1] unless ($debug_mode==0);
	    if($_[1] ne $$tab_type_ref[$tab_nconst[$lconst]]){
		print STDERR "Error found at level $lconst: types don't match!\n";
		exit 0;
	    }
	    # remove ending space
#	    $$tab_string_ref[$tab_nconst[$lconst]] =~ s/\s+$//sgo;
	    # close constituent
	    print STDERR "*** DEBUG *** Closing constituent $tab_nconst[$lconst]\n" unless ($debug_mode==0);
	    $lconst--;
	}
	],
	[#Rule 15
		 'close', 2,
sub
#line 94 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 16
		 'chunk', 2, undef
	],
	[#Rule 17
		 'chunk', 1, undef
	],
	[#Rule 18
		 'chunk', 2,
sub
#line 98 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 19
		 'word', 1,
sub
#line 101 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{
	    print STDERR "*** DEBUG *** Found string '".$_[1] . "'\n" unless ($debug_mode==0);
	    if((defined $$tab_string_ref[$tab_nconst[$lconst]])
                &&(scalar(@{$$tab_string_ref[$tab_nconst[$lconst]]}) != 0)){
		print STDERR "*** DEBUG *** Appended to previously found string\n" unless ($debug_mode==0);
#		$$tab_string_ref[$tab_nconst[$lconst]].=$_[0]->text;
		if(($_[1] eq $lastword) || ($_[1]=~/^\./)){
		}else{
		    push @{$$tab_string_ref[$tab_nconst[$lconst]]}, "word" . $$word_id_np_ref ;
		    $$word_id_np_ref++;
		    $lastword=$_[1];
		}
	    }else{
#		$$tab_string_ref[$tab_nconst[$lconst]]=$_[0]->text;
		if(!(($_[1] eq $lastword)||($_[1] =~ /^\./))){
		    $lastword=$_[1];
		    my @tmp;
		    push @tmp, "word" . $$word_id_np_ref;
		    $$tab_string_ref[$tab_nconst[$lconst]]=\@tmp;
		    $$word_id_np_ref++;
		}else{
		}
	    }
	}
	],
	[#Rule 20
		 'word', 2,
sub
#line 125 "lib/Alvis/NLPPlatform/ParseConstituents.yp"
{ $_[0]->YYErrok }
	]
],
                                  @_);
    bless($self,$class);
}

#line 128 "lib/Alvis/NLPPlatform/ParseConstituents.yp"




sub _Error {
        exists $_[0]->YYData->{ERRMSG}
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
#    print "Syntax error...\n";
}

sub _Lexer {
    my($parser)=shift;


    $doc_hash = $parser->YYData->{DOC_HASH} or  return('',undef);
    $decal_phrase_idx = $parser->YYData->{DECAL_PHRASE_IDX} or  return('',undef);
    $word_id_np_ref = $parser->YYData->{WORD_ID_NP_REF} or  return('',undef);

    $tab_type_ref = $parser->YYData->{TAB_TYPE_REF};
    $tab_string_ref = $parser->YYData->{TAB_STRING_REF};

    # $lconst = $parser->YYData->{LCONST_REF};
    $nconst = $parser->YYData->{NCONST_REF};

    $word_count=$$word_id_np_ref;

#     $parser->YYData->{INPUT}
#     or $parser->YYData->{INPUT} = "[PP of [NP two transcription factors factors NP] PP]\n"
#     or  return('',undef);
#      $parser->YYData->{INPUT} = $parser->YYData->{CONSTITUENT_STRING};
#  or  return('',undef);

#     chomp $parser->YYData->{INPUT};
#     chop $parser->YYData->{INPUT};
#     print STDERR $parser->YYData->{INPUT};
#     print STDERR ";;\n";

#     print STDERR "==>";
#     print STDERR $parser->YYData->{CONSTITUENT_STRING};
#     print STDERR "\n";

#      print STDERR "$lconst : $$nconst\n";

    $parser->YYData->{CONSTITUENT_STRING}=~s/^[ \t]*#.*//;
    $parser->YYData->{CONSTITUENT_STRING}=~s/^[ \t]*//;
    my $open = '\[([A-Z]+)';
    my $close = '([A-Z]+)\]';
    my $word = '([^\s\]\[]+)';

    for ($parser->YYData->{CONSTITUENT_STRING}) {
        s/^$open// and return ('OPEN', $1);
        s/^$close// and return ('CLOSE', $1);
	s/^$word// and return('WORD', $1);
        s/^(.)//s  and return($1,$1);
	
    }

}


1;
