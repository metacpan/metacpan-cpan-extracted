
package API::Plesk::Response;

use strict;
use warnings;

use Data::Dumper;

sub new {
    my ( $class, %attrs) = @_;
    $class = ref $class || $class;

    my $operator  = $attrs{operator};
    my $operation = $attrs{operation};
    my $response  = $attrs{response};
    my $results = [];
    my $is_success = 1;

    # internal API::Plesk error
    if ( $attrs{error} ) {
        $results = [{
            errcode => '',
            errtext => $attrs{error},
            status  => 'error'
        }];
        $is_success = '';
    }
    # remote system plesk error
    elsif ( exists $response->{packet}->{'system'} ) {
        $results = [$response->{packet}->{'system'}];
        $is_success = '';
        $operator   = 'system';
        $operation  = '';
    }
    else {
        eval {
            for my $result ( @{$response->{packet}->{$operator}->{$operation}->[0]->{result}} ) {
                push @$results, $result;
                $is_success = '' if $result->{status} && $result->{status} eq 'error';
            }
            1;
        } || do {
            $results = [{
                errcode => '',
                errtext => "Internal Plesk error: $_.\nError: $@\nDetails:" . Dumper( $response ),
                status  => 'error'
            }];
        };
    }

    my $self = {
        results     => $results,
        operator   => $operator,
        operation  => $operation,
        is_success => $is_success,
    };

    return bless $self, $class;
}

sub is_success { $_[0]->{is_success} }

sub id   { $_[0]->{results}->[0]->{id} }
sub guid { $_[0]->{results}->[0]->{guid} }

sub data {
    my ( $self ) = @_;
    return [] unless $self->is_success;
    return [ map { $_->{data} || () } @{$self->{results}} ];
}

sub results {
    my ( $self ) = @_;
    return   unless $self->is_success;
    return $self->{results} || [];
}

sub error_code { $_[0]->error_codes->[0]; }
sub error_text { $_[0]->error_texts->[0]; }

sub error {
    my ( $self ) = @_;
    return ($self->{results}->[0]->{errcode} || '0') . ': ' .  $self->{results}->[0]->{errtext};
}

sub error_codes {
    my ( $self ) = @_;
    return [] if $self->is_success;
    return [ map { $_->{errcode} || () } @{$self->{results}} ];
}

sub error_texts {
    my ( $self ) = @_;
    return [] if $self->is_success;
    return [ map { $_->{errtext} || () } @{$self->{results}} ];
}

sub errors {
    my ( $self ) = @_;
    return [] if $self->is_success;
    my @errors;
    for ( @{$self->{results}} ) {
        my $error = ($_->{errcode} || '0') . ': ' .  $_->{errtext};
        push @errors, $error;
    }
    return \@errors;
}

sub is_connection_error {
    my ( $self ) = @_;

    return
        $self->error_text =~ /connection failed/ ||
        $self->error_text =~ /connection timeout/ ||
        $self->error_text =~ /500\s+/
            ? 1 : 0;
}

1;

__END__

=head1 NAME

API::Plesk::Response -  Class for processing server answers with errors handling.

=head1 SYNOPSIS

    my $res = API::Plesk::Response->new(
        operator => 'customer',
        operation => 'get',
        response => 'xml answer from plesk api',
    );

    $res->is_success;
    $res->is_connection_error;

    # get errors
    $res->error_code;
    $res->error_codes->[0];
    $res->error_text;
    $res->error_texts->[0];
    $res->error;
    $res->errors->[0];

    # get data sections
    $res->data->[0];

    # get result sections
    $res->results->[0];

    # get id and guid
    $res->id;
    $res->guid;


=head1 DESCRIPTION

This class is intended for convenient processing results of Plesk API responses.
Every operation of API::Plesk::Component return object of this class.
And it get you easy way to manipulate with response from Plesk API.

=head1 METHODS

=over 3

=item new(%attributes)

Create response object.

=item is_success()

Returns true if all results have no errors.

=item is_connection_error()

Returns true if connection error happened.

=item data()

    $response->data;
    $response->data->[0];

=item results()

    $response->results;
    $response->results->[0];

=item error_code()

    $response->error_code;

=item error_codes()

    $response->error_codes->[0];

=item error_text()

    $response->error_text;

=item error_texts()

    $response->error_texts->[0];

=item error()

    $response->error;

=item errors()

    $response->errors->[0];

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
