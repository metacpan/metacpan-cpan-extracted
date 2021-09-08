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
package App::nioscli::Commands::ref_delete;
$App::nioscli::Commands::ref_delete::VERSION = '0.001';

# VERSION
# AUTHORITY

## use critic
use strictures 2;
use JSON qw(from_json);
use MooseX::App::Command;

extends qw(App::nioscli);

command_short_description 'Delete an Object reference';

parameter 'ref' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

sub run {
  my $self     = shift;
  my $response = $self->nios_client->delete( path => $self->ref );
  die( $response->{'_content'} ) unless $response->is_success;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli::Commands::ref_delete

=head1 VERSION

version 0.001

=head1 OVERVIEW

Delete an Object reference

B<Examples>

=over

=item * Delete an Object reference

    nioscli ref-delete REF [long options...]

=back

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
