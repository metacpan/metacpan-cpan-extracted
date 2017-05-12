package DBIx::ObjectMapper::Mapper::Attribute;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Params::Validate qw(:all);
use Class::MOP;

sub new {
    my $class  = shift;
    my $mapper = shift;

    my %option = validate(
        @_,
        {
            include    => { type => ARRAYREF, default => +[] },
            exclude    => { type => ARRAYREF, default => +[] },
            prefix     => { type => SCALAR,   default => q{} },
            properties => { type => HASHREF|ARRAYREF,  default => +{} },
        }
    );
    $option{table}        = $mapper->table;
    $option{mapped_class} = $mapper->mapped_class;

    my $type = 'Hash';

    if (   $mapper->constructor->{arg_type} eq 'ARRAY'
        || $mapper->constructor->{arg_type} eq 'ARRAYREF' )
    {
        if ( ref $option{properties} eq 'HASH' ) {
            if( ( keys %{ $option{properties} } ) == 0 ) {
                $option{properties} = [];
            }
            else {
                confess
                    "not match constructor{arg_type}.(properties is HASHREF)";
            }
        }

        $type = 'Array';
    }

    my $attribute_class = $class . '::' . $type;
    Class::MOP::load_class($attribute_class)
        unless Class::MOP::is_class_loaded($attribute_class);
    my $self = bless \%option, $attribute_class;
    $self->init;

    return $self;
}

sub _init_attributes {
    my $self = shift;
    my $table = $self->table;
    my %primary_key_map = map { $_ => $table->c($_) } @{ $table->primary_key };

    my @attributes;
    if ( my @include = @{ $self->include } ) {
        my $ex_primary_key = 0;
        for my $p ( @include ) {
            if ( $p and ref $p eq $table->column_metaclass ) {
                $ex_primary_key = 1 if $primary_key_map{ $p->name };
                push @attributes, $p;
            }
            elsif ( !ref($p) and my $meta_col = $table->c($p) ) {
                $ex_primary_key = 1
                    if $primary_key_map{ $meta_col->name };
                push @attributes, $meta_col;
            }
            else {
                confess "$p is not exists metadata at include_property";
            }
        }

        unless ($ex_primary_key) {
            push( @attributes, $_ ) for values %primary_key_map;
        }
    }
    else {    # default all
        @attributes = @{ $table->columns };
    }

    if ( @{$self->exclude} ) {
        my %exclude = map {
            ( ref($_) eq $table->column_metaclass )
          ? ( $_->name => 1 )
          : ( $_ => 1 );
        } grep {
            if ($_) {
                if ( ref($_) eq $table->column_metaclass ) {
                    !$primary_key_map{ $_->name };
                }
                else {
                    !$primary_key_map{$_};
                }
            }
        } @{ $self->exclude };
        @attributes = grep { !$exclude{ $_->name } } @attributes;
    }

    return @attributes;
}

sub table          { $_[0]->{table} }
sub include        { $_[0]->{include} }
sub exclude        { $_[0]->{exclude} }
sub prefix         { $_[0]->{prefix} }
sub properties     { $_[0]->{properties} }
sub property_names { confess "Abstruct Method" }
sub property_info  { confess "Abstruct Method" }

sub property {
    my $self = shift;
    my $name = shift;
    my @via = split('\.', $name);
    my $via_1 = shift(@via);
    my $info = $self->property_info($via_1);
    confess "$via_1 does not exists in attributes." unless $info;
    my $prop = $info->{isa};

    for( @via ) {
        $prop = $prop->property($_);
        confess "$_ does not exists in attributes." unless $prop;
    }
    return $prop;
}
*prop = *p = \&property;

sub lazy_column {
    my ( $self, $name ) = @_;
    my $prop = $self->property_info($name);
    if( $prop->lazy eq 1 ) {
        return $name => $prop->{isa};
    }
    elsif( $prop->lazy ) {
        my %lazy_column;
        for my $prop_name ( $self->property_names ) {
            my $other_prop = $self->property_info($prop_name);
            $lazy_column{$prop_name} = $other_prop->{isa}
                if $other_prop->lazy eq $prop->lazy;
        }
        return %lazy_column;
    }
    else {
        return;
    }
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Mapper::Attribute

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
