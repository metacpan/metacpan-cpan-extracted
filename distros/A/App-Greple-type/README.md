[![Actions Status](https://github.com/kaz-utashiro/greple-type/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-type/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-type.svg)](https://metacpan.org/release/App-Greple-type)
# NAME

App::Greple::type - file type filter module for greple

# SYNOPSIS

    greple -Mdig -Mtype --type-xxxx ... --dig .

# DESCRIPTION

This module filters search target files by given rule.  It is
convenient to use with other **greple** module which support recursive
or multi-file search such as **-Mfind**, **-Mdig** or **-Mgit**.

For example, option for Perl is defined as this:

    option --type-perl \
           --suffix=pl,PL,pm,pod,t,psgi \
           --shebang=perl

Using this option, only files those name end with **--suffix** option
or files which contains string `perl` in the first `#!` (shebang)
line will be searched.

Option **--suffix** and **--shebang** are defined in
[App::Greple::select](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aselect) module.

# CONFIGURATION

- **-Mtype::config**(_key_\[=_value_\])

    **-Mtype** module can be called with **config** function to control
    module behavior.

    - **short**

        Calling as **-Mtype::config(short)** or **-Mtype::config=short**
        introduce short name for rule options.  When short name mode is
        activated, all **--type-xxxx** options can be used as **--xxxx** as
        well.

# OPTIONS

    option --type-actionscript  --suffix=as,mxml
    option --type-ada           --suffix=ada,adb,ads
    option --type-asm           --suffix=asm,s
    option --type-asp           --suffix=asp
    option --type-aspx          --suffix=master,ascx,asmx,aspx,svc
    option --type-batch         --suffix=bat,cmd
    option --type-cc            --suffix=c,h,xs
    option --type-cfmx          --suffix=cfc,cfm,cfml
    option --type-clojure       --suffix=clj
    option --type-cmake         --suffix=cmake --select-name=^CMakeLists.txt$
    option --type-coffeescript  --suffix=coffee
    option --type-cpp           --suffix=cpp,cc,cxx,m,hpp,hh,h,hxx,c++,h++
    option --type-csharp        --suffix=cs
    option --type-css           --suffix=css
    option --type-dart          --suffix=dart
    option --type-delphi        --suffix=pas,int,dfm,nfm,dof,dpk,dproj,groupproj,bdsgroup,bdsproj
    option --type-elisp         --suffix=el
    option --type-elixir        --suffix=ex,exs
    option --type-erlang        --suffix=erl,hrl
    option --type-fortran       --suffix=f,f77,f90,f95,f03,for,ftn,fpp
    option --type-go            --suffix=go
    option --type-groovy        --suffix=groovy,gtmpl,gpp,grunit,gradle
    option --type-haskell       --suffix=hs,lhs
    option --type-hh            --suffix=h
    option --type-html          --suffix=htm,html
    option --type-java          --suffix=java,properties
    option --type-js            --suffix=js
    option --type-json          --suffix=json
    option --type-jsp           --suffix=jsp,jspx,jhtm,jhtml
    option --type-less          --suffix=less
    option --type-lisp          --suffix=lisp,lsp
    option --type-lua           --suffix=lua --shebng=lua
    option --type-markdown      --suffix=md
    option --type-md            --type-markdown
    option --type-make          --suffix=mak,mk --select-name=^(GNUmakefile|Makefile|makefile)$
    option --type-matlab        --suffix=m
    option --type-objc          --suffix=m,h
    option --type-objcpp        --suffix=mm,h
    option --type-ocaml         --suffix=ml,mli
    option --type-parrot        --suffix=pir,pasm,pmc,ops,pod,pg,tg
    option --type-perl          --suffix=pl,PL,pm,pod,t,psgi --shebang=perl
    option --type-perltest      --suffix=t
    option --type-php           --suffix=php,phpt,php3,php4,php5,phtml --shebang=php
    option --type-plone         --suffix=pt,cpt,metadata,cpy,py
    option --type-python        --suffix=py --shebang=python
    option --type-rake          --select-name=^Rakefile$
    option --type-rr            --suffix=R
    option --type-ruby          --suffix=rb,rhtml,rjs,rxml,erb,rake,spec \
                                --select-name=^Rakefile$ --shebang=ruby
    option --type-rust          --suffix=rs
    option --type-sass          --suffix=sass,scss
    option --type-scala         --suffix=scala
    option --type-scheme        --suffix=scm,ss
    option --type-shell         --suffix=sh,bash,csh,tcsh,ksh,zsh,fish \
                                --shebang=sh,bash,csh,tcsh,ksh,zsh,fish
    option --type-smalltalk     --suffix=st
    option --type-sql           --suffix=sql,ctl
    option --type-tcl           --suffix=tcl,itcl,itk
    option --type-tex           --suffix=tex,cls,sty
    option --type-tt            --suffix=tt,tt2,ttml
    option --type-vb            --suffix=bas,cls,frm,ctl,vb,resx
    option --type-verilog       --suffix=v,vh,sv
    option --type-vim           --suffix=vim
    option --type-xml           --suffix=xml,dtd,xsl,xslt,ent --select-data='\A.*<[?]xml'
    option --type-yaml          --suffix=yaml,yml

# BACKGROUND

This module is inspired by [App::Gre](https://metacpan.org/pod/App%3A%3AGre) command, and original matching
rule is taken from it.

Filename matching can be done with **-Mfind** module, but to know file
type from its content, different mechanism was required.  So I made
the **--begin** function can die to stop the file processing, and
introduced new **-Mselect** module.

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [App::Greple::select](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aselect)

[App::Gre](https://metacpan.org/pod/App%3A%3AGre)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
