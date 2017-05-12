package CatalystX::Features::Plugin::ConfigLoader;
$CatalystX::Features::Plugin::ConfigLoader::VERSION = '0.26';
use warnings;
use strict;
use Carp;
use base qw/Catalyst::Plugin::ConfigLoader/; 
use MRO::Compat;

sub find_files {
    my $c = shift;
    my @files = $c->next::method(@_);

    my $appname = ref $c || $c;

    foreach my $feature ( $c->features->list ) {
        my $suffix = Catalyst::Utils::env_value( $appname, 'CONFIG_LOCAL_SUFFIX' )
            || $c->config->{ 'Plugin::ConfigLoader' }->{ config_local_suffix }
            || 'local';

        my @normal = map { $feature->name.".".$_ }  @{ Config::Any->extensions };
        my @local = map { $feature->name."_${suffix}.".$_ }  @{ Config::Any->extensions };
        push @files, map { Path::Class::dir($feature->path, $_)->stringify } @normal, @local;
    }
    return @files;
}

=head1 NAME

CatalystX::Features::Plugin::ConfigLoader - Makes ConfigLoader know about features

=head1 VERSION

version 0.26

=head1 SYNOPSIS

	/MyApp/features/my.simple.feature_1.23/my.simple.feature.conf
		
=head1 DESCRIPTION

Loads config files from features. The feature config file should have the feature
name, plus the regular your usual C<C::P::ConfigLoaded> config extensions.

The config values will be merged into the main app config hash. That means
the feature is allowed to change the main app config values. 

=head1 TODO

=over 4

=item * Warn when there are duplicate values.

=back

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
