#perl -T
#
# Check the Changes file contains updates for $VERSION to avoid
# releasing the package without updating Changes
#
# $Id: changes_version.t 10 2006-05-22 18:21:21Z tom $

use strict;

use Test::More  tests => 1;

use Archive::StringToZip ();

use Fatal       qw(open);

open my($fh), 'Changes';
my $changes = do {local $/ = undef; <$fh> };
my $version = $Archive::StringToZip::VERSION;

like $changes, qr/^$version\s+/ms, 'Changes contains current version number';
