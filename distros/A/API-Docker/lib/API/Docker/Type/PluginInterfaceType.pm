package API::Docker::Type::PluginInterfaceType;
# ABSTRACT: One entry of C<Plugin.Config.Interface.Types>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker prefix => Str, required => 1;


docker capability => Str, required => 1;


docker version => Str, required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PluginInterfaceType - One entry of C<Plugin.Config.Interface.Types>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PluginInterfaceType> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one entry of C<Plugin.Config.Interface.Types>. The example the
swagger gives for that field is the bare string C<docker.volumedriver/1.0>
rather than an object, and its three parts line up with the three fields
below in the order they appear.

=head2 prefix

Undocumented upstream. C<docker> in that example. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 capability

Undocumented upstream. C<volumedriver> in that example. The swagger lists
this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 version

Undocumented upstream. C<1.0> in that example. The swagger lists this field
as required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

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
