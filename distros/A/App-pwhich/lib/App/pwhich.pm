package App::pwhich;

use strict;
use warnings;
use 5.008001;
use File::Which qw( which );
use Getopt::Std qw( getopts );

# ABSTRACT: Perl-only `which`
our $VERSION = '1.15'; # VERSION

sub main
{
  local @ARGV = @_;
  
  my %opts;
  getopts('avs', \%opts) || return _usage();
  
  return _version() if $opts{v};
  
  return _usage() unless @ARGV;
  
  foreach my $file (@ARGV)
  {
    my @result = $opts{a}
    ? which($file)
    : scalar which($file);
    
    # We might end up with @result = (undef) -> 1 elem
    @result = () unless defined $result[0];
    unless($opts{s})
    {
      print "$_\n" for grep { defined } @result;
    }
    
    unless (@result)
    {
      print STDERR "$0: no $file in PATH\n" unless $opts{s};
      return 1;
    }
  }
  
  return 0;
}

sub _version
{
  my $my_version = $App::pwhich::VERSION || 'dev';
  print <<"END_TEXT";
This is pwhich running File::Which version $File::Which::VERSION
                       App::pwhich version $my_version

Copyright 2002 Per Einar Ellefsen

Some parts Copyright 2009 Adam Kennedy

Other parts Copyright 2015 Graham Ollis

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
END_TEXT
  2;
}

sub _usage
{
  print <<"END_TEXT";
Usage: $0 [-a] [-s] [-v] programname [programname ...]
      -a        Print all matches in PATH, not just the first.
      -v        Prints version and exits
      -s        Silent mode

END_TEXT
  1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pwhich - Perl-only `which`

=head1 VERSION

version 1.15

=head1 SYNOPSIS

 perldoc pwhich

=head1 DESCRIPTION

This module contains the guts of the L<pwhich> script that is
used to be bundled with L<File::Which>.  It was removed from
that distribution because most users of L<File::Which> do not
need L<pwhich>.  If you require L<pwhich>,
as a prerequisite, please use L<App::pwhich> as a prerequisite
instead of L<File::Which>.

=head1 SUPPORT

Bugs should be reported via the GitHub issue tracker

L<https://github.com/plicease/App-pwhich/issues>

For other issues, contact the maintainer.

=head1 CAVEATS

This module does not know about built-in shell commands, as the built-in
command C<which> and C<where> ususally do.

This module is fully supported back to Perl 5.8.1.  It may work on 5.8.0.

=head1 SEE ALSO

=over 4

=item L<pwhich>

Published interface (script) for this module.

=item L<File::Which>

Implementation used by this module.

=item L<Devel::CheckBin>

This module purports to "check that a command is available", but does not
provide any documentation on how you might use it.

=back

=head1 AUTHOR

Original author: Per Einar Ellefsen E<lt>pereinar@cpan.orgE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by Per Einar Ellefsen <pereinar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
