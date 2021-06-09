package Amp::Client;
use Moo;
use Amp::DbPoolClient;
use Amp::Config;
use Data::Dumper;
use feature 'say';

our $VERSION = '0.03';

has config => (is => 'lazy');

sub dbh {
    my $self = shift;
    my $instance = shift;
    my $type = shift;
    if (defined $type && ($type eq "readonly" || $type eq "any")) {
        return $self->readClient($instance)
    }
    else {
        return $self->writeClient($instance)
    }
}

sub readClient {
    my $self = shift;
    my $instance = shift;

    return Amp::DbPoolClient->new(
        instanceName => $instance,
        type         => 'master',
        config       => $self->config
    );
}

sub writeClient {
    my $self = shift;
    my $instance = shift;

    return Amp::DbPoolClient->new(
        instanceName => $instance,
        type         => 'readonly',
        config       => $self->config
    );
}

sub _build_config {
    my $self = shift;
    return Amp::Config->new();
}

1;
__END__

=encoding utf-8

=head1 NAME

Amp::Client - Blah blah blah

=head1 SYNOPSIS

  use Amp::Client;

=head1 DESCRIPTION

Amp::Client is

=head1 AUTHOR

Russell Shingleton E<lt>reshingleton@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2021- Russell Shingleton

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
