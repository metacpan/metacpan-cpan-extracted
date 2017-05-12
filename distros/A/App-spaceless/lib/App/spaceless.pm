package App::spaceless;

use strict;
use warnings;
use 5.010001;
use Config;
use Shell::Guess;
use Shell::Config::Generate qw( win32_space_be_gone );
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );

# ABSTRACT: Convert PATH type environment variables to spaceless versions
our $VERSION = '0.07'; # VERSION


sub _running_shell
{
  state $shell;
  $shell = Shell::Guess->running_shell unless defined $shell;
  $shell;
}

sub main
{
  shift;
  local @ARGV = @_;
  my $shell;
  my $file;
  my $help;
  my $version;
  my $trim;
  my $cygwin = 1;
  my $expand;
  my $list;
  my $squash;

  my $config = Shell::Config::Generate->new;
  $config->echo_off;
  my $sep = quotemeta $Config{path_sep};
  
  GetOptions(
    'csh'       => sub { $shell = Shell::Guess->c_shell },
    'sh'        => sub { $shell = Shell::Guess->bourne_shell },
    'cmd'       => sub { $shell = Shell::Guess->cmd_shell },
    'command'   => sub { $shell = Shell::Guess->command_shell },
    'fish'      => sub { $shell = Shell::Guess->fish_shell },
    'korn'      => sub { $shell = Shell::Guess->korn_shell },
    'power'     => sub { $shell = Shell::Guess->power_shell },
    'login'     => sub { $shell = Shell::Guess->login_shell },
    'sep=s'     => sub { $sep = quotemeta $_[1]; $config->set_path_sep($_[1]) },
    'sep-in=s'  => sub { $sep = quotemeta $_[1] },
    'sep-out=s' => sub { $config->set_path_sep($_[1]) },
    'squash|s'  => \$squash,
    'no-cygwin' => sub { $cygwin = 0 if $^O eq 'cygwin' },
    'list|l'    => \$list,
    'expand|x'  => \$expand,
    'trim|t'    => \$trim,
    'f=s'       => \$file,
    'help|h'    => \$help,
    'version|v' => \$version,
  ) || pod2usage(1);

  if($help)
  {
    pod2usage({ -verbose => 2 });
  }
  
  if($version)
  {
    say 'App::spaceless version ', ($App::spaceless::VERSION // 'dev');
    return 1;
  }

  $shell = _running_shell() unless defined $shell;
  
  my $filter = $^O eq 'cygwin' && $shell->is_win32 ? sub { map { Cygwin::posix_to_win_path($_) } @_ } : sub { @_ };

  @ARGV = ('PATH') unless @ARGV;

  my $to_long = $^O eq 'cygwin' ? sub { Cygwin::win_to_posix_path(Win32::GetLongPathName(Cygwin::posix_to_win_path($_))) } : sub { Win32::GetLongPathName($_[0]) };

  my $mutator = $expand ? sub { map { $to_long->($_) } @_ } : sub { win32_space_be_gone(grep { -e $_ } @_) };

  foreach my $var (@ARGV)
  {
    my @path = $filter->($mutator->(
      grep { $trim ? -d $_ : 1 } 
      grep { $cygwin ? 1 : $_ =~ qr{^([A-Za-z]:|/cygdrive/[A-Za-z])} } 
      split /$sep/, $ENV{$var} // ''
    ));
    
    if($squash)
    {
      my %path;
      @path = grep { !$path{$_}++ } @path;
    }
    
    $config->set_path( $var => @path );
    do { say $_ for @path } if $list;
  }

  unless($list)
  {
    if(defined $file)
    {
      $config->generate_file($shell, $file);
    }
    else
    {
      print $config->generate($shell);
    }
  }
  
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::spaceless - Convert PATH type environment variables to spaceless versions

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This module provides the machinery for the L<spaceless> app, a program
that helps convert PATH style environment variables to spaceless varieties
on Windows systems (including Cygwin).

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
