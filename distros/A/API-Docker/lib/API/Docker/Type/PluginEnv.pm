package API::Docker::Type::PluginEnv;
# ABSTRACT: One entry of C<Plugin.Config.Env>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str, required => 1;


docker description => Str, required => 1;


docker settable => [Str], required => 1;


docker value => Str, required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PluginEnv - One entry of C<Plugin.Config.Env>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PluginEnv> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<Plugin.Config.Env>. None of its four fields is described, but
the example the swagger gives for that field shows all four at once: C<Name>
C<"DEBUG">, C<Description> C<"If set, prints debug messages">, C<Settable>
C<null> and C<Value> C<"0">.

=head2 name

Undocumented upstream. The variable's name, C<"DEBUG"> in that example. The
swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 description

Undocumented upstream. What setting it does, C<"If set, prints debug
messages"> in that example. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 settable

Undocumented upstream. An array of strings, C<null> in that example, and the
swagger never says what they hold. What a user changes on an installed
plugin goes in through C<POST /plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 value

Undocumented upstream. The value it currently has, C<"0"> in that example --
a string, even where it reads as a number. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
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
