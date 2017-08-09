package App::Gallery;

use 5.014000;
use strict;
use warnings;

use File::Basename qw/fileparse/;
use File::Copy qw/cp/;
use File::Path qw/make_path/;
use File::Slurp;
use File::Spec::Functions qw/catdir catfile/;
use HTML::Template::Compiled;
use Image::Magick;

our $VERSION = '0.001';

my $default_template;
my %default_args = (tmpl => '', title => 'Gallery', width => 600, height => 600);

sub run {
	my (undef, $args, @images) = @_;
	my %args = (%default_args, %$args);
	my $full = catfile $args{out}, 'full';
	my $thumb = catfile $args{out}, 'thumb';
	my $tmpl = HTML::Template::Compiled->new(
		(($args{tmpl} // '') eq '')
		  ? (scalarref => \$default_template)
		  : (filename => $args{tmpl}),
		default_escape => 'HTML',
	);
	make_path $full, $thumb;

	for my $path (@images) {
		my $basename = fileparse $path;
		my $thumb_path = catfile $thumb, $basename;
		my $dest_path = catfile $full, $basename;

		link $path, $dest_path or cp $path, $dest_path or die "$!";

		my $img = Image::Magick->new;
		$img->Read($path);
		my ($width, $height) = $img->Get('width', 'height');
		my $aspect_ratio = $width / $height;
		if ($width > $args{width}) {
			$width = $args{width};
			$height = $width / $aspect_ratio;
		}
		if ($height > $args{height}) {
			$height = $args{height};
			$width = $height * $aspect_ratio;
		}
		$img->Thumbnail(width => $width, height => $height);
		$img->Write($thumb_path);
	}

	$tmpl->param(
		title => $args{title},
		images => [map { scalar fileparse $_ } @images]
	);

	my $index = catfile $args{out}, 'index.html';
	write_file $index, $tmpl->output;
}

$default_template = <<'EOF';
<!DOCTYPE html>
<title><tmpl_var title></title>
<meta charset="utf-8">
<style>
.imgwrap {
        display: inline-block;
        margin: 6px 3px;
        vertical-align: center;
        text-align: center;
}
</style>
<link rel="stylesheet" href="style.css">

<h1><tmpl_var title></h1>
<div>
<tmpl_loop images><div class=imgwrap><a href='full/<tmpl_var _>'><img src='thumb/<tmpl_var _>'></a></div>
</tmpl_loop></div>
EOF

1;
__END__

=encoding utf-8

=head1 NAME

App::Gallery - Very basic picture gallery

=head1 SYNOPSIS

  use App::Gallery;

=head1 DESCRIPTION

App::Gallery is a script for creating a very basic picture gallery out
of a list of pictures.

=head1 SEE ALSO

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
