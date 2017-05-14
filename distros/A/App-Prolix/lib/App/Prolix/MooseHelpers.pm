package App::Prolix::MooseHelpers;
# ABSTRACT: Moose helpers for App::Prolix

use Moose ();
use Moose::Exporter;
use warnings;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'has_counter', 'has_rw', 'has_option' ]);

sub has_rw {
    my ($meta, $name, %options) = @_;
    $meta->add_attribute(
        $name,
        is => 'rw',
        %options
    );
}

sub has_option {
    my ($meta, $name, %options) = @_;
    $meta->add_attribute(
        $name,
        is => 'rw',
        metaclass => 'Getopt',
        %options
    );
}

sub has_counter {
    my ($meta, $name, %options) = @_;
    $meta->add_attribute(
        $name,
        traits => ['Counter'],
        is => 'ro',
        isa     => 'Num',
        default => 0,
        handles => {
            ('inc_' . $name)   => 'inc',
            ('dec_' . $name)   => 'dec',
            ('reset_' . $name) => 'reset',
        },
        %options
    );
}

6;


__END__
=pod

=head1 NAME

App::Prolix::MooseHelpers - Moose helpers for App::Prolix

=head1 VERSION

version 0.03

=head1 AUTHOR

Gaal Yahas <gaal@forum2.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Google, Inc.

This is free software, licensed under:

  The MIT (X11) License

=cut

