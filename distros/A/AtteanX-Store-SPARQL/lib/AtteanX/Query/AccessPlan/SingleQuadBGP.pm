package AtteanX::Query::AccessPlan::SingleQuadBGP;

use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.010';

use Moo::Role;
use AtteanX::Plan::SPARQLBGP;

around 'access_plans' => sub {
	my $orig = shift;
	my $self = shift;
	my $model = shift;
	my $active_graphs = shift;
	my $pattern = shift;
	my @plans = $orig->($self, $model, $active_graphs, $pattern, @_);
	if ($pattern->does('Attean::API::TriplePattern')) {
		my $sp = AtteanX::Plan::SPARQLBGP->new(children => [shift(@plans)], distinct => 0, ordered => []);
		push(@plans, $sp);
	}
	return @plans;
};

1;


__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Query::AccessPlan::SingleQuadBGP - An access plan for single-quad basic graph patterns

=head1 SYNOPSIS

A query planner can compose this role using

  with 'AtteanX::Query::AccessPlan::SingleQuadBGP';

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

