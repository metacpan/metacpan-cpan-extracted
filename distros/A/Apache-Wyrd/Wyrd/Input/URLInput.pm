package Apache::Wyrd::Input::URLInput;
use strict;
use base qw(Apache::Wyrd::Input);
use LWP::UserAgent;
use HTTP::Request::Common;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Input::URLInput - Check URLs as inputs

=head1 SYNOPSIS

	<BASECLASS::Input::URLInput name="url" size="40" />

=head1 DESCRIPTION

Like any Form::Input Wyrd, but uses LWP::UserAgent to check that the URL
entered is a valid one.  Will call insert_error on the enclosing Form if
an attempt to contact the URL first using the HEAD method and then the GET
method both return 404 Not Found.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'type'} = 'url';
}

sub _smart_type {
	my ($self) = @_;
	return 'text';
}

sub _startup_url {
	my ($self, $value, $params) = @_;
	use Apache::Wyrd::Datum;
	$self->{'_datum'} ||= (Apache::Wyrd::Datum::Text->new($value, $params));
	$self->{'_template'} ||= '<input type="text" name="$:name" value="$:value"?:size{ size="$:size"}?:id{ id="$:id"}?:maxlength{ maxlength="$:maxlength"}?:tabindex{ tabindex="$:tabindex"}?:accesskey{ accesskey="$:tabindex"}?:onchange{ onchange="$:onchange"}?:onselect{ onselect="$:onselect"}?:onblur{ onblur="$:onblur"}?:onfocus{ onfocus="$:onfocus"}?:disabled{ disabled}?:readonly{ readonly}>';
}

sub _check_param {
	my ($self, $value) = @_;
	$self->_info("Checking URL with value $value");
	my $error = 1;
	if (not($value) or ($value eq 'NULL')) {
		#do nothing.  Blank is OK, so are NULL placemarkers
	} elsif ($value !~ m#\w{3,6}://#) {
		#check for protocol/machine
		$self->_warn("URL error -- Malformed URL");
		$self->{'_error_messages'} = [@{$self->{'_error_messages'}}, "The URL $value is not valid.  Please enter a full URL."];
		$error = 0;
	} else {
		my $ua = LWP::UserAgent->new;
		$ua->timeout(60);
		my $response = $ua->request(HEAD $value);
		my $status = $response->status_line;
		$self->_debug("URL HEAD status is $status");
		if ($status =~ /404/) {
			$response = $ua->request(GET $value);
			$status = $response->status_line;
			$self->_debug("URL GET status is $status");
		}
		if ($status =~ /404/) {
			#warn("URL error -- Status is $status");
			$self->{'_error_messages'} = [@{$self->{'_error_messages'}}, "This URL: $value returned an error: $status.  Please fix it before continuing."];
			$error = 0;
		}
	}
	$self->{'_errors'} ||= [$self->name] unless ($error);
	return $error;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Form

Build complex HTML forms from Wyrds

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;