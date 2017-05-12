package Data::HandyGen::mysql::ColumnDef;

use strict;
use warnings;

our $VERSION = '0.0.2';
$VERSION = eval $VERSION;

use Carp;


=head1 NAME

Data::HandyGen::mysql::ColumnDef - Manages one column definition 


=head1 VERSION

This documentation refers to Data::HandyGen::mysql::ColumnDef version 0.0.2


=head1 SYNOPSIS

    use Data::HandyGen::mysql::ColumnDef;
    
    my $cd = Data::HandyGen::mysql::ColumnDef->new('colname', %column_definition);

    #  true if 'colname' is auto_increment
    my $res = $cd->is_auto_increment();
    
    #  get column type 
    my $type = $cd->data_type();
    

=head1 CAUTION

This module is not intended for use outside Data::HandyGen. Its interface may be changed in the future.


=head1 DESCRIPTION

This class is a container of column definition retrieved from information_schema.columns.


=head1 METHODS 


=head2 new($colname, %params)

Constructor.

%params is a hash which contains a column definition retrieved from information_schema.columns. 


=cut

sub new {
    my ($inv, $colname, @defs) = @_;

    my %params = ();
    if (@defs == 1 and ref $defs[0] eq 'HASH') {
        %params = %{ $defs[0] };
    }
    elsif (@defs % 2 == 0) {
        %params = @defs;
    }
    else {
        confess "Invalid nums of defs. num = " . scalar(@defs);
    }

    for my $key (keys %params) {
        if ( uc $key ne $key ) {
            $params{uc $key} = delete $params{$key};
        }
    }

    my $class = ref $inv || $inv;
    my $self = bless { name => $colname, %params }, $class;

    return $self;
}


=head2 name()

Returns column name.

=cut

sub name { shift->{name}; }


=head2 is_auto_increment()

Returns 1 if the column is auto_increment. Otherwise returns 0.

=cut

sub is_auto_increment {
    my ($self) = @_;

    return ( $self->{EXTRA} =~ /auto_increment/ ) ? 1 : 0;
}


=head2 To retrieve other attributes

information_schema.columns has many attributes. You can retrieve one of them by using a method which name corresponds to attribute name in lowercase.

For example, you can retrieve 'DATA_TYPE' like this:

    $type = $column_def->data_type();

=cut

sub AUTOLOAD {
    my ($self) = @_;

    our $AUTOLOAD;
    $AUTOLOAD =~ /::(\w+)$/;
    my $key = uc($1);

    return if $key eq 'DESTROY';   #  do nothing

    if ( exists($self->{$key}) ) {
        return $self->{$key};
    }
    else {
        confess "[$AUTOLOAD] : no such attribute";
    }

}


1;


__END__


=head1 AUTHOR

Egawata 


=head1 LICENCE AND COPYRIGHT

Copyright (c)2013-2014 Egawata All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
