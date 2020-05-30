package Storage::Setup;

use strict;
use warnings;
use Test::Roo::Role;
use MySchema;
use DBIx::Class::ParseError;

requires 'connect_info';

has schema => (
    is => 'lazy',
);

sub _build_schema { MySchema->connect( shift->connect_info ) }

has sources => (
    is => 'ro', predicate => 1,
);

has parser => (
    is => 'lazy', handles => [qw(db_driver)],
);

sub _build_parser {
    my $self = shift;
    DBIx::Class::ParseError->new(
        schema        => $self->schema,
        custom_errors => $self->custom_errors
    );
}

has custom_errors => (
    is      => 'ro',
    builder => '_build_custom_errors',
);

sub _build_custom_errors { {} }

before setup => sub {
    my $self = shift;
    $self->schema->deploy({
        $self->has_sources ? ( sources => $self->sources ) : ()
    });
};

sub test_parse_error {
    my ($self, $args) = @_;
    my ($desc, $type, $table, $source_name, $error_str)
        = @$args{qw(desc type table source_name error_str)};
    ok($error_str, $desc);
    my $parser = $self->parser;
    my $error = $parser->process($error_str);
    is($error_str, $error, 'stringfy');
    isa_ok($error, 'DBIx::Class::Exception', '::ParseError::Error');
    is($error_str, $error->message, 'same error str in message');
    is($error->type, $type, 'error type');
    is($error->table, $table, 'target table');
    is($error->source_name, $source_name, 'source name');
    return $error;
}

1;
