package Test::Clustericious::Command;

use strict;
use warnings;
use 5.010001;
use if !$INC{'File/HomeDir/Test.pm'}, 'File::HomeDir::Test';
use base qw( Exporter Test::Builder::Module );
use Exporter qw( import );
use Mojo::Loader;
use Path::Class qw( file dir );
use File::HomeDir;
use Env qw( @PERL5LIB @PATH );
use Capture::Tiny qw( capture );
use File::Which qw( which );
use File::Glob qw( bsd_glob );
use YAML::XS ();
use File::Temp qw( tempdir );

# ABSTRACT: Test Clustericious commands
our $VERSION = '1.24'; # VERSION


our @EXPORT      = qw( extract_data mirror requires run_ok generate_port note_file clean_file create_symlink );
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT );

unshift @INC, dir(File::HomeDir->my_home, 'lib')->stringify;
unshift @PERL5LIB, map { dir($_)->absolute->stringify } @INC;
unshift @PATH, dir(File::HomeDir->my_home, 'bin')->stringify;

sub _can_execute_in_tmp
{
  my $script = file( tempdir( CLEANUP => 1 ), 'mytest' );
  $script->spew("#!$^X\nexit 0");
  chmod 0755, "$script";
  my $exit;
  capture { system "$script", "okay"; $exit = $? };
  $exit == 0;
}

sub requires
{
  my($command, $num) = @_;
  my $tb = __PACKAGE__->builder;

  $tb->plan( skip_all => 'test requires execute in tmp') unless __PACKAGE__->_can_execute_in_tmp;

  unless(defined $command)
  {
    $tb->plan( tests => $num ) if defined $num;
    return;
  }

  if($command =~ /^(.*)\.conf$/)
  {
    my $name = $1;
    if(defined $ENV{CLUSTERICIOUS_COMMAND_TEST} && -r $ENV{CLUSTERICIOUS_COMMAND_TEST})
    {
      my $config = do {
        require Clustericious::Config;
        my $config = Clustericious::Config->new($ENV{CLUSTERICIOUS_COMMAND_TEST});
        my %config = %$config;
        \%config;
      }->{$name};
      $tb->plan( skip_all => "developer test not configured" ) unless defined $config;
      
      unshift @PATH, $config->{path} if defined $config->{path};
      unshift @PATH, dir(File::HomeDir->my_home, 'bin')->stringify;
      $ENV{$_} = $config->{env}->{$_} for keys %{ $config->{env} };
      $command = $config->{exe} // $name;
    }
    else
    {
      $tb->plan( skip_all => "developer only test" );
    }
  }

  if(which $command)
  {
    $tb->plan( tests => $num ) if defined $num;
  }
  else
  {
    $tb->plan( skip_all => "test requires $command to be in the PATH" );
  }
}

