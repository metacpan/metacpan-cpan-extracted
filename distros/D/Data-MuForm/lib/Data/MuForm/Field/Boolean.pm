package Data::MuForm::Field::Boolean;
# ABSTRACT: a true or false field

use Moo;
extends 'Data::MuForm::Field::Checkbox';
our $VERSION = '0.03';


sub value {
    my $self = shift;

    my $v = $self->next::method(@_);

    return $v ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Boolean - a true or false field

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This field returns 1 if true, 0 if false.  The widget type is 'Checkbox'.
Similar to Checkbox, except only returns values of 1 or 0.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
