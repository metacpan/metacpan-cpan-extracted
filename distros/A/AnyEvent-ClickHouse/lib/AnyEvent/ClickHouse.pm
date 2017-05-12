package AnyEvent::ClickHouse;

use 5.010000;
use strict;
no strict 'refs';
use warnings;

our $VERSION = '0.031';

use vars qw(@ISA @EXPORT);
our @ISA = qw(Exporter);
our @EXPORT = qw(clickhouse_do clickhouse_select clickhouse_select_array clickhouse_select_hash);

use AnyEvent;
use AnyEvent::HTTP;
use URI;
use URI::QueryParam;
use Scalar::Util qw/looks_like_number/;

use Data::Dumper;

our $headers;
$headers->{'User-agent'} =  'Mozilla/5.0 (compatible; U; Perl-AnyEvent-ClickHouse;)';
$headers->{'Te'} =  undef;
$headers->{'Referer'} =  undef;
$headers->{'Connection'} =  'Keep-Alive';

sub _init {
	my $param = shift;

    my %_param = (
        host        => '127.0.0.1',
        port        => 8123,
        database    => 'default',
        user        => undef,
        password    => undef
    );
    foreach my $_key ( keys %_param ) {
        unless ($param->{$_key}){
            $param->{$_key} = $_param{$_key};
        }
    }

    unless ($param->{uri}) {
        my $_uri = URI->new(sprintf ("http://%s:%d/",$param->{host},$param->{port}));
        $_uri->query_param('user' => $param->{user}) if $param->{user};
        $_uri->query_param('password' => $param->{password}) if $param->{password};
        $_uri->query_param('database' => $param->{database});
        $param->{uri} = $_uri;
    }

	return $param;
}

sub _data_prepare {
    my $self = shift;
    my @_rows = map { [@$_] } @_;
    foreach my $row (@_rows) {
        foreach my $val (@$row) {
            unless (defined ($val)) {
                $val = qq{''};
            }
            elsif (ref($val) eq 'ARRAY') {
                $val = q{'}.join ("','", @$val).q{'};
            }
            elsif (defined ($val) && !looks_like_number($val)) {
                $val =~  s/\\/\\\\/g;
                $val =~  s/'/\\'/g;
                $val = qq{'$val'};
            }
        }
    } 
    return scalar @_rows ? join ",", map { "(".join (",", @{ $_ }).")" } @_rows : "\n"; 
}

sub clickhouse_do {
    my $param = shift;
    my $query = shift;
    my $cb = shift;
    my $err_cb = shift;
    my $data = _data_prepare(@_);

    $param = _init $param;
    $param->{uri}->query_param('query' => $query);

    http_request
        POST => $param->{uri}->as_string(),
        body => $data,
        headers => $headers,
        persistent => 1,
        keepalive => 1,
        sub {
            my $data = shift;
            my $hdr = shift;
            my $status = $hdr->{Status};

            if ($status == 200){
                # do ok
                if (defined $cb && ref $cb eq 'CODE') {
                    $cb->($data);
                }
            }
            else {
                # 500 error
                if (defined $err_cb && ref $err_cb eq 'CODE') {
                    # if defined err cb func
                    $err_cb->($data);
                }
            }            
        }
    ;
}

sub _select {
    my $format = shift;
    my $param = shift;
    my $query = shift;
    my $cb = shift;
    my $err_cb = shift;

    $param = _init $param;
    $param->{uri}->query_param('query' => $query);

    http_request
        GET => $param->{uri}->as_string(),
        headers => $headers,
        persistent => 1,
        keepalive => 1,
        sub {
            my $data = shift;
            my $hdr = shift;
            my $status = $hdr->{Status};

            if ($status == 200){
                # select ok
                unless ($format eq 'raw') {
                    $data = $format->($data);
                }
                $cb->($data);
            }
            else {
                # 500 error
                if (defined $err_cb && ref $err_cb eq 'CODE') {
                    # if defined err cb func
                    $err_cb->($data);
                }
            }
        }
    ;
}

sub clickhouse_select {
    unshift @_, 'raw';
    &_select;
}

sub clickhouse_select_array {
    unshift @_, sub {
        my @data = split /\n/, shift;
        return [ map { [ split (/\t/) ] } @data ];
    };
    &_select;
}

sub clickhouse_select_hash {
    my $param = shift;
    my $query = shift;
    $query .= ' FORMAT TabSeparatedWithNames';

    unshift @_, $query;
    unshift @_, $param;
    unshift @_, sub {
        my @data = split /\n/, shift;
        my @_response = @{[ map { [ split (/\t/) ] } @data ]};
        my $response;
        my $key = shift @_response;
        for (0..$#_response) {
            my $row = $_;
            for (0..$#{$_response[$row]}) {
                my $col = $_;
                $response->[$row]->{"".$key->[$col].""} = $_response[$row][$_];
            }
        }
        return $response;
    };
    &_select;
}

1;

__END__


