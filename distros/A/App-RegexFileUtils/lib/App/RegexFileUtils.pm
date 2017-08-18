package App::RegexFileUtils;

use strict;
use warnings;
use File::Spec;
use File::ShareDir::Dist qw( dist_share );
use File::Which qw( which );

# ABSTRACT: use regexes with file utils like rm, cp, mv, ln
our $VERSION = '0.08'; # VERSION


sub main {
  my $class = shift;
  my $mode = shift;
  my $appname = $mode;
  $mode =~ s!^.*/!!;
  my @args = @_;
  
  my @options = ();
  my $verbose = 0;
  my $do_hidden = 0;
  my $re;
  my $sub;
  my $modifiers;
  my $modifiers_match = '';
  my $tr;
  my $static_dest = 0;
  
  while(defined($args[0]) && $args[0] =~ /^-/) {
    my $arg = shift @args;
  
    if($arg =~ /^--recmd$/) {
      $mode = shift @args;
      $mode =~ s!^.*/!!;
    } elsif($arg =~ /^--reverbose$/) {
      $verbose = 1;
    } elsif($arg =~ /^--reall$/) {
      $do_hidden = 1;
    } else {
      push @options, $arg;
    }
  }
  
  my $dest = pop @args;
  
  unless(defined $dest) {
    print STDERR "usage: $appname [options] [source files] /pattern/[substitution/]\n";
    print STDERR "       $appname [options] /pattern/ /path/to/destination\n";
    print STDERR "\n";
    print STDERR "--recmd [command]      change the behavior of the tool\n";
    print STDERR "--verbose              print commands before they are executed\n";
    print STDERR "--reall                include hidden (so called `dot') files\n";
    print STDERR "\n";
    print STDERR "all other arguments are passed to the system tool\n";
    exit;
  }
  
  my $orig_mode = $mode;
  $mode =~ s/^re//;
  
  my %modes = (
    'mv'    => 'mv',
    'move'    => 'mv',
    'rename'  => 'mv',
    'cp'    => 'cp',
    'copy'    => 'cp',
    'ln'    => 'ln',
    'link'    => 'ln',
    'symlink'  => 'ln',
    'rm'    => 'rm',
    'remove'  => 'rm',
    'unlink'  => 'rm',
    'touch'    => 'touch',
  );
  
  unshift @options, '-s' if $mode eq 'symlink';
  
  $mode = $modes{$mode};
  unless(defined $mode) {
    print STDERR "unknown mode $orig_mode\n";
    exit;
  }
  
  my $no_dest = 0;
  if($mode eq 'touch' || $mode eq 'rm') {
    $no_dest = 1;
  }
  
  if($dest =~ m!^(s|)/(.*)/(.*)/([ig]*)$!) {
    $re = $2;
    $sub = $3;
    $modifiers = $4;
    $modifiers_match = 'i' if $modifiers =~ /i/;
  
    if($no_dest) {
      print STDERR "substitution `$mode' doesn't make sense\n";
      exit;
    }
  
  }
  
  elsif($dest =~ m!tr/(.*)/(.*)/$!) {
    $tr = $1;
    $sub = $2;
  
    if($no_dest) {
      print STDERR "translation `$mode' doesn't make sense\n";
    }
  }
  
  elsif($dest =~ m!^(m|)/(.*)/([i]*)$!) {
    $re = $2;
    $modifiers = $3;
    $modifiers_match = $3;
  }
  
  elsif(-d $dest) {
    my $src = pop @args;
    if($src =~ m!^(m|)/(.*)/([i]*)$!) {
      $static_dest = 1;
      $re = $2;
      $modifiers = $3;
      $modifiers_match = $3;
    } else {
      die "source is not a regex";
    }
  }
  
  else {
    die "destination is not a directory or a regex";
  }
  
  my @files = @args;
  
  if(@files ==0) {
    opendir(DIR, '.') || die "unable to opendir `.' $!";
    @files = readdir(DIR);
    closedir DIR;
  }
  
  for(@files) {
    next if /^\./ && !$do_hidden;
    next unless eval "/$re/$modifiers_match" || defined $tr;
    my $old = $_;
    my $new = $old;
    
    my @cmd = ($mode, @options, $old);
    
    if(defined $tr) {
      eval "\$new =~ tr/$tr/$sub/";
    } elsif(defined $sub) {
      eval "\$new =~ s/$re/$sub/$modifiers";
    } elsif($static_dest) {
      $new = $dest;
    } else {
      if($no_dest) {
        $new = '';
      } else {
        $new = '.';
      }
    }
    
    push @cmd, $new unless $no_dest;
    print "% @cmd\n" if $verbose;
    
    __PACKAGE__->_fix_path(\@cmd);
    
    system @cmd;

    if ($? == -1) {
      print STDERR "failed to execute: $!\n";
      exit 2;
    } elsif ($? & 127) {
      print STDERR "child died with signal ", $? & 127, "\n";
    } elsif($? >> 8) {
      print "child exited with value ", $? >> 8, "\n";
    }
  }
}

