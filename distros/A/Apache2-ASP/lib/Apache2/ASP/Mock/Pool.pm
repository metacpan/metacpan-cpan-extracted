
package Apache2::ASP::Mock::Pool;

use strict;
use warnings 'all';


#==============================================================================
sub new
{
  return bless {_cleanup_handlers => [ ]}, shift;
}# end new()


#==============================================================================
sub cleanup_register
{
  my ($s, $ref, $args) = @_;
  
  push @{$s->{_cleanup_handlers}}, sub { $ref->( $args ) };
}# end cleanup_register()


#==============================================================================
sub call_cleanup_handlers
{
  my $s = shift;
  
  map { $_->() } @{$s->{_cleanup_handlers}};
}# end call_cleanup_handlers()

1;# return true:


=pod

=head1 NAME

Apache2::ASP::Mock::Pool - Mimics the $r->pool APR::Pool object

=head1 SYNOPSIS

  my $pool = $Response->context->r->pool;
  $pool->cleanup_register( sub { ... }, \@args );

=head1 DESCRIPTION

This package mimics the L<APR::Pool> object obtained via $r->pool in a normal mod_perl2 environment,
and is used by L<Apace2::ASP::API>.

=head1 PUBLIC METHODS

=head2 cleanup_register( sub { ... }, \@args )

Causes the subref to be executed with C<@args> at the end of the current request.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

