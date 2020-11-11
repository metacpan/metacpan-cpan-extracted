package inc::OSPrereqs;

use strict;
use warnings;
use namespace::autoclean;

use MetaCPAN::Client;

use Moose;

extends 'Dist::Zilla::Plugin::OSPrereqs';

# This fixes https://github.com/dagolden/Dist-Zilla-Plugin-OSPrereqs/issues/16
## no critic (ValuesAndExpressions::ProhibitInterpolationOfLiterals )
sub BUILDARGS {
    my ( $class, @arg ) = @_;
    my %copy = ref $arg[0] ? %{ $arg[0] } : @arg;

    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};
    my $os    = delete $copy{prereq_os};

    my @dashed = grep {/^-/} keys %copy;

    my %other;
    for my $dkey (@dashed) {
        ( my $key = $dkey ) =~ s/^-//;

        $other{$key} = delete $copy{$dkey};
    }

    Carp::confess "don't try to pass -_prereq as a build arg!"
        if $other{_prereq};

    return {
        zilla       => $zilla,
        plugin_name => $name,
        ( defined $os ? ( prereq_os => $os ) : () ),
        _prereq => \%copy,
        %other,
    };
}

my $FallbackVersion = '1.94';
my $Version;

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines )
sub _prereq {
    my $self = shift;

    return if $ENV{CI};

    return { 'DateTime::TimeZone::Local::Win32' => $Version }
        if $Version;

    my $release
        = MetaCPAN::Client->new->release('DateTime-TimeZone-Local-Win32');
    if ($release) {
        $Version = $release->version;
    }
    else {
        $Version = $FallbackVersion;
        $self->log_warning(
            "Could not find DateTime-TimeZone-Local-Win32 on MetaCPAN. Falling back to hard-coded version $FallbackVersion"
        );
    }

    return { 'DateTime::TimeZone::Local::Win32' => $Version };
}

__PACKAGE__->meta->make_immutable;

1;
