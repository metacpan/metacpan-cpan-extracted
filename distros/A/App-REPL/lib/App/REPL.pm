package App::REPL;
use warnings;
use strict;
use Data::Dumper;
use PadWalker 'peek_my';
use Term::ANSIColor ':constants';
$Term::ANSIColor::AUTORESET = 1;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);

$VERSION = '0.012';
@ISA = qw(Exporter);
@EXPORT = qw(x p env ret rdebug help);

# ----------------------------------------------------------------------
sub x { print Dumper @_ }
sub p { print @_, "\n" }
sub env { peek_my(1) }
sub ret { $App::REPL::ret }
sub rdebug {
  if (@_) { $App::REPL::DEBUG = shift } else { $App::REPL::DEBUG++ }
  print YELLOW "Debug level set to $App::REPL::DEBUG\n"
}
sub help {
  if (@_ and shift eq 'commands') {
    system perldoc => 'App::REPL'
  }
  else {
    print YELLOW <<EOH;
Auto-imported commands (from App::REPL): x p env ret rdebug help

See also: C<help 'commands'>
EOH
  }
}


1;

__END__
# ----------------------------------------------------------------------
=head1 NAME

App::REPL - A container for functions for the iperl program

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module contains functions that the iperl program automatically
imports into any package it enters, for interactive convenience.

Please see the README for general information.

=head1 EXPORT

=head1 FUNCTIONS

=head2 x

Print arguments with C<Data::Dumper::Dumper>

=head2 p

Print arguments with C<print>

=head2 env

Return a hashref containing the (stored -- not current) lexical
environment.

=head2 ret

Return a reference to the value of the previous evaluation --
that is, a reference to whatever irepl printed after the last
Perl you evaluated.  This function will probably evolve to
take an argument C<$n>, to return the C<$n>'th previous result.

=head2 rdebug (C<$value>)

With no arguments, bump C<$REPL::DEBUG>.  With an argument, set
C<$REPL::DEBUG> to that.  This is for debugging iperl itself;
currently at 1 it shows eval'd code, and at 2 it dumps the PPI
document corresponding to entered code.

=head2 help (commands)

With no arguments, print a brief message.  With an argument,
either print corresponding help or -- in the case of C<'commands'>,
currently the only optional argument -- call perldoc
appropriately.

=head1 AUTHOR

Julian Fondren, C<< <ayrnieu@cpan.org> >>

=head1 BUGS

Does not reliably report errors in eval'd code.

Does not try hard enough to collect a return value from eval'd code.

Makes probably dangerous use of PPI.

Please report any bugs or feature requests to
C<bug-app-repl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-REPL>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 VERSION CONTROL

A subversion repository with anonymous checkout exists at
http://OpenSVN.csie.org/app_repl , and you can also browse
the repository from that URL with a web browser.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Julian Fondren, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
