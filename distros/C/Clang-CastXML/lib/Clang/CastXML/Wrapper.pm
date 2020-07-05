package Clang::CastXML::Wrapper;

use Moo;
use 5.020;
use experimental qw( signatures );
use Capture::Tiny ();
use Clang::CastXML::Wrapper::Result;
use Clang::CastXML::Exception::ProcessException::BadCastXMLVersionException;

# ABSTRACT: Lowish level wrapper around the CastXML binary
our $VERSION = '0.01'; # VERSION


has exe => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require Clang::CastXML::Find;
    Clang::CastXML::Find->where;
  },
);


has version => (
  is      => 'ro',
  lazy    => 1,
  default => sub ($self) {
    my $result = $self->raw('--version');
    return $1 if $result->is_success && $result->out =~ /castxml version (\S+)/;
    Clang::CastXML::Exception::ProcessException::BadCastXMLVersionException->throw(
      result => $result
    );
  },
);


sub raw ($self, @arguments)
{
  my($out,$err,$ret,$sig) = Capture::Tiny::capture {
    system $self->exe, @arguments;
    ($? >> 8,$? & 127);
  };

  Clang::CastXML::Wrapper::Result->new(
    wrapper => $self,
    args    => [@arguments],
    out => $out, err => $err, ret => $ret, sig => $sig,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Wrapper - Lowish level wrapper around the CastXML binary

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Clang::CastXML::Wrapper;
 
 my $wrapper = Clang::CastXML::Wrapper->new;
 my $result = $wrapper->raw('--version');

=head1 DESCRIPTION

This class provides an interface for executing L<CastXML>.

=head1 PROPERTIES

=head2 exe

 my $exe = $wrapper->exe;

Returns the path to the castxml executable used by the wrapper class.

=head2 version

 my $version = $wrapper->version;

Returns the CastXML version number.

=head1 METHODS

=head2 raw

 my $result = $wrapper->raw(@arguments);

Run CastXML with the given C<@arguments>.

C<$result> is an instance of L<Clang::CastXML::Wrapper::Result>.

=head1 SEE ALSO

L<Clang::CastXML>, L<Clang::CastXML::Wrapper::Result>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
