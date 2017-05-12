package Catalyst::Helper::View::Tenjin;

# ABSTRACT: Helper for creating Tenjin Views

use strict;
use warnings;

our $VERSION = "0.050001";
$VERSION = eval $VERSION;

=head1 NAME

Catalyst::Helper::View::Tenjin - Helper for creating Tenjin Views

=head1 VERSION

version 0.050001

=head1 SYNOPSIS

	script/myapp_create.pl view Tenjin Tenjin

=head1 DESCRIPTION

This module provides Catalyst applications' create.pl script the ability to
easily create a Tenjin view for you application. After creating the view
please check that the default configuration in the created view fits your needs.

=head1 METHODS

=head2 mk_compclass( $helper )

=cut

sub mk_compclass {
	my ($self, $helper) = @_;

	$helper->render_file('compclass', $helper->{file});
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::View::Tenjin>

=head1 AUTHOR

Ido Perlmuter E<lt>ido at ido50.netE<gt>, based on L<Catalyst::View::TT> by
Sebastian Riedel (E<lt>sri at oook.deE<gt>) and Marcus Ramberg
E<lt>mramberg at cpan.orgE<gt>).

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Tenjin';

__PACKAGE__->config(
	#USE_STRICT => 1,
	INCLUDE_PATH => [ [% app %]->path_to('root', 'templates') ],
	TEMPLATE_EXTENSION => '.html',
	#ENCODING => 'UTF-8', # this is the default
);

=head1 NAME

[% class %] - Tenjin view for [% app %]

=head1 DESCRIPTION

Tenjin view for [% app %].

=head1 SEE ALSO

L<[% app %]>, L<Catalyst::View::Tenjin>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;