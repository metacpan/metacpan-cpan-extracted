package Catalyst::Helper::Model::MongoDB;
our $AUTHORITY = 'cpan:GETTY';
$Catalyst::Helper::Model::MongoDB::VERSION = '0.13';
# ABSTRACT: Helper for MongoDB models
use strict;
use warnings;


sub mk_compclass {
    my ( $self, $helper, $host, $port, $dbname, $collectionname, $gridfs ) = @_;

	my %args = (
		host => $host,
		port => $port,
		dbname => $dbname,
		collectionname => $collectionname,
		gridfs => $gridfs,
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

Catalyst::Helper::Model::MongoDB - Helper for MongoDB models

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  script/myapp_create.pl model MyModel MongoDB [host] [port] [dbname] [collectionname] [gridfs]

=head1 DESCRIPTION

Helper for the L<Catalyst> MongoDB model.

=head1 USAGE

=head1 METHODS

=head2 mk_compclass

Makes the model class.

=head2 mk_comptest

Makes tests.

=head1 SUPPORT

IRC

  Join #catalyst on irc.perl.org and ask for Getty.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Raudssus Social Software.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use Moose;
BEGIN { extends 'Catalyst::Model::MongoDB' };

__PACKAGE__->config(
	host => '[% host || 'localhost' %]',
	port => '[% port || '27017' %]',
	dbname => '[% dbname %]',
	collectionname => '[% collectionname %]',
	gridfs => '[% gridfs %]',
);

=head1 NAME

[% class %] - MongoDB Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

MongoDB Catalyst model component.

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
