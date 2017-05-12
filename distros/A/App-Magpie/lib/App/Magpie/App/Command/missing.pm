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

package App::Magpie::App::Command::missing;
# ABSTRACT: List modules shipped by Mageia not present locally
$App::Magpie::App::Command::missing::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
'This command lists Perl modules shipped by Mageia but not present on
the local system. This is especially useful if one wants to run "magpie
old" afterwards.'
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
    require App::Magpie::Action::Missing;
    App::Magpie::Action::Missing->new->run($opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::missing - List modules shipped by Mageia not present locally

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This command lists Perl modules shipped by Mageia but not present on the
local system. This is especially useful if one wants to run "magpie old"
afterwards.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
