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

package App::Magpie::App::Command::dwim;
# ABSTRACT: automagically update Mageia packages
$App::Magpie::App::Command::dwim::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
"Automatically update Perl modules which aren't up to date in Mageia."
}

sub opt_spec {
    my $self = shift;
    return (
        [ 'directory|d=s' => "directory where update will be done" ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    $self->log_init($opts);
    require App::Magpie::Action::DWIM;
    App::Magpie::Action::DWIM->new->run( $opts->{directory} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::dwim - automagically update Mageia packages

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    $ magpie dwim

    # to get list of available options
    $ magpie help olddwim

=head1 DESCRIPTION

This command will check all installed Perl modules, and update the
Mageia packages that have a new version available on CPAN.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
