package App::Changelord::Role::Changelog;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Role::Changelog::VERSION = 'v0.0.1';
use v5.36.0;

use Moo::Role;
use CLI::Osprey;

option source => (
    is => 'ro',
    format => 's',
    doc => q{changelog yaml file. Defaults to the env variable $CHANGELOG, or 'CHANGELOG.yml'},
    default => $ENV{CHANGELOG} || 'CHANGELOG.yml',
);

has changelog => ( is => 'lazy' );

sub _build_changelog($self) {
    return YAML::LoadFile($self->source)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Role::Changelog

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
