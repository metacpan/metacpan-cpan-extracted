package DBIO::Candy::Exports;
# ABSTRACT: Create sugar for DBIO components

use strict;
use warnings;

use Sub::Util ();

our %methods;
our %aliases;

sub export_methods        { $methods{scalar caller(0)} = $_[0] }
sub export_method_aliases { $aliases{scalar caller(0)} = $_[0] }

sub get_methods_for { $methods{$_[0]} }
sub get_aliases_for { $aliases{$_[0]} }

use Sub::Exporter -setup => {
   exports => [ qw(export_methods export_method_aliases) ],
   groups  => { default => [ qw(export_methods export_method_aliases) ] },
};

# Sub::Exporter generates an anonymous import; name it so
# t/55namespaces_cleaned.t can verify *that* sub is properly named (it
# only checks naming/namespace-leak hygiene, not what export_methods /
# export_method_aliases actually do -- that behavior, and DBIO::Candy's
# consumption of it, is covered by t/candy_exports.t).
Sub::Util::set_subname('DBIO::Candy::Exports::import', \&import);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Candy::Exports - Create sugar for DBIO components

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

 package DBIO::SomeComponent;

 sub create_widget { ... }

 # so you don't depend on ::Candy
 eval {
   require DBIO::Candy::Exports;
   DBIO::Candy::Exports->import;
   export_methods ['create_widget'];
   export_method_aliases {
     widget => 'create_widget'
   };
 };

 1;

The above will make it such that users of your component who use it with
L<DBIO::Candy> will have the methods you designate exported into their
namespace.

See F<t/candy_exports.t> for a runnable example, including a component
consumed by L<DBIO::Candy>'s C<-components> option.

=head1 DESCRIPTION

This module allows DBIO components to register sugar functions that
L<DBIO::Candy> will export into result classes that load those components.

=head1 METHODS

=head2 export_methods

 export_methods [qw( foo bar baz )];

Define methods that get exported as subroutines of the same name.

=head2 export_method_aliases

 export_method_aliases {
   old_method_name => 'new_sub_name',
 };

Define methods that get exported as subroutines of a different name.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
