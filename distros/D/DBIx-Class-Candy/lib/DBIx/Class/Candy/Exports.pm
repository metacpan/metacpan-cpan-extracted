package DBIx::Class::Candy::Exports;
$DBIx::Class::Candy::Exports::VERSION = '0.005003';
# ABSTRACT: Create sugar for your favorite ORM, DBIx::Class

use strict;
use warnings;

our %methods;
our %aliases;

sub export_methods        { $methods{scalar caller(0)} = $_[0] }
sub export_method_aliases { $aliases{scalar caller(0)} = $_[0] }

use Sub::Exporter -setup => {
   exports => [ qw(export_methods export_method_aliases) ],
   groups  => { default => [ qw(export_methods export_method_aliases) ] },
};

1;

__END__

=pod

=head1 NAME

DBIx::Class::Candy::Exports - Create sugar for your favorite ORM, DBIx::Class

=head1 SYNOPSIS

 package DBIx::Class::Widget;

 sub create_a_widget { ... }

 # so you don't depend on ::Candy
 eval {
   require DBIx::Class::Candy::Exports;
   DBIx::Class::Candy::Exports->import;
   export_methods ['create_a_widget'];
   export_method_aliases {
     widget => 'create_a_widget'
   };
 }

 1;

The above will make it such that users of your component who use it with
L<DBIx::Class::Candy> will have the methods you designate exported into
their namespace.

=head1 DESCRIPTION

The whole point of this module is to make sugar a first class citizen in
the component world that dominates L<DBIx::Class>.  I make enough components
and like this sugar idea enough that I want to be able to have both at the
same time.

=head1 IMPORTED SUBROUTINES

=head2 export_methods

 export_methods [qw( foo bar baz )];

Use this subroutine to define methods that get exported as subroutines of the
same name.

=head2 export_method_aliases

 export_method_aliases {
   old_method_name => 'new_sub_name',
 };

Use this subroutine to define methods that get exported as subroutines of a
different name.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
