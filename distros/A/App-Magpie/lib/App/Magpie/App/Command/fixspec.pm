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

package App::Magpie::App::Command::fixspec;
# ABSTRACT: update a spec file to match some policies
$App::Magpie::App::Command::fixspec::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
"Update a spec file from a perl module package, and make sure it follows
a list of various policies. Also update the list of build prereqs."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::FixSpec;
    App::Magpie::Action::FixSpec->new->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::fixspec - update a spec file to match some policies

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    $ eval $( magpie co -s perl-Foo-Bar )
    $ magpie fixspec

    # to get list of available options
    $ magpie help fixspec

=head1 DESCRIPTION

This command will update a spec file from a perl module package, and
make sure it follows a list of various policies. It will also update the
list of build prereqs, according to F<META.yml> (or F<META.json>)
shipped with the distribution.

Note that this command will abort if it finds that the spec is too much
outdated (eg, not using C<%perl_convert_version>)

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
