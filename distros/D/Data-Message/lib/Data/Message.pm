use strict;
package Data::Message;
{
  $Data::Message::VERSION = '1.104';
}
# ABSTRACT: parse and build header-and-body messages (kinda like email)

use Email::Simple 1.92;
use base qw[Email::Simple];

my $private = \q[no peeking];

sub new {
    my ($self, $message, %attrs) = @_;
    my $object = $self->SUPER::new($message);
    $object->{"$private"} = \%attrs;
    return $object;
}

sub header_set {
    my $self = shift;
    local $Email::Simple::GROUCHY = $self->{"$private"}->{grouchy};
    return $self->SUPER::header_set(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Message - parse and build header-and-body messages (kinda like email)

=head1 VERSION

version 1.104

=head1 SYNOPSIS

  use Data::Message;
  
  my $message = Data::Message->new(join('',<>), fold => 1);
  
  print $message->header("Customer-ID");
  print $message->body;

=head1 DESCRIPTION

B<ACHTUNG!>  What's the point of this module?  It isn't even clear to me,
the current maintainer.  Consider using Email::Simple or Email::MIME
directly.

This module is a generic interface to dealing with RFC2822 compliant
messages. Email is the most common example of messages in this format,
but not the only one. HTTP requests and responses are also sent and
received in this format. Many other systems rely on storing or
sending information with a header of key/value pairs followed by an
B<optional> body.

Because C<Email::Simple> is so good at parsing this format, and so
fast, this module inherits from it. Changes to the interface are only
prevelant in options provided to the constructor C<new()>. For any
other interface usage documentation, please see L<Email::Simple>.

Because C<Data::Message> is a subclass of C<Email::Simple>, its
mixins will work with this package. For example, you may use
C<Email::Simple::Creator> to aid in the creation of C<Data::Message>
objects from scratch.

=head2 new()

  my $message = Data::Message->new(join( '', <> ));

The first argument is a scalar value containing the text of the
payload to be parsed. Subsequent arguments are passed as key/value
pairs.

=head1 SEE ALSO

L<Email::Simple>,
L<Email::Simple::Creator>,
L<Email::Simple::Headers>,
L<perl>.

=head1 AUTHORS

=over 4

=item *

Casey West

=item *

Ricardo SIGNES <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Casey West.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
