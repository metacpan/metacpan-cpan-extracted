package App::plasm;

use strict;
use warnings;
use 5.010;
use Pod::Usage qw( pod2usage );
use Getopt::Long qw( GetOptions );

# ABSTRACT: Perl WebAssembly command line tool
our $VERSION = '0.03'; # VERSION


sub main
{
  my $class = shift;  # unused

  Getopt::Long::Configure('permute');

  if(defined $_[0] && $_[0] =~ /\.wasm$/)
  {
    unshift @_, 'run';
  }

  if(defined $_[0] && $_[0] !~ /^-/)
  {
    my $cmd   = shift;
    my $class = "App::plasm::$cmd";
    my $main  = $class->can('main');
    pod2usage({
      -message => "no subcommand '$cmd'",
      -exitval => 2,
    }) unless defined $main;
    return $main->(@_);
  }
  else
  {
    local @ARGV = @_;
    GetOptions(
      'help|h'    => sub { pod2usage({ -exitval => 0 }) },
      'version|v' => sub { print "plasm version @{[ App::plasm->VERSION || 'dev' ]} Wasm.pm @{[ Wasm->VERSION ]}\n"; exit 0 },
    ) or pod2usage({ -exitval => 2 });
    pod2usage({ -exitval => 2 });
  }
}

package App::plasm::run;

use Pod::Usage qw( pod2usage );
use Getopt::Long qw( GetOptions );
use Wasm 0.08;
use Wasm::Hook;

my $sandbox;

sub main
{
  local @ARGV = @_;

  Getopt::Long::Configure('require_order');

  my @pod = (-verbose => 99, -sections => "SUBCOMMANDS/run");

  GetOptions(
    'help|h'    => sub { pod2usage({ -exitval => 0, @pod }) },
  ) or pod2usage({ -exitval => 2, @pod });

  my $filename = shift @ARGV;

  pod2usage({ @pod,
    -exitval  => 2,
  }) unless defined $filename;

  pod2usage({ @pod,
    -message => "File not found: $filename",
    -exitval  => 2,
  }) unless -f $filename;

  my $class = "App::plasm::run::sandbox@{[ $sandbox++ ]}";

  local $0 = $filename;

  Wasm->import(
    -api     => 0,
    -package => $class,
    -file    => $filename,
  );

  my $start = $class->can('_start');
  $start->();

  # TODO: detect exit value and pass that on...

  return 0;
}

package App::plasm::dump;

use Pod::Usage qw( pod2usage );
use Getopt::Long qw( GetOptions );
use Wasm::Wasmtime 0.08;

sub main
{
  local @ARGV = @_;

  my @pod = (-verbose => 99, -sections => "SUBCOMMANDS/run");

  GetOptions(
    'help|h'    => sub { pod2usage({ -exitval => 0, @pod }) },
  ) or pod2usage({ -exitval => 2, @pod });

  my $filename = shift @ARGV;

  pod2usage({ @pod,
    -exitval  => 2,
  }) unless defined $filename;

  pod2usage({ @pod,
    -message => "File not found: $filename",
    -exitval  => 2,
  }) unless -f $filename;

  my $module = Wasm::Wasmtime::Module->new(
    file => $filename,
  );

  print $module->to_string;

  return 0;
}

package App::plasm::wat;

use Pod::Usage qw( pod2usage );
use Getopt::Long qw( GetOptions );
use Wasm::Wasmtime::Wat2Wasm qw( wat2wasm );
use Path::Tiny qw( path );

sub main
{
  local @ARGV = @_;

  my @pod = (-verbose => 99, -sections => "SUBCOMMANDS/wat");

  GetOptions(
    'help|h'    => sub { pod2usage({ -exitval => 0, @pod }) },
  ) or pod2usage({ -exitval => 2, @pod });

  my $filename = shift @ARGV;

  pod2usage({ @pod,
    -exitval  => 2,
  }) unless defined $filename;

  pod2usage({ @pod,
    -message => "File not found: $filename",
    -exitval  => 2,
  }) unless -f $filename;

  my $in  = path($filename);
  my $out = $in->parent->child(do {
    my $basename = $in->basename;
    $basename =~ s/\.wat$//;
    $basename . '.wasm';
  });

  pod2usage({ @pod,
    -message => "Output file already exists: $out",
    -exitval  => 2,
  }) if -e $out;

  $out->spew_raw(wat2wasm($in->slurp_utf8));

  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::plasm - Perl WebAssembly command line tool

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 % perldoc plasm

=head1 DESCRIPTION

This module contains the machinery for L<plasm>, the Perl WebAssembly
command line tool.  For details on its use see L<plasm>.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=item L<plasm>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
