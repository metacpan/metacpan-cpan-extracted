" Vim syntax file
" Language:	aasp Apache::ASP combination of Perl and HTML
" Maintainer:	Jon Topper <jon@a-h.net>
" Last change:	2001 Feb 09

" Remove any old syntax stuff hanging around
syn clear

so <sfile>:p:h/html.vim
syn include @Perl <sfile>:p:h/perl.vim
syn cluster htmlPreproc add=aaspPerlInsideTags

syntax region aaspPerlInsideTags keepend matchgroup=Delimiter start=+<%=\=+ skip=+".*%>.*"+ end=+%>+ contains=@Perl

let b:current_syntax = "aasp"

" vim: ts=8

