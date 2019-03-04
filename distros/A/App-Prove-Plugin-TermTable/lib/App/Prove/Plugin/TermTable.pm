package App::Prove::Plugin::TermTable;

use strict;
use warnings;
use 5.008001;
use Term::Size::Any qw( chars );

# ABSTRACT: Set the size of the console for Term::Table
our $VERSION = '0.03'; # VERSION


sub load
{
  my($class, $p) = @_;
  return if $ENV{TABLE_TERM_SIZE};
  open FP, '>', '/dev/tty';
  $ENV{TABLE_TERM_SIZE} = chars(*FP);
  close FP;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::TermTable - Set the size of the console for Term::Table

=head1 VERSION

version 0.03

=head1 SYNOPSIS

From command-line:

 prove -PTermTable

From .proverc:

 -PTermTable

=head1 DESCRIPTION

Some of the L<Test2::Tools> provide some pretty tables for comparing deltas from failed tests.  It tries to 
detect the size of the terminal so that long lines can be wrapped and the tables remain readable.  Unfortunately
when you run the tests under C<prove>, C<stdout> is redirected to a non-terminal and the size of the terminal
cannot be detected.  This plugin will detect the size of the terminal using C</dev/tty> instead of C<stdout> and
set the appropriate environment variable so that tables can be printed to use the entire terminal diameter.

I understand why 80 columns is the default for when you do not know the size of a terminal, but really who here 
in 2018 is actually using an 80 column display?  sigh.

=head1 SEE ALSO

=over 4

=item L<Test2>

=item L<App::Prove>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
