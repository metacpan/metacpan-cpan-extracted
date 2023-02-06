package App::Toot::Test;

use strict;
use warnings;

use parent 'Test::More';

our $VERSION = '0.03';

sub import {
    my $class = shift;
    my %args  = @_;

    warnings->import;
    strict->import;

    if ( $args{tests} ) {
        $class->builder->plan( tests => $args{tests} )
            unless $args{tests} eq 'no_declare';
    }
    elsif ( $args{skip_all} ) {
        $class->builder->plan( skip_all => $args{skip_all} );
    }

    Test::More->export_to_level(1);

    require Test::Exception;
    Test::Exception->export_to_level(1);

    require Test::Warnings;

    return;
}

sub override {
    my %args = (
        package => undef,
        name    => undef,
        subref  => undef,
        @_,
    );

    eval "require $args{package}";

    my $fullname = sprintf "%s::%s", $args{package}, $args{name};

    no strict 'refs';
    no warnings 'redefine', 'prototype';
    *$fullname = $args{subref};

    return;
}

1;

=pod

=head1 NAME

App::Toot::Test - testing module for App::Toot tests

=head1 SYNOPSIS

 use App::Toot::Test;

=head1 DESCRIPTION

C<App::Toot::Test> can be used in tests to automatically import testing modules and provides methods to mock and override.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Blaine Motsinger under the MIT license.

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
