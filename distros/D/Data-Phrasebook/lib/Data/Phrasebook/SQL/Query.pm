package Data::Phrasebook::SQL::Query;
use strict;
use warnings FATAL => 'all';
use base qw( Data::Phrasebook::Debug );
use vars qw( $AUTOLOAD );
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook::SQL::Query - Query Extension to the SQL/DBI Phrasebook Model.

=head1 SYNOPSIS

    my $q = $book->query( 'find_author' );
    my $q = $book->query( 'find_author', 'Dictionary' );

=head1 DESCRIPTION

An extension to the SQL class to specifically handle the DBI interface for
each query requested.

=head1 CONSTRUCTOR

=head2 new

Not to be accessed directly, but via the parent L<Data::Phrasebook>, by
specifying the class as SQL.

=head1 METHODS

=head2 sql

Get/set the current C<sql> statement, in a form suitable for passing
straight to DBI.

=head2 sth

Get/set the current statement handle.

=head2 args

Return list of arguments that will be used as bind parameters to any
placeholders. Any given arguments will replace the whole list.

Returns list in list context, arrayref in scalar.

=head2 order

As for C<args>, but regarding the corresponding list of argument
B<names>.

The assorted C<order_XXX> methods are supported as for C<args_XXX>.

=head2 dbh

Get/set the database handle.

=cut

sub new {
    my $self = shift;
    my %hash = @_;
    $self->store(3,"$self->new IN")	if($self->debug);
    my $atts = \%hash;
    bless $atts, $self;
    return $atts;
}

sub DESTROY {
    my $self = shift;
    $self->sth->finish    if($self->sth);
    return;
}

sub sql {
    my $self = shift;
    return @_ ? $self->{sql} = shift : $self->{sql};
}
sub dbh {
    my $self = shift;
    return @_ ? $self->{dbh} = shift : $self->{dbh};
}
sub sth {
    my $self = shift;
    return @_ ? $self->{sth} = shift : $self->{sth};
}
sub args {
    my $self = shift;
    my @args = @_;
    $self->{args} = \@args if(@_);
    return $self->{args};
}
sub order {
    my $self = shift;
    my @args = @_;
    $self->{order} = \@args if(@_);
    return @{$self->{order}} if($self->{order});
    return ();
}

=head1 PREPARATION / EXECUTING METHODS

=head2 execute

Executes the query. Returns the result of C<DBI::execute>.

Any arguments are given to C<order_args> with the return of that method
being used as arguments to C<DBI::execute>. If no arguments, uses those
already specified.

Calls C<prepare> if necessary.

=cut

sub execute {
    my $self = shift;
    $self->store(3,"->execute IN: @_")	if($self->debug);
    my $sth = $self->sth;
    my @args = @_ ? $self->order_args( @_ ) : ();
    @args = ()  if(@args && !defined $args[0]);
    $sth = $self->prepare() unless $sth;

    unless(@args) {
        $self->rebind;
        return $sth->execute();
    }

    $self->store(4,"->execute args[".join(",",map {$_||'undef'} @args)."]")	if($self->debug);
    return $sth->execute( map { $$_ } @args );
}

=head2 order_args

Given a hash or hashref of keyword to value mappings, organises
an array of arguments suitable for use as bind parameters
in the order needed by the query itself.

=cut

sub order_args {
    my $self = shift;
    my %args = (@_ == 1 ? %{$_[0]} : @_);
    my @order = $self->order;
    my @args = $self->args;

    for (0..$#order)
    {
        my $key = $order[$_];
        if (exists $args{ $key })
        {
            my $val = $args{ $key };
            $args[$_] = (ref $val) ? $val : \$val;
        }
    }

    return @args;
}

=head2 prepare

Prepares the query for execution. This method is called
implicitly in most cases so you generally don't need
to know about it.

=cut

sub prepare {
    my $self = shift;
    $self->store(3,"$self->prepare IN")	if($self->debug);
    my $sql = $self->sql;
    $self->store(4,"$self->prepare sql=[$sql]")	if($self->debug);
    croak "Can't prepare without SQL" unless defined $sql;
    my $sth = $self->dbh->prepare_cached( $sql );
    $self->sth( $sth );
    return $sth;
}

=head2 rebind

Rebinds any bound values. Lets one pass a scalar reference in
the arguments to C<order_args> and have the bound value update
if the original scalar changes.

This method is not needed externally to this class.

=cut

sub rebind {
    my $self = shift;
    my $sth = $self->sth;
    my $args = $self->args;
    for my $x (0..$#{$args})
    {
        $self->store(4,'->rebind param['.($x+1).','.(${ $args->[$x] }).']')	if($self->debug);
        $sth->bind_param( $x+1, ${ $args->[$x] } )
    }
    return;
}

=head1 DELEGATED METHODS

Any method not mentioned above is given to the statement
handle.

All these delegations will implicitly call C<prepare>.

=cut

# Currently the following is not true, but will be fixed at some point:
#
#Any C<fetch*> methods will additionally call C<execute>
#unless the statement handle is already active.

sub _call_other {
    my ($self, $execute, $method) = splice @_, 0, 3;
    my $sth = $self->sth || $self->prepare();
    $self->execute() if $execute and not $sth->{Active};
    return $sth->$method( @_ );
}

sub AUTOLOAD {
    my $self = shift;
    my ($method) = $AUTOLOAD =~ /([^:]+)$/;
#print STDERR "\n#[$AUTOLOAD][$method]\n";
    my $sth = $self->sth || $self->prepare();

    if ($sth->can($method))
    {
        no strict 'refs';
        my $execute = $method =~ /^fetch/ ? 1 : 0 ;
        *{$method} = sub {
                my $s = shift;
                $s->_call_other( $execute, $method, @_ )
        };
        return $self->$method( @_ );
    }
    return;
}

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>,
L<Data::Phrasebook::SQL>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Original author: Iain Campbell Truskett (16.07.1979 - 29.12.2003)
  Maintainer: Barbie <barbie@cpan.org> since January 2004.
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003 Iain Truskett.
  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
