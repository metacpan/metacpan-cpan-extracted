my $css = '';
foreach my $name (@{$wtk->{'cssfiles'}}) {
	my $filename = $wtk->{'privatepath'}.'/styles/'.$name;
	   $filename .= '.css' if $filename !~ /\.css$/;
	if (-f $filename) {
		open CSSFILE, '<'.$filename or next;
		$css .= "\n".join('', <CSSFILE>);
		close CSSFILE;
	}
}

# compress css a little

# erease comments
$css =~ s/\/\/[^\n\r]*[\r\n]//g;
$css =~ s/\/\*[^\/]+\*\///mg;

# many whitespaces -> one whitespace
$css =~ s/[\s\t\n\r]+/ /g;

# space after semicolon
$css =~ s/([\;\{\:])[\s]*/$1/g;

return output(1,'ok',$css,'text/css');
