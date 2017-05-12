package Acme::OnePiece;
use 5.008005;
use strict;
use warnings;

use IO::File;

our $VERSION = "0.02";

sub _options {
  return {}
}

sub new {
  my $class = shift;
  my $file = shift;
  my $options = $class->_options;

  my $io = IO::File->new($file, 'r') or die "Usage: Acme::OnePiece->new(\$filename)\n" . $!;
  my @lines = $io->getlines;
  my $contents = join('',@lines);
  $options->{contents} = $contents;

  my $self = bless $options, $class;
  return $self;
}

sub onepiece {
  my ($self) = @_;
  my $contents = $self->{contents};
  $contents =~ s/(\n+|\s+)/-/g;
  $contents =~ s/-+/-/g;
  return $contents;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::OnePiece - substitute strings in a file into 'one piece'-ed.

=head1 SYNOPSIS

    use Acme::OnePiece;

    my $one = Acme::OnePiece->new($filename);
    print $one->onepiece;

=head1 DESCRIPTION

Acme::OnePiece is ...

you can get strings concatenated by '-' from a file.

this makes entirely no sense...

=head1 METHODS

=head2 onepice

  print Acme::OnePiece->new($filename)->onepiece;

=head1 LICENSE

Copyright (C) hidehigo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hidehigo E<lt>hidehigo@cpan.orgE<gt>

=cut

