package DTTZBundle;

use strict;
use warnings;
use namespace::autoclean;

use MetaCPAN::Client;

use Moose;

extends 'Dist::Zilla::PluginBundle::DROLSKY';

use Dist::Zilla::Plugin::OSPrereqs;
if ( Dist::Zilla::Plugin::OSPrereqs->VERSION <= 0.011 ) {

    # This fixes https://github.com/dagolden/Dist-Zilla-Plugin-OSPrereqs/issues/16

## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
    eval <<'EOF';
{
package Dist::Zilla::Plugin::OSPrereqs;
no warnings 'redefine';
sub BUILDARGS {
    my ( $class, @arg ) = @_;
    my %copy = ref $arg[0] ? %{ $arg[0] } : @arg;

    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};
    my $os    = delete $copy{prereq_os};

    my @dashed = grep { /^-/ } keys %copy;

    my %other;
    for my $dkey (@dashed) {
        ( my $key = $dkey ) =~ s/^-//;

        $other{$key} = delete $copy{$dkey};
    }

    Carp::confess "don't try to pass -_prereq as a build arg!" if $other{_prereq};

    return {
        zilla       => $zilla,
        plugin_name => $name,
        ( defined $os ? ( prereq_os => $os ) : () ),
        _prereq     => \%copy,
        %other,
    };
}
}
EOF
}

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
                prereq_os                          => 'MSWin32',
                'DateTime::TimeZone::Local::Win32' => $version,
            }
        ],
    );

    return;
};

__PACKAGE__->meta->make_immutable;

1;
