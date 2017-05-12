use 5.010;
use strict;
use warnings;

package CatalystX::TraitFor::Dispatcher::ExactMatch;

use Moose::Role;

BEGIN
{
	$CatalystX::TraitFor::Dispatcher::ExactMatch::AUTHORITY = 'cpan:TOBYINK';
	$CatalystX::TraitFor::Dispatcher::ExactMatch::VERSION   = '0.003';
}

requires qw( dispatch_types );

around prepare_action => sub
{
	my $next = shift;
	my $self = shift;
	my ($ctx, @etc) = @_;
	
	my $req = $ctx->req;
	(my $path = $req->path) =~ s{^/+}{};
	
	my $matched = 0;
	foreach my $type ( @{ $self->dispatch_types } )
	{
		if (!$matched and $type->match($ctx, $path))
		{
			$matched++;
		}
	}
	
	if ($matched)
	{
		$ctx->log->debug(sprintf('Got exact match "%s"', $req->match));
		s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg foreach grep { defined } @{$req->captures||[]};
	}
	
	$self->$next($ctx, @etc);
};

'fixed';

__END__

=head1 NAME

CatalystX::TraitFor::Dispatcher::ExactMatch - handle trailing slashes properly

=head1 SYNOPSIS

   package MyApp;
   
   use Catalyst::Runtime 5.80;
   use Catalyst qw/
      -Debug
      Static::Simple
      /;
   use CatalystX::RoleApplicator;
   
   __PACKAGE__->apply_dispatcher_class_roles(
      qw/CatalystX::TraitFor::Dispatcher::ExactMatch/
   );

=head1 DESCRIPTION

The Catalyst dispatcher doesn't differentiate between:

=over

=item C<http://localhost:3000/foo>

=item C<http://localhost:3000/foo/>

=back

Not even with Regex dispatching. Not even by writing a custom dispatch
type.

This is apparently a "feature". As far as I'm concerned, it's a bug.

This trait for Catalyst::Dispatcher attempts to perform an exact match,
including trailing slashes, ahead of Catalyst's default dispatching. It's
not been tested in every possible configuration, but it works for me.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=CatalystX-TraitFor-Dispatcher-ExactMatch>.

=head1 SEE ALSO

L<CatalystX::RoleApplicator>,
L<Catalyst::Dispatcher>.

L<Catalyst::Plugin::SanitizeUrl> appears to do something similar for
pre-Moose versions of Catalyst.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

