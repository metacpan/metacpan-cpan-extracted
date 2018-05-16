package DTTZBundle;

use strict;
use warnings;
use namespace::autoclean;

use MetaCPAN::Client;

use Moose;

extends 'Dist::Zilla::PluginBundle::DROLSKY';

my $FallbackVersion = '1.94';
override configure => sub {
    my $self = shift;
    super();

    return if $ENV{TRAVIS};

    my $version;
    my $release
        = MetaCPAN::Client->new->release('DateTime-TimeZone-Local-Win32');
    if ($release) {
        $version = $release->version;
    }
    else {
        $version = $FallbackVersion;
        $self->log_warning(
            "Could not find DateTime-TimeZone-Local-Win32 on MetaCPAN. Falling back to hard-coded version $FallbackVersion"
        );
    }

    $self->add_plugins(
        [
            'OSPrereqs' => 'MSWin32' => {
                'DateTime::TimeZone::Local::Win32' => $version,
            }
        ],
    );

    return;
};

__PACKAGE__->meta->make_immutable;

1;
