use strict;
use warnings;

package Badge::Depot::Plugin::Travis;

use Moose;
use namespace::autoclean;
use Types::Standard qw/Str HashRef/;
use Path::Tiny;
use JSON::MaybeXS 'decode_json';
with 'Badge::Depot';

# ABSTRACT: Travis plugin for Badge::Depot
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0203';

has user => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->has_meta) {
            return $self->_meta->{'username'} if exists $self->_meta->{'username'};
        }
    },
);
has repo => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->has_meta) {
            return $self->_meta->{'repo'} if exists $self->_meta->{'repo'};
        }
    },
);
has branch => (
    is => 'ro',
    isa => Str,
    default => 'master',
);
has _meta => (
    is => 'ro',
    isa => HashRef,
    predicate => 'has_meta',
    builder => '_build_meta',
);

sub _build_meta {
    my $self = shift;

    return {} if !path('META.json')->exists;

    my $json = path('META.json')->slurp_utf8;
    my $data = decode_json($json);

    return {} if !exists $data->{'resources'}{'repository'}{'web'};

    my $repository = $data->{'resources'}{'repository'}{'web'};
    return {} if $repository !~ m{^https://(?:www\.)?github\.com/([^/]+)/(.*)(?:\.git)?$};

    return {
        username => $1,
        repo => $2,
    };
}

sub BUILD {
    my $self = shift;
    $self->link_url(sprintf 'https://travis-ci.org/%s/%s', $self->user, $self->repo);
    $self->image_url(sprintf 'https://api.travis-ci.org/%s/%s.svg?branch=%s', $self->user, $self->repo, $self->branch);
    $self->image_alt('Travis status');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Badge::Depot::Plugin::Travis - Travis plugin for Badge::Depot



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Badge-Depot-Plugin-Travis"><img src="https://api.travis-ci.org/Csson/p5-Badge-Depot-Plugin-Travis.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Badge-Depot-Plugin-Travis-0.0203"><img src="https://badgedepot.code301.com/badge/kwalitee/Badge-Depot-Plugin-Travis/0.0203" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Badge-Depot-Plugin-Travis%200.0203"><img src="https://badgedepot.code301.com/badge/cpantesters/Badge-Depot-Plugin-Travis/0.0203" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-67.3%-red.svg" alt="coverage 67.3%" />
</p>

=end html

=head1 VERSION

Version 0.0203, released 2016-04-09.

=head1 SYNOPSIS

    use Badge::Depot::Plugin::Travis;

    my $badge = Badge::Depot::Plugin::Travis->new(user => 'my_name', repo => 'the_repo', branch => 'master');

    print $badge->to_html;
    # prints '<a href="https://travis-ci.org/my_name/my_repo"><img src="https://api.travis-ci.org/my_name/my_repo.svg?branch=master" /></a>'

=head1 DESCRIPTION

Create a L<Travis|https://travis-ci.org> badge for a github repository.

This class consumes the L<Badge::Depot> role.

=head1 ATTRIBUTES

The C<user> and C<repo> attributes are required or optional, depending on your configuration. It looks for the C<resources/repository/web> setting in C<META.json>:

=over 4

=item *

If C<META.json> doesn't exist in the dist root, C<user> and C<repo> are required.

=item *

If C<resources/repository/web> doesn't exist (or is not a github url), C<user> and C<repo> are required.

=back

=head2 user

Github username.

=head2 repo

Github repository.

=head2 branch

Github branch. Optional, C<master> by default.

=head1 SEE ALSO

=over 4

=item *

L<Badge::Depot>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Badge-Depot-Plugin-Travis>

=head1 HOMEPAGE

L<https://metacpan.org/release/Badge-Depot-Plugin-Travis>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
