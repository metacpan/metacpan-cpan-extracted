#!/usr/bin/env perl

use inc::Module::Install;

name 'Apache2-EmbedMP3';

all_from 'lib/Apache2/EmbedMP3.pm';

requires 'Music::Tag::MP3' => '0.29',
	'Music::Tag::Lyrics' => '0.29';

no_index directory => 'examples';

WriteAll;


