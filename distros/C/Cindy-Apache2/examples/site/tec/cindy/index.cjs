; $Id: index.cjs 42 2010-05-22 14:23:18Z jo $
; Extract a menu from the apache directory index

; Loop over all index rows (files and directories)
; position() > 2 removes the th and hr rows
; The last() row is also a hr row
"/html/body/table/tr[position()>2]
                    [position()<last()]
                    [./td[2]!='Parent Directory']"
       repeat //ul/li {

    ; td[1]/img/@alt='[DIR]' filters directories

    ; remove the recursion target, if this is not a dir. row
    ; @alt is appended because it evaluates to true
    ./td[1]/img[@alt='[DIR]']/@alt  condition ./div
    ; mark a for easier debugging
    ./td[1]/img/@alt           attribute ./a  class

    ; Visible text
    ; Remove 3 leading characters
    ; Translate underscores to blanks
    ; Misuse of substring with count as a ?: operator
    "substring(
      translate(
        substring-before(
                ./td[2]/a, 
                substring('./', 1 + count(./td[1]/img[@alt='[DIR]']), 1)
                ), '_', ' '), 4)" 
                               content ./a ;
    ; Overwrite with a description if there is one
    ; Note that translate removes &nbsp; (' ' is not a blank) 
    ./td[5][translate(normalize-space(.),' ','')!=''] content ./a ;

    ; href URL
    ; noop link for dir, absolute path for href otherwise.
    ; substring-before and substring with count
    ; are misused to switch between both
    "substring-before(
      substring(
        concat(
               '#?',
               substring-after(/html/head/title, 
                         'Index of '),
               substring('/', 1, string-length(/html/head/title) - 10), 
               ./td[2]/a/@href,
               '?'), 
            1 + 2 * count(./td[1]/img[@alt!='[DIR]'])),
        '?')"         
                               attribute  ./a href ;

    ; Recursion using SSI
    "concat('#include virtual=', 
            substring-after(/html/head/title, 
                            'Index of '),
            '/',
            ./td[2][../td[1]/img/@alt='[DIR]']/a/@href,
            'menu.shtml ')"    comment ./div ;
    
} ;

