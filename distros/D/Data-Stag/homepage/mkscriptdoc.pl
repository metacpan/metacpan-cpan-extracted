#!/usr/local/bin/perl
use strict;

use Data::Stag qw(:all);

#my @files = (glob("$ENV{HOME}/stag/scripts/*pl"),glob("$ENV{HOME}/DBIx-DBStag/scripts/*pl"));
my @sect1 = ();
my @sect2 = ();
foreach my $f (glob("$ENV{HOME}/stag/scripts/*pl")) {
    push(@sect1, mk($f));
}
foreach my $f (glob("$ENV{HOME}/DBIx-DBStag/scripts/*pl")) {
    push(@sect2, mk($f));
}
my $html = 
  [html=>[
	  [head=>[
		  [title=>"Stag Script Index"],
		  [link=>[
			  ['@'=>[
				 [rel=>"stylesheet"],
				 [type=>"text/css"],
				 [href=>"./stylesheet.css"]]]]]]],
	  [body=>[
		  [h1=>'Stag Scripts'],
		  [div=>[
			 ['@'=>[
				[class=>'intro']]],
			 ['.'=>[
				[p=>"These scripts come with the stag and dbstag distributions"]]]]],
		  [h2=>'Data::Stag Script List'],
		  @sect1,
		  [h2=>'DBIx::DBStag Script List'],
		  @sect2]]]];
stag_nodify($html);
print $html->xml;
exit 0;

sub mk {
    my $f = shift;
    print STDERR "FILE:$f\n";
    my $n = $f;
    $n =~ s/.*\///;
    $n =~ s/\..*//;
    `mkdir script-docs` unless -d 'script-docs';
    my $url = "script-docs/$n.html";
    system("pod2html --title $n --htmlroot . --podroot . $f > $url");
    my $pod = Data::Stag->parse(-file=>$f,-format=>'Data::Stag::PodParser');
    my ($namesect) = $pod->where('section',
				 sub {shift->get('name') eq 'NAME'});
    my ($descsect) = $pod->where('section',
				 sub {shift->get('name') eq 'DESCRIPTION'});
    my ($synsect) = $pod->where('section',
				sub {shift->get('name') eq 'SYNOPSIS'});
    if (!$namesect || !$descsect || !$synsect) {
	print STDERR "SKIPPING $f\n";
	next;
    }
    my $name = $namesect->get('text');
    next unless $name;
    my $desc = join("\n",$descsect->get('text'));
    my $syn = join("\n",$synsect->get('text'));
    my $summary = '';
    if ($name =~ /(.*)\s+\-\s+(.*)/) {
	($name,$summary) = ($1,$2);
    }
    return
      (
	 [hr=>''],
	 [h3=>[
	       [a=>[
		    ['@'=>[
			   [href=>$url]]],
		    ['.'=>"$name"]]]]],
	 [div=>[
		['@'=>[
		       [class=>'summary']]],
		['.'=>$summary]]],
	 [div=>[
		['@'=>[
		       [class=>'codeblock']]],
		['.'=>[
		       [pre=>$syn]]]]],
	 [div=>[
		['@'=>[
		       [class=>'scriptdesc']]],
		['.'=>[
		       [pre=>$desc]]]]],
      );
}
