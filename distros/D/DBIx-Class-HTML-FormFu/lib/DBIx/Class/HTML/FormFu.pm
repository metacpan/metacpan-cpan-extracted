package DBIx::Class::HTML::FormFu;
use strict;
use warnings;
use Carp qw( croak );

our $VERSION = '0.01005';

sub fill_formfu_values {
    my ( $dbic, $form, $attrs ) = @_;

    $attrs = {
        prefix_col => '',
        suffix_col => '',
        %{ $attrs || {} }
    };
    my $prefix = $attrs->{prefix_col};
    my $suffix = $attrs->{suffix_col};

    my $fields;
    eval { $fields = $form->get_fields; };
    croak "require a compatible form object: $@" if $@;

    for my $field (@$fields) {
        my $field_name = $field->name;
        next unless defined $field_name;

        my ($dbic_name) = ( $field_name =~ /\A(?:$prefix)?(.*)(?:$suffix)?\z/ );
        next
          unless ( $dbic->has_column($dbic_name)
            || $dbic->result_source->has_relationship($dbic_name) );

        if (   $dbic->result_source->has_relationship($dbic_name)
            && $dbic->result_source->related_source($dbic_name)
            ->has_column('id')
            && $dbic->result_source->related_source($dbic_name)
            ->get_column('id') )
        {
            $field->default(
                $dbic->result_source->related_source($dbic_name)->id
                );
        }
        else {
            $field->default( $dbic->$dbic_name );
        }
    }

    return $form;
}

sub populate_from_formfu {
    my ( $dbic, $form, $attrs ) = @_;

    $attrs = {
        prefix_col => '',
        suffix_col => '',
        %{ $attrs || {} }
    };

    my %checkbox;
    eval {
        %checkbox =
          map { $_->name => 1 }
          grep { defined $_->name }
          @{ $form->get_fields( { type => 'Checkbox' } ) || [] };
    };
    croak "require a compatible form object: $@" if $@;

    my $params = $form->params;

    for my $col ( $dbic->result_source->columns ) {
        my $col_info    = $dbic->column_info($col);
        my $is_nullable = $col_info->{is_nullable} || 0;
        my $data_type   = $col_info->{data_type} || '';
        my $form_col    = $attrs->{prefix_col} . $col . $attrs->{suffix_col};
        my $value = exists $params->{$form_col} ? $params->{$form_col} : undef;

        if (
            (
                   $is_nullable
                || $data_type =~ m/^timestamp|date|int|float|numeric/i
            )
            && defined $value
            && $value eq ''
          )
        {
            $value = undef;
            $dbic->$col($value);
        }

        if ( $checkbox{$form_col} && !defined $value && !$is_nullable ) {
            $dbic->$col( $col_info->{default_value} );
        }
        elsif ( defined $value || $checkbox{$form_col} ) {
            $dbic->$col($value);
        }
    }

    $dbic->update_or_insert;

    return $dbic;
}

1;

__END__

=head1 NAME

DBIx::Class::HTML::FormFu - DEPRECATED - use HTML::FormFu::Model::DBIC instead

=head1 DEPRECATED

For new applications, you're advised to use L<HTML::FormFu::Model::DBIC>
instead.

=head1 SYNOPSIS

    # fill a form from the database
    
    my $row = $schema->resultset('Foo')->find($id);
        
    $row->fill_formfu_values( $form )

    # populate the database from a submitted form
    
    if ( $form->submitted && !$form->has_errors ) {
        
        my $row = $schema->resultset('Foo')->find({ id => $params->{id} });
        
        $row->populate_from_formfu( $form );
    }

=head1 ATTRIBUTES

The fill_formfu_values and populate_from_formfu functions can both take an optional hasref argument to process the field names from form field name to database fieldname.

The hasref takes to arguments:
    prefix_col takes a string to add to the begining of the form field names.
    suffix_col takes a string to add to the end of the form field names.

=head2 Example

If you have the following form fields:

    private_street
    private_city
    private_email
    office_street
    office_city
    office_email

You most likely would like to save both datasets in same table:

    my $private = $user->new_related( 'data', { type => 'private' } );
    $private->populate_from_formfu( $form, { prefix_col => 'private_' } );
    my $office = $user->new_related( 'data', { type => 'office' } );
    $office->populate_from_formfu( $form, { prefix_col => 'office_' } );

The table needs the following rows:

    id     (not really needed)
    street
    city
    email
    type
    user_id

=head1 FREQUENTLY ASKED QUESTIONS (FAQ)

=head2 If I have another column in the database that is not present on the form? How do I add a value to the form to still use 'populate_from_formfu'?

Use $form->add_valid( name => 'value' );

Example:

    my $passwd = generate_passwd();
    $form->add_valid( passwd => $passwd );
    $resultset->populate_from_formfu( $form );

add_valid() works for fieldnames that don't exist in the form.

=head1 CAVEATS

To ensure your column's inflators and deflators are called, we have to 
get / set values using their named methods, and not with C<get_column> / 
C<set_column>.

Because of this, beware of having column names which clash with DBIx::Class 
built-in method-names, such as C<delete>. - It will have obviously 
undesirable results!

=head1 SUPPORT

Project Page:

L<http://code.google.com/p/html-formfu/>

Mailing list:

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/html-formfu>

Mailing list archives:

L<http://lists.scsys.co.uk/pipermail/html-formfu/>

=head1 BUGS

Please submit bugs / feature requests to 
L<http://code.google.com/p/html-formfu/issues/list> (preferred) or 
L<http://rt.perl.org>.

=head1 SUBVERSION REPOSITORY

The publicly viewable subversion code repository is at 
L<http://html-formfu.googlecode.com/svn/trunk/DBIx-Class-HTML-FormFu>.

If you wish to contribute, you'll need a GMAIL email address. Then just 
ask on the mailing list for commit access.

If you wish to contribute but for some reason really don't want to sign up 
for a GMAIL account, please post patches to the mailing list (although  
you'll have to wait for someone to commit them). 

If you have commit permissions, use the HTTPS repository url: 
L<https://html-formfu.googlecode.com/svn/trunk/DBIx-Class-HTML-FormFu>

=head1 SEE ALSO

L<HTML::FormFu>, L<DBIx::Class>, L<Catalyst::Controller::HTML::FormFu>

=head1 AUTHOR

Carl Franks

=head1 CONTRIBUTORS

Adam Herzog

Daisuke Maki

Mario Minati

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Carl Franks

Based on the original source code of L<DBIx::Class::HTMLWidget>, copyright 
Thomas Klausner.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
