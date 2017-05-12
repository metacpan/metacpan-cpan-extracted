package Data::DynamicValidator::Label;
{
  $Data::DynamicValidator::Label::VERSION = '0.03';
}
# ABSTRACT: Class holds label and allows extract current value under it in subject

use strict;
use warnings;

use overload fallback => 1,
    q/""/  => sub { $_[0]->to_string },
    q/&{}/ => sub {
        my $self = shift;
        return sub { $self->value }
    };

sub new {
    my ($class, $label_name, $path, $data) = @_;
    my $self = {
        _name  => $label_name,
        _path  => $path,
        _data  => $data,
    };
    bless $self => $class;
}


sub to_string {
    my $self = shift;
    $self->{_path}->named_component($self->{_name});
}

sub value {
    my $self = shift;
    $self->{_path}->value($self->{_data}, $self->{_name});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DynamicValidator::Label - Class holds label and allows extract current value under it in subject

=head1 VERSION

version 0.03

=head1 METHODS

=head2 to_string

Stringizes to the value of label under current path

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
