#!perl -w
package D::oh;
use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION);
use strict;
use Exporter;
use File::Basename;
use IO::Handle;
use Carp;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(sortFile);
$VERSION = sprintf("%d.%02d", q$Revision: 0.05 $ =~ /(\d+)\.(\d+)/);

#-----------------------------------------------------------------
my($Sep) = (($^O eq 'MacOS') ? ':' : '/');
my($Err) = (($^O eq 'MacOS') ? "$ENV{TMPDIR}D\'oh" : '/tmp/D\'oh');
my($Out) = undef;
#-----------------------------------------------------------------
sub date {
    no strict 'refs';
    my($fh)   = ($_[0] =~ /^STDOUT$/i ? 'STDOUT' : 'STDERR');
    printf $fh "\n#===== %s [$$]: %s =====#\n",
    	($0 =~ /([^$Sep]+)$/), scalar localtime;
	1;
}
#-----------------------------------------------------------------
sub stdout {
	$Out = $_[0] ? $_[0] : ($Out ? $Out : $Err);
	open(STDOUT,">>$Out") || croak("D'oh can't open $Err: $!");
	STDOUT->autoflush(1);
	1;
}
#-----------------------------------------------------------------
sub stderr {
	$Err = $_[0] ? $_[0] : $Err;
	open(STDERR,">>$Err") || croak("D'oh can't open $Err: $!");
	STDERR->autoflush(1);
	1;
}
#-----------------------------------------------------------------
1;

__END__

=head1 NAME

D'oh - Debug module

=head1 SYNOPSIS

	#!/usr/bin/perl -w
	use D'oh;
	D'oh::stderr();
	D'oh::stderr('/tmp/stderr');

	#print date and script name/pid to STDERR
	D'oh::date();

	#redirect STDOUT	
	D'oh::stdout();
	D'oh::stdout('/tmp/stdout');
	D'oh::date('STDOUT');

	print "hellloooooo\n";
	die "world";

	__END__

	tail /tmp/stdout
	#===== myscript [1743]: Mon Feb  2 11:27:41 1998 =====#
	hellloooooo

	tail /tmp/stderr
	#===== myscript [1743]: Wed Apr  1 11:24:39 1998 =====#
	# world.
	File '/export/home/chrisn/bin/myscript'; Line 15

=head1 DESCRIPTION

The module, when used, prints all C<STDERR> (or C<STDOUT>) to a given file, which is by default C</tmp/D'oh>.

=head1 BUGS

Also, multiple scripts can write simultaneously to the same error file, making it really messy.  If you don't like this, then select different files for each script or whatever.

=head1 Mac OS

Mac OS does not like to have multiple opens to the same file.  Use different files.  The default directory for the files is C<$ENV{TMPDIR}> in MacPerl, not C</tmp>.

=head1 AUTHOR

Chris Nandor, pudge@pobox.com, http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 VERSION

Version 0.05 (02 February 1998)

=cut
