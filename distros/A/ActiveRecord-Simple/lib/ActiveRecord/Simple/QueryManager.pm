package ActiveRecord::Simple::QueryManager;

use ActiveRecord::Simple::Find;


sub new { bless {}, shift }

sub all  { ActiveRecord::Simple::Find->new(shift->{caller})->fetch }
sub get  { ActiveRecord::Simple::Find->new(shift->{caller}, @_)->fetch }
sub find { ActiveRecord::Simple::Find->new(shift->{caller}, @_) }

sub sql_fetch_all {
    my ($self, $sql, @bind) = @_;

    my $data = $self->{caller}->dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
    my @list;
    for my $row (@$data) {
        $self->{caller}->_mk_ro_accessors([keys %$row]);
        bless $row, $self->{caller};
        push @list, $row;
    }

    return \@list;
}

sub sql_fetch_row {
    my ($self, $sql, @bind) = @_;

    my $row = $self->{caller}->dbh->selectrow_hashref($sql, undef, @bind);
    $self->{caller}->_mk_ro_accessors([keys %$row]);
    bless $row, $self->{caller};

    return $row;
}

1;

__END__;

=head1 NAME

ActiveRecord::Simple::QueryManager - query manager for ActiveRecord classes

=head1 DESCRIPTION

Query manager for ActiveRecord classes. 

=head1 SYNOPSIS

	my $qm = ActiveRecord::Simple::QueryManager->new;
	$qm->{caller} = 'User';
	my @users = $qm->all(); # SELECT * FROM user;
	my @johns = $qm->find({ name => 'John' })->fetch;


=head2 sql_fetch_all

Execute any SQL code and fetch data. Returns list of objects. Accessors for all not specified fields
will be created as read-only.

    my @values = Purchase->sql_fetch_all('SELECT id, amount FROM purchase WHERE amount > ?', 100);
    print $_->id, " ", $_->amount for, "\n" @values;


=head2 sql_fetch_row

Execute any SQL and fetch data. Returns an object.

    my $customer = Customer->sql_fetch_row('SELECT id, name FORM customer WHERE id = ?', 1);
    print $customer->name, "\n";

=head2 find

Returns L<ActiveRecord::Simple::Find> object.

    my $finder = Customer->find(); # it's like ActiveRecord::Simple::Find->new();
    $finder->order_by('id');
    my @customers = $finder->fetch;


=head2 all

Same as __PACKAGE__->find->fetch;


=head2 get

Get object by primary_key

    my $customer = Customer->get(1);
    # same as Customer->find({ id => 1 })->fetch;