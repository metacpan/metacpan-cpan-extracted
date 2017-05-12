#!/usr/bin/perl

package Catalyst::Plugin::Cache::Backend::Memory;
use Storable;

use strict;
use warnings;

use Storable qw/freeze thaw/;
    
sub new { bless {}, shift }

sub get { ${thaw($_[0]{$_[1]}) || return} };

sub set { $_[0]{$_[1]} = freeze(\$_[2]) };

sub remove { delete $_[0]{$_[1]} };

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Backend::Memory - Stupid memory based caching backend.

=head1 SYNOPSIS

    use Catalyst::Plugin::Cache::Backend::Memory;

    my $m = Catalyst::Plugin::Cache::Backend::Memory->new;

    $m->set( foo => "thing" );

=head1 DESCRIPTION

This backend uses L<Storable> to cache data in memory.

In combination with an engine like FastCGI/mod_perl/prefork which calls fork()
your cache will get async because child processes don't share cache in memory.

=cut


