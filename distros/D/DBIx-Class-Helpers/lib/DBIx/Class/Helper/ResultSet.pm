package DBIx::Class::Helper::ResultSet;
$DBIx::Class::Helper::ResultSet::VERSION = '2.036000';
# ABSTRACT: All the ResultSet Helpers in one place

use parent qw{
   DBIx::Class::Helper::ResultSet::AutoRemoveColumns
   DBIx::Class::Helper::ResultSet::CorrelateRelationship
   DBIx::Class::Helper::ResultSet::IgnoreWantarray
   DBIx::Class::Helper::ResultSet::Me
   DBIx::Class::Helper::ResultSet::NoColumns
   DBIx::Class::Helper::ResultSet::Random
   DBIx::Class::Helper::ResultSet::RemoveColumns
   DBIx::Class::Helper::ResultSet::ResultClassDWIM
   DBIx::Class::Helper::ResultSet::SearchOr
   DBIx::Class::Helper::ResultSet::SetOperations
   DBIx::Class::Helper::ResultSet::Shortcut
};

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet - All the ResultSet Helpers in one place

=head1 DESCRIPTION

This is just a simple Helper helper that includes all of the ResultSet Helpers
in one convenient module.  It does not include deprecated helpers.

=head2 NOTE

You probably want this applied to your entire schema.  The most convenient
way to do that is to make a base ResultSet and inherit from that in all of
your custom ResultSets as well has make it the default ResultSet for the
non-custom ResultSets.  Example:

 package My::App::Schema::ResultSet;

 use strict;
 use warnings;

 use parent 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components('Helper::ResultSet');

 1;

 package My::App::Schema;

 use parent 'DBIx::Class::Schema';

 My::App::Schema->load_namespaces(
    default_resultset_class => 'ResultSet',
 );

 1;

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
