package App::Changelord::Command::Print;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Command::Print::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey
    desc => 'print the changelog',
    description_pod => <<'END';
Render the full changelog. The default is to render the changelog
in markdow, but the option C<--json> can be used to have a JSON
version instead.

To generate the changelog without the NEXT release, uses the
C<--no-next> option.
END

with 'App::Changelord::Role::Changelog';
with 'App::Changelord::Role::ChangeTypes';
with 'App::Changelord::Role::Render';

option json => (
    is => 'ro',
    default => 0,
    doc => 'output schema as json',
);

option next => (
    is => 'ro',
    default => 1,
    negatable => 1,
    doc => 'include the NEXT release. Defaults to true.',
);

sub run($self) {
    no warnings 'utf8';
    print $self->as_markdown( $self->next );
}

'end of App::Changelog::Command::Print';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Print

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
