=encoding utf-8

=head1 NAME

App::Greple::type - file type filter module for greple

=head1 SYNOPSIS

    greple -Mdig -Mtype --type-xxxx ... --dig .

=head1 VERSION

Version 1.0301

=head1 DESCRIPTION

This module filters search target files by given rule.  It is
convenient to use with other B<greple> module which support recursive
or multi-file search such as C<-Mfind>, C<-Mdig> or C<-Mgit>.

For example, option for Perl is defined as this:

    option --type-perl \
           --suffix=pl,PL,pm,pod,t,psgi \
           --shebang=perl

Using this option, only files those name end with C<--suffix> option
or files which contains string C<perl> in the first C<#!> (shebang)
line will be searched.

Option B<--suffix> and B<--shebang> are defined in
L<App::Greple::select> module.

=head2 NEGATIVE OPTIONS

Negative options are automatically generated from positive options
with C<--no-> prefix.  For example, C<--no-type-perl> option is
defined as this:

    option --no-type-perl \
           --x-suffix=pl,PL,pm,pod,t,psgi \
           --x-shebang=perl

=head2 SHORT NAMES

Short name mode is activated by default on this version.  When
activated, all C<--type-xxxx> and C<--no-type-xxxx> options can be
used as C<--xxxx> and C<--no-xxxx> as well.

As for Perl, C<--perl> and C<--no-perl> can be used.

If you want to disable this mode, call module with config function
call, like C<-Mtype::config(short=0)> or C<-Mtype::config=short=0>.

=head1 OPTIONS

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

=head1 BACKGROUND

This module is inspired by L<App::Gre> command, and original matching
rule is taken from it.

Filename matching can be done with B<-Mfind> module, but to know file
type from its content, different mechanism was required.  So I made
the B<--begin> function can die to stop the file processing, and
introduced new B<-Mselect> module.

=head1 SEE ALSO

L<App::Greple>, L<App::Greple::select>

L<App::Gre>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::type;
our $VERSION = "1.0301";

use v5.14;
use warnings;
use Data::Dumper;

my($module, $argv);
my %opt = (short => 1, negative => 1);

sub initialize {
    ($module, $argv) = @_;
}

sub config {
    while (my($k, $v) = splice @_, 0, 2) {
	$opt{$k} = $v;
    }
}

sub finalize {
    my @options = $module->options;
    #
    # set negative --no-type-xxx options
    #
    if ($opt{negative}) {
	my @options = $module->options;
	for my $from (@options) {
	    my @to = $module->getopt($from) or next;
	    $from =~ s/^--type/--no-type/ or next;
	    grep {
		s/^--(?=suffix|select|shebang)/--x-/g || s/^--(?=type-)/--no-/
	    } @to and do {
		$module->setopt($from, \@to);
	    };
	}
    }
    #
    # set --xxx    for --type-xxx option
    # set --no-xxx for --no-type-xxx option
    #
    if ($opt{short}) {
	my @options = $module->options;
	for my $opt (@options) {
	    $opt =~ /^--(?<no>(no-)?)type-(?<name>.+)/ or next;
	    $module->setopt("--$+{no}$+{name}", $opt);
	}
    }
    warn Dumper $module if $opt{dump};
}

1;

__DATA__

autoload -Mdig --dig --git

option default -Mselect

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

#  LocalWords:  perl shebang config
