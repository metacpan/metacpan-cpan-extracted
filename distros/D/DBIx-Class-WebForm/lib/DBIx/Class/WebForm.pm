package DBIx::Class::WebForm;

use strict;
use warnings;
use HTML::Element;

our $VERSION = '0.02';

=head1 NAME

DBIx::Class::WebForm - CRUD Methods For DBIx::Class

=head1 SYNOPSIS

    use base 'DBIx::Class::WebForm';

    my $results = Data::FormValidator->check( ... );
    my $film = Film->retrieve('Fahrenheit 911');
    $film->update_from_form($results);
    my $new_film = Film->create_from_form($results);

=head1 DESCRIPTION

CRUD Methods For DBIx::Class.

=head1 METHODS

=over 4

=item $class->create_from_form($form)

=cut

sub create_from_form {
    my $class = shift;
    die "create_from_form can only be called as a class method" if ref $class;
    __PACKAGE__->_run_create( $class, @_ );
}

=item $self->update_from_form($form)

=cut

sub update_from_form {
    my $self = shift;
    die "update_from_form cannot be called as a class method" unless ref $self;
    __PACKAGE__->_run_update( $self, @_ );
}

sub _run_create {
    my ( $me, $class, $results ) = @_;
    my $them = bless {}, $class;
    my $cols = {};
    foreach my $col ( $them->columns ) {
        if(defined($results->valid($col)))
        {
            $cols->{$col} = $results->valid($col);
        }
    }
    return $class->create($cols);
}

sub _run_update {
    my ( $me, $them, $results ) = @_;
    my %pk;
    $pk{$_} = 1 for $them->primary_columns;
    foreach my $col ( keys %{ $results->valid } ) {
        if ( $them->can($col) ) {
            next if $pk{$col};
            my $val = $results->valid($col);
            $them->$col($val);
        }
    }
    $them->update;
    return 1;
}

=item $class->to_cgi

=cut

sub to_cgi {
    my $class = shift;
    map { $_ => $class->to_field($_) } $class->columns;
}

=item $self->to_field( $field, $how )

=cut

sub to_field {
    my ( $self, $field, $how ) = @_;
    my $class = ref $self || $self;
    if ( $how and $how =~ /^(text(area|field)|select)$/ ) {
        no strict 'refs';
        my $meth = "_to_$how";
        return $class->$meth($field);
    }
    my $hasa = $class->_relationships->{$field};
    return $self->_to_select($field)
      if defined $hasa
      and $class->resolve_class( $hasa->{class} )->isa("DBIx::Class");

    my $type = $class->column_type($field);
    return $self->_to_textarea($field)
      if $type
      and $type =~ /^(TEXT|BLOB)$/i;
    return $self->_to_textfield($field);
}

sub _to_textarea {
    my ( $self, $col ) = @_;
    my $a = HTML::Element->new(
        "textarea",
        name => $col,
        rows => "3",
        cols => "22"
    );
    if ( ref $self ) { $a->push_content( $self->$col ) }
    $a;
}

sub _to_textfield {
    my ( $self, $col ) = @_;
    my $value = ref $self && $self->$col;
    my $a = HTML::Element->new( "input", type => "text", name => $col );
    $a->attr( "value" => $value ) if $value;
    $a;
}

sub _to_select {
    my ( $self, $col, $hint ) = @_;
    my $has_a_class = $hint
      || $self->resolve_class( $self->_relationships->{$col}->{class} );
    my @objs = $has_a_class->search;
    my $a = HTML::Element->new( "select", name => $col );
    for (@objs) {
        my $sel = HTML::Element->new( "option", value => $_->id );
        $sel->attr( "selected" => "selected" )
          if ref $self
          and eval { $_->id eq $self->$col->id };
        $sel->push_content( $_ . '' );
        $a->push_content($sel);
    }
    $a;
}

=item $class->column_type($col)

=cut

sub column_type {
    my ( $class, $col ) = @_;

    return if(!$class->has_column($col));

    return $class->column_info($col)->{data_type};
}

=back

=head1 AUTHOR

Matt S. Trout
Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
