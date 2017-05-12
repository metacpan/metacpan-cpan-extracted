#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::checkout;
# ABSTRACT: check-out or update a given package
$App::Magpie::App::Command::checkout::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub command_names { qw{ checkout co }; }

sub description {
"Check out a package from Mageia repository, or update the local
check-out if it already exists."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'directory|d=s' => "directory where to check out"    ],
        [ 'shell|s'       => "display Bourne shell commands to execute to change directory" ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    # sanity check
    my $pkg = shift @$args;
    $self->usage_error( "A package should be specified." )
        unless defined $pkg;

    # do the checkout
    $self->log_init($opts);
    require App::Magpie::Action::Checkout;
    my $pkgdir = App::Magpie::Action::Checkout->new->run($pkg, $opts->{directory});

    # display command to execute if shell mode
    say "cd $pkgdir" if $opts->{shell};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::checkout - check-out or update a given package

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    $ magpie checkout perl-Foo-Bar
    $ magpie co -d ~/rpm/cauldron -q perl-Foo-Bar
    $ eval $( magpie co -s perl-Foo-Bar )

    # to get list of available options
    $ magpie help checkout

=head1 DESCRIPTION

This command will check out a package from Mageia repository, or update
a local check-out if it already exists. It uses the C<mgarepo> command
underneath, so you might want to look at this command for more
information.

The "shell" option (C<--shell> / C<-s>) is especially useful if you
C<eval> the result of this command, to go directly in the fresh
check-out directory. In that case, you may want to add the following to
your F<~/.bashrc>:

    function cco() { eval $(magpie co -d ~/rpm/cauldron -q -s $*); }

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
