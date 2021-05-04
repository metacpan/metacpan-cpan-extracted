package Clang::CastXML::Container;

use Moo;
use 5.022;
use experimental qw( signatures );
use XML::Parser;
use Clang::CastXML::Exception::ParseException;

# ABSTRACT: Container class for XML output from CastXML
our $VERSION = '0.02'; # VERSION


has $_ => (
  is       => 'ro',
  required => 1,
) for qw( result source dest );


sub to_xml ($self)
{
  return $self->dest->slurp_utf8;
}


sub to_href ($self)
{
  my $cur = { inner => [] };
  my @stack;

  my $parser = XML::Parser->new(
    Handlers => {
      Start => sub ($, $element, %attrs) {

        # Fixups
        delete $attrs{location}; # redundant
        if($element =~ /^(Function|Variable)$/n)
        {
          # TODO: This works for current Clang (probably).  If we need to
          # support other compiles, like Visual C++ this computed
          # mangle will probably have to be updated.
          my $bad_mangle = '_Z' . length($attrs{name}) . $attrs{name};
          delete $attrs{mangled} if $attrs{mangled} eq $bad_mangle;
        }

        my $inner = ( $cur->{inner} //= [] );
        push @stack, $cur;
        $cur = {
          _class => $element,
          %attrs,
        };
        push @$inner, $cur;
      },
      End   => sub ($, $element) {
        my $save = $cur;
        $cur = pop @stack;

        delete $save->{file} if defined $save->{file} && $save->{file} eq ($cur->{file} // '');
        delete $save->{line} if defined $save->{line} && $save->{line} eq ($cur->{line} // '');
      }
    },
  );

  my $fh = $self->dest->openr;

  local $@ = '';
  eval { $parser->parse($fh) };
  Clang::CastXML::Exception::ParseException->throw if $@;

  return $cur->{inner}->[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Container - Container class for XML output from CastXML

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Clang::CastXML;
 
 my $castxml = Clang::CastXML->new;
 my $container = $castxml->introspect(' int add(int,int); ');
 
 # get the raw XML output from CastXML
 my $xml = $container->to_xml;
 
 # get a nested datastructure (hash reference)
 # of the output from CastXML
 my $perl = $container->to_href;

=head1 DESCRIPTION

This class provides an interface to the output generated from CastXML.
You can assume that the CastXML successfully processed the C/C++ source,
because the L<Clang::CastXML> method C<introspect> will throw an
exception if there is an error there, rather than return a bad object.

=head1 PROPERTIES

=head2 result

 my $result = $container->result;

This is a L<Clang::CastXML::Wrapper::Result>, which contains the raw
output of the process run.

=head2 source

 my $source = $container->source.

This is a L<Path::Tiny> which points to the C/C++ source file.

=head2 dest

 my $dest = $container->dest;

This is a L<Path::Tiny> which points to the XML output file.

=head1 METHODS

=head2 to_xml

 my $xml = $xml->to_xml;

Returns the raw XML as a utf-8 string.

=head2 to_href

 my $perl = $container->to_href;

Returns a set of nested data structures (hash references, array references, etc)
with the same data as what is in the raw XML.  This is probably easier for Perl
to grock than the raw XML.

May throw an exception:

=over 4

=item L<Clang::CastXML::Exception::ParseException>

If there is an error parsing the XML.

=back

=head1 SEE ALSO

L<Clang::CastXML>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
