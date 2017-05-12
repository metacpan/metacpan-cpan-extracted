=head1 NAME

DR::Tarantool::Iterator - an iterator and a container class for
L<DR::Tarantool>

=head1 SYNOPSIS

    use DR::Tarantool::Iterator;

    my $iter = DR::Tarantool::Iterator->new([1, 2, 3]);

    my $item0 = $iter->item(0);

    my @all = $iter->all;
    my $all = $iter->all;

    while(my $item = $iter->next) {
        do_something_with_item( $item );
    }


=head1 METHODS

=cut

use utf8;
use strict;
use warnings;

package DR::Tarantool::Iterator;
use Carp;
use Data::Dumper;


=head2 new

A constructor.

=head3 Arguments

=over

=item *

An array of tuples to iterate over.

=item *

A list of named arguments:

=over

=item item_class

Name of the class to bless each tuple in the iterator with.
If the field is 'B<ARRAYREF>' then the first element of the array is
B<item_class>, and the second element is B<item_constructor>.

=item item_constructor

Name of a constructor to invoke for each tuple. If this value is
undefined and B<item_class> is defined, the iterator blesses each
tuple but does not invoke a constructor on it.

The constructor is invoked on with three arguments: B<item>,
B<item_index> and B<iterator>, for example:


    my $iter = DR::Tarantool::Iterator->new(
        [ [1], [2], [3] ],
        item_class => 'MyClass',
        item_constructor => 'new'
    );

    my $iter = DR::Tarantool::Iterator->new(    # the same
        [ [1], [2], [3] ],
        item_class => [ 'MyClass', 'new' ]
    );


    my $item = $iter->item(0);
    my $item = MyClass->new( [1], 0, $iter );  # the same

    my $item = $iter->item(2);
    my $item = MyClass->new( [3], 2, $iter );  # the same

=item data

Application state to store in the iterator. Is useful
if additional state needs to be passed into tuple constructor.

=back

=back

=cut

sub new {
    my ($class, $items, %opts) = @_;

    croak 'usage: DR::Tarantool::Iterator->new([$item1, $item2, ... ], %opts)'
        unless 'ARRAY' eq ref $items;


    my $self = bless { items   => $items } => ref($class) || $class;

    $self->item_class(
        ('ARRAY' eq ref $opts{item_class}) ?
            @{ $opts{item_class} } : $opts{item_class}
    ) if exists $opts{item_class};

    $self->item_constructor($opts{item_constructor})
        if exists $opts{item_constructor};

    $self->data( $opts{data} ) if exists $opts{data};
    $self;
}


=head2 clone(%opt)

Clone the iterator object, but do not clone the tuples.
This method can be used to create an iterator that has
a different B<item_class> and (or) B<item_constructor>.

If B<clone_items> argument is true, the function clones the  tuple
list as well.

    my $iter1 = $old_iter->clone(item_class => [ 'MyClass', 'new' ]);
    my $iter2 = $old_iter->clone(item_class => [ 'MyClass', 'new' ],
        clone_items => 1);

    $old_iter->sort(sub { $_[0]->name cmp $_[1]->name });
    # $iter1 is sorted, too, but $iter2 is not

=cut

sub clone {

    my $self = shift;
    my %opts;
    if (@_ == 1) {
        %opts = (clone_items => shift);
    } else {
        %opts = @_;
    }

    my %pre = (
        data                => $self->data,
        item_class          => $self->item_class,
        item_constructor    => $self->item_constructor
    );

    my $clone_items = delete $opts{clone_items};

    my $items = $clone_items ? [ @{ $self->{items} } ] : $self->{items};
    $self = $self->new( $items, %pre, %opts );
    $self;
}


=head2 count

Return the number of tuples available through the iterator.

=cut

sub count {
    my ($self) = @_;
    return scalar @{ $self->{items} };
}


=head2 item

Return one tuple from the iterator by its index 
(or croak an error if the index is out of range).

=cut

sub item {
    my ($self, $no) = @_;

    my $item = $self->raw_item( $no );

    if (my $class = $self->item_class) {

        if (my $m = $self->item_constructor) {
            return $class->$m( $item, $no, $self );
        }

        return bless $item => $class if ref $item;
        return bless \$item => $class;
    }

    return $self->{items}[ $no ];
}


=head2 raw_item

Return one raw tuple from the iterator by its index 
(or croak error if the index is out of range).

In other words, this method ignores B<item_class> and B<item_constructor>.

=cut

sub raw_item {
    my ($self, $no) = @_;

    my $exists = $self->exists($no);
    croak "wrong item number format: " . (defined($no) ? $no : 'undef')
        unless defined $exists;
    croak 'wrong item number: ' . $no unless $exists;

    if ($no >= 0) {
        croak "iterator doesn't contain item with number $no"
            unless $no < $self->count;
    } else {
        croak "iterator doesn't contain item with number $no"
            unless $no >= -$self->count;
    }

    return $self->{items}[ $no ];
}


=head2 raw_sort(&)

Sort the contents referred to by the iterator (changes the current 
iterator object).
The compare function receives two B<raw> objects:

    $iter->raw_sort(sub { $_[0]->field cmp $_[1]->field });

=cut

