package ClickHouse;

use 5.010;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.05';

use Net::HTTP;
use URI;
use URI::Escape;
use URI::QueryParam;
use Carp;
use Scalar::Util qw/looks_like_number/;
use Try::Tiny;

our $AUTOLOAD;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;
    $self->_init(%opts);
    return $self;
}

{
    my %_attrs = (
        '_host'       => 'localhost',
        '_port'       => 8123,
        '_database'   => 'default',
        '_user'       => '',
        '_password'   => '',
        '_keep_alive' => 1,
        '_format'     => 'TabSeparated',
        '_socket'     => undef,
        '_uri'        => undef,
        '_timeout'    => 30,
    );

    #
    # CLASS METHODS
    #
    # Returns a copy of the instance.
    sub _clone {
        my ($self)  = @_;
        my ($clone) = {%$self};
        bless( $clone, ref $self );
        return ($clone);
    }

    # Verify that an attribute is valid (called by the AUTOLOAD sub)
    sub _accessible {
        my ( $self, $name ) = @_;
        if ( exists $_attrs{$name} ) {

            #$self->verbose("attribute $name is valid");
            return 1;
        }
        else { return 0; }
    }

    # Initialize the object (only called by the constructor)
    sub _init {
        my ( $self, %args ) = @_;

        foreach my $key ( keys %_attrs ) {
            $key =~ s/^_+//;
            if ( defined ($args{$key}) && $self->_accessible( "_$key" ) ) {
                $self->{"_$key"} = $args{$key};
            }
            else {
                $self->{"_$key"} = $_attrs{"_$key"};
            }
        }
        $self->{'_builder'} = \&_builder;

        $self->_connect();

        return 1;
    }

    sub _builder {
        my ($self) = @_;
        delete $self->{'_socket'};
        delete $self->{'_uri'};

        # create Net::HTTP object
        my $socket = Net::HTTP->new(
            'Host'        => $self->{'_host'},
            'PeerPort'    => $self->{'_port'},
            'HTTPVersion' => '1.1',
            'KeepAlive'   => $self->{'_keep_alive'},
            'Timeout'     => $self->{'_timeout'},

        ) or die "Can't connect: $@";

        # create URI object
        my $uri = URI->new(sprintf ("/?database=%s", $self->{'_database'}));
        $uri->query_param('user' => $self->{'_user'}) if $self->{'_user'};
        $uri->query_param('password' => $self->{'_password'}) if $self->{'_password'};

        $self->{'_socket'} = $socket;
        $self->{'_uri'} = $uri;

        return 1;

    }

    sub _connect {
        my ($self) = @_;
        $self->_builder($self);
        return 1;
    }

    sub _query {
        my ($self, $cb) = @_;
        return &try (
            $cb,
            catch {
                $self->_connect();
                $cb->();
            }
        );
    }
}

sub ClickHouse::AUTOLOAD {
    no strict 'refs';
    my ( $self, $value ) = @_;
    if ( ( $AUTOLOAD =~ /.*::_get(_\w+)/ ) && ( $self->_accessible($1) ) ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
        return ( $self->{$attr_name} );
    }
    if ( $AUTOLOAD =~ /.*::_set(_\w+)/ && $self->_accessible($1) ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return; };
        $self->{$1} = $value;
        return;
    }
    croak "No such method: $AUTOLOAD";
}

sub DESTROY {}

sub disconnect {
    my ($self) = @_;
    if (my $socket = $self->_get_socket()) {
        $socket->keep_alive(0);
        $self->ping();
    }
    return 1;
}



sub select {
    my ($self, $query) = @_;
    return $self->_query(sub {
        my $method;
        my $query_url;
        my @post_data = ();
        if (length ($query) <= 7000) {
            $query_url = $self->_construct_query_uri( $query );
            $method = 'GET';
        }
        else {
            $query_url = $self->_get_uri()->clone();
            $method = 'POST';
            push @post_data, $query;
        }


        $self->_get_socket()->write_request( $method => $query_url, @post_data );
        return $self->_parse_response($query);
    });
}

sub select_value {
    my ($self, $query) = @_;

    my $arrayref = $self->select($query);
    return $arrayref->[0]->[0];
}

sub do {
    my ($self, $query, @rows) = @_;
    return $self->_query(sub {
        my @prepared_rows = $self->_prepare_query(@rows);
        my $query_url = $self->_construct_query_uri($query);
        my $post_data = scalar @prepared_rows ? join (",", map { "(" . join (",", @{ $_ }) . ")" } @prepared_rows) : "\n" ;

        $self->_get_socket()->write_request('POST' => $query_url, $post_data);
        return $self->_parse_response($query);
    });

}

