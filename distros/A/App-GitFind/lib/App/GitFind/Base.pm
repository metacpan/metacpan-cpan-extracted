package App::GitFind::Base;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.000002';

use parent 'Exporter';  # TODO use Exporter::Tidy instead?
use vars::i [
    '$VERBOSE' => 0,
    '$QUIET' => 0,
    '@EXPORT' => [qw(true false
                    croak ddc getparameters *QUIET _qwc *VERBOSE vlog vwarn)],
];

#use Import::Into;

use constant { true => !!1, false => !!0 };

# Re-exports
#use Carp qw(confess);
#use Data::Dumper::Compact ();
#use Getargs::Mixed;

# === Documentation === {{{1

=head1 NAME

App::GitFind::Base - base definitions for App::GitFind

=head1 SYNOPSIS

    use App::GitFind::Base;

Imports the functions described herein.  Does not set L<strict> and L<warnings>
in the caller, since invoking modules have to do so on their own anyway for the
sake of Kwalitee.

=head1 VARIABLES

=head2 $QUIET

Set to a truthy value to disable logging via L</vlog>.  Overrides L</$VERBOSE>.
Exported as C<*QUIET> so that it can be C<local>ized.

=head2 $VERBOSE

Set to a positive integer to enable logging via L</vlog>.
Exported as C<*VERBOSE> so that it can be C<local>ized.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _qwc

qw(), but permitting comments.  Call as C<< _qwc(<<EOT) >>.  Thanks to ideas at
https://www.perlmonks.org/?node=qw%20comments .  Prototyped as C<($)>.

Has a leading underscore because for some reason that makes my syntax files
happier!

=cut

sub _qwc ($) {
    my @retval;
    for(split "\n", $_[0]//'') {
        chomp;
        s{#.*$}{};                      # Remove comments
        s{(?:^\s+)|(?:\s+$)}{}g;        # Remove leading/trailing ws
        push @retval, grep { length } split /\s+/;
    }
    return @retval;
} #_qwc()

=head2 getparameters

An alias of the C<parameters()> function from L<Getargs::Mixed>, but with
C<-undef_ok> set.

=cut

sub getparameters {
    state $GM = (require Getargs::Mixed, Getargs::Mixed->new(-undef_ok => true));

    unshift @_, $GM;
    goto &Getargs::Mixed::parameters;
} #getparameters()

=head2 ddc

L<Data::Dumper::Compact/ddc>, but lazily loads C<Data::Dumper::Compact>.

=cut

sub ddc {
    state $dumpcb = (require Data::Dumper::Compact, Data::Dumper::Compact->new->dump_cb);
    goto &$dumpcb;
}

=head2 croak

As L<Carp/croak>, but lazily loads C<Carp>.

=cut

sub croak {
    require Carp;
    goto &Carp::croak;
}

=head2 vlog

Log information to STDERR if L</$VERBOSE> is set.  Usage:

    vlog { <list of things to log> }
        [optional min verbosity level (default 1)]
        [, log-routine args];

The items in the list are joined by C<' '> on output, and a C<'\n'> is added.
Each line is prefixed with C<'# '> for the benefit of test runs.
To break the list across multiple lines, specify C<\n> at the beginning of
a list item.

The list is in C<{}> so that it won't be evaluated if logging is turned off.
It is a full block, so you can run arbitrary code to decide what to log.
If the block returns an empty list, vlog will not produce any output.
However, if the block returns at least one element, vlog will produce at
least a C<'# '>.

The message will be output only if L</$VERBOSE> is at least the given minimum
verbosity level (1 by default).

If C<< $VERBOSE >= 4 >>, the filename and line from which vlog was called
will also be printed.

If more arguments are provided than two, the extras are the arguments
to the subroutine.  This permits you to pass arguments from the caller's
C<@_> that would otherwise be shadowed inside the logging routine.  E.g.:

    sub foo {
        vlog { $_[0] } 1, $_[1];    # log foo's $_[1]
    }

=cut

sub vlog (&;@) {
    return if $QUIET;
    my ($crRoutine, $level) = splice @_, 0, 2;
    return unless $VERBOSE >= ($level // 1);

    my @log = $crRoutine->(@_);
    return unless @log;

    chomp $log[$#log] if $log[$#log];
    # TODO add an option to number the lines of the output
    my $msg = join(' ', @log);
    $msg =~ s/^/# /gm;

    if($VERBOSE >= 4) {
        my ($package, $filename, $line) = caller;
        $msg .= " (at $filename:$line)";
    }

    say STDERR $msg;
} #vlog()

=head2 vwarn

As L</vlog>, but warns regardless of L</$VERBOSE>.  Does respect L</$QUIET>.

=cut

sub vwarn (&) {
    return if $QUIET;

    my @log = &{$_[0]}();
    return unless @log;

    vlog { "Warning:", @log } $VERBOSE;
} #vwarn()

=head2 import

See L</SYNOPSIS>

=cut

#sub import {
#    my $target = caller;
#    $_[0]->export_to_level(1, @_);                              # Symbols
#
#    #$_->import::into($target) foreach qw(strict warnings);      # Pragmas
#        # ... each module has to import those anyway to satisfy Kwalitee.
#
#    #Carp->import::into($target, qw(carp croak confess cluck));  # Packages
#    #Data::Dumper::Compact->import::into($target, 'ddc');
#    #Getargs::Mixed->import::into($target);
#} #import()

1;
__END__
# === Rest of the docs === {{{1

=head1 AUTHOR

Christopher White, C<< <cxw at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Christopher White.
Portions copyright 2019 D3 Engineering, LLC.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# }}}1
# vi: set fdm=marker fdl=0: #