sub raw_sort {
    my ($self, $cb) = @_;
    my $items = $self->{items};
    @$items = sort { &$cb($a, $b) } @$items;
    return $self;
}

=head2 sort(&)

Sort the contents referred to by the iterator (changes the current object).
The compare function receives two constructed objects:

    $iter->sort(sub { $_[0]->field <=> $_[1]->field });

=cut

sub sort : method {
    my ($self, $cb) = @_;
    my $items = $self->{items};
    my @bitems = map { $self->item( $_ )  } 0 .. $#$items;
    my @isorted = sort { &$cb( $bitems[$a], $bitems[$b] )  } 0 .. $#$items;

    @$items = @$items[ @isorted ];
    return $self;
}


=head2 grep(&)

Find all objects in the set referred to by the iterator that
match a given search criteria (linear search).

    my $admins = $users->grep(sub { $_[0]->is_admin });

=cut

sub grep :method {
    my ($self, $cb) = @_;
    my $items = $self->{items};
    my @bitems = map { $self->item( $_ ) } 0 .. $#$items;
    my @igrepped = grep { &$cb( $bitems[$_] )  } 0 .. $#$items;
    @igrepped = @$items[ @igrepped ];

    return $self->new(
        \@igrepped,
        item_class => $self->item_class,
        item_constructor => $self->item_constructor,
        data => $self->data
    );
}


=head2 raw_grep(&)

Same as grep, but works on raw objects.

    my $admins = $users->raw_grep(sub { $_[0]->is_admin });

=cut

sub raw_grep :method {
    my ($self, $cb) = @_;
    my $items = $self->{items};
    my @igrepped = grep { &$cb($_) } @$items;

    return $self->new(
        \@igrepped,
        item_class => $self->item_class,
        item_constructor => $self->item_constructor,
        data => $self->data
    );
}


=head2 get

An alias for L<item> method.

=cut

sub get { goto \&item; }


=head2 exists

Return B<true> if the iterator contains a tuple with the given
index.

    my $item = $iter->exists(10) ? $iter->get(10) : somethig_else();

=cut

sub exists : method{
    my ($self, $no) = @_;
    return undef unless defined $no;
    return undef unless $no =~ /^-?\d+$/;
    return 0 if $no >= $self->count;
    return 0 if $no <  -$self->count;
    return 1;
}


=head2 next

Return the next tuple, or B<undef> in case of eof.

    while(my $item = $iter->next) {
        do_something_with( $item );
    }

Index of the current tuple can be queried with function 'L<iter>'.

=cut

sub next :method {
    my ($self) = @_;
    my $iter = $self->iter;

    if (defined $self->{iter}) {
        return $self->item(++$self->{iter})
            if $self->iter < $#{ $self->{items} };
        delete $self->{iter};
        return undef;
    }

    return $self->item($self->{iter} = 0) if $self->count;
    return undef;
}


=head2 iter

Return index of the tuple at the current iterator position.

=cut

sub iter {
    my ($self) = @_;
    return $self->{iter};
}


=head2 reset

Reset iteration index, return the previous value of the index.

=cut

sub reset :method {
    my ($self) = @_;
    return delete $self->{iter};
}


=head2 all

Return all tuples available through the iterator.

    my @list = $iter->all;
    my $list_aref = $iter->all;

    my @abc_list = map { $_->abc } $iter->all;
    my @abc_list = $iter->all('abc');               # the same


    my @list = map { [ $_->abc, $_->cde ] } $iter->all;
    my @list = $iter->all('abc', 'cde');                # the same


    my @list = map { $_->abc + $_->cde } $iter->all;
    my @list = $iter->all(sub { $_[0]->abc + $_->cde }); # the same

=cut

sub all {
    my ($self, @items) = @_;

    return unless defined wantarray;
    my @res;

    local $self->{iter};


    if (@items == 1) {
        my $m = shift @items;

        while (defined(my $i = $self->next)) {
            push @res => $i->$m;
        }
    } elsif (@items) {
        while (defined(my $i = $self->next)) {
            push @res => [ map { $i->$_ } @items ];
        }
    } else {
        while (defined(my $i = $self->next)) {
            push @res => $i;
        }
    }

    return @res if wantarray;
    return \@res;
}



=head2 item_class

Set/return the tuple class. If the value is defined, the iterator
blesses tuples with it (and also calls L<item_constructor> if it is set).

=cut

sub item_class {
    my ($self, $v, $m) = @_;
    $self->item_constructor($m) if @_ > 2;
    return $self->{item_class} = ref($v) || $v if @_ > 1;
    return $self->{item_class};
}


=head2 item_constructor

Set/return the tuple constructor.
The value is used only if L<item_class> is defined.

=cut

sub item_constructor {
    my ($self, $v) = @_;
    return $self->{item_constructor} = $v if @_ > 1;
    return $self->{item_constructor};
}


=head2 push

Push a tuple into the iterator.

=cut

sub push :method {
    my ($self, @i) = @_;
    push @{ $self->{items}} => @i;
    return $self;
}


=head2 data

Return/set an application-specific context maintained in the iterator
object. This can be useful to pass additional state to B<item_constructor>.

=cut

sub data {
    my ($self, $data) = @_;
    $self->{data} = $data if @_ > 1;
    return $self->{data};
}

1;
