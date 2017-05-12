#!/usr/bin/env perl
# FILENAME: moose-diff.pl
# CREATED: 07/16/14 22:33:59 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Example

use strict;
use warnings;
use utf8;

use CPAN::Changes::Release;
use CPAN::Meta;
use Path::Tiny qw( path );
use FindBin;
use lib "$FindBin::Bin/../lib";
use CPAN::Changes::Group::Dependencies::Stats;

my $files_root = path($FindBin::Bin)->child('moose-dif');

my $s = CPAN::Changes::Group::Dependencies::Stats->new(
  new_prereqs =>
    CPAN::Meta->load_file( $files_root->child('Moose-2.1210-META.json')->relative('.')->stringify )->effective_prereqs,
  old_prereqs =>
    CPAN::Meta->load_file( $files_root->child('Moose-2.1005-META.json')->relative('.')->stringify )->effective_prereqs,
);

my $release = CPAN::Changes::Release->new();
$release->add_changes( { group => "Dependencies::Stats" }, @{ $s->changes } );

binmode *STDOUT, ':raw:utf8';
print $release->serialize;

