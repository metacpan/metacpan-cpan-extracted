package Alzabo::Runtime::RowState::Potential;

use strict;

use Alzabo::Runtime;

use base qw(Alzabo::Runtime::RowState::Live);

sub _init
{
    my $class = shift;
    my $row = shift;
    my %p = @_;

    # Can't just call ->update here cause with MethodMaker there may
    # be update hooks that probably shouldn't be invoked here.
    foreach ( keys %{ $p{values} } )
    {
        # This will throw an exception if the column doesn't exist.
        my $c = $row->table->column($_);

        Alzabo::Exception::Params->throw( error => "Column " . $c->name . " cannot be null." )
            unless defined $p{values}->{$_} || $c->nullable || defined $c->default;

        $row->{data}{$_} = $p{values}->{$_};
    }

    foreach my $c ( $row->table->columns )
    {
        if ( defined $c->default )
        {
            my $name = $c->name;
            $row->{data}{$name} = $c->default unless defined $row->{data}{$name};
        }
    }

    return 1;
}

sub _get_data
{
    my $class = shift;
    my $row = shift;

    my %data;
    @data{@_} = @{ $row->{data} }{@_};

    return %data;
}

sub update
{
    my $class = shift;
    my $row = shift;
    my %data = @_;

    foreach my $k (keys %data)
    {
        # This will throw an exception if the column doesn't exist.
        my $c = $row->table->column($k);

        Alzabo::Exception::NotNullable->throw
            ( error => $c->name . " column in " . $row->table->name . " table cannot be null.",
              column_name => $c->name,
            )
                unless defined $data{$k} || $c->nullable || defined $c->default;
    }

    my $changed = 0;
    while ( my ( $k, $v ) = each %data )
    {
        next if $row->_cached_data_is_same( $k, $data{$k} );

        $row->{data}{$k} = $v;
        $changed = 1;
    }

    return $changed;
}

# doesn't need to do anything
sub refresh { }

sub delete
{
    $_[1]->set_state( 'Alzabo::Runtime::RowState::Deleted' );
}

sub id_as_string { '' }

sub is_potential { 1 }

sub is_live { 0 }

sub is_deleted { 0 }


1;

__END__

=head1 NAME

Alzabo::Runtime::RowState::Potential - Row objects that are not in the database

=head1 SYNOPSIS

  my $row = $table->potential_row;

  $row->make_live;  # $row is now a _real_ row object!

=head1 DESCRIPTION

This state is used for potential rows, rows which do not yet exist in
the database.

=head1 METHODS

See L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
