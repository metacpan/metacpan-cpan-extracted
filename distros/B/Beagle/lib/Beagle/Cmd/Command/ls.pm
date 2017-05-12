package Beagle::Cmd::Command::ls;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

has type => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'filter by type',
    cmd_aliases   => 't',
    traits        => ['Getopt'],
);

has 'created-before' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'created_before',
    documentation => 'filter by created(before this value)',
    traits        => ['Getopt'],
);

has 'created-after' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'created_after',
    documentation => 'filter by created(after this value)',
    traits        => ['Getopt'],
);

has 'updated-before' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'updated_before',
    documentation => 'filter by updated(before this value)',
    traits        => ['Getopt'],
);

has 'updated-after' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'updated_after',
    documentation => 'filter by updated(after this value)',
    traits        => ['Getopt'],
);

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'all the beagles',
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

has 'limit' => (
    isa           => 'Num',
    is            => 'rw',
    documentation => 'limit number of entries',
    cmd_aliases   => 'l',
    traits        => ['Getopt'],
);

has 'draft' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'filter by draft',
    traits        => ['Getopt'],
);

has 'final' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'filter by not-draft',
    traits        => ['Getopt'],
);

has 'order' => (
    isa           => 'Str',
    is            => 'rw',
    default       => '-created',
    documentation => 'order of entries in each beagle',
    traits        => ['Getopt'],
);

has 'marks' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => '_marks',
    cmd_aliases   => 'm',
    documentation => 'filter by marks',
    traits        => ['Getopt'],
);

has 'tags' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'tags',
    cmd_aliases   => 'm',
    documentation => 'filter by tags',
    traits        => ['Getopt'],
);

has 'names' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/ls list search/ }

sub filter {
    my $self = shift;
    my ( $bh, $opt, $args ) = @_;

    my @found;

    my $type = $self->type;

    my %condition;
    %condition = %{ $opt->{condition} } if $opt->{condition};

    my $type_info = entry_type_info();

    for my $t ( keys %$type_info ) {
        my $attr = $type_info->{$t}{plural};
        if ( $type eq $t || $type eq 'all' ) {
            for my $entry ( @{ $bh->$attr ||[]} ) {
                next
                  if ( $self->draft && !$entry->draft )
                  || ( $self->final && $entry->draft );

                next unless is_in_range( $entry, %condition );
                push @found, $entry;
            }
        }
    }

    if ( $self->tags ) {
        my $cond = to_array( $self->tags );
        my $filter_tags = sub {
            my $entry = shift;
            return 1 unless @$cond;
            my $tags = $entry->tags;
            for my $tag (@$cond) {
                if ( !grep { $tag eq $_ } @$tags ) {
                    return;
                }
            }
            return 1;
        };

        @found = grep { $filter_tags->($_) } @found;
    }


    if (@$args) {
        my @results;
        my @regex;
        for my $arg (@$args) {
            my ( $value, $modifier ) = $arg =~ m{^(?:qr|m)?/(.+)/(.*)};
            my $regex;
            if ($value) {
                if ($modifier) {
                    $regex = qr/(?$modifier)$value/;
                }
                else {
                    $regex = qr/$value/;
                }
            }
            else {
                  $regex = qr/$arg/mi;
            }
            push @regex, $regex;
        }

        for my $entry (@found) {
            my $pass = 1;
            my $content = $entry->serialize( id => 1 );
            for my $regex (@regex) {
                undef $pass unless $content =~ $regex;
            }
            push @results, $entry if $pass;
        }
        @found = @results;
    }

    if ( $self->_marks ) {
        my $cond = to_array( $self->_marks );
        my $marks = marks();

        my $filter_marks = sub {
            my $id = shift;
            return 1 unless @$cond;
            return   unless $marks->{$id};
            for my $mark (@$cond) {
                if ( !exists $marks->{$id}{$mark} ) {
                    return;
                }
            }
            return 1;
        };

        @found = grep { $filter_marks->( $_->id ) } @found;
    }

    return @found;
}

sub _prepare {
    my $self = shift;
    my $type = $self->type || 'all';
    $self->type($type);

    my @bh;
    if ( $self->all ) {
        @bh = values %{handles()};
    }
    elsif ( $self->names ) {
        my $handles = handles();
        my $names = to_array( $self->names );
        for my $name ( @$names ) {
            die "invalid name: $name" unless $handles->{$name};
            push @bh, $handles->{$name};
        }
    }
    else {
        @bh = current_handle or die "please specify beagle by --name or --root";
    }
    return @bh;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my @bh = $self->_prepare();

    my %condition = map { $_ => $self->$_ }
      qw/created_before created_after updated_before updated_after/;

    for my $item ( keys %condition ) {
        next unless defined $condition{$item};
        my $epoch = parse_datetime( $condition{$item} )
          or die "failed to parse datetime from string $condition{$item}";

        $condition{$item} = $epoch;
    }

    $opt->{condition} = \%condition;

    my @found;
    for my $bh (
        sort {
            $self->order =~ /-name/i
              ? ( $b->name cmp $a->name )
              : ( $a->name cmp $b->name )
        } @bh
      )
    {
        push @found, $self->filter( $bh, $opt, $args );
        if (   $self->limit
            && $self->limit > 0
            && $self->order =~ /name/i
            && @found >= $self->limit )
        {
            @found = @found[ 0 .. $self->limit - 1 ];
            last;
        }
    }

    if (@found) {
        $self->show_result(@found);
    }
}

sub show_result {
    my $self  = shift;
    my @found = @_;
    return unless @found;

    my $limit = $self->limit;
    $limit = 0 if !$limit || $limit < 0;

    my $order = lc $self->order;
    ( my $sign, $order ) = $order =~ /^([\+\-])?(.+)/;
    $sign ||= '+';

    if ( $order ne 'name' ) {
        if ( $found[0]->can($order) ) {
            if ( $limit && $limit < @found ) {
                @found = (
                    sort {
                        $sign eq '+'
                          ? ( $a->$order cmp $b->$order )
                          : ( $b->$order cmp $a->$order )
                      } @found
                )[ 0 .. $limit - 1 ];
            }
            else {
                @found = sort {
                    $sign eq '+'
                      ? ( $a->$order cmp $b->$order )
                      : ( $b->$order cmp $a->$order )
                } @found;
            }
        }
        else {
            die "invalid order: $order";
        }
    }

    @found = @found[ 0 .. $self->limit - 1 ]
      if $self->limit && $self->limit > 0 && $self->limit < @found;

    return unless @found;

    require Text::Table;
    my $tb;
    if ( $self->verbose ) {
        $tb = Text::Table->new( 'name', 'type', 'id', 'created', 'updated',
            'summary' );
        $tb->load(
            map {
                [
                    root_name( $_->root ),
                    $_->type,
                    $_->id,
                    pretty_datetime( $_->created ),
                    pretty_datetime( $_->updated ),
                    $_->summary(10),
                ]
              } @found
        );
    }
    else {
        $tb = Text::Table->new();
        $tb->load( map { [ $_->id, $_->summary(30) ] } @found );
    }
    puts $tb;
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::ls - list/search entries

=head1 SYNOPSIS

    $ beagle ls                             # all the entries
    $ beagle ls homer                       # entries that match qr/homer/mi
    $ beagle ls 'homer.*bart'               # entries that match qr/homer.*bart/mi
    $ beagle ls '/homer.*bart/im'           # ditto
    $ beagle ls --order created --limit 10  # only show the first 10 entries

    $ beagle ls --type article homer    # articles that match "homer"
    $ beagle articles homer             # ditto

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

