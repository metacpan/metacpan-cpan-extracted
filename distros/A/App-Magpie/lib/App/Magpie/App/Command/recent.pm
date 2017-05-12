#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use strict;
use warnings;

package App::Magpie::App::Command::recent;
# ABSTRACT: Recent uploads on PAUSE not available in Mageia
$App::Magpie::App::Command::recent::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
"This command checks what has been recently (1 day) uploaded on PAUSE
which is not available in Mageia."
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
    require App::Magpie::Action::Recent;
    App::Magpie::Action::Recent->new->run($opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::recent - Recent uploads on PAUSE not available in Mageia

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This command checks what has been recently (1 day) uploaded on PAUSE
which is not available in Mageia. Interesting to see what could be done
to extend Perl support in Mageia.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
