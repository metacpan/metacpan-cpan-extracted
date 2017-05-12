package Ambrosia::QL;
use strict;
use warnings;

use Ambrosia::core::Nil;
use Ambrosia::Meta;

#=rem
#
#driver: источник данных:
#    - ARRAY;
#    - Ambrosia::QL;
#    - класс у которго реализован метод CQL().
#
#__variable: содержит ссылку на переменную в которой размещен объект;
#__predicate: ссылка на функцию, которая проверяет соответствие полученного объекта заданному условию;
#__select: ссылка на функцию, которая может проделать дополнительную обработку полученного объекта;
#__join: ссылка на родителя
#
#=cut
#

class sealed {
    public  => [qw/driver source/],
    private => [qw/__variable __predicate __on __select __join __join_kw __limit __skip/],
};

our $VERSION = 0.010;

sub new :Private
{
}

sub _TRUE { 1 }

sub from(&)
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    return $class->SUPER::new(
            source => shift,
            driver => new Ambrosia::core::Nil(),
            __variable  => shift || \my $tmp,
            __predicate => \&_TRUE,
            __on        => \&_TRUE,
            __limit     => 0,
            __skip      => 0,
        );
}

sub in
{
    my $self = shift;
    my $driver = shift;

    if ( eval { $driver->isa('Ambrosia::DataProvider::BaseDriver') }  )
    {
        $self->driver = $driver;
        $self->driver->reset()->source($self->source);
    }
    else
    {
        throw Ambrosia::error::Exception 'QL: bad driver: ' . $driver;
    }

    return $self;
}

sub what
{
    my $self = shift;
    $self->driver->what(@_);
    return $self;
}

sub predicate
{
    my $self = shift;

    if(ref $_[0] eq 'CODE')
    {
        $self->__limit = 1;
        my $p = $_[0];
        my $old = $self->__predicate;
        $self->__predicate = sub { $old->(@_) && $p->(@_) }
    }
    else
    {
        $self->driver->predicate(@_);
    }

    return $self;
}

sub uniq
{
    my $self = shift;
    $self->driver->uniq(@_);
    return $self;
}

sub order_by
{
    my $self = shift;
    $self->driver->order_by(@_);
    return $self;
}

sub join
{
    my $self = shift;
    my ($kw, $driver, $source);

    if ( scalar @_ == 1 )
    {
        $kw = 'INNER';
        $driver = $self->driver->clone;
        $source = $driver->get_source();
    }
    elsif ( scalar @_ == 2 )
    {
        $kw = shift || 'INNER';
        $driver = $self->driver->clone;
        $source = $driver->get_source();
    }
    else
    {
        $kw = shift || 'INNER';
        $driver = shift()->clone;
        $source = $driver->get_source();
    }
    $driver->reset()->source($source);

    my $newQL = Ambrosia::QL->from()->in($driver);
    $newQL->__join = $self;
    $newQL->__join_kw = $kw;
    return $newQL;
}

sub on
{
    my $self = shift;

    if(ref $_[0] eq 'CODE')
    {
        my $p = $_[0];
        my $old = $self->__on;
        $self->__on = sub { $old->(@_) && $p->(@_) }
    }
    else
    {
        $self->driver->on(@_);
    }

    return $self;
}

sub select
{
    my $root = shift;
    my $code = shift;

    while( my $j = $root->__join )
    {
        $j->driver->join($root->__join_kw, $root->driver);
        $root = $j;
    };
    my $var = $root->__variable;

    if ( $code )
    {
        $root->__select = sub {
            if (my @a = $root->driver->next())
            {
                $$var = $a[0];
                if ( $root->__predicate->($$var) )
                {
                    local $_ = $$var;
                    return $code->();
                }
                return;
            }
            $root->__limit = 0;
            return;
        };
    }
    else
    {
        $root->__select = sub {
            if (my @a = $root->driver->next())
            {
                $$var = $a[0];
                return $$var if $root->__predicate->($$var);
                return;
            }
            $root->__limit = 0;
            return;
        };
    }

    return $root;
}

sub __next
{
    return $_[0]->__select->();
}

sub next
{
    my $self = shift;
    $self->select() unless $self->__select;

    my @val = ();
    while(1)
    {
        @val = $self->__next();
        return if !$self->__limit && scalar @val == 0;
        return $val[0] if scalar @val;
    }
    return;
}

sub skip
{
    my $self = shift;
    if ( $self->__limit )
    {
        $self->__skip = shift;
    }
    else
    {
        $self->driver->skip(shift);
    }
    return $self;
}