use constant _share_dir => do {
  my $path;
  $path = dist_share('App-RegexFileUtils');
  die 'can not find share directory' unless $path && -d "$path/ppt";    
  $path;
};

sub _fix_path
{
  my($class, $cmd) = @_;

  return unless $^O eq 'MSWin32';

  return if which($cmd->[0]);

  $cmd->[0] = File::Spec->catfile(
    App::RegexFileUtils->_share_dir,
    'ppt', $cmd->[0] . '.pl',
  );
  unshift @$cmd, $^X;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::RegexFileUtils - use regexes with file utils like rm, cp, mv, ln

=head1 VERSION

version 0.08

=head1 SYNOPSIS

Remove all files with a .bak extension:

 % rerm '/\.bak$/'

Change the extension of all files from .jpeg or .JPG (any case) to .jpg

 % remv '/\.jpe?g$/.jpg/i'

Copy all Perl files to a different directory:

 % recp '/\.p[lm]$/' /perl/lib

Create symlinks to .so files so that the symlinks lack a version number

 % reln -s '/\.so\..*$/.so/'

=head1 DESCRIPTION

This distribution provides a version of C<rm>, C<cp>, C<mv> and C<ln> with a I<re> 
(as in regular expression) prefix where the file sources can be specified as a regular
expression, or the file source and destination can be specified as a regular expression 
substitution Perl style.  The functionality that this provides can be duplicated with 
shell syntax (typically for loops), but I find these scripts require less typing and 
work regardless of the shell you are using.

The scripts in this distribution do not remove, copy, move or link files directly, 
instead they call the real C<rm>, C<cp>, C<mv> and C<ln> programs provided by your
operating system.  You can therefore use any options that they support, for example
the C<-i> option will allow you to interactively delete files:

 % rerm -i '/\.bak$/'

=head1 OPTIONS

In addition to any options supported by the underlying operating system, these scripts
will recognize the following options (and NOT pass them to the underlying system utilities).
They are prefixed with C<--re> so that they do not interfere with any "real" options.

=head2 --recmd command

Specifies the command to execute.  This is usually determined by Perl's $0 variable.

=head2 --reverbose

Print out the system commands that are actually executed.

=head2 --reall

Include even hidden dot files, like C<.profile> and C<.login>.

=head1 METHODS

These commands can also be invoked from your Perl script, using this module:

=head2 main

 App::RegexFileUtils->main( $program, @arguments )

For example:

 use App::RegexFileUtils;
 App::RegexFileUtils->main( 'rm', '/\.bak$/' );

=head1 CAVEATS

You will need to enclose many regular expressions in single
quotes '' on the command line as many regular expression characters
have special meanings in shells.

The underlying fileutils command (rm, cp, ln, etc) will be called
for each file operated on, which may be slow if many files match
the regular expression provided.

This was written a long time ago and the code isn't very modern.

Directories with a training slash may be ambiguous with a regex, so
if you want to use a path as a destination instead of a regex, be
sure you do NOT include the trailing slash.  That is:

 # use this:
 % recp /^foo/ /usr/bin
 # NOT this:
 % recp /^foo/ /usr/bin/

=head1 BUNDLED FILES

This distribution comes bundled with C<cp>, C<ln>, C<rm>, C<touch>
from the L<Perl Power Tools|https://metacpan.org/release/ppt> project.
These are only used if the operating system does not provide these
commands.  This is normally only the case on Windows.  They are individually
licensed separately.

=head2 cp.pl

This program is copyright by Ken Schumack 1999.

This program is free and open software. You may use, modify, distribute
and sell this program (and any modified variants) in any way you wish,
provided you do not restrict others from doing the same.

=head2 ln.pl

This program is copyright by Abigail 1999.

This program is free and open software. You may use, copy, modify, distribute,
and sell this program (and any modified variants) in any way you wish,
provided you do not restrict others from doing the same.

=head2 rm.pl

Copyright (c) Steve Kemp 1999, skx@tardis.ed.ac.uk

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head2 touch.pl

This program is copyright by Abigail 1999.

This program is free and open software. You may use, copy, modify, distribute
and sell this program (and any modified variants) in any way you wish,
provided you do not restrict others to do the same.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
