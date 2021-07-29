package My::Module::Build;

use strict;
use warnings;

use 5.010;

use Module::Build;
our @ISA = qw{ Module::Build };

use My::Module::Meta;

use Carp;

sub ACTION_test {
    my ( $self, @args ) = @_;

    -e 'META.json'
	or $self->depends_on( 'distmeta' );

    $self->depends_on( 'build' );

    return $self->SUPER::ACTION_test( @args );
}

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

    state $meta = My::Module::Meta->new();
    my $optionals = join ',', $meta->optionals_for_testing();
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

1;

__END__

=head1 NAME

My::Module::Build - Extend Module::Build for Date::ManipX::Almanac

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build authortest # supplied by this module
 ./Build install

=head1 DESCRIPTION

This extension of L<Module::Build|Module::Build> adds the following
action to those provided by L<Module::Build|Module::Build>:

  authortest

=head1 ACTIONS

This module provides the following actions:

=head2 authortest

This action runs not only those tests which appear in the F<t>
directory, but those that appear in the F<xt> directory. The F<xt> tests
are provided for information only, since some of them (notably
F<xt/critic.t> and F<xt/pod_spelling.t>) are very sensitive to the
configuration under which they run.

Some of the F<xt> tests require modules that are not named as
requirements. These should disable themselves if the required modules
are not present.

This action is sensitive to the C<verbose=1> argument, but not to the
C<--test_files> argument.

This action also creates the F<META.*> files if needed.

=head2 test

This action overrides the core C<test> action to create the F<META.*>
files if needed.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-ManipX-Almanac>,
L<https://github.com/trwyant/perl-Date-ManipX-Almanac/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
