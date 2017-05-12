package  Config::Format::Ini::Grammar;
use Parse::RecDescent;
use strict;
use warnings;

my $gram = <<'END_GRAMMAR' ;
{       my $h ;
	use Data::Dumper;
	my %esc =  map {$_ => pack 'H2', $_}  0..255;
	@esc{ '\n', '\t', '\r', '\a' } = ( "\n", "\t", "\r", "\a" );
	sub merge2hash { my $aref = shift; my $h;
	   ref eq 'HASH' and @{$h}{keys %$_} = values %$_  for @$aref; $h;
	}
        sub  postprocess {
		local $_ = shift ||return;
		s/ \\x([\d]{1,3})/ $esc{ "$1"+0 } /egx;
		s/ (\\[ntra])    / $esc{$1}       /xge;
	        $_ ;
        }
}
	         

    startrule : <skip:'[ \t]*'>   
		Section(s) 
		{ $return =  merge2hash( $item[2])  }

    Section:   Title  "\n"  Pair(s?) 
		{ $return = { $item[1]=> merge2hash( $item[3])||{} } }
                | COMMENT(s) 
                | BLANK(s) 
  	        | <resync>

    Title:     '[' /\w+/ ']'      COM(?)  
		{ $item[2] }

    Pair:      KEY '=' VAL(s?)    COM(?)   "\n"
	       {$return = {$item[1]=>$item[3]} }
    Pair:      COMMENT(s){$return = 0}
              | BLANK(s) {$return = 0}
    Pair:     <resync:[^[\n]+\n>

    KEY:      /\w+(?=\s*=)/

    VAL:       <perl_quotelike>
               <reject: ${item[1]}[1] ne '"' >
               { $item[1]->[2] =~ s/\\\n//g }
               { $item[1]->[2] }
    VAL:      
                /.*? (?<!\\)(?=[,;#\n]) /sx 
                { $item[1] =~ s/\\\n//g     }
		{ $item[1] =~ s/[;#].*\Z//m }
		{ $item[1] =~ s/^\s+|\s+$// }
                { postprocess( $item[1] ) }
    VAL:       ',' VAL 
               {$item[2]} 
 


    BLANK:     "\n"
    COM:        /^(?:[#;].*)/
    COMMENT:    COM "\n"

END_GRAMMAR

sub new { Parse::RecDescent->new( $gram ) }

1;
__END__
=head1 NAME

Config::Format::Ini::Grammar -  P:RD grammar for ini file format

