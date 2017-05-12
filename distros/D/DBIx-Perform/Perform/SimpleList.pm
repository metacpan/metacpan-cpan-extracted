package DBIx::Perform::SimpleList;
use strict;
use base 'Exporter';
use Data::Dumper;
use DBI;

our $VERSION = '0.695';

our @EXPORT_OK = qw(	&new
  &is_empty
  &is_last
  &is_first
  &look_ahead
  &current_row
  &next_row
  &previous_row
  &get_value_at
  &add_row
  &insert_row
  &replace_row
  &remove_row
  &last_row
  &first_row
  &list_size
  &list_cursor
  &stuff_list
  &reset
  &iterate_list
  &clear_list
  &clone_list
  &dump_list
);

our @rows = ();

sub new {
    my $class = shift;

    bless my $self = {
        limit => 1250,
        limitinc => 1250,
        size => 0,
        iter => 0,
        rows => undef,
    } => ( ref $class || $class );
    return $self;
}

sub is_empty {
    my $self = shift;

    $self->{size} == 0 ? return 1 : return undef;
}

sub not_empty {
    my $self = shift;

    $self->{size} == 0 ? return undef : return 1;
}

sub is_first {
    my $self = shift;

    $self->{iter} == 0 ? return 1 : return undef;
}

sub look_ahead {
    my $self = shift;

    return undef if $self->is_last;

    my $next = $self->next_row;
    $self->previous_row;

    return $next;
}

sub is_last {
    my $self = shift;

    $self->{iter} == $self->{size}-1 ? return 1 : return undef;
}

sub reset {
    my $self = shift;

    $self->{iter} = -1;
}

sub iterate_list {
    my $self = shift;

    return undef if $self->is_last;

    return $self->next_row;
}

sub current_row {
    my $self = shift;

    return $self->{rows}->[ $self->{iter} ];
}

sub next_row {
    my $self   = shift;
    my $offset = shift;

    if ( defined($offset) ) {
        $self->{iter} += $offset;
    }
    else { ++$self->{iter}; }

    $self->{iter} = $self->{size}-1 if $self->{iter} >= $self->{size};

    $self->{limit} = 1250 if $self->{limit} < 1250;
    $self->{limitinc} = 1250 if $self->{limitinc} < 1250;
    if ($self->{iter} >= $self->{limit}) {
        $self->increase_limit;
    }

    return $self->{rows}->[ $self->{iter} ];
}

sub increase_limit {
    my $self = shift;
    if (defined $self->{sth}) {
        my $rowcache;
        while (@{$rowcache=$self->{sth}
                 ->fetchall_arrayref([], $self->{limitinc})
                 || [] }
               && $self->{limit} <= $self->{iter} ) {
            $self->{limit} += $self->{limitinc};
            push @{$self->{rows}}, @$rowcache;
        }
    }
}

sub previous_row {
    my $self   = shift;
    my $offset = shift;

    if ( defined($offset) ) {
        $self->{iter} -= $offset;
    }
    else { --$self->{iter}; }

    $self->{iter} = 0 if $self->{iter} < 0;

    return $self->{rows}->[ $self->{iter} ];
}

sub get_value_at {
    my $self  = shift;
    my $value = shift;
    my $index = shift;

    die "index greater than list size" if !( $self->{size} > $index );

    for ( my $count = 0 ; $count < $index ; $self->{iter}++ ) { }

    $self->add($value);

    return $self->{rows}->[ $self->{iter} ];
}

sub add_row_to_end {
    my $self = shift;
    my $row  = shift;

    return undef if !defined($row);

    push @{$self->{rows}}, $row;
    $self->{iter} = 0;
    ++$self->{size};
    ++$self->{limit};

    return $self->{rows}->[0];
}

sub add_row {
    my $self = shift;
    my $row  = shift;

    return undef if !defined($row);

    unshift @{$self->{rows}}, $row;
    $self->{iter} = 0;
    ++$self->{size};
    ++$self->{limit};

    return $self->{rows}->[0];
}

sub list_cursor {
    my $self = shift;

    return $self->{iter};
}

