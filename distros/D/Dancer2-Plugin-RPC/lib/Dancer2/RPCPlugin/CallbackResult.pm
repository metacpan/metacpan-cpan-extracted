package Dancer2::RPCPlugin::CallbackResult;
use Moo::Role;

our $VERSION = '2.00';

=head1 NAME

Dancer2::RPCPlugin::CallbackResult - Base class for callback-result.

=head1 SYNOPSIS

    package My::CallbackResult;
    use Moo;
    with 'Dancer2::RPCPlugin::CalbackResult';
    ...

=cut

requires '_as_string';

use overload (
    '""' => sub { $_[0]->_as_string },
    fallback => 1,
);

use namespace::autoclean;
1;

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
