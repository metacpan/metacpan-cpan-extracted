package main;

sub setup {
		my $filename = shift;

		my $upload = Catalyst::Request::Upload->new();

		$upload->tempname($filename);
		$upload->filename($filename);
		$upload->size(-s $filename);

		$upload->type("image/gif") if ($filename =~ /\.gif$/i);
		$upload->type("image/jpeg") if ($filename =~ /\.(jpe?g|jpe)/i);
		$upload->type("image/png") if ($filename =~ /\.png/i);

		return $upload;
}

1;
