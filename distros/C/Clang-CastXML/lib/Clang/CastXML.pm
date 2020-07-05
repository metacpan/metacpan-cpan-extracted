package Clang::CastXML;

use Moo;
use 5.020;
use experimental qw( signatures );
use Ref::Util qw( is_blessed_ref is_ref );
use Clang::CastXML::Container;
use Path::Tiny ();
use Clang::CastXML::Exception::UsageException;
use Clang::CastXML::Exception::ProcessException::IntrospectException;

# ABSTRACT: C-family abstract syntax tree output tool
our $VERSION = '0.01'; # VERSION


has wrapper => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require Clang::CastXML::Wrapper;
    Clang::CastXML::Wrapper->new;
  },
);


sub introspect ($self, $source, $dest=undef)
{
  if(is_blessed_ref $source && $source->isa('Path::Tiny'))
  {
    # nothing to do
  }
  elsif(!is_ref $source && defined $source)
  {
    my $content = $source;
    $source = Path::Tiny->tempfile(
      TEMPLATE => 'castxml-XXXXXX',
      SUFFIX   => '.C',
    );
    $source->spew_utf8($content);
  }
  else
  {
    Clang::CastXML::Exception::UsageException->throw(
      diagnostic => "Source should be either a Path::Tiny instance or string containing the C source",
    );
  }

  $dest //= Path::Tiny->tempfile(
    TEMPLATE => 'castxml-XXXXXX',
    SUFFIX   => '.xml',
  );

  unless(is_ref $dest && $dest->isa('Path::Tiny'))
  {
    Clang::CastXML::Exception::UsageException->throw(
      diagnostic => "Destination should be a Path::Tiny object",
    );
  }

  my $result = $self->wrapper->raw("--castxml-output=1", "-o" => "$dest", "$source");

  if($result->is_success)
  {
    return Clang::CastXML::Container->new(
      result => $result,
      source => $source,
      dest   => $dest,
    );
  }
  else
  {
    Clang::CastXML::Exception::ProcessException::IntrospectException->throw(
      result => $result,
    );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML - C-family abstract syntax tree output tool

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Clang::CastXML;
 use Path::Tiny qw( path );
 
 my $castxml = Clang::CastXML->new;
 my $container = $castxml->introspect( path('foo.C') );
 my $raw_xml = $container->to_xml;

=head1 DESCRIPTION

This class provides an interface to CastXML for introspecting C/C++ code.
This can be useful for writing FFI or XS bindings.

=head1 PROPERTIES

=head2 wrapper

 my $wrapper = $castxml->wrapper;

Returns the L<Clang::CastXML::Wrapper> instance.  The default is usually reasonable.

=head1 METHODS

=head2 introspect

 my $container = $castxml->introspect($source);
 my $container = $castxml->introspect($source, $dest);

This runs CastXML on the given source and returns an XML container which can be used
to get the raw XML, or to convert it to a more useful format.

C<$source> should be either a L<Path::Tiny> object for the C/C++ source file, or
a string containing the C/C++ source.

C<$dest> is optional, and if provided should be a L<Path::Tiny> object where the
XML will be written.  If not provided, then a temporary file will be created.

C<$container> is an instance of L<Clang::CastXML::Container>.

May throw an exception:

=over 4

=item L<Clang::CastXML::Exception::UsageException>

If you pass in a C<$source> or C<$dest> of the wrong type.

=item L<Clang::CastXML::Exception::ProcessException::IntrospectException>

If there is an error running the C<castxml> executable.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
