package Template::Declare::Catalyst;

use strict;
use warnings;
use base 'Template::Declare';

our $VERSION = '0.12';

__PACKAGE__->mk_classdata('context');

*c = \&context;

1;
__END__

=head1 Name

Template::Declare::Catalyst - Template::Declare subclass for Catalyst

=head1 Synopsis

   use parent 'Template::Declare::Catalyst';
   use Template::Declare::Tags;

    template hello => sub {
        my ($self, $vars) = @_;
        html {
            head { title { "Hello, $vars->{user}" } };
            body { h1    { "Hello, $vars->{user}" } };
        };
    };

=head1 Description

This subclass of L<Template::Declare|Template::Declare> adds extra
functionality for use in L<Catalyst|Catalyst> with
L<Catalyst::View::TD|Catalyst::View::TD>.

=head1 Interface

=head2 Class Methods

=head3 C<context>

  my $c = Template::Declare::Catalyst->context;

Returns the Catalyst context object, if available.

=head3 C<c>

  my $c = Template::Declare::Catalyst->c;

An alias for C<context>.

=head1 SEE ALSO

L<Catalyst::View::TD>, L<Catalyst::Helper::View::TD>,
L<Catalyst::Helper::TDClass>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 License

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
