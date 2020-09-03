use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::FilterItem;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0104';

use Carp qw/croak confess/;
use Safe::Isa qw/$_isa/;
use Scalar::Util qw/blessed/;
use Moo;

use experimental qw/signatures postderef/;

# parts, resultset and value (and nothing else) are constructor args
has parts => (
    is => 'rw',
    required => 1,
    default => sub { [] },
);
has resultset => (
    is => 'rw',
    required => 1,
    default => sub { undef },
);
has value => (
    is => 'rw',
    required => 1,
);

# so these are *not* constructor args
for my $scalar_arg (qw/left_hand_prefix operator sql_operator column_name/) {
    has $scalar_arg => (
        is => 'rw',
        default => sub { undef },
    );
}
has left_hand_functions => (
    is => 'rw',
    default => sub { [] },
);
has quote_value => (
    # it's a boolean!
    is => 'rw',
    default => sub { 1 },
);

around BUILDARGS => sub ($orig, $class, %args) {
    if(exists $args{'resultset'} && exists $args{'value'}) {
        if(blessed $args{'value'}) {
            my $flatten_method = sprintf 'smooth__flatten__%s', blessed $args{'value'};
            if($args{'resultset'}->can($flatten_method)) {
                $args{'value'} = $args{'resultset'}->$flatten_method($args{'value'});
            }
        }
    }
    $class->$orig(%args);
};

sub get_part($self, $index) {
    return $self->parts->[$index];
}
sub get_all_parts($self) {
    return $self->parts->@*;
}
sub shift_parts($self, $repeats = 1) {
    if($repeats == 1) {
        return shift $self->parts->@*;
    }
    elsif($repeats > 1) {
        return splice $self->parts->@*, 0, $repeats;
    }
}

sub set_left_hand_prefix($self, $prefix) {
    if(defined $self->left_hand_prefix) {
        die "Trying to set left hand prefix ($prefix), but it is already set to (@{[ $self->left_hand_prefix ]})";
    }
    $self->left_hand_prefix($prefix);
}

sub add_left_hand_function($self, $data) {
    push $self->left_hand_functions->@* => $data;
}
sub left_hand_functions_get_all($self) {
    if(!$self->left_hand_functions) {
        return ();
    }
    return $self->left_hand_functions->@*;
}

sub parse($self) {
    # Ordinary column name, like 'me.first_name' or 'that_relation.whatever', then we keep that as the column name
    if($self->get_part(0) =~ m/\./) {
        $self->column_name($self->shift_parts);
    }
    # Otherwise we make it into an ordinary column name
    elsif($self->resultset->result_source->has_column($self->get_part(0))) {
        $self->column_name(sprintf '%s.%s', $self->resultset->current_source_alias, $self->shift_parts);
    }
    else {
        my $possible_relation = $self->get_part(0);
        my $possible_column = $self->get_part(1);

        my $has_relationship = $self->resultset->result_source->has_relationship($possible_relation);

        if($has_relationship && defined $possible_column && $self->resultset->result_source->relationship_info($possible_relation)->{'class'}->has_column($possible_column)) {
            if($self->value->$_isa('DBIx::Class::Row')) {
                confess "Don't pass a row object to a column";
            }
            $self->column_name(sprintf '%s.%s', $self->shift_parts(2));
        }
        elsif($has_relationship && $self->value->$_isa('DBIx::Class::Row')) {
            $self->column_name(sprintf '%s.id', $possible_relation);
            $self->value($self->value->id);
            $self->shift_parts;
        }
        else {
            confess "Has no relation <$possible_relation> or that has no column <$possible_column>";
        }
    }

    for my $part ($self->get_all_parts) {
        my @params = ();
        if($part =~ m{^ (\w+) \( ([^)]+) \) $}x) {
            $part = $1;
            @params = split /\s*,\s*/ => $2;
        }
        my $method = "smooth__lookup__$part";

        my $lookup_result;
        if($self->resultset->can($method)) {
            $lookup_result = $self->resultset->$method($self->column_name, $self->value, \@params);
        }
        else {
            confess "Can't do <$method>, find suitable Lookup and add it to load_components";
        }

        if(!exists $lookup_result->{'value'}) {
            confess "Lookup for <$part> is expected to return { value => ... }, can't proceed";
        }
        $self->value(delete $lookup_result->{'value'});
        if(exists $lookup_result->{'left_hand_function'}) {
            $self->add_left_hand_function(delete $lookup_result->{'left_hand_function'});
        }
        if(exists $lookup_result->{'left_hand_prefix'}) {
            $self->set_left_hand_prefix(delete $lookup_result->{'left_hand_prefix'});
        }
        if(exists $lookup_result->{'sql_operator'}) {
            $self->sql_operator(delete $lookup_result->{'sql_operator'});
        }
        if(exists $lookup_result->{'operator'}) {
            $self->operator(delete $lookup_result->{'operator'});
        }
        if(exists $lookup_result->{'quote_value'}) {
            $self->quote_value(delete $lookup_result->{'quote_value'});
        }
        else {
            $self->quote_value(1);
        }
        if(scalar keys $lookup_result->%*) {
            die sprintf "Unexpected keys returned from lookup for <$part>: %s", join(', ' => sort keys $lookup_result->%*);
        }
    }

    # Happy case
    if((!defined $self->left_hand_functions || !scalar $self->left_hand_functions->@*) && !defined $self->left_hand_prefix && $self->quote_value) {
        my $column_name = $self->column_name;

        if($self->operator && $self->operator ne '=') {
            return ($self->column_name, { $self->operator => $self->value });
        }
        else {
            return ($self->column_name, $self->value);
        }
    }
    else {
        my @left_hand = ();
        if($self->left_hand_prefix) {
            push @left_hand => $self->left_hand_prefix;
        }
        my $function_call_string = $self->column_name;
        for my $lhf ($self->left_hand_functions_get_all) {
            if(exists $lhf->{'complete'}) {
                $function_call_string = delete $lhf->{'complete'};
            }
            elsif(exists $lhf->{'name'}) {
                $function_call_string = sprintf '%s(%s)', delete ($lhf->{'name'}), $function_call_string;
            }
            elsif(exists $lhf->{'start'} && exists $lhf->{'end'}) {
                $function_call_string = sprintf '%s%s%s', delete ($lhf->{'start'}), $function_call_string, delete ($lhf->{'end'});
            }
        }
        push @left_hand => $function_call_string;
        push @left_hand => $self->sql_operator ? $self->sql_operator : $self->operator ? $self->operator : '=';

        if($self->quote_value) {
            # Either ? or (?, ?, ...., ?)
            my $placeholders = ref $self->value eq 'ARRAY' ? '(' . join(', ', split (//, ('?' x scalar $self->value->@*))) . ')' : ' ? ';
            push @left_hand => $placeholders;

            my $left_hand = join ' ' => @left_hand;
            return (undef, \[$left_hand, (ref $self->value eq 'ARRAY' ? $self->value->@* : $self->value)]);
        }
        else {
            push @left_hand => $self->value;
            my $left_hand = join ' ' => @left_hand;
            return (undef, \[$left_hand]);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::FilterItem - Short intro

=head1 VERSION

Version 0.0104, released 2020-08-30.

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
