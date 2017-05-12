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

package App::Magpie::App::Command::sort;
# ABSTRACT: sort packages needing a rebuild according to their requires
$App::Magpie::App::Command::sort::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
"This command will sort a list of packages to be rebuilt so that
dependencies are followed."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'input|i=s'
            => "file with list of packages to be sorted (default: STDIN)"
            => { default => "-" } ],
        [ 'output|o=s'
            => "file with list of sorted packages (default: STDOUT)"
            => { default => "-" } ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::Sort;
    App::Magpie::Action::Sort->new->run( $opts );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::sort - sort packages needing a rebuild according to their requires

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    $ urpmf --requires :perlapi-5.16 | perl -pi -E 's/:.*//' | magpie sort

    # to get list of available options
    $ magpie help sort

=head1 DESCRIPTION

This command will sort a list of packages to be rebuilt so that
dependencies are followed.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
