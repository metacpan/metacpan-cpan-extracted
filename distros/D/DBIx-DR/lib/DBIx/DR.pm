use utf8;
use strict;
use warnings;

use DBIx::DR::Iterator;
use DBIx::DR::Util ();
use DBIx::DR::PlPlaceHolders;

package DBIx::DR;
our $VERSION = '0.32';
use base 'DBI';
use Carp;
$Carp::Internal{ (__PACKAGE__) } = 1;

sub connect {
    my ($class, $dsn, $user, $auth, $attr) = @_;

    my $dbh = $class->SUPER::connect($dsn, $user, $auth, $attr);

    $attr = {} unless ref $attr;

    $dbh->{"private_DBIx::DR_iterator"} =
        $attr->{dr_iterator} || 'dbix-dr-iterator#new';

    $dbh->{"private_DBIx::DR_item"} =
        $attr->{dr_item} || 'dbix-dr-iterator-item#new';

    $dbh->{"private_DBIx::DR_sql_dir"} = $attr->{dr_sql_dir};

    $dbh->{"private_DBIx::DR_template"} = DBIx::DR::PlPlaceHolders->new(
        sql_dir     => $attr->{dr_sql_dir},
        sql_utf8    => $attr->{dr_sql_utf8} // 1
    );

    $dbh->{"private_DBIx::DR_dr_decode_errors"} = $attr->{dr_decode_errors};

    return $dbh;
}

package DBIx::DR::st;
use base 'DBI::st';
use Carp;
$Carp::Internal{ (__PACKAGE__) } = 1;

package DBIx::DR::db;
use Encode qw(decode encode);
use base 'DBI::db';
use DBIx::DR::Util;
use File::Spec::Functions qw(catfile);
use Carp;
$Carp::Internal{ (__PACKAGE__) } = 1;


sub set_helper {
    my ($self, %opts) = @_;
    $self->{"private_DBIx::DR_template"}->set_helper(%opts);
}

sub _dr_extract_args_ep {
    my $self = shift;

    my (@sql, %args);

    if (@_ % 2) {
        ($sql[0], %args) = @_;
        delete $args{-f};
    } else {
        %args = @_;
    }

    croak "SQL wasn't defined" unless @sql or $args{-f};

    my ($iterator, $item);

    unless ($args{-noiterator}) {
        $iterator = $args{-iterator} || $self->{'private_DBIx::DR_iterator'};
        croak "Iterator class was not defined" unless $iterator;

        unless($args{-noitem}) {
            $item = $args{-item} || $self->{'private_DBIx::DR_item'};
            croak "Item class was not definded" unless $item;
        }
    }

    return (
        $self,
        \@sql,
        \%args,
        $item,
        $iterator,
    );
}



sub _user_sql($@) {
    my ($sql, @bv) = @_;
    $sql =~ s/\?/'$_'/ for @bv;
    return $sql;
}


sub select {
    my ($self, $sql, $args, $item, $iterator) = &_dr_extract_args_ep;

    my $req = $self->{"private_DBIx::DR_template"}->sql_transform(
        @$sql,
        %$args
    );

    carp  _user_sql($req->sql, $req->bind_values) if $args->{'-warn'};
    croak _user_sql($req->sql, $req->bind_values) if $args->{'-die'};

    my $res;

    local $SIG{__DIE__} = sub { croak $self->_dr_decode_err(@_) };

    if (exists $args->{-hash}) {
        $res = $self->selectall_hashref(
                $req->sql,
                $args->{-hash},
                $args->{-dbi},
                $req->bind_values
            );

    } else {
        my $dbi = $args->{-dbi} // {};
        croak "argument '-dbi' must be HASHREF or undef"
            unless 'HASH' eq ref $dbi;
        $res = $self->selectall_arrayref(
                $req->sql,
                { %$dbi, Slice => {} },
                $req->bind_values
            );
    }


    return $res unless $iterator;

    my ($class, $method) = camelize $iterator;

    return $class->$method(
        $res, -item => $item, -noitem_iter => $args->{-noitem_iter}) if $method;
    return bless $res => $class;
}

sub single {
    my ($self, $sql, $args, $item) = &_dr_extract_args_ep;
    my $req = $self->{"private_DBIx::DR_template"}->sql_transform(
        @$sql,
        %$args
    );
    
    carp  _user_sql($req->sql, $req->bind_values) if $args->{'-warn'};
    croak _user_sql($req->sql, $req->bind_values) if $args->{'-die'};

    local $SIG{__DIE__} = sub { croak $self->_dr_decode_err(@_) };
    my $res = $self->selectrow_hashref(
            $req->sql,
            $args->{-dbi},
            $req->bind_values
        );

    return unless $res;

    my ($class, $method) = camelize $item;
    return $class->$method($res) if $method;
    return bless $res => $class;
}

