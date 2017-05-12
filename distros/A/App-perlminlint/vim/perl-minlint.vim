" perl-minlint - lint everytime you save perl script
" Version: 0.0.1
" Author: KOBAYASHI, Hiroaki <hkoba@cpan.org>
" Copyright (c) 2014 KOBAYASHI, Hiroaki
" License: Modified BSD License

if exists('g:loaded_perl_minlint') && g:loaded_perl_minlint
  finish
endif

function! Perl_minlint()
  let fn = shellescape(expand('%'))
  let out = system("perlminlint --no-stderr " . fn)
  let err = v:shell_error
  if err != 0
	"XXX parse file/line and highlight...
    echo out
  endif
endfunction
