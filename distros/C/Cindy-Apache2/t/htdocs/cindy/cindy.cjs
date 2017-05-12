; $Id: cindy.cjs 15 2010-03-09 18:55:50Z jo $

/data/title       content   /html/head/title ;
/data/content     content   /html/body/h2[1] ;
/data/replace     replace   /html/body/p[1]/b[1] ;
/data/omit        omit-tag  /html/body/p[1]/b[2] ;
/data/size        attribute /html/body/p[1]/font size ;
/data/color       attribute /html/body/p[1]/font color ;
/data/color       attribute /html/body/p[2]/span[2]/font color ;
/data/cfalse      condition /html/body/p[2]/span[1] ;
/data/ctrue       condition /html/body/p[2]/span[2] ;
/data/repeat/row  repeat    /html/body/table/tr {
  ./value           content   ./td[1] ;
  ./text            content   ./td[2] 
} ;
/data/repeat/row  repeat      /html/body/select/option {
  ./value           attribute   .  value ;
  ./selected        attribute   .  selected ;
  ./text            content     . 
} ;