sub perform {
    my ($self, $sql, $args) = &_dr_extract_args_ep;
    my $req = $self->{"private_DBIx::DR_template"}->sql_transform(
        @$sql,
        %$args
    );
    
    carp  _user_sql($req->sql, $req->bind_values) if $args->{'-warn'};
    croak _user_sql($req->sql, $req->bind_values) if $args->{'-die'};

    local $SIG{__DIE__} = sub { croak $self->_dr_decode_err(@_) };
    my $res = $self->do(
            $req->sql,
            $args->{-dbi},
            $req->bind_values
        );
    return $res;
}


sub _dr_decode_err {
    my ($self, @arg) = @_;
    if ($self->{"private_DBIx::DR_dr_decode_errors"}) {
        for (@arg) {
            $_ = eval { decode utf8 => $_ } || $_ unless utf8::is_utf8 $_;
        }
    }
    return @arg if wantarray;
    return join ' ' => @arg;
}


1;

__END__

=head1 NAME

DBIx::DR - easy DBI helper (perl inside SQL and blessed results)

=head1 SYNOPSIS

    my $dbh = DBIx::DR->connect($dsn, $login, $passed);

    $dbh->perform(
        'UPDATE tbl SET a = 1 WHERE id = <%= $id %>',
        id => 123
    );

    my $rowset = $dbh->select(
        'SELECT * FROM tbl WHERE id IN (<% list @$ids %>)',
        ids => [ 123, 456 ]
    );
    my $rowset = $dbh->select(-f => 'sqlfile.sql.ep', ids => [ 123, 456 ]);

    while(my $row = $rowset->next) {
        print "id: %d, value: %s\n", $row->id, $row->value;
    }

=head1 DESCRIPTION

The package I<extends> L<DBI> and allows You:

=over

=item *

to use perl inside Your SQL requests;

=item *

to bless resultsets into Your package;

=item *

to place Your SQL's into dedicated directory;

=item *

to use usual L<DBI> methods.

=back


=head1 Additional 'L<connect|DBI/connect>' options.

=head2 dr_iterator

A string describes iterator class.
Default value is 'B<dbix-dr-iterator#new>' (decamelized string).

=head2 dr_item

A string describes item (one row) class.
Default value is 'B<dbix-dr-iterator-item#new>' (decamelized string).

=head2 dr_sql_dir

Directory path to seek sql files (If You use dedicated SQLs).

=head2 dr_decode_errors

Decode database errors into utf-8

=head2 dr_sql_utf8

Default value: C<true>. If true, it will open sql files with option C<:utf8>.

=head1 METHODS

All methods can receive the following arguments:

=over

=item -f => $sql_file_name

It will load SQL-request from file. It will seek file in directory
that was defined in L<dr_sql_dir> param of connect.

You needn't to use suffixes (B<.sql.ep>) here, but You can.

=item -item => 'decamelized_obj_define'

It will bless (or construct) row into specified class. See below.
Default value defined by L<dr_item> argument of B<DBI::connect>.

=item -noitem

Do not bless row into any class.

=item -iterator => 'decamelized_obj_define'

It will bless (or construct) rowset into specified class.
Default value defined by L<dr_iterator> argument of B<DBI::connect>.

=item -noiterator

Do not bless rowset into any class.

=item -noitem_iter

Do not pass iterator as second argument to item constructor.

=item -dbi => HASHREF

Additional DBI arguments.

=item -hash => FIELDNAME

Selects into HASH. Iterator will operate by names (not numbers).

=item -die => 0|1

If B<true> the method will die with SQL-request.

=item -warn => 0|1

If B<true> the method will warn with SQL-request.

=back

=head2 Decamelized strings

Are strings that represent class [ and method ].

 foo_bar                => FooBar
 foo_bar#subroutine     => FooBar->subroutine
 foo_bar-baz            => FooBar::Baz

=head2 perform

Does SQL-request like 'B<UPDATE>', 'B<INSERT>', etc.

    $dbh->perform($sql, value => 1, other_value => 'abc');
    $dbh->perform(-f => $sql_file_name, value => 1, other_value => 'abc');


=head2 select

