#!/usr/bin/perl
#this file here just to shut up 'make test' errors 
use strict;
use Test;
use lib '../blib/lib';

BEGIN {
        if(!eval q{require Tree::DAG_Node}){
           plan tests => 1;
           warn "No Tree::DAG_Node. Test skipped.\n";
           ok(1);
           exit;
        } else {
           {plan tests => 2} 
           use CGI::Widget::HList;
           use CGI::Widget::HList::Node;
           my $root = CGI::Widget::HList::Node->new;
           ok(1);
           my $hlist = CGI::Widget::HList->new(-root=>$root);
           ok(2);
         }
      }

1;

