package Catalyst::Controller::DBIC::API::StoredResultSource;
$Catalyst::Controller::DBIC::API::StoredResultSource::VERSION = '2.006002';
#ABSTRACT: Provides accessors for static resources

use Moose::Role;
use MooseX::Types::Moose(':all');
use Catalyst::Controller::DBIC::API::Types(':all');
use Try::Tiny;
use namespace::autoclean;

requires '_application';


has 'class' => ( is => 'ro', isa => Str, writer => '_set_class' );


has 'result_class' => (
    is      => 'ro',
    isa     => Maybe [Str],
    default => 'DBIx::Class::ResultClass::HashRefInflator'
);


sub stored_result_source {
    return shift->stored_model->result_source;
}


sub stored_model {
    return $_[0]->_application->model( $_[0]->class );
}


sub check_has_column {
    my ( $self, $col ) = @_;
    die "Column '$col' does not exist in ResultSet '${\$self->class}'"
        unless $self->stored_result_source->has_column($col);
}


sub check_has_relation {
    my ( $self, $rel, $other, $nest, $static ) = @_;

    $nest ||= $self->stored_result_source;

    if ( HashRef->check($other) ) {
        my $rel_src = $nest->related_source($rel);
        die "Relation '$rel_src' does not exist" if not defined($rel_src);

        while ( my ( $k, $v ) = each %$other ) {
            $self->check_has_relation( $k, $v, $rel_src, $static );
        }
    }
    else {
        return 1 if $static && ArrayRef->check($other) && $other->[0] eq '*';
        die "Relation '$rel' does not exist in ${\$nest->from}"
            unless $nest->has_relationship($rel) || $nest->has_column($rel);
        return 1;
    }
}


sub check_column_relation {
    my ( $self, $col_rel, $static ) = @_;

    if ( HashRef->check($col_rel) ) {
        try {
            while ( my ( $k, $v ) = each %$col_rel ) {
                $self->check_has_relation( $k, $v, undef, $static );
            }
        }
        catch {
            # not a relation but a column with a predicate
            while ( my ( $k, undef ) = each %$col_rel ) {
                $self->check_has_column($k);
            }
        }
    }
    else {
        $self->check_has_column($col_rel);
    }
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::StoredResultSource - Provides accessors for static resources

=head1 VERSION

version 2.006002

=head1 PUBLIC_ATTRIBUTES

=head2 class

The name of the Catalyst model for this controller.

=head2 result_class

Populates the result_class attribute of resultsets.

=head1 PUBLIC_METHODS

=head2 stored_result_source

Returns the result_source of the stored_model.

=head2 stored_model

Returns the model for the configured class.

Be aware that model is called as a class method on the Catalyst application
and not as an instance method on $c which might lead to unexpected results
in conjunction with ACCEPT_CONTEXT!

=head2 check_has_column

Convenience method for checking if the column exists in the result source

=head2 check_has_relation

check_has_relation meticulously delves into the result sources relationships to
determine if the provided relation is valid.
Accepts a relation name, an optional HashRef indicating a nested relationship.
Iterates and recurses through provided arguments until exhausted.
Dies if at any time the relationship or column does not exist.

=head2 check_column_relation

Convenience method to first check if the provided argument is a valid relation
(if it is a HashRef) or column.

=head1 AUTHORS

=over 4

=item *

Nicholas Perez <nperez@cpan.org>

=item *

Luke Saunders <luke.saunders@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Oleg Kostyuk <cub.uanic@gmail.com>

=item *

Samuel Kaufman <sam@socialflow.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Luke Saunders, Nicholas Perez, Alexander Hartmaier, et al..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
