package BaseLib;

## $Id: BaseLib.pm,v 1.6 2002/10/23 12:04:31 hasant Exp $
## Manipulate @INC dynamically for independent installation path
##
## Written by: Hasanuddin Tamir <hasant@trabas.com>
## Copyright (C) 2000 Trabas.  All rights reserved.
##
## This program is free software; you may redistribute it
## and/or modify it under the same terms as Perl itself.

use strict;
use File::Spec;
use File::Basename 'dirname';
use Cwd 'abs_path';

$BaseLib::VERSION = '0.05';

sub import {
	shift;
	my($base, $lib, $glob) = @_;

	# the base directory name is now mandatory
	croak('No base directory supplied')
		unless defined $base && $base ne '';

	my $dirname = abs_path(dirname $0);
	my @dirs = File::Spec->splitdir($dirname);
	while (@dirs) {
		last if $dirs[-1] eq $base;
		pop @dirs;
	}

	@dirs || croak("Couldn't find the base `$base' in `$dirname'");
	my $basedir = File::Spec->catdir(@dirs);

	$lib = File::Spec->catdir(qw(lib perl))
		unless defined $lib and $lib ne '' and $lib ne '-';
	my $libdir = File::Spec->catdir($basedir, $lib);

	# ask lib.pm to finish the job :-) well, assummed it's not loaded yet
	# FIXME: is it necessary to check this?
	my %inc = map { $_ => 1 } @INC;
	unless ($inc{$libdir}) {
		require lib;
		lib::import('lib', $libdir);
	}

	# give them if they want it
	if ($glob) {
		no strict 'refs';
		my $pack = caller;
		${"$pack\:\:$glob"} = $basedir;
	}
	else {
		$BaseLib::BaseDir = $basedir;
	}
}

# private routine
sub croak {
	require Carp;
	Carp::croak(__PACKAGE__, ": @_");
}


1;


=head1 NAME

BaseLib - manipulate @INC dynamically for independent installation path

=head1 SYNOPSIS

  use BaseLib qw(BASEDIR LIBDIR);

or just,

  use BaseLib;


=head1 DESCRIPTION

If you have a set of application with certain file structure under a
base directory, e.g. C<pim>, and it has a private modules directory
called C<lib-perl>, and it's intalled under C</usr/local>. For the
application to work, the scripts may need to say:

   use lib '/usr/local/pim/lib-perl';

Someday, you need to move the application to, say, C</vhost/www.host.com>,
so you need to change the use statement all over the scripts to:

   use lib '/vhost/www.some.host.com/pim/lib-perl';

If you do this a lot and get tired of changing the line for every
different installation path in every script, or, you don't want to
bother people using your application to change the line to meet their
conditions, then you might need this module.

Now your scripts can say:

   use BaseLib qw(pim lib-perl);

where C<pim> and C<lib-perl> are the BASEDIR and LIBDIR arguments,
respectively.

So there's no need to worry about different installation layout, wherever
the C<pim> base directory is put under. The BASEDIR argument is mandatory
while LIBDIR is optional (defaults to C<lib/perl>).

As addition, you can use B<BaseLib>'s global package variable,
B<$BaseDir> to refer to the full path to C<pim>. For example,
assuming the application is installed under C</usr/local>, then

   print "Data dir: $BaseLib::BaseDir/data\n";

will print,

   Data dir: /usr/local/pim/data

You have to use the fully qualified package name since it's not
exportable.

You can use your own global variable by supplying the third argument
in the use statement. For example,

   use BaseLib qw(pim lib-perl MyOwnBaseDir);

So saying,

   print "Data dir: $MyOwnBaseDir/data\n";

will result the same thing. If you use 'use strict;', which is a good
thing, you need to explicitly declare it as global variable. Either,

   use vars '$MyOwnBaseDir';

or, if you use version 5.6 or later,

   our $MyOwnBaseDir;

If you want to use the default LIBDIR (C<lib/perl>), you can indicate
so by using dash ("-").

   use BaseLib qw(pim - MyOwnBaseDir);

Or, just give an empty string,

   use BaseLib ('pim', '', 'MyOwnBaseDir');


=head1 NOTES

I rewrote the implementation to make this module more reusable in
different environment. No path resolving is hardcoded. Unfortunately, I
have no any chance to test it.

B<BaseLib> will find the last occurence of I<BASEDIR> string. If you mean
the base directory as C</usr/local/myapp>, while the script uses the module
locates in C</usr/local/myapp/bin/sample/myapp/test/script.pl>, then the
full path to the application base directory ends in
C</usr/local/myapp/bin/sample/myapp>.

Any improvements/suggestions for wider support are welcome. A simple
comment on this module will do as well.

=head1 AUTHOR

This module is written by Hasanuddin Tamir E<lt>hasant@trabas.comE<gt>.

Copyright (C) 2000 B<Trabas>.  All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<lib>, L<FindBin>

=cut