sub remove_row {
    my $self = shift;

    return undef if $self->{size} == 0;

    my $i = $self->{iter};

    --$self->{size};
    --$self->{limit};
    $self->{limit} = $self->{size} if $self->{limit} > $self->{size};
    while ( $i < $self->{limit} ) {
        $self->{rows}[$i] = $self->{rows}[$i+1];
        $i++;
    }

    return $self->current_row;
}

sub insert_row {
    my $self = shift;
    my $row  = shift;

    return undef if !defined($row);

    if ( $self->{size} == 0 ) {
        $self->{rows}->[0] = $row;
        ++$self->{size};
    }

    if ( $self->{iter} != $self->{size}-1 ) {
        my @tmp = @{ $self->{rows} };
        my @b   = ();
        my $i   = 0;

        foreach my $r (@tmp) {
            if ( $i == $self->{iter} ) {
                $b[$i] = $row;
                $i++;
            }
            $b[$i] = $r;
            $i++;
        }
        $self->{rows} = \@b;
    }
    else { $self->{rows}->[ $self->{size}-1 ] = $row; }

    ++$self->{size};

    return $self->current_row;
}

sub replace_row {
    my $self = shift;
    my $row  = shift;

    return undef if !defined($row);

    $self->{rows}[ $self->{iter} ] = $row;

    return $self->current_row;
}

#If last_row fucntion wanted,
# needs changing to handle "limit" added on 2007 Aug 17.
#sub last_row {
#    my $self = shift;
#
#    $self->{iter} = $self->{size}-1;
#
#    return $self->{rows}->[ $self->{iter} ];
#}

sub first_row {
    my $self = shift;

    $self->{iter} = 0;
    return $self->{rows}->[0];
}

sub list_size {
    my $self = shift;

    return $self->{size};
}

sub get_count {
    my $self  = shift;
    my $query = shift;
    my $vals  = shift;
    my $db    = shift;

    my $sth = $db->prepare($query);
    if ($sth) {
        if (defined $sth->execute(@$vals)) {
            if ($::TRACE) {
                warn "$query\n";
                warn join (", ", @$vals) . "\n" if defined $vals;
            }
            $self->{size} = $sth->fetchrow_array;
        }
    }
}

#2007 Aug: added "q_cnt", which is a 2nd query that the calling function
# must provide.  q_cnt must be a "select count(*) from ..." query.
sub stuff_list {
    my $self  = shift;
    my $db    = shift;
    my $q_cnt = shift;
    my $query = shift;
    my $vals  = shift;

    my $GlobalUi = $DBIx::Perform::GlobalUi;

    $self->clear_list;

    $self->{sth} = $db->prepare_cached($query);

    if ($self->{sth}) {
        my @vals1 = ();
        @vals1 = @$vals if $query =~ /\?/;
        if ( defined( $self->{sth}->execute(@vals1) ) ) {
            $self->{rows} = $self->{sth}->fetchall_arrayref([], $self->{limit});
            $self->{size} = @{$self->{rows}};
            if ($self->{size} >= $self->{limit}) {
                $self->{size} = $self->get_count($q_cnt, \@$vals, $db);
            }

            $self->{iter} = 0;
            return $self->first_row;
        }
    }

    $GlobalUi->display_comment($GlobalUi->{error_messages}->{'db16e'});
    $GlobalUi->display_error("$DBI::errstr");
    return undef;
}

sub clear_list {
    my $self = shift;

    $self->{size} = 0;
    $self->{iter} = 0;

    $self->{rows} = ();
    $self->{sth}  = 0;
    $self->{limit} = 1250;
    $self->{limitinc} = 1250;
}

sub clone_list {
    my $self = shift;
    my $list = new DBIx::Perform::SimpleList;

    my @a;
    my $i = 0;

    while ( $i < $self->{size} ) {
        $a[$i] = $self->{rows}->[$i];
        $i++;
    }
    $list->{rows} = \@a;
    $list->{iter} = 0;
    $list->{size} = $self->{size};

    return $list;
}

sub dump_list {
    my $self = shift;

    print STDERR "iter: $self->{iter}\n";
    print STDERR "size: $self->{size}\n";
    print STDERR "rows array: \n";
    print STDERR Dumper( $self->{rows} );
}

1;
