package Collection::Utl::ActiveRecord;

=head1 NAME

 Collection::Utl::ActiveRecord -  Tools for track changes in HASHes.

=head1 SYNOPSIS

 use Collection::Utl::ActiveRecord;

 sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    my %hash;
    tie %hash, 'Collection::Utl::ActiveRecord', hash => $ref;
    return \%hash;
 }

=head1 DESCRIPTION

 Tools for track changes in HASHes.
 
=cut

use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
require Tie::Hash;
use Collection::Utl::Base;
@Collection::Utl::ActiveRecord::ISA = qw(Tie::StdHash Collection::Utl::Base);
$Collection::Utl::ActiveRecord::VERSION = '0.01';

attributes qw( _changed_ _orig_record __temp_array);

sub _init {
    my $self = shift;
    return $self->Init(@_);
}

sub DELETE {
    my ( $self, $key ) = @_;
    $self->_changed_(1);
    delete $self->_orig_record->{$key};

}

sub STORE {
    my ( $self, $key, $val ) = @_;
    my $hash = $self->_orig_record;
    $self->_changed_(1);
    $hash->{$key} = $val;
}

sub _changed { $_[0]->_changed_}
sub FETCH {
    my ( $self, $key ) = @_;
    if ( $key eq '_changed' ) {
        $self->_changed_();
    }
    else {
        $self->_orig_record->{$key};
    }
}

sub Init {
    my ( $self, %arg ) = @_;
    $self->_orig_record( $arg{hash} );
    unless ( $arg{hash} ) {
        carp "Not inited param hash"
    }
    $self->_changed_(0);
    return 1;
}

sub GetKeys {
    my $self = shift;
    my $hash = $self->_orig_record;
    return [ keys %$hash ];
}


sub TIEHASH {return Collection::Utl::Base::new(@_) }

sub FIRSTKEY {
    my ($self) = @_;
    $self->{__temp_array} =  [ sort { $a cmp $b } @{ $self->GetKeys() } ] ;
    shift( @{ $self->{__temp_array} } );
}

sub NEXTKEY {
    my ( $self, $key ) = @_;
    shift( @{ $self->{__temp_array} } );
}

sub EXISTS {
    my ( $self, $key ) = @_;
    my $hash = $self->_orig_record;
    return exists $hash->{$key};
}

sub CLEAR {
    my $self = shift;
    %{ $self->_orig_record } = ();
    $self->_changed_(1);
}

1;
__END__


=head1 SEE ALSO

Tie::StdHash

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

