package App::CpanfileSlipstop::Resolver;
use strict;
use warnings;

use CPAN::Meta::Requirements;

sub new {
    my ($class, %args) = @_;

    my $self = bless +{
        reqs      => CPAN::Meta::Requirements->new,
        cpanfile  => $args{cpanfile}, # Module::CPANfile
        snapshot  => $args{snapshot}, # Carton::Snapshot
    }, $class;

    return $self;
}

sub reqs     { $_[0]->{reqs}     }
sub cpanfile { $_[0]->{cpanfile} }
sub snapshot { $_[0]->{snapshot} }

sub read_cpanfile_requirements {
    my ($self) = @_;

    for my $phase (qw(configure build runtime test develop)) {
        $self->reqs->add_requirements(
            $self->cpanfile->prereqs->requirements_for($phase, 'requires')
        );
    }
    # `carton install` only treats 'requires'.
    # https://metacpan.org/source/MIYAGAWA/Carton-v1.0.34/lib/Carton/CPANfile.pm#L38

    return;
}

sub merge_snapshot_versions {
    my ($self, $merge_method, $with_core) = @_;

    my $find_method = $with_core ? 'find_or_core' : 'find';

    my $cpanfile_modules = [ keys %{$self->reqs->as_string_hash} ];

    for my $module (@$cpanfile_modules) {
        next if $self->ignore_module($module); # skip modules url specified

        my $installed_dist = $self->snapshot->$find_method($module);
        if ($installed_dist) {
            my $version = $installed_dist->version_for($module);
            $self->reqs->$merge_method($module, $version) if $version;
        }
    }
}

sub ignore_module {
    my ($self, $module) = @_;

    # ignore like this.
    #
    #   requires 'Class::Enumemon',
    #       mirror => 'https://cpan.metacpan.org/',
    #       dist   => 'POKUTUNA/Class-Enumemon-0.01.tar.gz';

    my $opts = $self->cpanfile->options_for_module($module) || {};
    return 1 if $opts->{dist};
    return 1 if $opts->{url};
    return 0;
}

sub get_version_range {
    my ($self, $module) = @_;

    my $version_range = $self->reqs->requirements_for_module($module);

    return undef if !$version_range || $version_range eq '0';

    # Remove noisy '>= 0'.
    # This causes when setting version by "add_maximum"
    $version_range =~ s/\A>= 0, //;

    return $version_range;
}

1;
