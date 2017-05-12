package Data::YADV;

use strict;
use warnings;
use v5.008_001;

our $VERSION = '0.001';

use Data::YADV::Structure;
use String::CamelCase 'camelize';

sub new {
    my ($class, $structure, %args) = @_;

    $args{error_handler} ||= \&_error_handler;

    bless {%args, structure => Data::YADV::Structure->new($structure)},
      $class;
}

sub check {
    my ($self, $schema, @path) = @_;
    
    my $module = $self->schema_to_module($schema);
    my $child  = $self->{structure}->get_child(@path);
    $self->build_checker($module, $child)->verify();
}

sub schema_to_module {
    my ($self, $schema) = @_;

    'Schema::' . camelize($schema);
}

sub build_checker {
    my ($self, $module, @args) = @_;

    $module->new(
        @args,
        schema   => $self,
        error_cb => $self->{error_handler}
    );
}

sub _error_handler {
    my ($path, $message) = @_;
    warn "$path: $message\n";
}

1;
__END__

=head1 NAME

Data::YADV - Yet Another Data Validator

=head1 SYNOPSIS

See t/schema.t for usage examples

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 AUTHOR

Sergey Zasenko

=cut