sub extract_data
{
  my(@values) = @_;
  my $caller = caller;
  Mojo::Loader::load_class($caller) unless $caller eq 'main';
  my $all = Mojo::Loader::data_section $caller;
  
  my $tb = __PACKAGE__->builder;
  
  foreach my $name (sort keys %$all)
  {
    my $file = file(File::HomeDir->my_home, $name);
    my $dir  = $file->parent;
    unless(-d $dir)
    {
      $tb->note("[extract] DIR  $dir");
      $dir->mkpath(0,0700);
    }
    unless(-f $file)
    {
      $tb->note("[extract] FILE $file@{[ $name =~ m{^bin/} ? ' (*)' : '']}");
      
      if($name =~ m{^bin/})
      {
        my $content = $all->{$name};
        $content =~ s{^#!/usr/bin/perl}{#!$^X};
        $file->spew($content);
        chmod 0700, "$file";
      }
      else
      {
        $file->spew($all->{$name});
      }
    }
  }
}

sub mirror
{
  my($src, $dst) = map { ref($_) ? $_ : dir($_) } @_;
  
  my $tb = __PACKAGE__->builder;

  $dst = dir(File::HomeDir->my_home, $dst) unless $dst->is_absolute;
  
  unless(-d $dst)
  {
    $tb->note("[mirror ] DIR  $dst");
    $dst->mkpath(0,0700);
  }
  
  foreach my $child ($src->children)
  {
    if($child->is_dir)
    {
      mirror($child, $dst->subdir($child->basename));
    }
    else
    {
      my $dst = $dst->file($child->basename);
      unless(-f $dst)
      {
        if(-x $child)
        {
          $tb->note("[mirror ] FILE $dst (*)");
          my $content = scalar $child->slurp;
          $content =~ s{^#!/usr/bin/perl}{#!$^X};
          $dst->spew($content);
          chmod 0700, "$dst";
        }
        else
        {
          $tb->note("[mirror ] FILE $dst");
          $dst->spew(scalar $child->slurp);
          chmod 0600, "$dst";
        }
      }
    }
  }
}

sub run_ok
{
  my(@cmd) = @_;
  my($out, $err, $error, $exit) = capture { system @cmd; ($!,$?) };
  
  my $ok = ($exit != -1) && ! ($exit & 128);
  
  my $tb = __PACKAGE__->builder;
  
  $tb->ok($ok, "run: @cmd");
  $tb->diag("  @cmd failed") unless $ok;
  $tb->diag("    - execute failed: $error") if $exit == -1;
  $tb->diag("    - died from signal: " . ($exit & 128)) if $exit & 128;

  Test::Clustericious::Command::Run->new(
    cmd => \@cmd,
    out => $out, err => $err, exit => $exit >> 8,
  );
}

sub generate_port
{
  require IO::Socket::INET;
  IO::Socket::INET->new(Listen => 5, LocalAddr => "127.0.0.1")->sockport;
}

sub note_file
{
  my $tb = __PACKAGE__->builder;

  foreach my $file (sort map { file $_ } map { bsd_glob "~/$_" } @_)
  {
    $tb->note("[content] $file");
    $tb->note(scalar $file->slurp);
  }
}

sub clean_file
{
  foreach my $file (sort map { file $_ } map { bsd_glob "~/$_" } @_)
  {
    $file->remove;
  }
}

sub create_symlink
{
  my $tb = __PACKAGE__->builder;
  my($old,$new) = map { file(File::HomeDir->my_home, $_) } @_;
  $new->remove if -f $new;
  $tb->note("[symlink] $old => $new");
  use autodie;
  symlink "$old", "$new";
  %Clustericious::Config::singletons = ();
}

package Test::Clustericious::Command::Run;

use base qw( Test::Builder::Module );

sub new
{
  my($class, %args) = @_;
  bless \%args, $class;
}

sub cmd { @{ shift->{cmd} // [] } }
sub out { shift->{out} }
sub err { shift->{err} }
sub exit { shift->{exit} }

sub exit_is
{
  my($self, $value, $name) = @_;
  $name //= "exit with $value";
  my $tb = __PACKAGE__->builder;
  $tb->is_eq($self->exit, $value, $name);
  unless($self->exit == $value)
  {
    $tb->diag("[cmd]\n", join(' ', $self->cmd)) if $self->cmd;
    $tb->diag("[out]\n", $self->out) if $self->out;
    $tb->diag("[err]\n", $self->err) if $self->err;
  }
  $self;
}

sub note
{
  my($self) = @_;
  my $tb = __PACKAGE__->builder;
  $tb->note("[out]\n" . $self->out) if $self->out;
  $tb->note("[err]\n" . $self->err) if $self->err;
  $self;
}

sub diag
{
  my($self) = @_;
  my $tb = __PACKAGE__->builder;
  $tb->diag("[out]\n" . $self->out) if $self->out;
  $tb->diag("[err]\n" . $self->err) if $self->err;
  $self;
}

sub out_like
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "output matches";
  $tb->like($self->out, $pattern, $name);

  $self;
}

sub out_unlike
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "output does not match";
  $tb->unlike($self->out, $pattern, $name);

  $self;
}

sub err_like
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "error matches";
  $tb->like($self->err, $pattern, $name);

  $self;
}

sub err_unlike
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "error does not match";
  $tb->unlike($self->err, $pattern, $name);
  
  $self;
}

sub tap
{
  my($self, $sub) = @_;
  $sub->($self);
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Clustericious::Command - Test Clustericious commands

=head1 VERSION

version 1.24

=head1 SYNOPSIS

 use Test::Clustericious::Command;

=head1 DESCRIPTION

This is currently a private module used internally by L<Clustericious>.  This may change in the future,
but for now you should not depend on it providing any functionality.

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
