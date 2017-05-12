# -*- Mode: perl -*-
#
# $Id: MakeMaker.pm,v 0.1 2001/03/31 10:04:36 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: MakeMaker.pm,v $
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Carp::Datum::MakeMaker;

use Log::Agent;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(WriteMakefile);

require ExtUtils::MakeMaker;

#
# ->WriteMakefile
#
# Supersedes the version from ExtUtils::MakeMaker to get a chance to ask
# whether the debugging version of the module needs to be installed or not.
# This is only possible starting with version 5.45 of MakeMaker (perl 5.6.1).
#
sub WriteMakefile {
	my %args = @_;
	my $version = $ExtUtils::MakeMaker::VERSION;
	my $name = $args{NAME};
	my $LIMIT = 5.45;

	if ($version < $LIMIT) {
		print "Keeping Carp::Datum calls in $name -- MakeMaker is too old\n";
		print "(Would need ExtUtils::MakeMaker version $LIMIT or better)\n";
		return &ExtUtils::MakeMaker::WriteMakefile;
	} elsif (-t STDIN) {
		local *TTY;
		open(TTY, ">/dev/tty");
		select((select(TTY), $| = 1)[0]);
		print TTY <<EOM;

The $name module uses the Carp::Datum extension to implement the
Programming by Contract paradigm, and also get flexible tracing abilities.

By default, I shall strip all the Carp::Datum stuff at build time, and
you will get a clean copy, almost as if the author of $name had never
used Carp::Datum in the first place.  Only DTRACE calls will be kept,
and will be redirected at runtime to Log::Agent.

Or you can choose to install the debugging version.  However, unless your
application explicitely requests debugging, Carp::Datum will remain silent,
only monitoring the assertions.  The exact runtime penalty you will suffer
depends on the amount of assertions, but it is around 15%.

EOM
		print TTY "Strip Carp::Datum calls in installed $name? [y] ";
		close TTY;
		my $ans = <STDIN>;
		return &ExtUtils::MakeMaker::WriteMakefile if $ans =~ /^n/i;
	} else {
		print "Will build $name with calls to Carp::Datum stripped\n";
	}

	#
	# They wish to remove all Carp::Datum code from the installed files.
	#

	$args{'macro'} = {} unless exists $args{'macro'};
	$args{'macro'}->{PM_FILTER} = "datum_strip";

	return &ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;

=head1 NAME

Carp::Datum::MakeMaker - Offer to strip Carp::Datum calls statically

=head1 SYNOPSIS

 # Put this at the top of the Makefile.PL for your module
 use ExtUtils::MakeMaker;       # you may omit this line
 use Carp::Datum::MakeMaker;

=head1 DESCRIPTION

The C<Carp::Datum::MakeMaker> module supersedes the regular WriteMakefile()
routine of C<ExtUtils::MakeMaker>.

When running the Makefile.PL from a module interactively, the user will
be asked whether calls to C<Carp::Datum> should be stripped at build time.

By default, or when running non-interactively, most calls to Carp::Datum
routines will be removed:
the C<datum_strip> program will be invoked to filter *.pm files during
the build process.  This program is a mere wrapper for the datum_strip()
routine, defined in C<Carp::Datum::Strip>.

The only call that will not be stripped is the DTRACE() call.  However, it
will be dynamically remapped to a C<Log::Agent> call.  It cannot be statically
remapped because of its baroque interface.

At the top of Makefile.PL, insert 

    use Carp::Datum::MakeMaker;

which will take care of loading C<ExtUtils::MakeMaker>.  Note that
it makes sense to refer to this module, since C<Carp::Datum> is being used
internally, and therefore the user will not be able to install the module
if they do not have C<Carp::Datum> already installed.

If you wish to be nicer about C<Carp::Datum> not being installed, you
can say instead:

    use ExtUtils::MakeMaker;
    eval "use Carp::Datum::MakeMaker;";

    WriteMakefile(
        'NAME'      => "Your::module::name",
        'PREREQ_PM' => {
            'Carp::Datum'  => '0.100',
        },
    );

It will allow them to run the Makefile.PL, and yet be reminded about the
missing C<Carp::Datum> module.  Chances are they won't be able to go
much farther though...

=head1 AUTHORS

Christophe Dehaudt and Raphael Manfredi are the original authors.

Send bug reports, hints, tips, suggestions to Dave Hoover at <squirrel@cpan.org>.

=head1 SEE ALSO

Carp::Datum::Strip(3), ExtUtils::MakeMaker(3).

=cut

