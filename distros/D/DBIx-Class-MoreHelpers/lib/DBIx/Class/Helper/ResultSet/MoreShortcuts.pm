package DBIx::Class::Helper::ResultSet::MoreShortcuts;

# ABSTRACT: Additional shortcuts to common searches (->blank, ->is, etc)
use strict;
use warnings;
use parent (qw(
   DBIx::Class::Helper::ResultSet::Shortcut::Search::Blank
   DBIx::Class::Helper::ResultSet::Shortcut::Search::NotBlank
   DBIx::Class::Helper::ResultSet::Shortcut::Search::BlankOrNull
   DBIx::Class::Helper::ResultSet::Shortcut::Search::NotBlankOrNull
   DBIx::Class::Helper::ResultSet::Shortcut::Search::Is
   DBIx::Class::Helper::ResultSet::Shortcut::Search::IsNot
   DBIx::Class::Helper::ResultSet::Shortcut::Search::IsAny
   DBIx::Class::Helper::ResultSet::Shortcut::Search::Zero
   DBIx::Class::Helper::ResultSet::Shortcut::Search::NullOrZero
   DBIx::Class::Helper::ResultSet::Shortcut::Search::Nonzero
   DBIx::Class::Helper::ResultSet::Shortcut::Search::Positive
   DBIx::Class::Helper::ResultSet::Shortcut::Search::Negative
));

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::ResultSet::MoreShortcuts - Additional shortcuts to common searches (->blank, ->is, etc)

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    # To apply to a specific ResultSet:
    package MyApp::Schema::ResultSet::Foo;
    
    __PACKAGE__->load_components(qw{Helper::ResultSet::MoreShortcuts});
    
    ...
    
    1;
    
    # Or, to apply to the entire schema:
    package MyApp::Schema;
    __PACKAGE__->load_namespaces( default_resultset_class => 'ResultSet' );
 
    1;

    package MyApp::Schema::ResultSet;
     
    __PACKAGE__->load_components(qw{Helper::ResultSet::MoreShortcuts});
     
    1;

    # And then elsewhere:
    my $foo_rs = $schema->resulset('Foo')->blank('column');

    # Both of these columns must be true:
    my $check_rs = $schema->resultset('Foo')->is(['active', 'ready_to_ship']);

=head1 DESCRIPTION

This helper set provides even more convenience methods for resultset selections.  In all cases 
where you can send a list of fields, all of the fields must match the value, except in the case
of C<is_any>.

=head2 blank

 $foo_rs->blank('field');
 $foo_rs->blank(['field1','field2']);

=head2 not_blank

 $foo_rs->not_blank('field');
 $foo_rs->not_blank(['field1','field2']);

=head2 blank_or_null

 $foo_rs->blank_or_null('field');
 $foo_rs->blank_or_null(['field1','field2']);

=head2 not_blank_or_null

 $foo_rs->not_blank_or_null('field');
 $foo_rs->not_blank_or_null(['field1','field2']);

=head2 is

 $foo_rs->is('boolean_field');
 $foo_rs->is(['boolean_field1','boolean_field2']);

=head2 is_not

 $foo_rs->is_not('boolean_field');
 $foo_rs->is_not(['boolean_field1','boolean_field2']);

=head2 is_any

 $foo_rs->is_any(['boolean_field1','boolean_field2']);

=head2 zero

 $foo_rs->zero('numeric_field');
 $foo_rs->zero(['numeric_field1', 'numeric_field2']);

=head2 null_or_zero

 $foo_rs->null_or_zero('numeric_field');
 $foo_rs->null_or_zero(['numeric_field1', 'numeric_field2']);

=head2 nonzero

 $foo_rs->nonzero('numeric_field');
 $foo_rs->nonzero(['numeric_field1', 'numeric_field2']);

=head2 positive

 $foo_rs->positive('numeric_field');
 $foo_rs->positive(['numeric_field1', 'numeric_field2']);

=head2 negative

 $foo_rs->negative('numeric_field');
 $foo_rs->negative(['numeric_field1', 'numeric_field2']);

=head1 ROADMAP

=over 2

=item * None of these are really doing much checking on their inputs. Oughta fix that and throw exceptions.

=back

=head1 SEE ALSO

This component is actually a number of other components put together in a tidy bundle. It 
is entirely probable that more will be added. You can use the individual ones, if you like:

=over 2

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::Blank>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::NotBlank>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::BlankOrNull>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::NotBlankOrNull>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::Is>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::IsNot>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Search::IsAny>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
