package Dancer::Plugin::Nitesi::Cart::DBI;

use strict;
use warnings;

=head1 NAME

Dancer::Plugin::Nitesi::Cart::DBI - DBI cart backend for Nitesi

=cut

use Nitesi::Query::DBI;

use Dancer qw/session hook/;
use Dancer::Plugin::Database;

use base 'Nitesi::Cart';

=head1 METHODS

=head2 init

=cut

sub init {
    my ($self, %args) = @_;
    my (%q_args);

    if (my $conn = $args{connection}) {
        if (ref($conn) and $conn->isa('DBI::db')) {
            # passing database handle directly, useful for testing
            $self->{dbh} = $conn;
        }
        else {
            $self->{dbh} = database($conn);
        }
    }
    else {
        $self->{dbh} = database();
    }

    %q_args = (dbh => $self->{dbh});

    if ($args{settings}->{log_queries}) {
	$q_args{log_queries} = sub {
	    Dancer::Logger::debug(@_);
	};
    };

    $self->{session_id} = $args{session_id} || '';
    $self->{settings} = $args{settings} || {};
    $self->{sqla} = Nitesi::Query::DBI->new(%q_args);

    hook 'after_cart_add' => sub {$self->_after_cart_add(@_)};
    hook 'after_cart_update' => sub {$self->_after_cart_update(@_)};
    hook 'after_cart_remove' => sub {$self->_after_cart_remove(@_)};
    hook 'after_cart_rename' => sub {$self->_after_cart_rename(@_)};
    hook 'after_cart_clear' => sub {$self->_after_cart_clear(@_)};
}

=head2 load

Loads cart from database. 

=cut

sub load {
    my ($self, %args) = @_;
    my ($uid, $name, $code);

    # check whether user is authenticated or not
    $uid = $args{uid} || 0;
    $self->{uid} = $uid;

    if ($uid) {
        # determine cart code (from uid)
        $code = $self->{sqla}->select_field(table => 'carts', field => 'code', where => {name => $self->name, uid => $uid});
    }
    elsif ($args{session_id}) {
        # determine cart code (from session_id)
        $code = $self->{sqla}->select_field(table => 'carts', field => 'code', where => {name => $self->name, uid => 0, session_id => $args{session_id}});
    }
    
    unless ($code) {
	$self->{id} = 0;
	return;
    }
    $self->{id} = $code;

    $self->_load_cart;    
}

=head2 id

Return cart identifier.

=cut

sub id {
    my $self = shift;

    if (@_ && defined ($_[0])) {
        my $id = $_[0];

        if ($id =~ /^[0-9]+$/) {
            $self->{id} = $id;
            $self->_load_cart;
        }
    }
    elsif (! $self->{id}) {
        # forces us to create entry in cart table
        $self->_create_cart;
    }

    return $self->{id};
}

=head2 save

No-op, as all cart changes are saved through hooks to the database.

=cut

sub save {
    return 1;
}

# creates cart in database
sub _create_cart {
    my $self = shift;

	$self->{id} = $self->{sqla}->insert('carts', {name => $self->name,
                                                  uid => $self->{uid} || 0,
                                                  session_id => $self->{session_id} || '',
                                                  created => $self->created,
                                                  last_modified => $self->last_modified,
                                                 });
}

# loads cart from database
sub _load_cart {
    my $self = shift;

    # build query for item retrieval
    my %specs = (fields => $self->{settings}->{fields} || 
                 [qw/products.sku products.name products.price cart_products.quantity/],
                 join => $self->{settings}->{join} ||
                 [qw/carts code=cart cart_products sku=sku products/],
                 where => {'carts.code' => $self->{id},
                          '-not_bool' => 'inactive',
                          });

    # retrieve items from database
    my $result = $self->{sqla}->select(%specs);

    $self->seed($result);
}

# hook methods
sub _after_cart_add {
    my ($self, @args) = @_;
    my ($item, $update, $record);

    unless ($self eq $args[0]) {
	# not our cart
	return;
    }

    $item = $args[1];
    $update = $args[2];

    unless ($self->{id}) {
        $self->_create_cart;
    }

    if ($update) {
	# update item in database
	$record = {quantity => $item->{quantity}};
	$self->{sqla}->update('cart_products', $record, {cart => $self->{id}, sku => $item->{sku}});
    }
    else {
	# add new item to database
	$record = {cart => $self->{id}, sku => $item->{sku}, quantity => $item->{quantity}, position => 0};
	$self->{sqla}->insert('cart_products', $record);
    }
}

sub _after_cart_update {
    my ($self, @args) = @_;
    my ($item, $new_item, $count);

    unless ($self eq $args[0]) {
	# not our cart
	return;
    }

    $item = $args[1];
    $new_item = $args[2];

    # update item in database
    Dancer::Logger::debug("Updating cart products with: ", $new_item);

    $count = $self->{sqla}->update(table => 'cart_products', 
				   set => $new_item, 
				   where => {cart => $self->{id}, sku => $item->{sku}});

    Dancer::Logger::debug("Items updated: $count.");
}

sub _after_cart_remove {
    my ($self, @args) = @_;
    my ($item);

    unless ($self eq $args[0]) {
	# not our cart
	return;
    }

    $item = $args[1];

    $self->{sqla}->delete('cart_products', {cart => $self->{id}, sku => $item->{sku}});
}

sub _after_cart_rename {
    my ($self, @args) = @_;

    unless ($self eq $args[0]) {
	# not our cart
	return;
    }

    $self->{sqla}->update('carts', {name => $args[2]}, {code => $self->{id}});    
}

sub _after_cart_clear {
    my ($self, @args) = @_;

    unless ($self eq $args[0]) {
	# not our cart
	return;
    }

    $self->{sqla}->delete('cart_products', {cart => $self->{id}});
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
