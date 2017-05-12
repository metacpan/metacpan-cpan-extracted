package Ambassador::API::V2::Error;

use Moo;
use Types::Standard ':types';
with 'Ambassador::API::V2::Role::Response';

our $VERSION = '0.001';

use overload
    '""'     => \&as_string,
    fallback => 1;

has errors => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_errors {
    my $self = shift;

    return $self->response->{errors}{error};
}

sub _code_and_message {
    my $self = shift;

    return $self->code . ': ' . $self->message;
}

sub as_string {
    my $self = shift;

    return join '', map { "$_\n" } $self->_code_and_message, @{$self->errors};
}

1;

__END__

=head1 NAME

Ambassador::API::V2::Error - An error response from the Ambassador API

=head1 DESCRIPTION

L<Ambassador::API::V2::Role::Response> plus...

=head1 ATTRIBUTES

=over 4

=item errors

An array ref of errors returned by the Ambassador API.

=back

=head1 METHODS

=over 4

=item $string = $error->as_string

  my $string = $error->as_string;

Returns the C<< $error->message >> and C<< $error->errors >> formatted
for human consumption.

=back

=head1 Overloading

If used as a string, C<as_string> will be called.

    print $error;

=head1 SOURCE

The source code repository for Ambassador-API-V2 can be found at
F<https://github.com/dreamhost/Ambassador-API-V2>.

=head1 COPYRIGHT

Copyright 2016 Dreamhost E<lt>dev-notify@hq.newdream.netE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
