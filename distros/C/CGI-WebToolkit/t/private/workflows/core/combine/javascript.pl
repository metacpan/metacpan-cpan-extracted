my $js = '';
foreach my $name (@{$wtk->{'jsfiles'}}) {
	my $filename = $wtk->{'privatepath'}.'/javascripts/'.$name;
	   $filename .= '.js' if $filename !~ /\.js$/;
	if (-f $filename) {
		open JSFILE, '<'.$filename or next;
		$js .= "\n".join('', <JSFILE>);
		close JSFILE;
	}
}

return output(1,'ok',$js,'text/javascript');
