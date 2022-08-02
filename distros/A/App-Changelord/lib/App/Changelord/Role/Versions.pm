package App::Changelord::Role::Versions;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Role::Versions::VERSION = 'v0.0.1';
use v5.36.0;

use List::AllUtils qw/ first min /;
use Version::Dotted::Semantic;

use Moo::Role;

use feature 'try';

requires 'changelog';

sub latest_version($self){
    first { $_ } grep { $_ ne 'NEXT' } map { eval { $_->{version} || '' } } $self->changelog->{releases}->@*, { version => 'v0.0.0' };
}

sub next_version($self) {
    my $version = Version::Dotted::Semantic->new($self->latest_version // '0.0.0');

    my $upcoming = $self->changelog->{releases}[0];

    if( $upcoming->{version} and $upcoming->{version} ne 'NEXT') {
        $upcoming = { changes => [] };
    }

    my %mapping = map {
        my $level = $_->{level};
        map { $_ => $level } $_->{keywords}->@*
    } $self->change_types->@*;

    no warnings;
    my $bump =min 2, map { $_ eq 'major' ? 0 : $_ eq 'minor' ? 1 : 2 } map { $mapping{$_->{type}} || 'patch' }
    map { ref ? $_ : { desc => $_ } }
    $upcoming->{changes}->@*;

    $version->bump($bump);

    return $version->normal;
}

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Role::Versions

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
