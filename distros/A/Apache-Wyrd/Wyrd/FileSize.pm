use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::FileSize;
our $VERSION = '0.98';
use base qw(Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(commify);

=pod

=head1 NAME

Apache::Wyrd::FileSize - Display a File's Size

=head1 SYNOPSIS

  <P>
    <a href="/sounds/nanny.ogg">Bathtub Song</a>&#151;size:
      <BASENAME::FileSize file="/sounds/nanny.ogg" />
  </p>

=head1 DESCRIPTION

Looks up and displays the size of a file.  Files are rounded to the closest 2 decimal points and are put in kilobytes or megabytes as appropriate.

=head2 HTML ATTRIBUTES

=over

=item file

File to look up.  Given in absolute path from the directory root.

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	my $file = $self->{'file'};
	$file = $self->dbl->req->document_root . "$file";
	if (-f $file) {
		my @stat = stat(_);
		my $size = $stat[7];
		my $unit = 'K';
		if ($size < 1048576) {
			$size /= 1024;
		} else {
			$size /= 1048576;
			$unit = 'M';
		}
		$size = int($size * 100);
		$size =~ s/(\d\d)$/.$1/;
		$size =~ s/\.00$//;
		$size =~ s/(\.\d)0$/$1/;
		$size = commify($size);
		$self->_data($size . $unit);
	} else {
		$self->_data(qq(?<!-- $file is not a file -->));
	}
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut
