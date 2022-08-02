package App::Changelord::Command::Bump;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Command::Bump::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey desc => 'bump next version',
description_pod => <<'END';
Set a version for the NEXT release based on the types of its changes.
Also set the release date of that release to today.
END

use Path::Tiny;
use JSON;
use YAML           qw/ Bless /;
use List::AllUtils qw/ first min uniq /;
use Version::Dotted::Semantic;

with 'App::Changelord::Role::Changelog';
with 'App::Changelord::Role::ChangeTypes';
with 'App::Changelord::Role::Versions';
with 'App::Changelord::Role::Stats';

sub run ($self) {
    my $bump = shift @ARGV;

    if ( $bump and !grep { $_ eq $bump } qw/ minor major patch / ) {
        die "invalid bump type '$bump', must be major, minor, or patch\n";
    }

    my $version;

    if ($bump) {
        $version = Version::Dotted::Semantic->new( $self->latest_version );
        $version->bump($bump);
        $version = $version->stringify;
    }
    else {
        $version = $self->next_version;
    }

    if (    $self->changelog->{releases}[0]{version}
        and $self->changelog->{releases}[0]{version} ne 'NEXT' ) {
        warn
          "No change detected since last version, hope you know what you're doing.\n";
        unshift $self->changelog->{releases}->@*, { version => 'NEXT', };
    }

    my @time = localtime;

    $self->changelog->{releases}[0]{version} = $version;
    $self->changelog->{releases}[0]{date}    = sprintf "%d-%02d-%02d",
      $time[5] + 1900, $time[4], $time[3];

      if( $self->changelog->{project}{with_stats} ) {
          push $self->changelog->{releases}[0]{changes}->@*, {
              type => 'stats', desc => $self->stats
          };
      }

    my $change = $self->changelog;
    Bless($change)->keys(
        [   uniq qw/
              project releases change_types
              /, sort keys %$change
        ] );
    Bless( $change->{project} )->keys(
        [   uniq qw/
              name homepage
              /, sort keys $change->{project}->%*
        ] );

    for ( grep { ref } $change->{releases}->@* ) {
        Bless($_)->keys( [ uniq qw/ version date changes /, sort keys %$_ ] );
    }

    path( $self->source )->spew( YAML::Dump($change) );

    say "new version minted: $version";
}

'end of App::Changelog::Command::Bump';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Bump

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
