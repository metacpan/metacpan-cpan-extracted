package Alien::git;

use strict;
use warnings;
use 5.008001;
use Capture::Tiny qw( capture );
use File::Which qw( which );

# ABSTRACT: Find system git
our $VERSION = '0.05'; # VERSION


sub cflags {''}
sub libs   {''}
sub dynamic_libs {}
sub install_type { 'system' }

# IF you are reading the documentation and wondering
# why it says that you need to add bin_dir to your
# PATH, and you are looking at the source here and seeing
# that it just returns an empty list, and wondering
# why?  It is because in the future Alien::git MAY
# support share installs, at which point your code will
# break if you are NOT adding bin_dir to your PATH.
sub bin_dir {()}

sub exe { scalar which $ENV{ALIEN_GIT} || 'git' }

sub version
{
  my($out) = capture {
    system(
      __PACKAGE__->exe,
      '--version',
    );
  };
  
  $out =~ /git version ([0-9\.]+)/
    ? $1
    : 'unknown';
}

sub alien_helper
{
  return {
    git => sub { __PACKAGE__->exe },
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::git - Find system git

=head1 VERSION

version 0.05

=head1 SYNOPSIS

From Perl:

 use Alien::git;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::git->bin_dir;
 my $git = Alien::git->exe;
 
 system $git, 'clone 'http://example.com/foo.git';

From L<alienfile>:

 use alienfile;
 
 share {
 
   download [
     [ '%{git}', 'clone', 'http://example.com/foo.git' ],
   ];
   
   ...
 
 };

=head1 DESCRIPTION

This module, like other L<Alien>s, can be used as a dependency
on the C<git> source control tool.  Unlike many other L<Alien>s,
it will I<only> work with a system install.  That is to say,
it will only work if C<git> is already installed.  Some day down
the line, it may also attempt to download and install git, as
other L<Alien>s do in the event that the operating system does
not provide it.  The main thing that this module provides today
is a L<alienfile> helper to invoke C<git>.

This module uses the first C<git> in the system C<PATH> by default.
You can override this by using the C<ALIEN_GIT> environment
variable.  You should also set this environment variable when
you are installing this module.

=head1 METHODS

=head2 bin_dir

 my @dirs = Alien::git->bin_dir;

Returns the list of directories that need to be added to
the PATH in order for C<git> to work.

=head1 HELPERS

=head2 git

 '%{git}'

Returns the command to invoke git.  This is usually the
full path to the git executable.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Build::Git>

=item L<Git::Wrapper>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
