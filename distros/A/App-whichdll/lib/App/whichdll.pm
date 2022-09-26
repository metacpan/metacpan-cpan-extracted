package App::whichdll;

use strict;
use warnings;
use 5.008001;
use FFI::CheckLib 0.28 qw( find_lib );
use Getopt::Long qw( GetOptions );
use Path::Tiny qw( path );

# ABSTRACT: Find dynamic libraries
our $VERSION = '0.04'; # VERSION


sub main
{
  local @ARGV;
  (undef, @ARGV) = @_;

  my %opts;

  my @alien;

  GetOptions(
    "a"       => \$opts{a},
    "v"       => \$opts{v},
    "s"       => \$opts{s},
    "x"       => \$opts{x},
    "alien=s" => \@alien,
  ) || return _usage();
  return _version() if $opts{v};
  return _usage()   unless @ARGV;

  my %seen;

  my @extra_args;
  if(@alien)
  {
    push @extra_args, alien => \@alien;
  }

  foreach my $name (@ARGV)
  {
    my @result;
    if($opts{a} || $name eq '*')
    {
      @result = find_lib( lib => '*', verify => sub { ($name eq '*') || ($_[0] eq $name) }, @extra_args);
    }
    else
    {
      my $result = find_lib( lib => $name, @extra_args );
      push @result, $result if defined $result;
    }

    unless($opts{s})
    {
      foreach my $path (map { path($_) } @result)
      {
        my $dir = path($path)->parent->realpath;
        $path = $dir->child($path->basename);
        if(-l $path)
        {
          my $target = path(readlink $path)->absolute($dir);
          if(-e $target)
          {
            $target = $target->realpath;
            next if (!$opts{x}) && $seen{$target}++;
            print "$path => $target\n";
          }
          else
          {
            next if (!$opts{x}) && $seen{$target}++;
            print "$path => !! $target !!\n";
          }
        }
        else
        {
          next if (!$opts{x}) && $seen{$path}++;
          print "$path\n";
        }
      }
    }

    unless(@result)
    {
      print STDERR "$0: no $name in dynamic library path\n" unless $opts{s};
      return 1;
    }
  }

  return 0;
}

sub _version
{
  my $my_version = $App::whichdll::VERSION || 'dev';
  print <<"EOF";
whichdll running FFI::CheckLib $FFI::CheckLib::VERSION
                 App::whichdll $my_version

Copyright 2017 Graham Ollis

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
EOF
  2;
}

sub _usage
{
  print <<"EOF";
Usage: $0 [-a] [-s] [-v] [--alien Alien::Name] dllname [dllname ...]
       -a       Print all matches in dynamic library path.
       --alien  Include Perl Aliens in search
       -v       Prints version and exits
       -s       Silent mode
       -x       Do not prune duplicates (due to symlinks, etc.)
EOF
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::whichdll - Find dynamic libraries

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 perldoc whichdll

=head1 DESCRIPTION

This modules contains the guts of the whichdll script, which provides a command line interface
for finding the dynamic libraries on your system in a portable way.

=head1 SEE ALSO

=over 4

=item L<whichdll>

=item L<pwhich>

=item L<App::whichpm>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
