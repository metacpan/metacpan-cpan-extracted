package Apache::Voodoo::MP::V2;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache2::Const qw(OK REDIRECT DECLINED FORBIDDEN AUTH_REQUIRED SERVER_ERROR NOT_FOUND M_GET);

use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::SubRequest;
use Apache2::RequestUtil;
use Apache2::Response;

use Apache2::Request;
use Apache2::Upload;
use Apache2::Cookie;

use base("Apache::Voodoo::MP::Common");

sub declined     { return Apache2::Const::DECLINED;     }
sub forbidden    { return Apache2::Const::FORBIDDEN;    }
sub unauthorized { return Apache2::Const::AUTH_REQUIRED;}
sub ok           { return Apache2::Const::OK;           }
sub server_error { return Apache2::Const::SERVER_ERROR; }
sub not_found    { return Apache2::Const::NOT_FOUND;    }

sub content_type   { shift()->{'r'}->content_type(@_); }
sub err_header_out { shift()->{'r'}->err_headers_out->add(@_); }
sub header_in      { shift()->{'r'}->headers_in->{shift()}; }
sub header_out     { shift()->{'r'}->headers_out->add(@_); }

sub redirect {
	my $self = shift;
	my $loc  = shift;

	if ($loc) {
		my $r = $self->{'r'};
		if ($r->method eq "POST") {
			$r->method_number(Apache2::Const::M_GET);
			$r->method('GET');
			$r->headers_in->unset('Content-length');

			$r->headers_out->add("Location" => $loc);
			$r->status(Apache2::Const::REDIRECT);
			$r->content_type;
		}
		else {
			$r->headers_out->add("Location" => $loc);
		}
	}
	return Apache2::Const::REDIRECT;
}

sub parse_params {
	my $self       = shift;
	my $upload_max = shift;

	my $apr = Apache2::Request->new($self->{r}, POST_MAX => $upload_max*5);

	my %params;
	foreach ($apr->param) {
		my @value = $apr->param($_);
		$params{$_} = @value > 1 ? [@value] : $value[0];
	}

	# make sure our internal special params don't show up in the parameter list.
	delete $params{'__voodoo_file_upload__'};
	delete $params{'__voodoo_upload_error__'};

	my @uploads = $apr->upload;
	if ($#uploads == 0) {
		my $u = $apr->upload($uploads[0]);
		if ($u->size() > $upload_max) {
			$params{'__voodoo_upload_error__'} = "File size exceeds $upload_max bytes.";
		}
		else {
			$params{'__voodoo_file_upload__'} = $u;
		}
	}
	elsif ($#uploads > 0) {
		foreach (@uploads) {
			my $u = $apr->upload($_);
			if ($u->size() > $upload_max) {
				$params{'__voodoo_upload_error__'} = "File size exceeds $upload_max bytes.";
			}
			else {
				push(@{$params{'__voodoo_file_upload__'}},$u);
			}
		}
	}

	return \%params;
}

sub set_cookie {
	my $self = shift;

	my $name    = shift;
	my $value   = shift;
	my $expires = shift;

	my $c = Apache2::Cookie->new($self->{r},
		-name     => $name,
		-value    => $value,
		-path     => '/',
		-domain   => $self->{'r'}->get_server_name()
	);

	if ($expires) {
		$c->expires($expires);
	}

	# I didn't use Apache2::Cookie's bake since it doesn't support setting the HttpOnly flag.
	# The argument setting the flag goes something like "Not every browser supports it,
	# so what's the point?"  Which seems to me to be a bit like saying "What's the point
	# in wearing this bullet proof vest if it doesn't stop a shell from a tank?"
	$self->err_header_out('Set-Cookie' => "$c; HttpOnly");
}

sub get_cookie {
	my $self = shift;

	unless (defined($self->{cookiejar})) {
		# cookies haven't be parsed yet.
		$self->{cookiejar} = Apache2::Cookie::Jar->new($self->{r});
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

	$self->{'r'}->pool->cleanup_register($sub,$obj);
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
