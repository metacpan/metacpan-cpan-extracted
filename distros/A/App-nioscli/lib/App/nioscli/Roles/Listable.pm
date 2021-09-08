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
package App::nioscli::Roles::Listable;
$App::nioscli::Roles::Listable::VERSION = '0.001';
## use critic
use strictures 2;
use JSON qw(to_json);
use MooseX::App::Role;
use Data::Dumper;

option 'max-results' => (
  is  => 'ro',
  isa => 'Int'
);

option 'filter' => (
  is  => 'ro',
  isa => 'HashRef'
);

option 'return-fields' => (
  is  => 'ro',
  isa => 'Str'
);

has 'params' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $p    = {};

    $p = { %{ $self->filter } } if $self->filter;
    $p->{_max_results} = $self->{'max-results'} if $self->{'max-results'};

    if ( $self->{'return-fields'} ) {
      $p->{_return_fields} = $self->{'return-fields'};
    }
    elsif ( $self->{'default_return_fields'} ) {
      $p->{_return_fields} = $self->{'default_return_fields'};
    }

    return $p;
  }
);

has 'exe' => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1
);

sub execute {
  my $self     = shift;
  my $response = $self->exe->( $self, params => $self->params );
  my @results =
    map { $_->is_success ? @{ $_->content->{result} } : [] } @{$response};
  print to_json( \@results, { utf8 => 1, pretty => 1 } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli::Roles::Listable

=head1 VERSION

version 0.001

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
