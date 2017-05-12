use strict;
use warnings;
use Carp ();
use 5.8.1;
use utf8;
use Encode ();
use DBIx::Simple 1.28;

$Carp::Internal{$_} = 1
    for qw( DBIx::Simple::UTF8Columns
            DBIx::Simple::UTF8Columns::Result );

package DBIx::Simple::UTF8Columns;

our $VERSION = '0.03';

use base qw( DBIx::Simple );

our $DEFAULT_ENCODING = 'utf8';

sub connect {
    my $class = shift;
    my $db    = $class->SUPER::connect(@_);

    if (defined $db) {
        # 'result_class' is lvalue
        $db->result_class = 'DBIx::Simple::UTF8Columns::Result';
    }

    return $db;
}

sub encoding {
    my $self = shift;

    if (! ref $self) {      # class method
        if (@_) {
            $DEFAULT_ENCODING = shift;
        }
        return $DEFAULT_ENCODING;
    }
    else {                  # instance method
        if (@_) {
            $self->{_encoding} = shift;
            $self->{_encoder}  = undef;
        }
        elsif (! defined $self->{_encoding}) {
            $self->{_encoding} = $DEFAULT_ENCODING;
            $self->{_encoder}  = undef;
        }
        return $self->{_encoding};
    }
}

sub _encoder {
    my $self = shift;

    if (! defined $self->{_encoder}) {
        $self->{_encoder} = Encode::find_encoding($self->encoding);
    }

    return $self->{_encoder};
}

sub query {
    my ($self, $query, @binds) = @_;

    foreach my $data ($query, @binds) {
        if (defined $data && ! ref $data && utf8::is_utf8($data)) {
            $data = $self->_encoder->encode($data);
        }
    }

    my $result = $self->SUPER::query($query, @binds);
    
    if ($self->{success} && defined $result) {
        $result->{_encoder} = $self->_encoder;
    }

    return $result;
}

package DBIx::Simple::UTF8Columns::Result;

use base qw( DBIx::Simple::Result );
use Carp;

sub _encoder {
    my ($self) = @_;

    if (! defined $self->{_encoder}) {
        $self->{_encoder}
            = Encode::find_encoding($DBIx::Simple::UTF8Columns::DEFAULT_ENCODING);
    }

    return $self->{_encoder};
}

sub _decode {
    my ($self, $data) = @_;
    
    if (defined $data && ! utf8::is_utf8($data)) {
        $data = $self->_encoder->decode($data);
    }
    return $data;
}

sub _encode {
    my ($self, $data) = @_;
    
    if (defined $data && utf8::is_utf8($data)) {
        $data = $self->_encoder->encode($data);
    }
    return $data;
}

# UNSUPPORTED: func, attr
# UNTOUCH:     columns
# UNSUPPORTED: bind, fetch, into

sub list {
    my $self = shift;

    my @results = $self->SUPER::list(@_);

    if (wantarray) {
        foreach my $result (@results) {
            $result = $self->_decode($result);
        }
        return @results;
    }
    else {
        return $self->_decode($results[-1]);
    }
}

sub array {
    my $self = shift;

    my $ref_result = $self->SUPER::array(@_);

    if (defined $ref_result) {
        foreach my $data (@$ref_result) {
            $data = $self->_decode($data);
        }
    }

    return $ref_result;
}

sub hash {
    my $self = shift;

    my $ref_results = $self->SUPER::hash(@_);

    if (defined $ref_results) {
        foreach my $result (values %$ref_results) {
            $result = $self->_decode($result);
        }
    }

    return $ref_results;
}

# UNTOUCH:     flat

sub arrays {
    my $self = shift;

    my @results = $self->SUPER::arrays(@_);
    foreach my $result (@results) {
        foreach my $column (@$result) {
            $column = $self->_decode($column);
        }
    }
    return wantarray ? @results : \@results;
}

# UNTOUCH:     hashes, map_hashes, map_arrays, map, rows, xto, html, text

1;
__END__

=head1 NAME

DBIx::Simple::UTF8Columns - Force UTF-8 flag for DBIx::Simple data

=head1 SYNOPSIS

    use DBIx::Simple::UTF8Columns;
    
    $db = DBIx::Simple::UTF8Columns->connect(...);
    
    # specify encoding of database' explicitly
    $db->encoding('utf8');
    # default is 'utf8', determined by global $DEFAULT_ENCODING
    $DBIx::Simple::UTF8Columns::DEFAULT_ENCODING = 'cp932';
    
    $record = $db->query(...)->hash;
    # now all of $record->{...} are UTF-8 flagged strings
    
    # you can supply UTF-8 flaged arguments to query
    $result = $db->query('INSERT INTO foo VALUES ??', "\x{263a}");
    
    # DBIx::Simple::OO is also supported
    use DBIx::Simple::OO;
    $record = $db->query(...)->object;
    # $record->field returns string with UTF-8 flag

=head1 DESCRIPTION

This module allows you to use string with UTF-8 flag (aka Unicode flag) as any
arguments and results of DBIx::Simple.  Also you can specify the encoding of
database other than UTF-8.

=head1 MISCELLANEOUS

Field name with UTF-8 flag is not supported.

Some methods in original module are not supported, such as
C<func>, C<attr>, C<bind>, C<fetch>, C<into>.

Functionalities with SQL::Abstract are tested, but those with
DBIx::XHTML_Table and Text::Table are not tested yet.

=head1 AUTHOR

ITO Nobuaki E<lt>daydream.trippers+cpan@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Simple>, L<DBIx::Class::UTF8Columns>, L<Template::Stash::ForceUTF8>

=cut
