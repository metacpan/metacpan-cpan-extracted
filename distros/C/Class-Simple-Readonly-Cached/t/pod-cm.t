#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

eval { require Test::Pod::Spelling::CommonMistakes; Test::Pod::Spelling::CommonMistakes->import() };
if($@) {
	plan skip_all => 'Test::Pod::Spelling::CommonMistakes required for testing POD spelling';
} else {
	all_pod_files_ok();
}