sub ping {
    my ($self) = @_;

    my ($code) = eval {
        $self->_get_socket()->write_request('GET' => '/');
        $self->_get_socket()->read_response_headers();
    };

    if ($@) {
        return 0;
    }
    unless ($code == 200) {
        return 0;
    }
    my $result = $self->_read_body();
    unless ($result->[0] eq 'Ok.' ) {
        return 0;
    }
    return 1;
}

sub _parse_response {
    my ($self, $query) = @_;
    my ($code, $mess) = $self->_get_socket()->read_response_headers();
    if ($code == 200 ) {
        return _formaty_query_result( $self->_read_body() );
    }
    else {
        my $add_mess = _formaty_query_result( $self->_read_body() );
        if (defined $add_mess) { $add_mess = $add_mess->[0]->[0] // '' };
        die "ClickHouse error: $mess ($add_mess)\n\t$query";
    }
}

sub _read_body {
    my ($self) = @_;

    my @response;
    my $chunk = '';
    while (1) {
        my $buf;
        my $n = $self->_get_socket()->read_entity_body($buf, 1024);
        die "can't read response: $!" unless defined $n;
        last unless $n;
        $buf = $chunk . $buf;
        push @response, split (/\n/, $buf);
        $chunk = substr ($buf,-1) eq "\n" ? '' : pop @response;
    }
    push @response, $chunk if $chunk;
    return \@response;
}

sub _formaty_query_result {
    my ($query_result) = @_;
    return [ map { [ split (/\t/) ] } @{ $query_result } ];
}


sub _construct_query_uri {
    my ($self, $query) = @_;

    my $query_uri = $self->_get_uri()->clone();
    $query_uri->query_param('query' => $query);

    return $query_uri->as_string();
}

sub _prepare_query {
    my ($class, @rows) = @_;
    my @clone_rows = map { [@$_] } @rows;
    foreach my $row (@clone_rows) {
        foreach my $value (@$row) {
            my $type = 'NUMBER';
            if (ref $value eq 'HASH') {
                $type = $value->{'TYPE'};
                $value = $value->{'VALUE'};
            }
            unless (defined ($value)) {
                $type = 'NULL';
            }
            if (ref $value eq 'ARRAY') {
                $type = 'ARRAY';
            }
            if ( defined ($value) && !looks_like_number ($value)) {
                $type = 'STRING';
            }
            $value = _escape_value($value, $type);
        }
    }
    return @clone_rows;
}

sub _escape_value {
    my ($value, $type) = @_;
    if ($type eq 'NULL') {
        $value = qq{''};
    }
    elsif ($type eq 'STRING') {
        utf8::encode($value) if utf8::is_utf8($value);
        $value =~  s{\\}{\\\\}g;
        $value =~  s/'/\\'/g;
        $value = qq{'$value'};
    }
    elsif ($type eq 'ARRAY') {
        $value = q{'} . join ("','", @$value) . q{'};
    }
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ClickHouse - Database driver for Clickhouse OLAP Database

=head1 VERSION

Version 0.05




=head1 SYNOPSIS

ClickHouse - perl interface to Clickhouse Database. My final goal is to create DBI compatible driver for ClickHouse, but for now it's standalone module.

It's the first version and so module is EXPERIMENTAL. I can't guarantee API stability. More over, API will probably change and it will be soon.

This module is a big rough on the edges, but I decided to release it on CPAN so people can start playing around with it.


=head1 EXAMPLE

    use ClickHouse;

    my $ch = ClickHouse->new(
        host     => $ENV{'CLICK_HOUSE_HOST'}
        port     => 8123,
        user     => 'Frodo'
        password => 'finger',
        timeout  => 5,
    );

    my $rows = $ch->select("SELECT id, field_one, field_two FROM some_table");

    for my $row (@$rows) {
        # Do something with your row
    }

    $ch->do("INSERT INTO some_table (id, field_one, field_two) VALUES",
        [1, "String value", 38962986],
        [2, "String value", 38962986],
    );


=head1 SUBROUTINES/METHODS

=head2 new

Create new connection object

=head2 select

Fetch data from table. It returns a reference to an array that contains one reference per row (similar to DBI::fetchall_arrayref).

=head2 do

Modify data inside the database. It's universal method for any queries, which modify data. So if you want to create, alter, detach or drop table or partition or insert data into table it's your guy.

=head1 AUTHOR

Ilya Rassadin, C<< <elcamlost at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/elcamlost/perl-DBD-ClickHouse/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ClickHouse


You can also look for information at:

=over 4

=item * ClickHouse official documentation

L<https://clickhouse.yandex/reference_en.html>

=item * Metacpan

L<https://metacpan.org/pod/ClickHouse/>

=item * GitHub

L<https://github.com/elcamlost/perl-DBD-ClickHouse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ClickHouse>

=item * Search CPAN

L<http://search.cpan.org/dist/ClickHouse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ilya Rassadin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

   The Artistic License 2.0 (GPL Compatible)

Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution. Such use shall not be
construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
