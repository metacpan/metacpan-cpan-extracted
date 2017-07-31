package Alien::Build::CommandSequence;

use strict;
use warnings;
use Capture::Tiny qw( capture );

# ABSTRACT: Alien::Build command sequence
our $VERSION = '0.75'; # VERSION


sub new
{
  my($class, @commands) = @_;
  my $self = bless {
    commands => \@commands,
  }, $class;
  $self;
}


sub apply_requirements
{
  my($self, $meta, $phase) = @_;
  my $intr = $meta->interpolator;
  foreach my $command (@{ $self->{commands} })
  {
    next if ref $command eq 'CODE';
    if(ref $command eq 'ARRAY')
    {
      foreach my $arg (@$command)
      {
        next if ref $arg eq 'CODE';
        $meta->add_requires($phase, $intr->requires($arg))
      }
    }
    else
    {
      $meta->add_requires($phase, $intr->requires($command));
    }
  }
  $self;
}

sub _run
{
  my($build, @cmd) = @_;
  $build->log("+ @cmd");
  system @cmd;
  die "external command failed" if $?;
}

sub _run_with_code
{
  my($build, @cmd) = @_;
  my $code = pop @cmd;
  $build->log("+ @cmd");
  my %args = ( command => \@cmd );
  ($args{out}, $args{err}, $args{exit}) = capture {
    system @cmd; $?
  };
  $build->log("[output consumed by Alien::Build recipe]");
  $code->($build, \%args);
}


sub _apply
{
  my($where, $prop, $value) = @_;
  if($where =~ /^(.*?)\.(.*?)$/)
  {
    _apply($2, $prop->{$1}, $value);
  }
  else
  {
    $prop->{$where} = $value;
  }
}

sub execute
{
  my($self, $build) = @_;
  my $intr = $build->meta->interpolator;

  my $prop = $build->_command_prop;
  
  foreach my $command (@{ $self->{commands} })
  {
    if(ref($command) eq 'CODE')
    {
      $command->($build);
    }
    elsif(ref($command) eq 'ARRAY')
    {
      my($command, @args) = @$command;
      my $code = pop @args if $args[-1] && ref($args[-1]) eq 'CODE';
      
      if($args[-1] && ref($args[-1]) eq 'SCALAR')
      {
        my $dest = ${ pop @args };
        if($dest =~ /^\%\{((?:alien|)\.(?:install|runtime|hook)\.[a-z\.0-9_]+)\}$/)
        {
          $dest = $1;
          $dest =~ s/^\./alien./;
          $code = sub {
            my($build, $args) = @_;
            die "external command failed" if $args->{exit};
            my $out = $args->{out};
            chomp $out;
            _apply($dest, $prop, $out);
          };
        }
        else
        {
          die "illegal destination: $dest";
        }
      }
      
      ($command, @args) = map { $intr->interpolate($_, $prop) } ($command, @args);
      
      if($code)
      {
        _run_with_code $build, $command, @args, $code;
      }
      else
      {
        _run $build, $command, @args;
      }
    }
    else
    {
      my $command = $intr->interpolate($command,$prop);
      _run $build, $command;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::CommandSequence - Alien::Build command sequence

=head1 VERSION

version 0.75

=head1 CONSTRUCTOR

=head2 new

 my $seq = Alien::Build::CommandSequence->new(@commands);

=head1 METHODS

=head2 apply_requirements

 $seq->apply_requirements($meta, $phase);

=head2 execute

 $seq->execute($build);

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Juan Julián Merelo Guervós (JJ)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
