package API::Docker::Type::Plugin::Config::Linux;
# ABSTRACT: The Linux-specific capabilities and devices a plugin needs
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::PluginDevice;
use namespace::clean;


docker capabilities => [Str];


docker allow_all_devices => Bool;


docker devices => [ 'PluginDevice' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Config::Linux - The Linux-specific capabilities and devices a plugin needs

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Linux> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 capabilities

Undocumented upstream. The Linux capabilities the plugin's process needs,
C<CAP_SYS_ADMIN> and C<CAP_SYSLOG> in the swagger's example.

=head2 allow_all_devices

Undocumented upstream. A boolean, C<false> in the swagger's example,
required beside the explicit L</devices> list.

=head2 devices

Undocumented upstream. The device list that stands beside
L</allow_all_devices>. See L<API::Docker::Type::PluginDevice>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