=head1 NAME

AnyEvent::ClickHouse - Simple but non-blocking HTTP client for ClickHouse Database

=head1 VERSION

Version 0.031

=head1 SYNOPSIS

    use AnyEvent::ClickHouse;

    clickhouse_select
        {   # connection options
            host        => '127.0.0.1',
            port        => 8123,
            user        => 'Harry',
            password    => 'Alohomora',
            database    => 'Hogwarts'
        },
        'select * from test FORMAT Pretty', # query
        sub {   # callback function if status ok 200
            my $data = shift;
        },
        sub {   # callback function if status error 500
            my $data = shift;
        }
    ;

    # ... do something else here  

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements a simple and non-blocking HTTP
client for ClickHouse Database. It supports clickhouse_do, clickhouse_select
clickhouse_select_array and clickhouse_select_hash methods.

=head1 DEFAULTS

    # connection options
    {
            host        => '127.0.0.1',
            port        => 8123
            database    => 'default'
    }

=head1 BASIC METHODS

=head2 clickhouse_select

Fetch data from the table (readonly). 

By default, data is returned in TabSeparated format.
You use the FORMAT clause of the query to request any other format.

=over 4

=item * Native

=item * TabSeparated                   (default)

=item * TabSeparatedWithNames

=item * CSV

=item * Pretty

=item * JSON

=item * XML

=item * ...

=back

L<https://clickhouse.yandex/reference_en.html#Formats>

    clickhouse_select
        {
            host        => '127.0.0.1',
            user        => 'Harry',
            password    => 'Alohomora'
        },
        'select * from test',
        sub {   # callback function if status ok 200
            my $data = shift;

            # ... do something
            # print $data;
        },
        sub {   # callback function if status error 500
            my $data = shift;

            # do something
            # print "err: ".$data."\n";
        }
    ;

You can use URI

    use URI;
    use URI::QueryParam;

    my $uri = URI->new(sprintf ("http://%s:%d/",'127.0.0.1',8123));  # host and port
    $uri->query_param('user' => 'Harry');
    $uri->query_param('password' => 'Alohomora');
    $uri->query_param('database' => 'default');

    clickhouse_select
        { 
            uri => $uri
        },
        ...


=head2 clickhouse_do

Universal method for any queries inside the database,
which modify data (insert data, create, alter, detach or drop table or partition).

    clickhouse_do
        {
            host        => '127.0.0.1',
            user        => 'Harry',
            password    => 'Alohomora'
        },
        "INSERT INTO test (id, f1, f2) VALUES",
        sub {   # callback function if status ok 200
            my $data = shift;
            # do something
        },
        undef,   # You can skip callback function
        [1, "Gryffindor", "a546825467 1861834657416875469"],
        [2, "Hufflepuff", "a18202568975170758 46717657846"],
        [3, "Ravenclaw", "a678 2527258545746575410210547"],
        [4, "Slytherin", "a1068267496717456 878134788953"]
    ;


=head1 ADDITIONAL  METHODS

=head2 clickhouse_select_array

Fetch data from the table (readonly). 
It returns a reference to an array that contains a references to an arrays for each row of data fetched.

Don't use FORMAT in query!

    clickhouse_select_array
        {
            host        => '127.0.0.1',
            user        => 'Harry',
            password    => 'Alohomora'
        },
        'select * from test',
        sub {   # callback function if status ok 200
            my $data = shift;

            # ... do something

            # foreach my $row (@$data) {
            #     # Do something with your row
            #     foreach my $col (@$row) {
            #         # ... Do something
            #         print $col."\t";
            #     }
            #     print "\n";
            # }

        },
        sub {   # callback function if status error 500
            my $data = shift;

            # do something
            # print "err: ".$data."\n";
        }
    ;

=head2 clickhouse_select_hash

Fetch data from the table (readonly). 
Returns a reference to an array that contains a hashref to the names of the columns (as keys)
and the data itself (as values).

Don't use FORMAT in query!

    clickhouse_select_hash
        {
            host        => '127.0.0.1',
            user        => 'Harry',
            password    => 'Alohomora'
        },
        'select * from test',
        sub {   # callback function if status ok 200
            my $data = shift;

            # ... do something

            # foreach my $row (@$data) {
            #     # Do something with your row
            #     foreach my $key (keys %{$row}){
            #         # ... Do something
            #         print $key." = ".$row->{$key}."\t";
            #     }
            #     print "\n";
            # }

        },
        sub {   # callback function if status error 500
            my $data = shift;

            # do something
            # print "err: ".$data."\n";
        }
    ;

=head1 SEE ALSO

=over 4

=item * ClickHouse official documentation   L<https://clickhouse.yandex/reference_en.html>

=item * AnyEvent   L<AnyEvent>

=item * AnyEvent::Log   L<AnyEvent::Log>

=back

=head1 AUTHOR

Maxim Motylkov

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

   Copyright 2016 Maxim Motylkov

   This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION,
   THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
