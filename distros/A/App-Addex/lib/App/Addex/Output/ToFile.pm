use strict;
use warnings;

package App::Addex::Output::ToFile;
# ABSTRACT: base class for output plugins that write to files
$App::Addex::Output::ToFile::VERSION = '0.026';
use parent 'App::Addex::Output';

use Carp ();

#pod =head1 DESCRIPTION
#pod
#pod This is a base class for output plugins that will write to files.  The
#pod "filename" configuration parameter must be given, and must be the name of a
#pod file to which the user can write.
#pod
#pod =method new
#pod
#pod   my $addex = App::Addex::Output::Subclass->new(\%arg);
#pod
#pod This method returns a new outputter.  It should be subclassed to provide a
#pod C<process_entry> method.
#pod
#pod Valid arguments are:
#pod
#pod   filename - the file to which to write configuration (required)
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  Carp::croak "no filename argument given for $class" unless $arg->{filename};

  my $self = $class->SUPER::new;

  open my $fh, '>', $arg->{filename}
    or Carp::croak "couldn't open output file $arg->{filename}: $!";

  binmode($fh, ':encoding(utf8)');

  $self->{fh} = $fh;

  return $self;
}

#pod =method output
#pod
#pod   $outputter->output($string);
#pod
#pod This method appends the given string to the output file, adding a newline.
#pod
#pod =cut

sub output {
  my ($self, $line) = @_;

  print { $self->{fh} } "$line\n"
    or Carp::croak "couldn't write to output file: $!";
}

sub finalize {
  # We'll just delete this ref and let garbage collection cause closing if
  # needed. -- rjbs, 2007-11-05
  delete $_[0]->{fh};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::Output::ToFile - base class for output plugins that write to files

=head1 VERSION

version 0.026

=head1 DESCRIPTION

This is a base class for output plugins that will write to files.  The
"filename" configuration parameter must be given, and must be the name of a
file to which the user can write.

=head1 METHODS

=head2 new

  my $addex = App::Addex::Output::Subclass->new(\%arg);

This method returns a new outputter.  It should be subclassed to provide a
C<process_entry> method.

Valid arguments are:

  filename - the file to which to write configuration (required)

=head2 output

  $outputter->output($string);

This method appends the given string to the output file, adding a newline.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
