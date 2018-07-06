package Data::MuForm::Field::URL;
# ABSTRACT: URL field
use Moo;
extends 'Data::MuForm::Field::Text';
use Regexp::Common ('URI');


has '+html5_input_type' => ( default => 'url' );

our $class_messages = {
    'invalid_url' => 'Invalid URL',
};

sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub validate {
  my ($self, $value) = @_;
  unless ( $value =~ qr/^$RE{URI}{HTTP}{-scheme => "https?"}$/ ) {
    $self->add_error($self->get_message('invalid_url'));
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::URL - URL field

=head1 VERSION

version 0.05

=head1 DESCRIPTION

A URL field;

=head1 NAME

Data::MuForm::Field::URL

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
