#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package DNS::NIOS::Traits::AutoPager;
$DNS::NIOS::Traits::AutoPager::VERSION = '0.005';

# ABSTRACT: Handle pagination automatically
# VERSION
# AUTHORITY

## use critic
use strictures 2;
use namespace::clean;
use Role::Tiny;

requires qw( get );

around 'get' => sub {
  my ( $orig, $self, %args ) = @_;

  my %params = (
    _return_as_object => 1,
    _max_results      => 100,
    _paging           => 1
  );

  my @responses;
  my $max_results = $args{params}->{_max_results} // 0;

  $args{params}
    ? %{ $args{params} } =
    ( %{ $args{params} }, %params )
    : $args{params} = \%params;

  my $response = $orig->( $self, %args );
  return [$response] if !$response->is_success;

  push( @responses, $response );
  while ( $response->content->{next_page_id} ) {
    last if $max_results and _is_max( $max_results, \@responses );
    %{ $args{params} } =
      ( %{ $args{params} }, _page_id => $response->content->{next_page_id} );
    $response = $orig->( $self, %args );
    push( @responses, $response );
  }

  return \@responses;
};

sub _is_max {
  my ( $max, $responses ) = @_;

  my $i = 0;
  foreach ( @{$responses} ) {
    foreach ( $_->{results} ) {
      last if $i >= $max;
      $i++;
    }
  }
  return $i >= $max;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::NIOS::Traits::AutoPager - Handle pagination automatically

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This trait replaces the C<get> method to handle pagination automatically, it turns
the result of all get operations into an ArrayRef of L<DNS::NIOS::Response>.

When C<_max_results> is present in the request, it is honored to some extent.

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
