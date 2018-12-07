package App::Prove::Plugin::TermTableStty;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Set the size of the console for Term::Table using stty size
our $VERSION = '0.01'; # VERSION


sub load
{
  return if $ENV{TERM_TABLE_SIZE};
  my $size = `stty size`;
  if($size =~ /[0-9]+\s+([0-9]+)/)
  {
    $ENV{TERM_TABLE_SIZE} = $1;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::TermTableStty - Set the size of the console for Term::Table using stty size

=head1 VERSION

version 0.01

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

This module is similar to L<App::Prove::Plugin::TermTableStty> but has fewer prereqs and requires a platform that
supports the C<stty size> command.

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
