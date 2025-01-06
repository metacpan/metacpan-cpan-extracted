package My::Module::Build;

use strict;
use warnings;

use Module::Build;
our @ISA = qw{ Module::Build };

use Carp;
# use lib 'inc';	# Already done because this module is running.
use My::Module::Recommend;

sub ACTION_authortest {
##  my ( $self, @args ) = @_;	# Arguments unused
    my ( $self ) = @_;

    $self->depends_on( qw{ functional_test optionals_test structural_test } );

    return;
}

sub ACTION_functional_test {
    my ( $self ) = @_;

    local $ENV{AUTHOR_TESTING} = 1;

    $self->my_depends_on();

    print <<'EOD';

functional_test
AUTHOR_TESTING=1
EOD

    # Not depends_on(), because that is idempotent. But we really do
    # want to run 'test' more than once if we do more than one of the
    # *_test actions.
    $self->dispatch( 'test' );

    return;
}

sub ACTION_optionals_test {
    my ( $self ) = @_;

    my $optionals = join ',', My::Module::Recommend->optionals();
    local $ENV{AUTHOR_TESTING} = 1;
    local $ENV{PERL5OPT} = "-MTest::Without::Module=$optionals";

    $self->my_depends_on();

    print <<"EOD";

optionals_test
AUTHOR_TESTING=1
PERL5OPT=-MTest::Without::Module=$optionals
EOD

    # Not depends_on(), because that is idempotent. But we really do
    # want to run 'test' more than once if we do more than one of the
    # *_test actions.
    $self->dispatch( 'test' );

    return;
}

sub ACTION_structural_test {
    my ( $self ) = @_;

    local $ENV{AUTHOR_TESTING} = 1;

    $self->my_depends_on();

    print <<'EOD';

structural_test
AUTHOR_TESTING=1
EOD

    my $structural_test_files = 'xt/author';
    if ( $self->can( 'args' ) ) {
	my @arg = $self->args();
	for ( my $inx = 0; $inx < $#arg; $inx += 2 ) {
	    $arg[$inx] =~ m/ \A structural[-_]test[-_]files \z /smx
		or next;
	    $structural_test_files = $arg[ $inx + 1 ];
	    last;
	}
    }
    $self->test_files( $structural_test_files );

    # Not depends_on(), because that is idempotent. But we really do
    # want to run 'test' more than once if we do more than one of the
    # *_test actions.
    $self->dispatch( 'test' );

    return;
}

sub my_depends_on {
    my ( $self ) = @_;
    my @depends_on;
    -d 'blib'
	or push @depends_on, 'build';
    -e 'META.json'
	or push @depends_on, 'distmeta';
    @depends_on
	and $self->depends_on( @depends_on );
    return;
}

sub harness_switches {
    my ( $self ) = @_;
    my @res = $self->SUPER::harness_switches();
    foreach ( @res ) {
	'-MDevel::Cover' eq $_
	    or next;
	$_ .= '=-db,cover_db,-ignore,inc/,-ignore,eg/';
    }
    return @res;
}

1;

__END__

=head1 NAME

Astro::SpaceTrack::Build - Extend Module::Build for PPIx::Regexp

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build authortest # supplied by this module
 ./Build install

=head1 DESCRIPTION

This extension of L<Module::Build|Module::Build> adds actions to those
provided by L<Module::Build|Module::Build>.

=head1 ACTIONS

This module provides the following actions:

=over

=item authortest

This action does nothing on its own, but it depends on
L<functional_test|/functional_test>, L<optionals_test|/optionals_test>,
and L<structural_test|/structural_test>, so invoking it runs all these
tests.

=item functional_test

This action is the same as C<test>, but the C<AUTHORTEST> environment
variable is set to true.

This test is sensitive to both the C<verbose> argument and the
C<test-files> argument.

=item optionals_test

This action is the same as C<test>, but the C<AUTHORTEST> environment
variable is set to true, and the C<PERL5OPT> environment variable is set
to C<-MTest::Without::Module=...>, where the elipsis is a
comma-separated list of all optional modules.

This test is sensitive to both the C<verbose> argument and the
C<test-files> argument.

=item structural_test

This action is the same as C<test>, but the C<AUTHORTEST> environment
variable is set to true, and the test files are F<xt/author>.

Some of these tests require modules that are not named as requirements.
Such tests should disable themselves if the required modules are not
present.

This test is sensitive to the C<verbose> argument and the
C<structural-test-files> argument, which specifies test files to run and
defaults to F<xt/author>. The use of C<structural-test-files> requires
at least L<Module::Build|Module::Build> version C<0.26>.

=back

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2011-2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
