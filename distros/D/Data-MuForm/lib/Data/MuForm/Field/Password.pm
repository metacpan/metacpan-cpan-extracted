package Data::MuForm::Field::Password;
# ABSTRACT: password field

use Moo;
extends 'Data::MuForm::Field::Text';


has '+password'         => ( default => 1 );
sub build_input_type { 'password' }

our $class_messages = {
    'required' => 'Please enter a password in this field',
};

sub get_class_messages  {
    my $self = shift;
    my $messages = {
        %{ $self->next::method },
        %$class_messages,
    };
    return $messages;
}


after 'field_validate' => sub {
    my $self = shift;

    if ( !$self->required && !( defined( $self->value ) && length( $self->value ) ) ) {
        $self->no_update(1);
        $self->clear_errors;
    }
};

sub validate {
    my $self = shift;

    $self->no_update(0);
    $self->next::method;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Password - password field

=head1 VERSION

version 0.05

=head1 DESCRIPTION

The password field has a default minimum length of 6, which can be
easily changed:

  has_field 'password' => ( type => 'Password', minlength => 7 );

It does not come with additional default checks, since password
requirements vary so widely. There are a few constraints in the
L<Data::MuForm::Types> modules which could be used with this
field:  NoSpaces, WordChars, NotAllDigits.
These constraints can be used in the field definitions 'apply':

   use Data::MuForm::Types ('NoSpaces', 'WordChars', 'NotAllDigits' );
   ...
   has_field 'password' => ( type => 'Password',
          apply => [ NoSpaces, WordChars, NotAllDigits ],
   );

If a password field is not required and nothing has been submitted,
then the field will be marked 'no_update' to keep from overwriting a
password in the database will a null.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
