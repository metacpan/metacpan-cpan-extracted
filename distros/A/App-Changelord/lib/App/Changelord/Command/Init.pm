package App::Changelord::Command::Init;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Command::Init::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey desc => 'initialize new changelog source file';

use Path::Tiny;
use JSON;
use YAML           qw/ Bless /;
use List::AllUtils qw/ first min uniq /;
use Version::Dotted::Semantic;

with 'App::Changelord::Role::ChangeTypes';
with 'App::Changelord::Role::Changelog';
with 'App::Changelord::Role::Versions';

sub serialize_changelog($self, $changelog = undef) {

    $changelog //= $self->changelog;

    Bless($changelog)->keys(
        [   uniq qw/
              project releases change_types
              /, sort keys %$changelog
        ] );
    Bless( $changelog->{project} )->keys(
        [   uniq qw/
              name homepage
              /, sort keys $changelog->{project}->%*
        ] );

    for ( grep { ref } $changelog->{releases}->@* ) {
        Bless($_)->keys( [ uniq qw/ version date changes /, sort keys %$_ ] );
    }

    return YAML::Dump($changelog);
}

sub run ($self) {
    my $src = $self->source;
    die "file '$src' already exists, aborting\n" if -f $src;

    my $change = {
        project => {
            name => undef,
            homepage => undef,
            with_stats => 'true',
            ticket_url => undef,
            commit_regex => q/^(?<type>[^: ]+):(?<desc>.*?)(\[(?<ticket>[^\]]+)\])?$/,
        },
        change_types => $self->change_types,
        releases => [
            { version => 'NEXT', changes => [] }
        ]
    };
    path($src)->spew( $self->serialize_changelog($change) );

    say "file '$src' created, enjoy!";
}

'end of App::Changelog::Command::Init';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Init

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
