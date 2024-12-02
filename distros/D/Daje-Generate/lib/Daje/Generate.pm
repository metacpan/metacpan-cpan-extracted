package  Daje::Generate;
use Mojo::Base -signatures;

use Daje::GenerateSQL;
use Daje::GenerateSchema;
use Daje::GeneratePerl;

our $VERSION = '0.09';

sub process ($self) {
    Daje::GenerateSQL->new(
        config_path => $self->config_path(),
    )->process();
    Daje::GenerateSchema->new(
        config_path => $self->config_path(),
    )->process();
    Daje::GeneratePerl->new(
        config_path => $self->config_path(),
    )->process();
}


1;



__END__

=encoding utf-8

=head1 NAME

Daje::Generate - It's new $module

=head1 SYNOPSIS

    use Daje::Generate;

=head1 DESCRIPTION

Daje::Generate is ...

=head1 LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

janeskil1525 E<lt>janeskil1525@gmail.comE<gt>

=cut

