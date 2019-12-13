package CanvasCloud::API::Account;
$CanvasCloud::API::Account::VERSION = '0.007';
# ABSTRACT: extends L<CanvasCloud::API>

use Moose;
use namespace::autoclean;

extends 'CanvasCloud::API';


has account_id => ( is => 'ro', required => 1 );


augment 'uri' => sub {
    my $self = shift;
    my $rest = inner() || '';
    $rest = '/' if ( defined $rest && $rest && $rest !~ /^\// );
    return sprintf( '/accounts/%s', $self->account_id ) . $rest;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Account - extends L<CanvasCloud::API>

=head1 VERSION

version 0.007

=head1 ATTRIBUTES

=head2 account_id

I<required:> set to the account id for Canvas call

=head2 uri

augments base uri to append '/accounts/account_id'

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
