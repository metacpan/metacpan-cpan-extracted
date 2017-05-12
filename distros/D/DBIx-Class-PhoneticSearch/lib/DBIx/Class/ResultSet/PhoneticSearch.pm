package DBIx::Class::ResultSet::PhoneticSearch;

use base 'DBIx::Class::ResultSet';

use strict;
use warnings;

use Carp;

sub search_phonetic {
    my ( $self, $search, $attributes ) = @_;
    
    $attributes ||= {};

    my $source = $self->result_source;
    
    my @search =
        ref $search eq 'ARRAY' ? @{$search}
      : ref $search eq 'HASH'  ? %{$search}
      :   croak 'search_phonetic takes an arrayref or a hashref';

    my $type = ref $search eq 'ARRAY' ? '-or' : '-and';

    my $query = [];

    while ( my $column = shift @search ) {
        my $value = shift @search;
        $column =~ s/^(.*?\.)?(.*)$/$2/;
        my $prefix = $1 || q{};
        my $info = $source->column_info($column);
        croak qq(Column '$column' is not a phonetic column)
          unless ( my $config = $info->{phonetic_search} );
          
        my $class  = 'Text::Phonetic::' . $config->{algorithm};
        my $column = $column . '_phonetic_' . lc( $config->{algorithm} );
        $self->_require_class($class);
        my $encoded_value = $class->new->encode($value);
        
        push(@{$query}, { "$prefix$column" => $encoded_value});

    }

    return $self->search( { $type => $query }, $attributes );
}

sub update_phonetic_columns {
    my ($self) = @_;
    my $i      = 0;
    my $source = $self->result_source;
    foreach my $column ( $source->columns ) {
        $i += $self->update_phonetic_column($column);
    }
    return $i;
}

sub update_phonetic_column {
    my ( $self, $column ) = @_;
    my $source = $self->result_source;
    my $config = $source->column_info($column)->{phonetic_search};
    my $i;
    return 0 unless ($config);
    my $class           = 'Text::Phonetic::' . $config->{algorithm};
    my $phonetic_column = $column . '_phonetic_' . lc( $config->{algorithm} );
    $self->_require_class($class);
    my $rs = $self->search( { $column => { '!=' => undef } } );

    while ( my $row = $rs->next ) {
        $row->update(
            { $phonetic_column => $class->new->encode( $row->$column ) } );
        $i++;
    }
    return $i;
}

sub _require_class {
    my ($self, $class) = @_;

    croak "class argument missing" if !defined $class;

    $class =~ s|::|/|g;
    $class .= ".pm";

    if ( !exists $::INC{$class} ) {
        eval { require $class };
        croak $@ if $@;
    }

    return;
}

1;
