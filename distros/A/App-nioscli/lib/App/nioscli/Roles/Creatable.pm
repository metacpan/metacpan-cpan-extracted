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
package App::nioscli::Roles::Creatable;
$App::nioscli::Roles::Creatable::VERSION = '0.001';
## use critic
use strictures 2;
use MooseX::App::Role;

has 'exe' => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1
);

has 'payload' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

has 'path' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

sub execute {
  my $self     = shift;
  my $response = $self->exe->(
    $self,
    path    => $self->path,
    payload => $self->payload

  );
  $response->is_success
    ? print( $response->{'_content'} . "\n" )
    : die( $response->{'_content'} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli::Roles::Creatable

=head1 VERSION

version 0.001

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
