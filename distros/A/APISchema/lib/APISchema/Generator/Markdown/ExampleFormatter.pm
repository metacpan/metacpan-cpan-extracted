package APISchema::Generator::Markdown::ExampleFormatter;
use 5.014;
use strict;
use warnings;

# lib
use APISchema::Generator::Markdown::Formatter qw(json);

# cpan
use URI::Escape qw(uri_escape_utf8);
use Class::Accessor::Lite (
    new => 1,
    ro => [qw(resolver spec)],
);

sub example {
    my $self = shift;
    return $self->resolver->example(@_);
}

sub header {
    my ($self) = @_;
    my $header = $self->spec->{header} or return '';
    my $resource = $header->definition or return '';
    my $example = $self->example($resource);

    return '' unless defined $example;
    return '' unless (ref $example) eq 'HASH';
    return '' unless scalar keys %$example;

    return join "\n", map {
        sprintf '%s: %s', $_ =~ s/[_]/-/gr, $example->{$_};
    } sort keys %$example;
}

sub parameter {
    my ($self) = @_;
    my $parameter = $self->spec->{parameter} or return '';
    my $resource = $parameter->definition or return '';
    my $example = $self->example($resource);

    return '' unless defined $example;
    return '' unless (ref $example) eq 'HASH';
    return '' unless scalar keys %$example;

    return '?' . join '&', map {
        # TODO multiple values?
        sprintf '%s=%s', map { uri_escape_utf8 $_ } $_, $example->{$_};
    } sort keys %$example;
}

sub body {
    my ($self) = @_;
    my $body = $self->spec->{body} or return '';
    my $resource = $body->definition or return '';
    my $example = $self->example($resource);

    return '' unless defined $example;

    return ref $example ? json($example) : $example;
}

sub header_and_body {
    my ($self) = @_;
    join("\n", grep { defined $_ && length $_ > 0 } $self->header, $self->body);
}

1;
