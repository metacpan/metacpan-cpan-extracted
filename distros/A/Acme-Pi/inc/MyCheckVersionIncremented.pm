use strict;
use warnings;
package inc::MyCheckVersionIncremented;

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

sub before_release
{
    my $self = shift;

    my $dist_version = $self->zilla->version;
    my $last_dist_version = $self->_indexed_distversion_via_query('Acme::Pi');

    my $fatal = $last_dist_version ge $dist_version;
    $self->${ $fatal ? \'log_fatal' : \'log' }([ 'We are releasing %s version %s. The last distribution version was %s.', $self->zilla->name, $dist_version, $last_dist_version ]);
}

use HTTP::Tiny;
use HTTP::Headers;
use Encode ();
use YAML::Tiny;
use CPAN::DistnameInfo;

# copied from [PromptIfStale] - TODO use CPAN::Common::Index instead.
sub _indexed_distversion_via_query
{
    my ($self, $module) = @_;

    my $url = 'http://cpanmetadb.plackperl.org/v1.0/package/' . $module;
    $self->log_debug([ 'fetching %s', $url ]);
    my $res = HTTP::Tiny->new->get($url);
    $self->log('could not query the index?'), return undef if not $res->{success};

    my $data = $res->{content};

    if (my $charset = HTTP::Headers->new(%{ $res->{headers} })->content_type_charset)
    {
        $data = Encode::decode($charset, $data, Encode::FB_CROAK);
    }
    $self->log_debug([ 'got response: %s', $data ]);

    my $payload = YAML::Tiny->read_string($data);

    $self->log('invalid payload returned?'), return undef unless $payload;
    $self->log_debug([ '%s not indexed', $module ]), return undef if not defined $payload->[0]{version};
    return CPAN::DistnameInfo->new($payload->[0]{distfile})->version;
}

1;
