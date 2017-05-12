use 5.006;
use strict;
use warnings;

package Data::Freq::Field;

=head1 NAME

Data::Freq::Field - Controls counting with Data::Freq at each level

=cut

use Carp qw(croak);
use Date::Parse qw(str2time);
use Scalar::Util qw(looks_like_number);
require POSIX;

=head1 METHODS

=head2 new

Usage:

    Data::Freq::Field->new({
        type    => 'text' , # { 'text' | 'number' | 'date' }
        sort    => 'count', # { 'value' | 'count' | 'first' | 'last' }
        order   => 'desc' , # { 'asc' | 'desc' }
        pos     => 0      , # { 0 | 1 | 2 | -1 | -2 | .. | [0, 1, 2] | .. }
        key     => 'mykey', # { any key(s) for input hash refs }
        convert => sub {...},
    });

Constructs a field object.

See L<Data::Freq/field specification> for details.

=cut

sub new {
    my ($class, $input) = @_;
    my $self = bless {}, $class;
    
    if (!ref $input) {
        $self->_extract_any($input) or croak "invalid argument: $input";
    } elsif (ref $input eq 'HASH') {
        for my $target (qw(type aggregate sort order pos key)) {
            if (defined $input->{$target}) {
                my $method = "_extract_$target";
                
                $self->$method($input->{$target})
                        or croak "invalid $target: $input->{$target}";
            }
        }
        
        for my $target (qw(offset limit)) {
            if (defined $input->{$target}) {
                $self->{$target} = int($input->{$target});
            }
        }
        
        for my $target (qw(convert)) {
            if (defined $input->{$target}) {
                $self->{$target} = $input->{$target};
                
                if (ref $input->{$target} ne 'CODE') {
                    croak "$target must be a CODE ref";
                }
            }
        }
    } elsif (ref $input eq 'ARRAY') {
        for my $item (@$input) {
            $self->_extract_any($item) or croak "invalid argument: $item";
        }
    } else {
        croak "invalid field: $input";
    }
    
    $self->{type} = 'text' unless defined $self->type;
    $self->{aggregate} ||= 'count';
    
    if ($self->type eq 'text') {
        $self->{sort} ||= 'score';
    } else {
        $self->{sort} ||= 'value';
    }
    
    if ($self->{sort} =~ /^(count|score|last)$/) {
        $self->{order} ||= 'desc';
    } else {
        $self->{order} ||= 'asc';
    }
    
    return $self;
}

=head2 evaluate_record

Usage:

    my $field = Data::Freq::Field->new(...);
    my $record = Data::Freq::Record->new(...);
    my $normalized_text = $field->evaluate_record($record);

Evaluates an input record as a normalized text that will be used for frequency counting,
depending on the parameters passed to the L<new()|/new> method.

This is intended to be an internal method for L<Data::Freq>.

=cut

sub evaluate_record {
    my ($self, $record) = @_;
    my $result = undef;
    
    TRY: {
        if (defined $self->pos) {
            my $pos = $self->pos;
            my $array = $record->array or last TRY;
            $result = "@$array[@$pos]";
        } elsif (defined $self->key) {
            my $key = $self->key;
            my $hash = $record->hash or last TRY;
            $result = "@$hash{@$key}";
        } elsif ($self->type eq 'date') {
            $result = $record->date;
        } elsif ($self->type eq 'number') {
            my $array = $record->array or last TRY;
            $result = $array->[0];
        } else {
            $result = $record->text;
        }
        
        last TRY unless defined $result;
        
        if ($self->type eq 'date') {
            $result = looks_like_number($result) ? $result : str2time($result);
            last TRY unless defined $result;
            $result = POSIX::strftime($self->strftime, localtime $result);
        }
    }
    
    if ($self->convert) {
        $result = $self->convert->($result);
    }
    
    return $result;
}

=head2 select_nodes

Usage:

    my $raw_node_list = [values %{$parent_node->children}];
    my $sorted_node_list = $field->select_nodes($raw_node_list);

Sorts and reduces a list of nodes (Data::Freq::Node) at the corresponding depth
in the L<frequency tree|Data::Freq/frequency tree>,
depending on the parameters passed to the L<new()|/new> method.

This is intended to be an internal method for L<Data::Freq>.

=cut

sub select_nodes {
    my ($self, $nodes, $subfield) = @_;
    my $type  = $self->type;
    my $sort  = $self->sort;
    my $order = $self->order;
    
    if ($sort eq 'score') {
        if ($subfield) {
            $sort = $subfield->aggregate;
        } else {
            $sort = 'count';
        }
    }
    
    my @tuples = map {[$_, $_->$sort, $_->first]} @$nodes;
    
    if ($type ne 'number' && $sort eq 'value') {
        if ($order eq 'asc') {
            @tuples = CORE::sort {$a->[1] cmp $b->[1] || $a->[2] <=> $b->[2]} @tuples;
        } else {
            @tuples = CORE::sort {$b->[1] cmp $a->[1] || $a->[2] <=> $b->[2]} @tuples;
        }
    } else {
        if ($order eq 'asc') {
            @tuples = CORE::sort {$a->[1] <=> $b->[1] || $a->[2] <=> $b->[2]} @tuples;
        } else {
            @tuples = CORE::sort {$b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]} @tuples;
        }
    }
    
    my @result = map {$_->[0]} @tuples;
    
    if (defined $self->offset || defined $self->limit) {
        my $offset = defined $self->offset ? $self->offset : 0;
        my $length = defined $self->limit ? $self->limit : scalar(@result);
        @result = splice(@result, $offset, $length);
    }
    
    return \@result;
}

