use 5.010001;
use strict;
use warnings;

package AtteanX::Query::Cache;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';
use Moo;

extends 'AtteanX::Endpoint';

after 'log_query' => sub {
	my $self	= shift;
	my $req		= shift;
	my $message	= shift;
	$self->model->publisher->publish('analyze.fullquery', $message);
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Query::Cache - Experimental prefetching SPARQL query cacher

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an alpha release of a system that is able to intercept SPARQL
queries if deployed in a proxy, and analyze the queries so that the
query can be evaluated on the proxy. It can look up in a cache on the
proxy, send parts of the query on to the remote endpoint, use Linked
Data Fragments when appropriate and so on. The analyzer may also
decide to prefetch certain data asynchronously.

It is known at present to have insufficient performance for any
practical use, but is released anyway as an alpha.


=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-atteanx-query-cache/issues>.

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

