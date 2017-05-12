package ArangoDB::Statement;
use strict;
use warnings;
use utf8;
use 5.008001;
use Carp qw(croak);
use JSON ();
use Scalar::Util qw(weaken);
use ArangoDB::Cursor;
use ArangoDB::BindVars;
use ArangoDB::Constants qw(:api);

use overload
    q{""}    => sub { $_[0]->{query} },
    fallback => 1;

sub new {
    my ( $class, $conn, $query ) = @_;
    my $self = bless {
        connection => $conn,
        query      => $query,
        bind_vars  => ArangoDB::BindVars->new(),
    }, $class;
    weaken( $self->{connection} );
    return $self;
}

sub execute {
    my ( $self, $options ) = @_;
    my $data = $self->_build_data($options);
    my $res = eval { $self->{connection}->http_post( API_CURSOR, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to execute query' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

sub parse {
    my $self = shift;
    my $res = eval { $self->{connection}->http_post( API_QUERY, { query => $self->{query} } ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to parse query' );
    }
    return $res->{bindVars};
}

sub explain {
    my $self = shift;
    my $data = { query => $self->{query}, bindVars => $self->{bind_vars}->get_all(), };
    my $res  = eval { $self->{connection}->http_post( API_EXPLAIN, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to explain query' );
    }
    return $res->{plan};
}

sub bind_vars {
    my $self = shift;
    if ( @_ == 0 ) {
        return $self->{bind_vars}->get_all();
    }
    else {
        my $name = shift;
        return $self->{bind_vars}->get($name);
    }
}

sub bind {
    my ($self) = shift;
    if ( @_ == 1 ) {
        $self->{bind_vars}->set( $_[0] );
    }
    else {
        my ( $key, $value ) = @_;
        $self->{bind_vars}->set( $key => $value );
    }
    return $self;
}

sub _build_data {
    my ( $self, $options ) = @_;
    my $data = {
        query => $self->{query},
        count => $options->{do_count} ? JSON::true : JSON::false,
    };

    if ( $self->{bind_vars}->count > 0 ) {
        $data->{bindVars} = $self->{bind_vars}->get_all();
    }

    if ( exists $options->{batch_size} && $options->{batch_size} > 0 ) {
        $data->{batchSize} = $options->{batch_size};
    }

    return $data;
}

sub _server_error_handler {
    my ( $self, $error, $message ) = @_;
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $message .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $message;
}

1;
__END__


=pod

=head1 NAME

ArangoDB::Statement - An ArangoDB AQL handler

=head1 SYNOPSIS

    use ArangoDB;
    
    my $db = ArangoDB->new(
        host => 'localhost',
        port => 8529,
    );
  
    my $sth = $db->query('FOR u IN users FILTER u.active == true RETURN u');
    my $cursor = $sth->execute({ 
        do_count => 1, 
        batch_size => 10,
    });
    while( my $doc = $cursor->next() ){
        # do something
    }
  
    # Use bind variable
    my $documents = $db->query(
        'FOR u IN users FILTER u.age >= @age SORT u.name ASC RETURN u'
    )->bind( age => 18 )->execute()->all;

=head1 DESCRIPTION

An AQL(ArangoDB Query Language) statement handler.

=head1 METHODS

=head2 new($conn,$query)

Constructor.

=over 4

=item $conn 

Instance of ArangoDB::Connection.

=item $query 

AQL statement.

=back

=head2 execute($options)

Execute AQL query and returns cursor(instance of L<ArangoDB::Cursor>).

$options is query options.The attributes of $options are:

=over 4

=item batch_size

Maximum number of result documents to be transferred from the server to the client in one roundtrip (optional). 

=item do_count

Boolean flag that indicates whether the number of documents found should be returned as "count" attribute in the result set (optional).

=back

=head2 parse()

Parse a query string without executing.

Return ARRAY reference of bind variable names.

=head2 explain()

Get execution plan of query.

Returns ARRAY reference.

=head2 bind_vars($name)

Returns bind variable based on $name.

If $name does not passed, returns all bind variables as HASH reference.

=head2 bind($vars)

=head2 bind($key => $value)

Set bind variable(s).

=over 4

=item $vars 

HASH reference that set of key/value pairs.

=item $key 

Bind variable name.

=item $value 

Bind variable value.

=back

Returns instance of L<ArangoDB::Statement>.You can use method chain:

    my $documents = $db->query(
        'FOR u IN users FILTER u.type == @type && u.age >= @age SORT u.name ASC RETURN u'
    )->bind({
        type => 1, 
        age  => 19 
    })->execute->all;

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
