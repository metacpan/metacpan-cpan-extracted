package Catalyst::Helper::Model::Riak;
BEGIN {
	$Catalyst::Helper::Model::Riak::AUTHORITY = 'cpan::NLTBO';
}
BEGIN {
	$Catalyst::Helper::Model::Riak::VERSION = '0.02';
}

use strict;
use warnings;

sub mk_compclass {
	my( $self, $helper, $host, $timeout ) = @_;

	my %args = (
		host => $host,
		ua_timeout => $timeout,
	);


	$helper->render_file('modelclass', $helper->{file}, \%args);
	return 1;
}

sub mk_comptest {
	my ($self, $helper) = @_;
	$helper->render_file('modeltest', $helper->{test});
}

1;

=pod

=head1 NAME

Catalyst::Helper::Model::Riak - Helper for Riak models

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  script/myapp_create.pl model MyModel Riak [host] [ua_timeout] 

=head1 DESCRIPTION

Helper for the L<Catalyst> Riak model.

=head1 USAGE

=head1 METHODS

=head2 mk_compclass

Makes the model class.

=head2 mk_comptest

Makes tests.

=head1 SUPPORT

Repository

  https://github.com/Mainframe2008/CatRiak
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Mainframe2008/CatRiak/issues

=head1 AUTHOR

Theo Bot <nltbo@cpan.org> L<http://www.proxy.nl/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Theo Bot

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use Moose;
BEGIN { extends 'Catalyst::Model::Riak' };

__PACKAGE__->config(
	host => '[% host || 'http://localhost:8098' %]',
	timeout => [% ua_timeout || '900' %],
);

=head1 NAME

[% class %] - Riak Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Riak Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');