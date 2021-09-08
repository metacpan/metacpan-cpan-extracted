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
package App::nioscli::Commands::ref_update;
$App::nioscli::Commands::ref_update::VERSION = '0.001';

# VERSION
# AUTHORITY

## use critic
use strictures 2;
use JSON qw(from_json);
use MooseX::App::Command;

extends qw(App::nioscli);

command_short_description 'Update an Object reference';

parameter 'ref' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

option 'json' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

sub run {
  my $self     = shift;
  my $response = $self->nios_client->update(
    path    => $self->ref,
    payload => from_json( $self->json )
  );

  $response->is_success
    ? print( $response->{'_content'} )
    : die( $response->{'_content'} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli::Commands::ref_update

=head1 VERSION

version 0.001

=head1 OVERVIEW

Update an Object reference

B<Examples>

=over

=item * Update an Object reference

    nioscli ref-update REF \
        --json '{ "name": "foo" }' \
        [long options...]

=back

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
