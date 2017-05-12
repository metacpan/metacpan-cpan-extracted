#!/usr/bin/perl
use v5.14;
use warnings;

use Plack::Builder;
use App::Web::VPKBuilder;

builder {
	enable 'ContentLength';
	enable Static => path => qr!^/static/!;
	App::Web::VPKBuilder->new->to_app
};

__END__
