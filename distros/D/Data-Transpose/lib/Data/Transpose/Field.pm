package Data::Transpose::Field;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Field - Field class for Data::Transpose

=head1 SYNOPSIS

     $field = $tp->field('email');

=head1 METHODS

=head2 new

    $field = Data::Transpose::Field->new(name => 'email');

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

has name => (is => 'rw',
             required => 1,
             isa => Str);

has target => (is => 'rw',
               isa => Str);

has _raw => (is => 'rwp');
has _output => (is => 'rwp');
has _filters => (is => 'ro',
                 isa => ArrayRef,
                 default => sub { [] },
               );

=head2 name

Set name of the field:

    $field->name('fullname');

Get name of the field:

    $field->name;

=head2 value

Initializes field value and returns value for output:
    
    $new_value = $self->value($raw_value);

=cut

sub value {
    my $self = shift;
    my $token;
    
    if (@_) {
        $self->_set__raw(shift);
        $token = $self->_raw;
        $self->_set__output($self->_apply_filters($token));
    }

    return $self->_output;
}

=head2 target

Set target name for target operation:

    $field->target('name');

Get target name:

    $field->target;

=head2 filter

Adds a filter to the filter chain:
    
    $field->filter($code);

Returns field object.

=cut

sub filter {
    my ($self, $filter) = @_;

    if (ref($filter) eq 'CODE') {
        push @{$self->_filters}, $filter;
    }

    return $self;
}

sub _apply_filters {
    my ($self, $token) = @_;
    
    for my $f (@{$self->_filters}) {
        $token = $f->($token);
    }

    return $token;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
