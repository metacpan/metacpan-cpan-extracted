" Vim syntax file
" Language: embperl
" Maintainer: Jan Hudec <bulb@ucw.cz>

" Head
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

if !exists("main_syntax")
    let main_syntax = "confmake"
endif
" EndHead

syn region  CMOption	start='[\w-]+' matchgroup=CMDirective end=';\|{\@=' matchgroup=CMDelimiter
syn match   CMDelimiter	'{}'

syn match CMPrimitive	/\<\(schema\|type\|contains\|simple\|anon_group\|named_group\|toplevel\|action\|contained\)\>/ containedin=CMOption
syn match CMPrimitive	/\<\(search-path\|output-dir\|config\|template\|src\|out\|command\|enc\)\>/ contained containedin=CMOption

syn match CMComment	/#.*/

hi def link CMDirective	Identifier
hi def link CMDelimiter	Delimiter
hi def link CMPrimitive	Keyword
hi def link CMComment	Comment

" Foot
let b:current_syntax = "confmake"

if main_syntax == "confmake"
    unlet main_syntax
endif
" EndFoot

" arch-tag: 38820aa7-a198-4b65-878e-f172c9b2dfd0
