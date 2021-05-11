package DBIC::Violator::Plack::Middleware;
use parent 'Plack::Middleware';

use strict;
use warnings;

# ABSTRACT: Plack Middleware hook for DBIC::Violator

use Plack::Util;
use DBIC::Violator;

use RapidApp::Util ':all';

sub call {
  my ($self, $env) = @_;
  
  my $Collector = DBIC::Violator->collector;
  
  return $Collector 
    ? $Collector->_middleware_call_coderef->($self,$env)
    : $self->app->($env)
  
}


1;


__END__

=head1 NAME

DBIC::Violator::Plack::Middleware - Plack Middleware hook for DBIC::Violator

=head1 SYNOPSIS

 use DBIC::Violator::Plack::Middleware;
 use Plack::Builder;

 builder {
   enable '+DBIC::Violator::Plack::Middleware';
   $psgi_app
 };
 

=head1 DESCRIPTION

This is the Plack middleware for L<DBIC::Violator> which can be used to track and link all 
DBIC queries and associate them with a parent HTTP request.

This module exists for some specific uses and may not ever be supported and so you probably
shouldn't use it. Full documentation maybe TBD.

=head1 CONFIGURATION


=head1 METHODS


=head1 SEE ALSO

=over

=item * 

L<DBIC::Violator>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