Does SQL-request, pack results into iterator class. By default it uses
L<DBIx::DR::Iterator> class.

    my $res = $dbh->select(-f => $sql_file_name, value => 1);
    while(my $row = $res->next) {
        printf "RowId: %d, RowValue: %s\n", $row->id, $row->value;
    }

    my $row = $row->get(15);  # row 15

    my $res = $dbh->select(-f => $sql_file_name,
            value => 1, -hash => 'name');
    while(my $row = $res->next) {
        printf "RowId: %d, RowName: %s\n", $row->id, $row->name;
    }

    my $row = $row->get('Vasya');  # row with name eq 'Vasya'

=head2 single

Does SQL-request that returns one row. Pack results into item class.
Does SQL-request, pack results (one row) into item class. By default it
uses L<DBIx::DR::Iterator::Item|DBIx::DR::Iterator/DBIx::DR::Iterator::Item>
class.


=head1 Template language

You can use perl inside Your SQL requests:

    % my $foo = 1;
    % my $bar = 2;
    <% my $foo_bar = $foo + $bar %>

    ..

    % use POSIX;
    % my $gid = POSIX::getgid;


There are two functions available inside perl:


=head2 quote

Replaces argument to 'B<?>', add argument value into bindlist.
You can also use shortcut 'B<=>' instead of the function.

B<Example 1>

    SELECT
        *
    FROM
        tbl
    WHERE
        id = <% quote $id %>

B<Result>

    SELECT
        *
    FROM
        tbl
    WHERE
        id = ?

and B<bindlist> will contain B<id> value.

If You use L<DBIx::DR::ByteStream> in place of string
the function will recall L<immediate> function.

B<Example 2>

    SELECT
        *
    FROM
        tbl
    WHERE
        id = <%= $id %>


=head2 immediate

Replaces argument to its value.
You can also use shortcut 'B<==>' instead of the function.


B<Example 1>

    SELECT
        *
    FROM
        tbl
    WHERE
        id = <% immediate $id %>


B<Result>

    SELECT
        *
    FROM
        tbl
    WHERE
        id = 123

Where 123 is B<id> value.

Be carful! Using the operator You can produce code that will be
amenable to SQL-injection.

B<Example 2>

    SELECT
        *
    FROM
        tbl
    WHERE
        id = <%== $id %>



=head1 Helpers

There are a few default helpers.

=head2 list

Expands array into Your SQL request.

=head3 Example

    SELECT
        *
    FROM
        tbl
    WHERE
        status IN (<% list @$ids %>)

=head4 Result

    SELECT
        *
    FROM
        tbl
    WHERE
        status IN (?,?,? ...)

and B<bindlist> will contain B<ids> values.


=head2 hlist

Expands array of hash into Your SQL request. The first argument can
be a list of required keys. Places each group into brackets.

=head3 Example


    INSERT INTO
        tbl
            ('a', 'b')
    VALUES
        <% hlist ['a', 'b'] => @$inserts


=head4 Result


    INSERT INTO
        tbl
            ('a', 'b')
    VALUES
        (?, ?), (?, ?) ...


and B<bindlist> will contain all B<inserts> values.


=head2 include

Includes the other SQL-part.

=head3 Example

    % include 'other_sql', argument1 => 1, argument2 => 2;


=head2 stacktrace

Returns perl stacktrace. You can use the helper for debug Your code.
The helper receives the following position-arguments:

=over

=item (first) $skip (default = 0)

How many frames to skip.

=item (second) $dept (default = 0)

How many frames to print.

=item (third) $separator (default ", ")

Separator between stackframes.

=back

=head3 Examples

    /* <%= stacktrace %> */

    /* <%= stacktrace $skip, $depth, $separator %> */


=head1 User's helpers

You can add Your helpers using method L<set_helper>.

=head2 set_helper

Sets (or replaces) helpers.

    $dbh->set_helper(foo => sub { ... }, bar => sub { ... });

Each helper receives template object as the first argument.

Examples:

    $dbh->set_helper(foo_AxB => sub {
        my ($tpl, $a, $b) = @_;
        $tpl->quote($a * $b);
    });

You can use L<quote> and L<immediate> functions inside Your helpers.

If You want use the other helper inside Your helper You have to do that
by Yourself. To call the other helper You can also use C<< $tpl->call_helper >>
function.

=head3 call_helper

    $dbh->set_helper(
        foo => sub {
            my ($tpl, $a, $b) = @_;
            $tpl->quote('foo' . $a . $b);
        },
        bar => sub {
            my $tpl = shift;
            $tpl->call_helper(foo => 'b', 'c');
        }
    );

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<https://github.com/unera/dbix-dr/>

=cut

