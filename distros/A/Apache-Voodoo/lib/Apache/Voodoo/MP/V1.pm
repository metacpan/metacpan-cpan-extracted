package Apache::Voodoo::MP::V1;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache;
use Apache::Constants qw(OK REDIRECT DECLINED FORBIDDEN SERVER_ERROR M_GET);

use Apache::Request;
use Apache::Cookie;

use base("Apache::Voodoo::MP::Common");

sub declined     { return Apache::Constants::DECLINED;     }
sub forbidden    { return Apache::Constants::FORBIDDEN;    }
sub ok           { return Apache::Constants::OK;           }
sub server_error { return Apache::Constants::SERVER_ERROR; }
sub not_found    { return Apache::Constants::NOT_FOUND;    }

sub content_type   { shift()->{'r'}->send_http_header(@_); }
sub err_header_out { shift()->{'r'}->err_header_out(@_); }
sub header_in      { shift()->{'r'}->header_in(@_); }
sub header_out     { shift()->{'r'}->header_out(@_); }

sub redirect {
	my $self = shift;
	my $loc  = shift;

	if ($loc) {
		my $r = $self->{'r'};
		if ($r->method eq "POST") {
			$r->method_number(Apache::Constants::M_GET);
			$r->method('GET');
			$r->headers_in->unset('Content-length');

			$r->header_out("Location" => $loc);
			$r->status(Apache::Constants::REDIRECT);
			$r->send_http_header;
		}
		else {
			$r->header_out("Location" => $loc);
		}
	}
	return Apache::Constants::REDIRECT;
}

sub parse_params {
	my $self       = shift;
	my $upload_max = shift;

	my %params;

	my $apr  = Apache::Request->new($self->{r}, POST_MAX => $upload_max);

	foreach ($apr->param) {
		my @value = $apr->param($_);
		$params{$_} = @value > 1 ? [@value] : $value[0];
	}

	# make sure our internal special params don't show up in the parameter list.
	delete $params{'__voodoo_file_upload__'};
	delete $params{'__voodoo_upload_error__'};

	if ($apr->parse()) {
		$params{'__voodoo_upload_error__'} = $apr->notes('error-notes');
	}
	else {
		my @uploads = $apr->upload;
		if (@uploads) {
			$params{'__voodoo_file_upload__'} = @uploads > 1 ? [@uploads] : $uploads[0];
		}
	}

	return \%params;
}

sub set_cookie {
	my $self = shift;

	my $name    = shift;
	my $value   = shift;
	my $expires = shift;

	my $c = Apache::Cookie->new($self->{r},
		-name     => $name,
		-value    => $value,
		-path     => '/',
		-domain   => $self->{'r'}->get_server_name()
	);

	if ($expires) {
		$c->expires($expires);
	}

	# I don't use Apache2::Cookie's bake since it doesn't support setting the HttpOnly flag.
	# The argument goes something like "Not every browser supports it, so what's the point?"
	# Isn't that a bit like saying "What's the point in wearing this bullet proof vest if it
	# doesn't stop a round from a tank?"
	$self->err_header_out('Set-Cookie' => $c->as_string()."; HttpOnly");
}

sub get_cookie {
	my $self = shift;

	unless (defined($self->{cookiejar})) {
		# cookies haven't be parsed yet.
		$self->{cookiejar} = Apache::Cookie::Jar->new($self->{r});
	}

	my $c = $self->{cookiejar}->cookies(shift);
	if (defined($c)) {
		return $c->value;
	}
	else {
		return undef;
	}
}

sub register_cleanup {
	my $self = shift;
	my $obj  = shift;
	my $sub  = shift;

	$self->{'r'}->register_cleanup(sub { $obj->$sub });
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
