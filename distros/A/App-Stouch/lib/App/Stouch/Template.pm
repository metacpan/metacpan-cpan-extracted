package App::Stouch::Template;
our $VERSION = '0.01';
use 5.016;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(render_file render_directory);

use File::Path qw(make_path);
use File::Spec;

sub render_file {

	my $in    = shift;
	my $out   = shift;
	my $param = shift;

	open my $ih, '<', $in  or die "Failed to open $in for reading: $!";
	open my $oh, '>', $out or die "Failed to open $out for writing :$!";

	while (my $l = readline $ih) {

		foreach my $f (keys %{$param}) {
			$l =~ s/\{\{$f\}\}/$param->{$f}/g;
		}

		print { $oh } $l;

	}

	close $ih;
	close $oh;

	return $out;

}

sub render_directory {

	my $in    = shift;
	my $out   = shift;
	my $param = shift;

	opendir my $dir, $in or die "Failed to open directory $in: $!";

	make_path($out);

	my @created = ($out);

	while (my $f = readdir $dir) {

		next if $f =~ /^\.\.?$/;

		my $fpath = File::Spec->catfile($in, $f);

		my @new;

		if (-d $fpath) {
			@new = render_directory($fpath, File::Spec->catfile($out, $f), $param);
		} elsif (-f $fpath or -l $fpath) {
			@new = render_file($fpath, File::Spec->catfile($out, $f), $param);
		}

		push @created, @new;

	}

	return @created;

}

1;

=head1 NAME

App::Stouch::Template - stouch template rendering

=head1 SYNOPSIS

  use App::Stouch::Template qw(render_file render_directory);

  render_file($template, $out, $param);
  render_directory($template, $out, $param);

=head1 DESCRIPTION

App::Stouch::Template is a module designed to perform simple template rendering
for L<stouch>. You should probably be reading its documentation instead of this.

=head1 SUBROUTINES

View the documentation for L<stouch> for more information on how template
rendering works.

No subroutines are exported by default.

=over 4

=item render_file($in, $out, $param)

Renders template file $in, writing output to $out. $param is a hash ref of
template text substitution parameters.

Returns $out.

=item render_directory($in, $out, $param)

Renders template directory $out, placing output in $out. $param is a hash ref
of template text substitution parameters.

C<render_directory> works by C<readdir>ing $in, calling C<render_directory> for
every directory and C<render_file> for every normal file.

Returns array of files created.

=back

=head1 AUTHOR

Written by Samuel Young, L<samyoung12788@gmail.com>.

=head1 COPYRIGHT

Copyright 2024, Samuel Young

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<stouch>

=cut
