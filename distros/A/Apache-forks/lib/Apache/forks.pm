package Apache::forks;

$VERSION = 0.03;

use strict;
use warnings;
use Carp ();
use vars qw(@ISA);

use constant BASE => 'forks';

BEGIN {
	@ISA = qw(Apache::forks::Common);
	require Apache::forks::Common;

	{
		no warnings 'redefine';
		*debug = *debug = \&Apache::forks::Common::debug;
		*childinit = *childinit = \&Apache::forks::Common::childinit;
	}

	__PACKAGE__->_load_forks();
}


package
	Apache::forks::shared;	# hide from PAUSE

use vars qw(@ISA);
BEGIN {
	@ISA = qw(Apache::forks::Common);
}
use constant BASE => 'forks::shared';

sub import {
	shift;
	_forks_shared->import(@_);
}

1;

__END__

=pod

=head1 NAME

Apache::forks - Transparent Apache ithreads integration using forks

=head1 VERSION

This documentation describes version 0.03.

=head1 SYNOPSIS

 # Configuration in httpd.conf

 PerlModule Apache::forks  # this should come before all other modules!

Do NOT change anything in your scripts. The usage of this module is transparent.

=head1 DESCRIPTION

Transparent Apache ithreads integration using forks.  This module enables the
ithreads API to be used among multiple processes in a pre-forking Apache http
environment.

=head1 REQUIRED MODULES

 Devel::Required (0.07)
 forks (0.26)
 mod_perl (any)
 Test::More (any)

=head1 USAGE

The module should be loaded upon startup of the Apache daemon.  You must be
using at least Apache httpd 1.3.0 or 2.0 for this module to work correctly.

Add the following line to your httpd.conf:

 PerlModule Apache::forks

or the following to the first PerlRequire script (i.e. startup.pl):

 use Apache::forks;

It is very important to load this module before all other perl modules!

A Common usage is to load the module in a startup file via the PerlRequire
directive. See C<eg/startup.pl> in this distribution.  In this case, be sure
that the module is first to load in the startup script, and that the
PerlRequre directive to load the startup script is the first mod_perl directive
in your httpd.conf file.

Please see the C<eg/> directory in this distribution for other examples.

=head1 NOTES

=head2 mod_perl processes start as detached threads

CGI scripts may behave differently when using forks with mod_perl, depending
on how you have implemented threads in your scripts.  This is frequently due to
the difference in the thread group behavior: every mod_perl handler (process)
is already a thread when your CGI starts executing, and all CGIs executing
simultaneously on your Apache server are all part of the same application
thread group.  Your script is no longer executed as the main thread
(Thread ID 0); it is just a detached child thread in the executing thread group.

This differs from pure CGI-style execution, where every CGI has its own unique
thread group (isolated from all other Apache process handlers) and each CGI
always begins execution as the main thread.

=head2 threads->list and $thr->join differences in mod_perl

Methods that operate other threads should be treated with care. For example, if you
were successfully doing the following in CGI:

 threads->new({'context' => 'scalar'}, sub {...}) for 1..5;
 push @results, $_->join foreach threads->list(threads::running); #<-- don't do this
 
or

 threads->new({'context' => 'scalar'}, sub {...}) for 1..5;
 $_->join foreach threads->list(threads::joinable);	#<-- don't do this

the join operation may inadvertantly join threads started by from other Apache
handler processes executing threaded code at the same time!

Do the following in mod_perl instead:

 push @my_threads, threads->new({'context' => 'scalar'}, sub {...}) for 1..5;
 push @results, $_->join foreach @my_threads;
 
or

 push @my_threads, threads->new({'context' => 'scalar'}, sub {...}) for 1..5;
 $_->join foreach map($_->is_joinable ? $_ : (), @my_threads);
 
The good news about making such logic changes is that they will work both in CGI
and mod_perl modes.  If you code all your threaded CGIs in this style, your code
should work fine without changes when switching to mod_perl.

=head1 TODO

Determine why mod_perl appears to skip END blocks of child threads (threads
started in an apache-forked handler process) that complete and exit safely.
This isn't necessarily harmful, but should be resolved to insure highest level
of application and memory stability.

=head1 CAVIATS

This module will only work with Apache httpd 1.3.0 or newer.  This is due to the
lack of mod_perl support for PerlChildInitHandler directive.  See L<mod_perl/"mod_perl">
for more information regarding this.

For Apache 2.x, this module currently only supports the MPM (Multi-Processing Module)
L<http://httpd.apache.org/docs/2.0/mod/prefork.html#prefork>.
This is due to the architecture of L<forks>, which only supports one perl thread per
process.

=head1 BUGS

=head1 CREDITS

=over

=item Apache::DBI

Provided the general framework to seamlessly load a module and execute a
subroutine on init of each Apache child handler process for both Apache 1.3.x 
and 2.x.

=back

=head1 AUTHOR

Eric Rybski, <rybskej@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2008 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks>, L<forks::shared>.

=cut
