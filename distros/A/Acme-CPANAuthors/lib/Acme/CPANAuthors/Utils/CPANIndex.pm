package Acme::CPANAuthors::Utils::CPANIndex;

use strict;
use warnings;
use Carp;

sub new {
  my $class = shift;
  my $self  = bless { preambles => {} }, $class;

  $self->_install_methods;
  $self->{$_} = {} for keys %{ $self->_mappings };

  $self->_parse(@_) if @_;

  $self;
}

sub _mappings  {+{}}
sub _preambles {}

sub _install_methods {
  my $self = shift;
  my $class = ref $self;

  no strict 'refs';
  no warnings 'redefine';
  for my $method ($self->_preambles) {
    *{"$class\::$method"} = sub {
      my $self = shift;
      $self->{preambles}{$method};
    }
  }

  for my $method (keys %{ $self->_mappings }) {
    my $key = $self->_mappings->{$method};
    *{"$class\::$method"} = sub {
      my ($self, $name) = @_;
      $self->{$key}{$name};
    };
    *{"$class\::${method}s"} = sub {
      my $self = shift;
      values %{ $self->{$key} };
    };
    *{"$class\::${method}_count"} = sub {
      my $self = shift;
      scalar values %{ $self->{$key} };
    };
  }
}

sub _handle {
  my ($self, $file) = @_;

  my $handle;
  if ($file =~ /\.gz$/) {
    require IO::Uncompress::Gunzip;
    $handle = IO::Uncompress::Gunzip->new($file) or croak "Failed to read $file";
  }
  else {
    require IO::File;
    $handle = IO::File->new($file, 'r') or croak "Failed to read $file";
    binmode $handle;
  }
  $handle;
}

1;

__END__

=head1 NAME

Acme::CPANAuthors::Utils::CPANIndex

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
