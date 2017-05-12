package CPAN::Diff::Module;
use Moo;

has name          => (is => 'rw', required => 1);
has local_version => (is => 'rw');
has cpan_version  => (is => 'rw');
has cpan_dist     => (is => 'rw');

1;

=encoding utf-8

=head1 NAME

CPAN::Diff::Module - Object representing module metadata

=head1 SYNOPSIS

    use CPAN::Diff::Module;

    my $module = CPAN::Diff::Module->new(
        name          => 'Acme::Color',
        local_version => '0.01',
        cpan_version  => '0.02',
        cpan_dist     => $dist, # a CPAN::DistnameInfo object
    );

    $module->name;
    $module->local_version;
    $module->cpan_version;
    $module->cpan_dist;



=head1 DESCRIPTION

Object representing module metadata.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut
