package App::Milter::Limit::Config;
$App::Milter::Limit::Config::VERSION = '0.52';
# ABSTRACT: Milter Limit configuration object

use strict;
use base qw(Class::Singleton Class::Accessor);
use Config::Tiny;

__PACKAGE__->mk_accessors(qw(config));


sub _new_instance {
    my ($class, $config_file) = @_;

    my $config = Config::Tiny->read($config_file)
        or die "failed to read config file: ", Config::Tiny->errstr;

    # set defaults
    $config->{_}{name} ||= 'milter-limit';
    $config->{_}{state_dir} ||= '/var/run/milter-limit';

    my $self = $class->SUPER::_new_instance({config => $config});

    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    my $conf = $self->global;
    if (my $user = $$conf{user}) {
        $$conf{user} = App::Milter::Limit::Util::get_uid($user);
    }

    if (my $group = $$conf{group}) {
        $$conf{group} = App::Milter::Limit::Util::get_gid($group);
    }
}


sub global {
    my $self = shift;
    $self->instance->config->{_};
}


sub section {
    my ($self, $name) = @_;
    $self->instance->config->{$name};
}


sub set_defaults {
    my ($self, $section, %defaults) = @_;

    $section = '_' if $section eq 'global';

    my $conf = $self->instance->config->{$section}
        or die "config section [$section] does not exist in the config file\n";

    for my $key (keys %defaults) {
        unless (defined $$conf{$key}) {
            $$conf{$key} = $defaults{$key};
        }
    }
}

1;

__END__

=pod

=head1 NAME

App::Milter::Limit::Config - Milter Limit configuration object

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 # pass config file name first time.
 my $conf = App::Milter::Limit::Config->instance('/etc/mail/milter-limit.conf');

 # after that, just call instance()
 $conf = App::Milter::Limit::Config->instance();

 # global config section
 my $global = $conf->global;
 my $limit = $global->{limit};

 # log section
 my $log_conf = $conf->section('log');
 my $ident = $log_conf->{identity};

 # driver section
 my $driver = $conf->section('driver');
 my $home = $driver->{home};

=head1 DESCRIPTION

C<App::Milter::Limit::Config> is holds the configuration data for milter-limit.  The
configuration data is read from an ini-style config file as a C<Config::Tiny>
object.

=head1 METHODS

=head2 instance $config_file

reads the ini style configuration from C<$config_file> and returns the
C<Config::Tiny> object

=head2 instance

get the configuration I<Config::Tiny> object.

=head2 global

get global configuration section (hashref)

=head2 section

get the configuration for the given section name

=head2 set_defaults $section, %defaults

set default values for a config section.  This will fill in the values from
C<%defaults> in the given C<$section> name if the keys are not already set.
Most likely you would call this as part of your plugin's C<init()> method to
set plugin specific defaults.

=for Pod::Coverage init

=head1 SEE ALSO

L<Config::Tiny>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/milter-limit>
and may be cloned from L<git://github.com/mschout/milter-limit.git>

=head1 BUGS

Please report any bugs or feature requests to bug-app-milter-limit@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Milter-Limit

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
