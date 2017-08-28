package App::Muter::Backend::Uuencode;
# ABSTRACT: a uuencode transform for App::Muter
$App::Muter::Backend::Uuencode::VERSION = '0.002002';
use strict;
use warnings;

our @ISA = qw/App::Muter::Backend::Chunked/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new(
        $args, %opts,
        enchunksize => 45,
        dechunksize => 62,
    );
    return $self;
}

sub encode_chunk {    ## no critic(RequireArgUnpacking)
    my ($self, $data) = @_;
    return pack('u', $data);
}

sub encode_final {
    my ($self, $data) = @_;
    return $self->SUPER::encode_final($data) . "`\n";
}

sub decode_chunk {
    my ($self, $data) = @_;
    return '' unless length $data;
    return unpack('u', $data);
}

App::Muter::Registry->instance->register(__PACKAGE__);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Muter::Backend::Uuencode - a uuencode transform for App::Muter

=head1 VERSION

version 0.002002

=head1 AUTHOR

brian m. carlson <sandals@crustytoothpaste.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016–2017 by brian m. carlson.

This is free software, licensed under:

  The MIT (X11) License

=cut
