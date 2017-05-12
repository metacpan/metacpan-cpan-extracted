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

package App::Magpie::App::Command::webstatic;
# ABSTRACT: create a static web site
$App::Magpie::App::Command::webstatic::VERSION = '2.010';
use App::Magpie::App -command;


# -- public methods

sub description {
"This command generates a static web site with some statistics &
information on Perl modules available in Mageia Linux."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [
            'directory|d=s'
                => "directory where website will be created"
                => { required => 1 }
        ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::WebStatic;
    App::Magpie::Action::WebStatic->new->run($opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::webstatic - create a static web site

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This command generates a static web site with some statistics &
information on Perl modules available in Mageia Linux.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
