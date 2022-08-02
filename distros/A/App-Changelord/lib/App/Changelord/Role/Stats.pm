package App::Changelord::Role::Stats;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Role::Stats::VERSION = 'v0.0.1';
use v5.36.0;

use Git::Repository;

use Moo::Role;

use feature 'try'; no warnings qw/ experimental /;

requires 'changelog';

# stolen from Dist::Zilla::Plugin::ChangeStats::Git

has repo => (
    is => 'ro',
    default => sub { Git::Repository->new( work_tree => '.' ) },
);

has stats => (
    is => 'lazy' );

sub _build_stats ($self) {
    my $comparison_data = $self->_get_comparison_data or return;

        my $stats = 'code churn: ' . $comparison_data;
        return $stats =~ s/\s+/ /gr;
}

sub _get_comparison_data($self) {

    # HEAD versus previous release
    # What are we diffing against? :)
    my $previous = $self->changelog->{releases}->@* > 1
        ? $self->changelog->{releases}[1]{version}
        : '4b825dc642cb6eb9a060e54bf8d69288fbee4904'; # empty tree

    my $output = eval {
            $self->repo->run( 'diff', '--shortstat', $previous, 'HEAD')
        };


    warn "could not gather stats: $@\n" if $@;

    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Role::Stats

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
