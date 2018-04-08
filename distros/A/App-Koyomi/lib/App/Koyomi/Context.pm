package App::Koyomi::Context;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/config/],
);
use DateTime;
use Module::Load;

use App::Koyomi::Config;

use version; our $VERSION = 'v0.6.1';

my $CONTEXT;

sub instance {
    my $class = shift;
    $CONTEXT //= sub {
        return bless +{
            config => App::Koyomi::Config->instance,
        }, $class;
    }->();
    return $CONTEXT;
}

sub datasource_job {
    my $self = shift // __PACKAGE__->instance;
    my $ds_module
        = sprintf 'App::Koyomi::DataSource::Job::%s', $self->config->{datasource}{module}{job};
    load $ds_module;
    $ds_module->instance(ctx => $self);
}

sub datasource_semaphore {
    my $self = shift // __PACKAGE__->instance;
    my $ds_module
        = sprintf 'App::Koyomi::DataSource::Semaphore::%s', $self->config->{datasource}{module}{semaphore};
    load $ds_module;
    $ds_module->instance(ctx => $self);
}

sub now {
    my $self = shift;
    DateTime->now(time_zone => $self->config->time_zone);
}

sub is_debug {
    my $self = shift;
    return 1 if $ENV{KOYOMI_DEBUG};
    my $debug_mode = $self->config->{debug_mode} // q{};
    return 1 if ($debug_mode eq 'true');
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Context> - koyomi application context

=head1 SYNOPSIS

    use App::Koyomi::Context;
    my $ctx = App::Koyomi::Context->instance;

=head1 DESCRIPTION

This module represents Singleton context object.

=head1 METHODS

=over 4

=item B<instance>

Fetch context singleton.

=item B<datasource_schedule>

Fetch schedule datasource object.

=back

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

