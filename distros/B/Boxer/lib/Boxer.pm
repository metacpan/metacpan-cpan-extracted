package Boxer;

=encoding UTF-8

=head1 NAME

Boxer - system deployment ninja tricks

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;

use Module::Find;
use Module::Load::Conditional qw(can_load);
use Log::Any qw($log);

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

=head1 SYNOPSIS

    use Boxer;

    my $domain = Boxer->get_world('Reclass')->new( suite => 'stretch', data => 'examples' );
    say $domain->list_parts();

    my $goal = $domain->get_part('lxp5');
    my $plan = $domain->map( $goal, 1 );
    $plan->as_file( Boxer::File::WithSkeleton->new( basename => 'preseed.cfg' ) );

    my $serializer = Boxer::File::WithSkeleton->new( skeleton => 'script.sh.in' );
    $plan->as_file( $serializer->file( 'script.sh', 1 ) );

    my $anothergoal = $domain->get_part('parl-greens');
    my $anotherplan = $domain->map($anothergoal);
    $anotherplan->as_file( $serializer->file( 'parl-greens.sh', 1 ) );

    my $newdomain = Boxer->get_world()->new( suite => 'buster', data => 'examples' );
    my $plan_a    = $newdomain->map($goal);
    $plan_a->as_file( Boxer::File::WithSkeleton->new( basename => 'preseed_pure.cfg' ) );

=head1 DESCRIPTION

Framework for system deployment ninja tricks.

See L<boxer> for further information.

=cut

sub list_worlds ($self)
{
	return findsubmod Boxer::World;
}

sub get_world
{
	my ( $self, $name ) = @_;

	$name ||= 'flat';

	foreach my $world ( $self->list_worlds() ) {
		if ( lc( substr( $world, -( length($name) + 2 ) ) ) eq lc("::$name") )
		{
			unless ( can_load( modules => { $world => 0 } ) ) {
				$log->error($Module::Load::Conditional::ERROR);
				return;
			}
			return $world;
		}
	}
	$log->error("No world \"$name\" found");
	return;
}

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Boxer>.

=head1 SEE ALSO

L<Debian Installer|https://www.debian.org/devel/debian-installer/>,
L<tasksel|https://www.debian.org/doc/manuals/debian-faq/ch-pkgtools.en.html#s-tasksel>,
L<debconf preseeding|https://wiki.debian.org/DebianInstaller/Preseed>,
L<Hands-off|http://hands.com/d-i/>

L<Debian Pure Blends|https://wiki.debian.org/DebianPureBlends>

L<Footprintless>

L<FAI class system|https://fai-project.org/fai-guide/#defining%20classes>

L<Elbe commands|https://elbe-rfs.org/docs/sphinx/elbe.html>

L<isar|https://github.com/ilbers/isar>

L<Debathena config-package-dev|https://debathena.mit.edu/config-packages/>

L<germinate|https://wiki.ubuntu.com/Germinate>

L<https://freedombox.org/>,
L<https://solidbox.org/>,
L<https://wiki.debian.org/Design>,
L<https://wiki.debian.org/DebianParl>,
L<http://box.redpill.dk/>

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2013-2016 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
