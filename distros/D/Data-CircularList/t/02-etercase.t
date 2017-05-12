# t/02-etercase.t
use strict;
use warnings;
use Test::More;
use Data::CircularList;


subtest 'number case' => sub {
    my $list = Data::CircularList->new;
    my @num_vals = qw(20 15 18 37 3);
    
    for my $num_val (@num_vals) {
        $list->insert($num_val);
    }
    
    my $iter = $list->iterator;
    for my $num_val (sort { $a <=> $b } @num_vals) {
         if ($iter->has_next) {
             is $iter->next->data, $num_val;
         }
    }

    is $iter->has_next, 1;
    is $iter->next->data, (sort { $a <=> $b } @num_vals)[0];
};

subtest 'string(dictionary) case' => sub {
    my $list = Data::CircularList->new;
    my @str_vals = qw(steeve Hisashi takahiro kazuyo jane holly01 1strike my2ke);
    
    for my $str_val (@str_vals) {
        $list->insert($str_val);
    }
    
    my $iter = $list->iterator;
    for my $str_val (sort { $a cmp $b } @str_vals) {
         if ($iter->has_next) {
             is $iter->next->data, $str_val;
         }
    }

    is $iter->has_next, 1;
    is $iter->next->data, (sort { $a cmp $b } @str_vals)[0];
};

subtest 'orignal object case' => sub {
    my $list = Data::CircularList->new;
    my @name_vals = qw(steeve Hisashi takahiro kazuyo jane holly01 1strike my2ke);
    
    for my $name_val (@name_vals) {
        $list->insert(Person->new(name => $name_val));
    }
    
    my $iter = $list->iterator;
    for my $name_val (sort { length($a) <=> length($b) || $a cmp $b } @name_vals) {
         if ($iter->has_next) {
             my $person = $iter->next->data;
             is $person->name, $name_val;
             is $person->length, length($name_val);
         }
    }

    is $iter->has_next, 1;
    my $person = $iter->next->data;
    is $person->name, (sort { length($a) <=> length($b) || $a cmp $b } @name_vals)[0];
    is $person->length, length((sort { length($a) <=> length($b) || $a cmp $b } @name_vals)[0]);
};

done_testing;

package Person;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        name => $args{'name'},
        length => length($args{'name'}),
    };
    bless $self => $class;
    $self->length(length($args{'name'}));
    return $self;
}

# sort by name's length
sub compare_to {
    my $self = shift;
    my $cell = shift;

    if ($self->length > $cell->length) {
        return 1;
    } elsif ($self->length == $cell->length) {
        return $self->name gt $cell->name ? 1 : 0;
    } else {
        return 0;
    }
}

sub name {
    my $self = shift;
    return defined $self->{'name'} ? $self->{'name'} : undef;
}

sub length {
    my $self = shift;
    return defined $self->{'length'} ? $self->{'length'} : undef;
}

1;
