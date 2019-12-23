use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::Row::JoinTable;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0102';

use parent 'DBIx::Class::Row';
use String::CamelCase;
use Module::Loader;
use Syntax::Keyword::Try;
use Carp qw/croak/;
use DBIx::Class::Candy::Exports;
use DBIx::Class::Smooth::Helper::Util qw/result_source_to_class result_source_to_relation_name clean_source_name/;

use experimental qw/postderef signatures/;

export_methods [qw/
    join_table
/];

state $module_loader = Module::Loader->new;

sub join_table($self, $left_source, $right_source) {

    my $left_class = result_source_to_class($self, $left_source);
    my $right_class = result_source_to_class($self, $right_source);
    my $via_class = $self;

    my $to_via_relation_name = result_source_to_relation_name($via_class, 1);
    my $via_to_right_relation_name = result_source_to_relation_name($right_source, 0);
    my $left_to_right_relation_name = result_source_to_relation_name($right_source, 1);
    my $via_to_left_relation_name = result_source_to_relation_name($left_source, 0);
    my $right_to_left_relation_name = result_source_to_relation_name($left_source, 1);

    my $left_column_name_in_via = $via_to_left_relation_name . '_id';
    my $right_column_name_in_via = $via_to_right_relation_name . '_id';

    $via_class->primary_belongs($left_source, { _smooth_foreign_key => 1 });
    $via_class->primary_belongs($right_source, { _smooth_foreign_key => 1 });

    $module_loader->load($left_class);
    $module_loader->load($right_class);

    $left_class->many_to_many($left_to_right_relation_name, $to_via_relation_name, $via_to_right_relation_name);
    $right_class->many_to_many($right_to_left_relation_name, $to_via_relation_name, $via_to_left_relation_name);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Helper::Row::JoinTable - Short intro

=head1 VERSION

Version 0.0102, released 2019-12-22.

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
