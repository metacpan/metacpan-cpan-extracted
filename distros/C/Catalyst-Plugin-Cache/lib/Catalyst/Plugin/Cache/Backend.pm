#!/usr/bin/perl

package Catalyst::Plugin::Cache::Backend;

use strict;
use warnings;

sub set {
    my ( $self, $key, $value ) = @_;
}

sub get {
    my ( $self, $key ) = @_;
}

sub remove {
    my ( $self, $key ) = @_;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Backend - Bare minimum backend interface.

=head1 SYNOPSIS

	use Catalyst::Plugin::Cache::Backend;

=head1 DESCRIPTION

This is less than L<Cache::Cache>.

=cut


