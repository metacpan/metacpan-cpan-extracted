#
# This file is part of App-nioscli
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package App::nioscli::Commands::ref_get;
$App::nioscli::Commands::ref_get::VERSION = '0.001';

# VERSION
# AUTHORITY

## use critic
use strictures 2;
use JSON qw(to_json from_json);
use MooseX::App::Command;

extends qw(App::nioscli);

command_short_description 'Get an Object reference';

option 'return_fields' => (
  is  => 'ro',
  isa => 'Str'
);

parameter 'ref' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

sub run {
  my $self = shift;
  my $response =
    defined $self->return_fields
    ? $self->nios_client->get(
    path   => $self->ref,
    params => { _return_fields => $self->return_fields }
    )
    : $self->nios_client->get( path => $self->ref );

  $response->is_success
    ? print(
    to_json( from_json( $response->{_content} ), { utf8 => 1, pretty => 1 } ) )
    : die( $response->{'_content'} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli::Commands::ref_get

=head1 VERSION

version 0.001

=head1 OVERVIEW

Get an Object reference

B<Examples>

=over

=item * Get an Object reference

    nioscli ref-get REF [long options...]

=back

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