=head2 type

Retrieves the C<type> parameter.

=head2 aggregate

Retrieves the C<aggregate> parameter.

=head2 sort

Retrieves the C<sort> parameter.

=head2 order

Retrieves the C<order> parameter.

=head2 pos

Retrieves the C<pos> parameter as an array ref.

=head2 key

Retrieves the C<key> parameter as an array ref.

=head2 limit

Retrieves the C<limit> parameter.

=head2 offset

Retrieves the C<offset> parameter.

=head2 strftime

Retrieves the C<strftime> parameter (L<POSIX::strftime()|POSIX/strftime>).

=head2 convert

Retrieves the C<convert> parameter.

=cut

sub type      {$_[0]{type    }}
sub aggregate {$_[0]{aggregate}}
sub sort      {$_[0]{sort    }}
sub order     {$_[0]{order   }}
sub pos       {$_[0]{pos     }}
sub key       {$_[0]{key     }}
sub limit     {$_[0]{limit   }}
sub offset    {$_[0]{offset  }}
sub strftime  {$_[0]{strftime}}
sub convert   {$_[0]{convert }}

sub _extract_any {
    my ($self, $input) = @_;
    
    for my $target (qw(pos type aggregate sort order)) {
        my $method = "_extract_$target";
        return $self if $self->$method($input);
    }
    
    return undef;
}

sub _extract_type {
    my ($self, $input) = @_;
    return undef if ref($input);
    
    if (!defined $input || $input eq '' || $input =~ /^texts?$/i) {
        $self->{type} = 'text';
        return $self;
    } elsif ($input =~ /^num(ber)?s?$/i) {
        $self->{type} = 'number';
        return $self;
    } elsif ($input =~ /\%/) {
        $self->{type} = 'date';
        $self->{strftime} = $input;
        return $self;
    } elsif ($input =~ /^years?$/i) {
        $self->{type} = 'date';
        $self->{strftime} = '%Y';
        return $self;
    } elsif ($input =~ /^month?s?$/i) {
        $self->{type} = 'date';
        $self->{strftime} = '%Y-%m';
        return $self;
    } elsif ($input =~ /^(date|day)s?$/i) {
        $self->{type} = 'date';
        $self->{strftime} = '%Y-%m-%d';
        return $self;
    } elsif ($input =~ /^hours?$/i) {
        $self->{type} = 'date';
        $self->{strftime} = '%Y-%m-%d %H';
        return $self;
    } elsif ($input =~ /^minutes?$/i) {
        $self->{type} = 'date';
        $self->{strftime} = '%Y-%m-%d %H:%M';
        return $self;
    } elsif ($input =~ /^(seconds?|time)?$/i) {
        $self->{type} = 'date';
        $self->{strftime} = '%Y-%m-%d %H:%M:%S';
        return $self;
    }
    
    return undef;
}

sub _extract_aggregate {
    my ($self, $input) = @_;
    return undef if !defined $input || ref($input) || $input eq '';
    
    if ($input =~ /^uniq(ue)?$/) {
        $self->{aggregate} = 'unique';
        return $self;
    } elsif ($input =~ /^max(imum)?$/) {
        $self->{aggregate} = 'max';
        return $self;
    } elsif ($input =~ /^min(imum)?$/) {
        $self->{aggregate} = 'min';
        return $self;
    } elsif ($input =~ /^av(g|e(rage)?)?$/) {
        $self->{aggregate} = 'average';
        return $self;
    }
    
    return undef;
}

sub _extract_sort {
    my ($self, $input) = @_;
    return undef if !defined $input || ref($input) || $input eq '';
    
    if ($input =~ /^values?$/i) {
        $self->{sort} = 'value';
        return $self;
    } elsif ($input =~ /^counts?$/i) {
        $self->{sort} = 'count';
        return $self;
    } elsif ($input =~ /^scores?$/i) {
        $self->{sort} = 'score';
        return $self;
    } elsif ($input =~ /^(first|occur(rence)?s?)$/i) {
        $self->{sort} = 'first';
        return $self;
    } elsif ($input =~ /^last$/i) {
        $self->{sort} = 'last';
        return $self;
    }
    
    return undef;
}

sub _extract_order {
    my ($self, $input) = @_;
    return undef if !defined $input || ref($input) || $input eq '';
    
    if ($input =~ /^asc(end(ing)?)?$/i) {
        $self->{order} = 'asc';
        return $self;
    } elsif ($input =~ /^desc(end(ing)?)?$/i) {
        $self->{order} = 'desc';
        return $self;
    }
    
    return undef;
}

sub _extract_pos {
    my ($self, $input) = @_;
    return undef if !defined $input;
    
    if (ref $input eq 'ARRAY') {
        $self->{pos} ||= [];
        push @{$self->{pos}}, @$input;
        return $self;
    } elsif ($input =~ /^-?\d+$/) {
        $self->{pos} ||= [];
        push @{$self->{pos}}, $input;
        return $self;
    }
    
    return undef;
}

sub _extract_key {
    my ($self, $input) = @_;
    return undef if !defined $input;
    
    $self->{key} ||= [];
    push @{$self->{key}}, (ref($input) eq 'ARRAY' ? @$input : ($input));
    return $self;
}

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
