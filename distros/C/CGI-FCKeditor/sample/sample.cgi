#!/usr/bin/perl
use strict;
use CGI;
use CGI::FCKeditor;

# Sample CGI for CGI::FCKeditor
# 2006.09.08 Kazuma Shiraiwa

my $name = 'fck';
my $dir = '/FCKeditor/';
my $css = "$dir".'editor/css/fck_editorarea.css';

my $q = new CGI;
my $value = $q->param("$name");

print $q->header(-charset=>'utf-8'),
	$q->start_html(-lang=>'ja', -title=>'hello world', -style=>{'src'=>"$css"}),
	$q->h1('hello world');

if ($value) {
	print $value;
}
else {
	my $fck = CGI::FCKeditor->new();
	$fck->set_name("$name");
	$fck->set_base("$dir");
	print $q->start_form,
		$fck->fck,
		$q->submit,
		$q->end_form;
}
print $q->end_html;
exit;

