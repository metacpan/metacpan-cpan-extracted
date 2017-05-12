package Const::Common;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

require Exporter;
use Data::Lock;

sub import {
    my $pkg   = caller;
    shift;
    my %constants = @_ == 1 ? %{ $_[0] } : @_;

    Data::Lock::dlock my $locked = \%constants;
    {
        no strict 'refs';
        ${ "$pkg\::_constants" } = $locked;
        for my $method (qw/const constants constant_names/) {
            *{ "$pkg\::$method" } = \&{ __PACKAGE__ . "::$method" };
        }
        push @{"$pkg\::ISA"}, ('Exporter');
        push @{"$pkg\::EXPORT"}, (keys %$locked);
    }

    require constant;
    @_ = ('constant', $locked);
    goto constant->can('import');
}

sub const {
    my ($pkg, $constant_name) = @_;
    $pkg->constants->{$constant_name};
}

sub constants {
    no strict 'refs';
    my $pkg = shift;
    ${ "$pkg\::_constants" };
}

sub constant_names {
    my $pkg = shift;
    sort keys %{ $pkg->constants };
}

1;
__END__

=encoding utf-8

=head1 NAME

Const::Common - Yet another constant definition module

=head1 SYNOPSIS

    package MyApp::Const;
    use Const::Common (
        BAR => 'BAZ',
        HASH => {
            HOGE => 'hoge',
        },
    );
    __END__

    use MyApp::Const;
    print BAR; # BAZ
    print HASH->{HOGE}; # hoge;
    HASH->{HOGE} = 10;  # ERROR!

=head1 DESCRIPTION

Const::Common is a module to define common constants in your project.

=head1 METHOD

=head2 C<< $hashref = $class->constants >>

=head2 C<< $array = $class->constant_names >>

=head2 C<< $value = $class->const($const_name) >>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
