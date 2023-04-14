#!/usr/bin/env perl
# AP-Client: CLI-based client / toolbox for ActivityPub
# Copyright © 2020-2023 AP-Client Authors <https://hacktivis.me/git/ap-client/>
# SPDX-License-Identifier: BSD-3-Clause
package App::ActivityPubClient;
our $VERSION = 'v0.1.3';
use strict;
use utf8;
use open ":std", ":encoding(UTF-8)";

use Scalar::Util qw(reftype);

use Exporter 'import';

our @EXPORT_OK = qw(print_object);

sub print_object_key {
	my ($indent, $object, $key) = @_;

	if ($object->{$key}) {
		print_ref($indent, $object->{$key}, $key);
	}
}

sub print_object {
	my ($indent, $object) = @_;

	my @regular_keys =
	  qw{url subtitleLanguage context inbox outbox prev next published updated summary content bcc bto cc to object attachment tag orderedItems mediaType};

	printf "%*s %s",     $indent, '⇒', $object->{"type"};
	printf ' id:<%s>',   $object->{"id"}   if $object->{"id"};
	printf ' href:<%s>', $object->{"href"} if $object->{"href"};
	printf ' “%s”',      $object->{"name"} if $object->{"name"};
	printf ' @%s', $object->{"preferredUsername"}
	  if $object->{"preferredUsername"};
	printf ' ⚠' if ($object->{"sensitive"} eq JSON->true);
	foreach (@regular_keys) {
		print_object_key($indent, $object, $_);
	}
}

sub print_ref {
	my ($indent, $object, $name) = @_;

	my $ref_type = reftype($object);

	if ($ref_type eq 'HASH') {
		printf "\n%*s%s: \n", $indent, ' ', $name;
		print_object($indent + 4, $object);
	} elsif ($ref_type eq 'ARRAY') {
		printf "\n%*s%s: ", $indent, ' ', $name if @{$object};
		foreach (@{$object}) {
			if (reftype($_) eq 'HASH') {
				print "\n";
				print_object($indent + 4, $_);
			} else {
				printf "%s ; ", $_;
			}
		}
	} else {
		printf "\n%*s%s: %s", $indent, ' ', $name, $object;
	}
}

1;
