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

package App::Magpie::App::Command::update;
# ABSTRACT: update a perl module to its latest version
$App::Magpie::App::Command::update::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub command_names { qw{ update refresh }; }

sub description {

"Update a perl module package to its latest version, try to rebuild it,
commit and submit if successful."

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
    require App::Magpie::Action::Update;
    App::Magpie::Action::Update->new->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::update - update a perl module to its latest version

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    $ eval $( magpie co -s perl-Foo-Bar )
    $ magpie update

    # to get list of available options
    $ magpie help update

=head1 DESCRIPTION

This command will update a perl module package to its latest version,
try to build it locally, commit and submit if successful.

Note that this command will abort if it finds that the spec is too much
outdated (eg, not using C<%define upstream_version>).

This command requires a C<CPAN::Mini> installation on the computer.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
