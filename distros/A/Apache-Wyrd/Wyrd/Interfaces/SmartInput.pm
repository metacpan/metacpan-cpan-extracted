use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Interfaces::SmartInput;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Interfaces::SmartInput - Interface for estimating pixel widths of Input Wyrds

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

Provides estimated pixel width and height attributes for text and
textarea inputs.  If an Input type is not explicitly 'text' or
'textarea' (such as a derived type that still uses a text input as it's
HTML input), it should set it's B<_smart_type> attribute to specify one
or the other of 'text' or 'textarea'.


=head1 BUGS/CAVEATS/RESERVED METHODS

Provides an estimate at best.  Assumes that browser defaults will not
rapidly change.  Supports only the major mac and windows browsers at the
time of writing.  Use CSS.  It's been around long enough.

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

sub _smart_type {
	my ($self) = @_;
	return $self->{'_smart_type'} if ($self->{'_smart_type'});
	return 'text' if ($self->{'type'} eq 'text');
	return 'textarea' if ($self->{'type'} eq 'textarea');
	return;
}

sub _input_size {
	my ($self) = @_;
	if ($self->_smart_type eq 'text') {
		return undef unless ($self->{'width'});
		my $size = undef;
		my $class = $self->_browser_class;
		$self->_info("Class is $class");
		my $width = $self->{'width'};
		if ($class eq 'safari') {
			$size = int(($width - 8)/7);
		} elsif ($class eq 'macie') {
			$size = int(($width - 10)/6);
		} else {
			#default winie, gecko
			$size = int(($width - 10)/7);
		}
		if ($size < 1) {
			$self->_error("width is an illegal value.  Ignoring.");
		} else {
			$self->{'size'} = $size;
		}
	} elsif ($self->_smart_type eq 'textarea') {
		my ($rows, $cols) = ();
		my $width = $self->{'width'};
		my $height = $self->{'height'};
		return undef unless ($width or $height);
		my $class = $self->_browser_class;
		$self->_info("Class is $class");
		if ($width) {
			if ($class eq 'safari') {
				$cols = int(($width + 2)/7);
			} elsif ($class eq 'macie') {
				$cols = int(($width - 22)/6);
			} elsif ($class =~ /gecko/) {
				$cols = int(($width - 24)/8);
			} else {
				#default winie
				$cols = int(($width - 16)/8);
			}
			if ($cols < 1) {
				$self->_error("width is an illegal value.  Ignoring.");
			} else {
				$self->{'cols'} = $cols;
			}
		}
		if ($height) {
			if ($class eq 'safari') {
				$rows = int(($height + 1)/14);
			} elsif ($class eq 'macie') {
				$rows = int($height/14);
			} elsif ($class eq 'macgecko') {
				$rows = int(($height - 24)/12);
			} elsif ($class eq 'wingecko') {
				$rows = int(($height - 16)/16);
			} else {
				#default winie
				$rows = int($height/18);
			}
			if ($rows < 1) {
				$self->_error("height is an illegal value.  Ignoring.");
			} else {
				$self->{'rows'} = $rows;
			}
		}
		$self->_debug("rows: $rows, cols: $cols");
	}
	return;
}

sub _browser_class {
	my ($self) = @_;
	my $ident = $self->dbl->req->headers_in->{'User-Agent'};
	return 'safari' if ($ident =~ /Safari/);
	if ($ident =~ /Gecko/) {
		return 'macgecko' if ($ident =~ /Macintosh/);
		return 'wingecko';
	}
	return 'macie' if ($ident =~ /Mac/);
	return 'winie';
}

1;
