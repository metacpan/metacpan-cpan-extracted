use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::Row::Creation;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Row';
use String::CamelCase;
use Module::Loader;
use Syntax::Keyword::Try;
use Carp qw/croak/;
use DBIx::Class::Candy::Exports;
use DBIx::Class::Smooth::Helper::Util qw/result_source_to_class result_source_to_relation_name /;

use experimental qw/postderef signatures/;

export_methods [qw/
    col
    primary
    foreign
    belongs
    unique
    primary_belongs
    ManyToMany
/];

state $module_loader = Module::Loader->new;

sub col($self, $name, $definition) {
    $self->add_columns($name => $definition);
}

sub primary($self, $name, $definition) {
    $self->add_columns($name => $definition);
    $self->set_primary_key($self->primary_columns, $name);
}
sub primary_belongs($self, @remaining) {
    my $column_name = $self->belongs(@remaining);
    $self->set_primary_key($self->primary_columns, $column_name);

}
sub foreign($self, $column_name, $definition) {
    $definition->{'is_foreign_key'} = 1;
    $self->add_column($column_name => $definition);
}

# assumes that the primary key is called 'id'
sub belongs($self, $other_source, $relation_name_or_definition, $definition_or_undef = {}) {
    my $belongs_to_class = result_source_to_class($self, $other_source);
    my $relation_name = result_source_to_relation_name($other_source);
    my $definition = {};

    # two-param call
    if(ref $relation_name_or_definition eq 'HASH') {
        $definition = $relation_name_or_definition;
    }
    # three-param call
    elsif(ref $definition_or_undef eq 'HASH') {
        $definition = $definition_or_undef;
        $relation_name = $relation_name_or_definition;
    }
    else {
        croak "Bad call to belongs in $self: 'belongs $other_source ...'";
    }
    my $column_name = $relation_name . '_id';


    # Its a ForeignKey field!
    if(exists $definition->{'_smooth_foreign_key'}) {
        delete $definition->{'_smooth_foreign_key'};
        $module_loader->load($belongs_to_class);

        my $primary_key_col = undef;

        try {
            $primary_key_col = $belongs_to_class->column_info('id');
        }
        catch {
            croak "$belongs_to_class has no column 'id'";
        }
        $definition->{'data_type'} = $primary_key_col->{'data_type'};
        $definition->{'is_foreign_key'} = 1;

        for my $attr (qw/size is_numeric/) {
            if(exists $primary_key_col->{ $attr }) {
                $definition->{ $attr } = $primary_key_col->{ $attr };
            }
        }
    }

    if(!exists $definition->{'data_type'}) {
        croak qq{ResultSource '$self' column '$column_name' => definition is missing 'data_type'};
    }
    my $sql = exists $definition->{'sql'} ? delete $definition->{'sql'} : {};
    my $related_name = exists $definition->{'related_name'} ? delete $definition->{'related_name'}
                     :                                        result_source_to_relation_name($self, 1)
                     ;
    my $related_sql = exists $definition->{'related_sql'} ? delete $definition->{'related_sql'} : {};

    $self->foreign($column_name => $definition);
    $self->belongs_to($relation_name, $belongs_to_class, { "foreign.id" => "self.$column_name" }, $sql);

    if(defined $related_name) {
        $module_loader->load($belongs_to_class);
        $belongs_to_class->has_many($related_name, $self, { "foreign.$column_name" => "self.id" }, $related_sql);
    }

    return $column_name;

}

sub unique {
    my $self = shift;
    my $column_name = shift;
    my $args = shift;

    $self->add_columns($column_name => $args);
    $self->add_unique_constraint([ $column_name ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Helper::Row::Creation - Short intro

=head1 VERSION

Version 0.0101, released 2018-11-29.

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
