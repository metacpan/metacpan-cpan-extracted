package App::Changelord::Command::Schema;
our $AUTHORITY = 'cpan:YANICK';
# SYNOPSIS: print out the changelog schema
$App::Changelord::Command::Schema::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey
    doc => 'print JSON schema for the changelog format',
    description_pod => <<'END';
Print the JSON schema describing the data format used by changelord.

By defaults prints the schema in YAML. Can also be printed as JSON
via the C<--json> option.
END

use Path::Tiny;
use JSON;
use YAML;

option json => (
    is => 'ro',
    default => 0,
    doc => 'output schema as json',
);

sub run($self) {

    my $schema = YAML::Load(path(__FILE__)->sibling('changelog-schema.yml')->slurp);

    print $self->json ? JSON->new->pretty->encode(YAML::Load($schema)) : YAML::Dump($schema);
}

'end of App::Changelog::Command::Schema';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Schema

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