sub take
{
    my $self = shift;
    my $cnt = shift;

    if ( $cnt && not $self->__limit )
    {
        $self->driver->limit($cnt);
    }

    $cnt = -1 unless defined $cnt;

    $self->select() unless $self->__select;

    my @values = ();
    while( 1 )
    {
        my @val = $self->__next();
        last if !$self->__limit && scalar @val == 0;
        $self->__skip--, next if $self->__limit && $self->__skip;
        if ( scalar @val )
        {
            push @values, @val;
            last unless --$cnt;
        }
    }
    $self->destroy();
    return @values;
}

sub count
{
    my $self = shift;
    my $cnt = $self->driver->count;
    my $val = [$self->take(@_)];
    $cnt = scalar @$val unless defined $cnt;
    return $val, $cnt;
}

sub destroy
{
    my $self = shift;

    $self->driver = new Ambrosia::core::Nil();
    $self->__predicate = \&_TRUE;
    $self->__on        = \&_TRUE;
    $self->__select    = undef;
    $self->__join->reset() if $self->__join;
    $self->__join = undef;
    $self->__join_kw = undef;

}

#TODO??
#sub let($&)
#{
#    my $p = shift;
#    my $var = shift;
#    __PACKAGE__;
#}
#
#sub group
#{
#    my $self = shift;
#}

1;

__END__

=head1 NAME

Ambrosia::QL - a Query Language to data source.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::QL;

    #get all rows from table tClient in data source described by to words
    #'DBI' (type of source) and 'Client' (name of source)
    my @r1 = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->select()
        ->take();

    #get one row from table tClient in data source described by to words
    #'DBI' (type of source) and 'Client' (name of source)
    #and where ClientId is 22
    my @r = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate('ClientId', '=', 22)
        ->select()
        ->take(1);

    #get one row from table tClient in data source described by to words
    #'DBI' (type of source) and 'Client' (name of source)
    #and that have been tested in 'checkClient'
    my @r = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate(\&checkClient)
        ->select()
        ->take(1);

=head1 DESCRIPTION

C<Ambrosia::QL> is a query language for getting data from data source provided by L<Ambrosia::DataProvider>.

=head1 CONSTRUCTOR

=head2 from (tableName, referenceToVariable)

=over 4

=item tableName

Name of the table which is a source of data.

=item referenceToVariable

Optional. Reference to a variable. This variable can be subsequently used in the select method as a hash.

=back

=head1 METHODS

=head2 in (driver)

Set data of sorce.

=head2 what (@_)

Describe what columns you want to get from data source.

    $ql->what(qw/Name Age/);
    $ql->what();

If parameters not present then whil select all columns.

=head2 predicate (ColumnName, Operation, Value)

You can use this method in two ways:

=over 4

=item Pointing to two or three parameters.

In this case, the processing of a predicate will be carried out on the side of the driver

    $ql->predicate('Name', '=', 'John');

    $ql->predicate('Name', '=', 'John')
       ->predicate('Age', '<', 42);
This means that the rows will be selected in which the column Name is "John" and Age less than 42

    $ql->predicate(['Name', '=', 'John'],['Name', '=', 'Jack']);
This means that the rows will be selected in which the column Name is "John" or "Jack"

Value is optional. So you can write: $ql->predicate('Name', 'IS NOT NULL')

=item Pointing to subrutine.

    $ql->predicate(sub { shift()->{tableName_columnName} =~ /^Jo/ });

This procedure is passed a hash whose keys are of the form "tableName_columnName" if you use method L<Ambrosia::QL/what>
and "columnName" if you not use method L<Ambrosia::QL/what>.

You can also combine calling some this methods.
    $ql->predicate(sub { shift()->{table_Name} =~ /^Jo/ })
       ->predicate(sub { shift()->{table_Age} == 42 });

That conjunction of predicates.

=back

=head2 select (subrutine)

You can call this method, indicating the subroutine for rows processing.

    my $client;
    my @r = Ambrosia::QL
        ->from('tClient', \$client)
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate(sub{
            shift->{tClient_Age} == 42})
        ->select(sub {
            return {map { my $k = $_; $k =~ s/^tClient_//; $k => $client->{$_}; } keys %$client};
        })
        ->take(1);

    #now @r contained
    #(
    #    {
    #     LastName   => 'LastName22',
    #     FirstName  => 'FirstName22',
    #     MiddleName => 'MiddleName22',
    #     Age        => 42,
    #    },
    #);

=head2 take ($count)

This method returns a specified number (C<$count>) of records from a data source and destroys the request object.
If $count is undefined then will returned all rows.

=head2 skip ($count)

This method specifies how many rows should pass before starting to produce results.

=head2 next

Return next row from source of data or return nothing if relevant rows not found more.
After use the C<next> you must call C<destroy>.

    my $ql = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate('Age', '=', 42);

    my @r = ();
    while(my $r = $ql->next() )
    {
        push @r, $r;
    }
    $ql->destroy();

=head2 destroy

Destroys the object and frees up resources.


=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
