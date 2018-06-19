#!perl
package D::oh;

use strict;
use warnings;

use File::Basename;
use File::Spec::Functions qw(catfile tmpdir);

use Carp;
use IO::Handle;
use JSON;
use Time::HiRes 'gettimeofday';

use parent 'Exporter';
our @EXPORT_OK;

our $VERSION = '1.01';

our $ERRFILE = catfile(($ENV{TMPDIR} || tmpdir), 'D\'oh');
our $OUTFILE;

sub import {
    push @EXPORT_OK, $_[1];
    D'oh->export_to_level(1, @_);  #'#
}

sub AUTOLOAD {
    my $data;
    if (@_ > 1) {
        $data = \@_;
    }
    elsif (ref $_[0]) {
        $data = $_[0];
    }
    else {
        $data = [$_[0]];
    }

    print STDERR encode_json($data), "\n";
}

sub date {
    my($fh) = ($_[0] && $_[0] =~ /^STDOUT$/i ? 'STDOUT' : 'STDERR');
    my @gt = gettimeofday();
    my @lt = gmtime($gt[0]);
    (my $ss = sprintf('%.03f', '.' . $gt[1])) =~ s/^0\.//;

    my $string = sprintf "# D'oh: %s [$$] %04d-%02d-%02d %02d:%02d:%02d.%sZ\n",
        basename($0), $lt[5]+1900, $lt[4]+1, @lt[3,2,1,0], $ss;

    no strict 'refs';
    print $fh $string;
}

sub stdout {
    $OUTFILE = $_[0] if $_[0];
    unless (defined $OUTFILE) {
        warn "filename required to output to";
        return;
    }
    open(STDOUT, '>>', $OUTFILE) or croak("D'oh can't open $OUTFILE: $!");
    STDOUT->autoflush(1);
}

sub stderr {
    $ERRFILE = $_[0] if $_[0];
    unless (defined $ERRFILE) {
        warn "filename required to output to";
        return;
    }
    open(STDERR, '>>', $ERRFILE) or croak("D'oh can't open $ERRFILE: $!");
    STDERR->autoflush(1);
}

1;

__END__

=head1 NAME

D'oh - Debug module that redirects STDOUT and STDERR

=head1 SYNOPSIS

	#!/usr/bin/perl
	use D'oh 'i_hate_this_program';
	D'oh::stderr('/tmp/stderr'); # redirect all stderr to /tmp/stderr

	# print date and script name/pid to STDERR
	D'oh::date();

	D'oh::stdout('/tmp/stdout'); # redirect all stderr to /tmp/stderr
	# print date and script name/pid to STDOUT
	D'oh::date('STDOUT');

    i_hate_this_program({ arbitrary => ['structured data'] });

	print "hellloooooo\n";
	die "world";

	__END__

    $ tail /tmp/stdout
    # D'oh: myscript [16440]: 2018-06-19 02:45:16.678Z
    hellloooooo

    $ tail /tmp/stderr
    # D'oh: myscript [16440]: 2018-06-19 02:45:16.677Z
    [{"arbitrary":["structured data"]}]
    world at myscript line 15.

=head1 DESCRIPTION

The module, when used, prints all C<STDERR> or C<STDOUT> to a given file, which is by default C</tmp/D'oh>.

C<stderr(FILENAME)> and C<stdout(FILENAME)> start the redirection.  Redirection is not reversible (unless you save-and-restore the filehandles yourself).  If no FILENAME is provided, the default is used.

C<date> prints a timestamp to STDERR (C<date('STDOUT')> prints it to STDOUT).

You can also dump random data as JSON to STDERR by calling any function name you want.  Just import the name you want to use.

=head1 AUTHOR

Chris Nandor, pudge@pobox.com, http://pudge.net/

Copyright (c) 1998-2018 Chris Nandor.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 VERSION HISTORY

Version 1.00 (2018-06-18)
Version 0.05 (1998-02-02)

=cut
