#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2025 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Systemd::Layers;
$Config::Model::Backend::Systemd::Layers::VERSION = '0.258.1';
use Mouse::Role;


sub default_directories {
    my $self = shift ;
    my $app = $self->node->instance->application;

    my @layers ;
    if ($app eq 'systemd-user') {
        @layers = (
            # paths documented by systemd-system.conf man page
            '/etc/systemd/user.conf.d/',
            '/run/systemd/user.conf.d/',
            '/usr/lib/systemd/user.conf.d/',
            # path found on Debian
            '/usr/lib/systemd/user/'
        );
    }
    elsif ($app !~ /file$/) {
        @layers = (
            # paths documented by systemd-system.conf man page
            '/etc/systemd/system.conf.d/',
            '/run/systemd/system.conf.d/',
            '/lib/systemd/system.conf.d/',
            # not documented but used to symlink to real files
            '/etc/systemd/system/',
            # path found on Debian
            '/lib/systemd/system/',
        );
    }

    return @layers;
}

1;

# ABSTRACT: Role that provides Systemd default directories

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::Systemd::Layers - Role that provides Systemd default directories

=head1 VERSION

version 0.258.1

=head1 SYNOPSIS

 package Config::Model::Backend::Systemd ;
 extends 'Config::Model::Backend::Any';
 with 'Config::Model::Backend::Systemd::Layers';

=head1 DESCRIPTION

Small role to provide Systemd default directories (user or system) to
L<Config::Model::Backend::Systemd> and L<Config::Model::Backend::Systemd::Unit>.

=head1 Methods

=head2 default_directories

Returns a list of default directory, depending on the application used (either
C<systemd> or C<systemd-user>.

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2025 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
