package Class::Init;

use 5.008001;
use strict;
use warnings;

use NEXT;

our @EXPORT = qw( new );
our @EXPORT_OK = @EXPORT;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '1.1';


# Preloaded methods go here.

sub _constructor ($;@) {
    # This gets called if all else fails to create $self.
    return bless { @_[1..$#_] }, $_[0];
}

sub new ($;@) {
    # Set $self to our parent's idea of new(), or otherwise just a simple blessed hashref.
    my $self = $_[0]->_constructor(@_[1..$#_]);
    # Scan the inheritance tree for initialization routines and execute them, top-down.
    $self->EVERY::LAST::_init(@_[1..$#_]);
    $self->_init(@_[1..$#_]) if defined &_init;

    $self;
}

sub _init ($;%) {
    # Install any default attributes into the object's hash.
    $_[0]->{$_[0+2*$_]} = $_[0]->{$_[1+2*$_]} for (1..($#_-1)/2);
}

1;
__END__

=head1 NAME

Class::Init - A base constructor class with support for local initialization methods.

=head1 SYNOPSIS

  package Something::Spiffy;
  use base qw(Class::Init);

  sub _init {
    my $self = shift;
    exists $self->{dsn} || die "parameter 'dsn' missing";
    $self->{_dbh} = DBI->connect($self->{dsn}) || die "DBI->connect failed";
  }

  package main;

  my $database = Something::Spiffy->new( dsn => '...' );
  my @users = $database->{_dbh}->...;

=head1 DESCRIPTION

Class::Init provides a constructor, C<new()>, that returns blessed hashrefs by
default; that constructor runs all instances of the subroutine C<_init> it
finds in the inheritance tree, top-down (C<EVERY>).

The goal of this module is to reduce the amount of effort required to construct
a simple object class; it helps reduce the amount of code that's duplicated
between classes by providing a generic constructor, while allowing individual
classes a low-effort way to publish their own changes to the new object.

=head1 AUTHOR

Richard Soderberg, E<lt>perl@crystalflame.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Richard Soderberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
