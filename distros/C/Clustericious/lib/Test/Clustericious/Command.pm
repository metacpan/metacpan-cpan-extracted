package Test::Clustericious::Command;

use strict;
use warnings;
use 5.010001;
use Test2::Plugin::FauxHomeDir;
use File::Glob qw( bsd_glob );
use base qw( Exporter );
use Exporter qw( import );
use Mojo::Loader;
use Path::Class qw( file dir );
use Env qw( @PERL5LIB @PATH );
use Capture::Tiny qw( capture );
use File::Which qw( which );
use File::Glob qw( bsd_glob );
use YAML::XS ();
use File::Temp qw( tempdir );
use Test2::API qw( context );

# ABSTRACT: Test Clustericious commands
our $VERSION = '1.29'; # VERSION


our @EXPORT      = qw( extract_data mirror requires run_ok generate_port note_file clean_file create_symlink );
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT );

unshift @INC, dir(bsd_glob '~/lib')->stringify;
unshift @PERL5LIB, map { dir($_)->absolute->stringify } @INC;
unshift @PATH, dir(bsd_glob '~/bin')->stringify;

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

  my $ctx = context();
  $ctx->plan( 0, 'SKIP', 'test requires execute in tmp') unless __PACKAGE__->_can_execute_in_tmp;

  unless(defined $command)
  {
    $ctx->plan( $num ) if defined $num;
    $ctx->release;
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
      $ctx->plan( 0, 'SKIP', "developer test not configured" ) unless defined $config;
      
      unshift @PATH, $config->{path} if defined $config->{path};
      unshift @PATH, dir(bsd_glob '~/bin')->stringify;
      $ENV{$_} = $config->{env}->{$_} for keys %{ $config->{env} };
      $command = $config->{exe} // $name;
    }
    else
    {
      $ctx->plan( 0, 'SKIP', "developer only test" );
    }
  }

  if(which $command)
  {
    $ctx->plan( $num ) if defined $num;
  }
  else
  {
    $ctx->plan( 0, 'SKIP', "test requires $command to be in the PATH" );
  }
  $ctx->release;
}

sub extract_data
{
  my(@values) = @_;
  my $caller = caller;
  Mojo::Loader::load_class($caller) unless $caller eq 'main';
  my $all = Mojo::Loader::data_section $caller;
  
  my $ctx = context();
  
  foreach my $name (sort keys %$all)
  {
    my $file = file(bsd_glob('~'), $name);
    my $dir  = $file->parent;
    unless(-d $dir)
    {
      $ctx->note("[extract] DIR  $dir");
      $dir->mkpath(0,0700);
    }
    unless(-f $file)
    {
      $ctx->note("[extract] FILE $file@{[ $name =~ m{^bin/} ? ' (*)' : '']}");
      
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
  
  $ctx->release;
}

sub mirror
{
  my($src, $dst) = map { ref($_) ? $_ : dir($_) } @_;
  
  my $ctx = context();

  $dst = dir(bsd_glob('~'), $dst) unless $dst->is_absolute;
  
  unless(-d $dst)
  {
    $ctx->note("[mirror ] DIR  $dst");
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
          $ctx->note("[mirror ] FILE $dst (*)");
          my $content = scalar $child->slurp;
          $content =~ s{^#!/usr/bin/perl}{#!$^X};
          $dst->spew($content);
          chmod 0700, "$dst";
        }
        else
        {
          $ctx->note("[mirror ] FILE $dst");
          $dst->spew(scalar $child->slurp);
          chmod 0600, "$dst";
        }
      }
    }
  }
  
  $ctx->release;
}

sub run_ok
{
  my(@cmd) = @_;
  
  # Yath set some environment variables which confuse a subprocess
  # for when we are testing the use of prove, etc
  local %ENV = %ENV;
  delete $ENV{$_} for grep /^T2_/, keys %ENV;
  
  my($out, $err, $error, $exit) = capture { system @cmd; ($!,$?) };
  
  my $ok = ($exit != -1) && ! ($exit & 128);
  
  my $ctx = context();
  
  $ctx->ok($ok, "run: @cmd");
  $ctx->diag("  @cmd failed") unless $ok;
  $ctx->diag("    - execute failed: $error") if $exit == -1;
  $ctx->diag("    - died from signal: " . ($exit & 128)) if $exit & 128;

  my $run = Test::Clustericious::Command::Run->new(
    cmd => \@cmd,
    out => $out, err => $err, exit => $exit >> 8,
  );
  
  $ctx->release;
  
  $run;
}

sub generate_port
{
  require IO::Socket::INET;
  IO::Socket::INET->new(Listen => 5, LocalAddr => "127.0.0.1")->sockport;
}

sub note_file
{
  my $ctx = context();
  foreach my $file (sort map { file $_ } map { bsd_glob "~/$_" } @_)
  {
    $ctx->note("[content] $file");
    $ctx->note(scalar $file->slurp);
  }
  $ctx->release;
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
  my($old,$new) = map { file(bsd_glob('~'), $_) } @_;
  $new->remove if -f $new;
  my $ctx = context();
  $ctx->note("[symlink] $old => $new");
  $ctx->release;
  use autodie;
  symlink "$old", "$new";
  %Clustericious::Config::singletons = ();
}

package Test::Clustericious::Command::Run;

use Test2::API qw( context );

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
  my $ctx = context();
  $ctx->ok($self->exit eq $value, $name);
  unless($self->exit == $value)
  {
    $ctx->diag("[cmd]\n", join(' ', $self->cmd)) if $self->cmd;
    $ctx->diag("[out]\n", $self->out) if $self->out;
    $ctx->diag("[err]\n", $self->err) if $self->err;
  }
  $ctx->release;
  $self;
}

sub note
{
  my($self) = @_;
  my $ctx = context();
  $ctx->note("[out]\n" . $self->out) if $self->out;
  $ctx->note("[err]\n" . $self->err) if $self->err;
  $ctx->release;
  $self;
}

sub diag
{
  my($self) = @_;
  my $ctx = context();
  $ctx->diag("[out]\n" . $self->out) if $self->out;
  $ctx->diag("[err]\n" . $self->err) if $self->err;
  $ctx->release;
  $self;
}

sub out_like
{
  my($self, $pattern, $name) = @_;

  my $ctx = context();
  $name ||= "output matches";
  $ctx->ok($self->out =~ $pattern, $name);
  $ctx->release;

  $self;
}

sub out_unlike
{
  my($self, $pattern, $name) = @_;

  my $ctx = context();  
  $name ||= "output does not match";
  $ctx->ok($self->out !~ $pattern, $name);
  $ctx->release;

  $self;
}

sub err_like
{
  my($self, $pattern, $name) = @_;

  my $ctx = context();  
  $name ||= "error matches";
  $ctx->ok($self->err =~ $pattern, $name);
  $ctx->release;

  $self;
}

sub err_unlike
{
  my($self, $pattern, $name) = @_;

  my $ctx = context();
  $name ||= "error does not match";
  $ctx->unlike($self->err, $pattern, $name);
  $ctx->release;
  
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

version 1.29

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

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
