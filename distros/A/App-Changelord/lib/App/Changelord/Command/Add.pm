package App::Changelord::Command::Add;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Command::Add::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey
    desc => 'add a change to the NEXT release',
    description_pod => <<'END';
Add a change entry to the NEXT release.
END

use PerlX::Maybe;
use Path::Tiny;
use App::Changelord::Command::Init;

with 'App::Changelord::Role::Changelog';

# TODO validate the type
option type => (
    format => 's',
    doc => 'type of change',
    is => 'ro',
);

option ticket => (
    format => 's',
    doc => 'associated ticket',
    is => 'ro',
);

sub is_next($self,$release) {
    my $version = $release->{version};
    return !$version || $version eq 'NEXT';
}

sub next_release($self) {
    my $changelog = $self->changelog;

    my $release = $changelog->{releases}[0];

    unless( $self->is_next($release) ) {
        unshift $changelog->{releases}->@*,
        $release = {
            version => 'NEXT',
            changes => [],
        };
    }

    return $release;
}

sub save_changelog($self) {
    my $src = $self->source;

    path($src)->spew( App::Changelord::Command::Init::serialize_changelog($self) );
}

sub run ($self) {
    my $version = $self->next_release;

    push $version->{changes}->@*, {
        maybe type => $self->type,
        maybe ticket => $self->ticket,
        desc => join ' ', @ARGV,
    };

    $self->save_changelog;

    say "change added to the changelog";
}

'end of App::Changelog::Command::Add';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Add

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
