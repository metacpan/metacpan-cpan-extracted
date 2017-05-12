
package ASP4::Mock::Pool;

use strict;
use warnings 'all';

sub new { return bless { cleanup_handlers => [ ] }, shift }
sub call_cleanup_handlers {
  my $s = shift;
  map { $_->( ) } @{ $s->{cleanup_handlers} }
}
sub cleanup_register {
  my ($s, $handler, $args) = @_;
  
  push @{ $s->{cleanup_handlers} }, sub { $handler->( $args ) };
}

sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::Mock::Pool - Mimics the $r->pool APR::Pool object

=head1 SYNOPSIS

  my $pool = $r->pool;
  $pool->cleanup_register( sub { ... }, \@args );

=head1 DESCRIPTION

This package mimics the L<APR::Pool> object obtained via $r->pool in a normal mod_perl2 environment.

=head1 PUBLIC METHODS

=head2 cleanup_register( sub { ... }, \@args )

Causes the subref to be executed with C<\@args> at the end of the current request.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

