package Alt::Template::Plugin::JSON::Moo;
our $AUTHORITY = 'cpan:JwRIGHT';
our $VERSION = '0.01';

=pod

=encoding utf8

=head1 NAME

Alt::Template::Plugin::JSON::Moo - Alternate Template::Plugin::JSON - using Moo

=head1 SYNOPSIS

	> cpanm Alt::Template::Plugin::JSON::Moo 

	[% USE JSON %]

=head1 DESCRIPTION

This is a modification of L<Template::Plugin::JSON>, switching it from using L<Moose> to
using L<Moo> and L<Type::Tiny>.  This allows for the use of the JSON Template plugin
without loading Moose or causing the Moosification of all your Moo classes and
roles.

=head1 BUGS

The use of L<namespace::clean> necessitated the increase of the minimum perl version from
5.6 to 5.8.1.

=head1 SEE ALSO

=over

=item * L<Template::Plugin::JSON>

=item * L<Template>

=item * L<JSON>

=item * L<Moo>

=item * L<Alt>

=back

=cut

1;
