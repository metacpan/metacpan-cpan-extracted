# Copyright (c) 2003 Ioannis Tambouras <ioannis@earthlink.net> .
# All rights reserved.


package Authen::Tcpdmatch::Lexer;
use Parse::Lex;
use Attribute::Handlers;

my $octet   = qr/\d{1,3}/ ;  
my $o3      = qr/(?:\.$octet){1,3}/ ;
my $netmask = "$octet$o3(?:/$octet(?:$o3)?)?"  ;


my @tokens = (
    'COMMENT',     '\#.*'              , 
    qw( ALL         ALL               ),
    qw( LOCAL       LOCAL             ),
    qw( EXCEPT      EXCEPT            ),
    qw( IP_DOT      \S+\.(?!\w)       ), 
    qw( DOT_HOST    \.\S*\b           ),
    'MASK',         "$netmask"         ,
    qw( WORD        \w+               ),
    qw( COLON        :                ),
    qw( EOL         \n                ),
    qw( Lerror      .*                ),
);

sub Lexer :ATTR(BEGIN) {
        Parse::Lex->skip('[ ,\t]*');
	${$_[2]} = new Parse::Lex @tokens or die;
}


1;
