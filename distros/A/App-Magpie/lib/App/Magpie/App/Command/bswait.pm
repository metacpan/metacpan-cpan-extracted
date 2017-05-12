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

package App::Magpie::App::Command::bswait;
# ABSTRACT: pause according to build-system recommendations
$App::Magpie::App::Command::bswait::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
"Pauses according to the recommendation of Mageia build-system.
Build-system provides some recommendation on how much time to pause
between 2 packages submission to not overload it - this is known as
throttling."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'nosleep|n!'  => "don't sleep" ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::BSWait;
    App::Magpie::Action::BSWait->new->run($opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::bswait - pause according to build-system recommendations

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This command pauses according to the recommendation of Mageia
build-system. Indeed, instead of pushing all your packages to be
rebuilt, it's better to throttle them one at a time. Build-system
provides some recommendation on how much to pause between 2 packages -
and this command uses this hint to pause accordingly.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
