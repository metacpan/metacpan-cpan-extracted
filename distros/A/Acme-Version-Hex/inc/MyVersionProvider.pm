use strict;
use warnings;
package inc::MyVersionProvider;

use Moose;
with 'Dist::Zilla::Role::VersionProvider';

sub provide_version
{
    my $self = shift;

    my $assign_regex = qr/our\s+\$VERSION\s*=\s*(0x(?:\d*\.)?\d+p[+-]\d+)\s*;/;
    my $eval_regex = qr/\$VERSION\s*=\s*eval\s*\$VERSION;/;
    my ($version, $eval) = $self->zilla->main_module->content=~ m{^$assign_regex\s*($eval_regex)?[^\n]*$}ms;
    $self->log([ 'got version %s', $version ]);

    $version = eval $version if $eval;
    $self->log([ 'evaluated version to %s', $version ]) if $eval;

    return $version;
}

{
    package Dist::Zilla::Dist::Builder;

    # override name used for the full distribution name to keep the version in hex
    no warnings 'redefine';
    sub dist_basename {
      my ($self) = @_;
      return join(q{},
        $self->name,
        '-',
        sprintf('%a', $self->version),  # the changed line
      );
    }
}

{
    package Dist::Zilla::Plugin::NextRelease;
    use Moose;
    __PACKAGE__->meta->make_mutable;
    around fill_in_string => sub
    {
        my $orig = shift;
        my $self = shift;
        my ($content, $params) = @_;

        $content = $self->$orig($content, $params);

        my $orig_version = ${ $params->{version} };
        my $new_version = sprintf('%a', $orig_version);
        $new_version .= ' ' x (List::Util::min(length($orig_version), 8) - length($new_version));

        $content =~ s/^Revision history for Acme-Version-Hex\n\n\K$orig_version(\s+)/$new_version$1/;
        return $content;
    };
}

{
    package Dist::Zilla::Plugin::Test::ChangesHasContent;
    use Moose;
    __PACKAGE__->meta->make_mutable;
    around fill_in_string => sub
    {
        my $orig = shift;
        my $self = shift;
        my ($content, $params) = @_;

        $self->$orig($content, { %$params, newver => sprintf('%a', $params->{newver}) });
    };
}

1;
