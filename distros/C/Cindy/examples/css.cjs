; $Id: $

use css ;

; Testing comments
title@test      content    "head > title" ;
content         content    "h2[test]" ;
replace         replace    "p.first > b.first" ;
omit            omit-tag   "p.first > b.second" ;
size            attribute  "p.first > font" size ;
color           attribute  "p.first > font" color ;
color           attribute  "p > span > font" color ;
cfalse          condition  "p > span.first, span.third" ;
ctrue           condition  "p > span.second" ;
comment         comment    "select" ;
"repeat > row"  repeat     "table > tr" {
  value           content   th ;
  text            content   td 
} ;
"repeat > row"  repeat      "select > option" {
  value           attribute   ""  value ;
  selected        attribute   ""  selected ;
  text            content     "" 
} ;
; remove class
does-not-exist  attribute  "span, p" class ;  
;does-not-exist  attribute  b class ;  

