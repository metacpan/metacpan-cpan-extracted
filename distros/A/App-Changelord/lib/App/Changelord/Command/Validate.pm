package App::Changelord::Command::Validate;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Command::Validate::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey
    doc => 'validate the changelog yaml',
    description_pod => <<'END';
Validate the changelog against the JSON Schema used by changelord.
END

use Path::Tiny;
use JSON;
use YAML::XS;
use JSON::Schema::Modern;

with 'App::Changelord::Role::Changelog';

option json => (
    is => 'ro',
    default => 0,
    doc => 'output schema as json',
);

sub run($self) {
    local $YAML::XS::Boolean = 'boolean';

    my $schema = path(__FILE__)->sibling('changelog-schema.yml')->slurp;

    my $result = JSON::Schema::Modern->new(
        output_format => 'detailed',
    )->evaluate(
        $self->changelog,
        YAML::XS::Load($schema),
    );

    return say "woo, changelog is valid!" if( $result eq 'valid' );


    print $result;
    die "\n";

}

'end of App::Changelog::Command::Validate';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Validate

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
