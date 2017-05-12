package Chloro::Role::ResultSet;
BEGIN {
  $Chloro::Role::ResultSet::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

use Chloro::Types qw( HashRef Result );

has _results => (
    traits   => ['Hash'],
    isa      => HashRef [Result],
    init_arg => 'results',
    required => 1,
    handles  => {
        results        => 'elements',
        result_for     => 'get',
        _result_values => 'values',
    },
);

1;

# ABSTRACT: An interface-only for resultset classes



=pod

=head1 NAME

Chloro::Role::ResultSet - An interface-only for resultset classes

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This role defines an interface for all resultsets, and is shared by the
L<Chloro::ResultSet> and L<Chloro::Result::Group> classes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

