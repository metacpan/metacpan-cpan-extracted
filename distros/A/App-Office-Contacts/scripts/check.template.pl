#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Text::Xslate 'mark_raw';

# --------------------------------------

my($template) = Text::Xslate -> new
	(
		input_layer => '',
		path        => 'htdocs/assets/templates/app/office/contacts',
	);

my($note) = $template -> render
(
	'note.tx',
	{
		name      => 'A Name',
		note_list =>
		[
		],
	}
);

say $note;
