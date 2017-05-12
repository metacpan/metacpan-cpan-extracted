use 5.10.0;
use strict;
use warnings;

package Badge::Depot::Plugin::Kwalitee;

# ABSTRACT: Kwalitee badge for Badge::Depot
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0103';

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str HashRef/;
use Types::URI qw/Uri/;
use JSON::MaybeXS 'decode_json';
use Path::Tiny;
with 'Badge::Depot';


has author => (
    is => 'ro',
    isa => Str,
    default => '_',
);
has dist => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->get_meta('dist')) {
            return $self->_meta->{'dist'};
        }
    },
);
has version => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->get_meta('version')) {
            return $self->_meta->{'version'};
        }
    },
);
has base_url => (
    is => 'ro',
    isa => Uri,
    coerce => 1,
    lazy => 1,
    default => 'http://badgedepot.code301.com',
);
has custom_image_url => (
    is => 'ro',
    isa => Uri,
    coerce => 1,
    lazy => 1,
    builder => 1,
);

sub _build_custom_image_url  {
    my $self = shift;
    return sprintf '%s/badge/kwalitee/%s/%s/%s', $self->base_url, $self->author, $self->dist, $self->version;
}
has _meta => (
    is => 'ro',
    isa => HashRef,
    traits => ['Hash'],
    lazy => 1,
    predicate => 'has_meta',
    builder => '_build_meta',
    handles => {
        get_meta => 'get',
    },
);

sub _build_meta {
    my $self = shift;

    if($self->has_zilla) {
        return {
            dist => $self->zilla->name,
            version => $self->zilla->version,
        };
    }

    return {} if !path('META.json')->exists;

    my $json = path('META.json')->slurp_utf8;
    my $data = decode_json($json);

    return {} if !exists $data->{'name'} || !exists $data->{'version'};

    return {
        dist => $data->{'name'},
        version => $data->{'version'},
    };
}

sub BUILD {
    my $self = shift;
    $self->link_url(sprintf 'http://cpants.cpanauthors.org/release/%s/%s-%s', $self->author, $self->dist, $self->version);
    $self->image_url($self->custom_image_url);
    $self->image_alt('Distribution kwalitee');
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Badge::Depot::Plugin::Kwalitee - Kwalitee badge for Badge::Depot



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Badge-Depot-Plugin-Kwalitee"><img src="https://api.travis-ci.org/Csson/p5-Badge-Depot-Plugin-Kwalitee.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Badge-Depot-Plugin-Kwalitee-0.0103"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Badge-Depot-Plugin-Kwalitee/0.0103" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Badge-Depot-Plugin-Kwalitee%200.0103"><img src="http://badgedepot.code301.com/badge/cpantesters/Badge-Depot-Plugin-Kwalitee/0.0103" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-71.2%-red.svg" alt="coverage 71.2%" />
</p>

=end html

=head1 VERSION

Version 0.0103, released 2016-08-12.

=head1 SYNOPSIS

If used standalone:

    use Badge::Depot::Plugin::Kwalitee;

    my $badge = Badge::Depot::Plugin::Kwalitee->new(dist => 'The-Dist', version => '0.1002', author => 'AUTHORID');

    print $badge->to_html;
    # prints:
    <a href="http://cpants.cpanauthors.org/release/AUTHORID/The-Dist-0.1002">
        <img src="http://badgedepot.code301.com/badge/kwalitee/AUTHORID/The-Dist/0.1002" alt="Distribution kwalitee" />
    </a>

If used with L<Pod::Weaver::Section::Badges>, in weaver.ini:

    [Badges]
    ; other settings
    badge = kwalitee
    ; set author here
    -kwalitee_author = AUTHORID

=head1 DESCRIPTION

Creates a L<Kwalitee|http://cpants.cpanauthors.org> badge for a distribution.

This class consumes the L<Badge::Depot> role.

=head1 ATTRIBUTES

This badge tries to use distribution meta data to set the attributes. If that is available most attributes need not be set manually. The following checks are made:

=over 4

=item 1

If the badge is used via L<Pod::Weaver::Section::Badges> during a L<Dist::Zilla> build, then C<version> and C<dist> are set to the values in the Dist::Zilla object.

=item 2

If there is a C<META.json> in the distribution root then that is used to set C<version> and C<dist>.

=back

If neither of those are true, then you should also pass C<dist> and C<version> to the constructor.

=head2 author

The releaser's CPAN identity. Required.

=head2 dist

Distribution name. With dashes, not colons.

=head2 version

Distribution version.

=head2 base_url

Default: C<https://badgedepot.code301.com>

Set this if you wish to use another instance of L<Badge::Depot::App>.

=head1 SEE ALSO

=over 4

=item *

L<Badge::Depot>

=item *

L<Task::Badge::Depot>

=back

=cut

=head1 SOURCE

L<https://github.com/Csson/p5-Badge-Depot-Plugin-Kwalitee>

=head1 HOMEPAGE

L<https://metacpan.org/release/Badge-Depot-Plugin-Kwalitee>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
