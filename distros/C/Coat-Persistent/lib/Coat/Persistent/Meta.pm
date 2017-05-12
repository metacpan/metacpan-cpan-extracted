package Coat::Persistent::Meta;

use strict;
use warnings;
use base 'Exporter';

# The placeholder for all meta-information saved for Coat::Persistent models.
my $META = {};

# supported meta attributes for models
my @attributes = qw(table_name primary_key accessor);

# accessor to the meta information of a model
# ex: Coat::Persistent::Meta->model('User')
sub registry { $META->{ $_[1] } }

sub attribute {
    my ($self, $class, $attribute) = @_;
    $META->{ $class }{attributes} ||= [];
    push @{ $META->{ $class }{'attributes'} }, $attribute;
}

sub attribute_exists {
    my ($self, $class, $attribute) = @_;
    return grep /^$attribute$/, @{ $META->{ $class }{'attributes'} };
}

sub attributes {
    my ($self, $class) = @_;
    $META->{ $class }{'attributes'} ||= [];
    return @{ $META->{ $class }{'attributes'} };
}

sub linearized_attributes {
    my ($self, $class) = @_;
    
    my @all = ();
    foreach my $c (reverse Coat::Meta->linearized_isa( $class ) ) {
        foreach my $attr (Coat::Persistent::Meta->attributes( $c )) {
            push(@all, $attr) unless (grep(/^$attr$/, @all));
        }
    }
    return @all;
}

# this is to avoid writing several times the same setters and 
# writers for the class
# (closures are the hidden gold behind Perl!)
# Examples:
#   - set the table name for a model
#   Coat::Persistent::Meta->table_name('User', 'users');
#   - get the primary_key 
#   Coat::Persistent::Meta->primary_key('User');
#
sub _create_model_accessor { 
    my ($attribute) = @_;

    my $sub_class_accessor = sub {
        my ($self, $model, $value) = @_;
        (@_ == 2) 
            ? return $META->{$model}{$attribute}
            : return $META->{$model}{$attribute} = $value;
    };
    
    # the real magic occurs now!
    my $symbol = "Coat::Persistent::Meta::${attribute}";
    { 
        no strict 'refs'; 
        no warnings 'redefine';
        *$symbol = $sub_class_accessor; 
    }
}

# When the package is imported, define the symbols
sub import {
    _create_model_accessor($_) for @attributes;
    __PACKAGE__->export_to_level( 1, @_ );
}

1;
__END__
=pod

=head1 NAME

Coat::Persistent::Meta -- meta-information for Coat::Persistent objects

=head1 DESCRIPTION

The purpose of this class is to translate Model information into SQL
information. Coat::Persistent uses this class to store and retreive
meta-information about models and their database-related properties.

This class provides accessors (setters and getters) for each 
meta-information it handles.

These are the supported meta-information:

=over 4

=item B<table_name> : The table name associated to the model

=item B<primary_key> : The column in the table used as primary key

=back

=head1 SEE ALSO

L<Coat::Persistent>

=head1 AUTHOR

This module was written by Alexis Sukrieh E<lt>sukria@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
