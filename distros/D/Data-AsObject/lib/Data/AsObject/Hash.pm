package Data::AsObject::Hash;
BEGIN {
  $Data::AsObject::Hash::VERSION = '0.07';
}

# ABSTRACT: Base class for Data::AsObject hashrefs

use strict;
use warnings;
use Carp;
use Data::AsObject ();
use namespace::clean -except => [qw/AUTOLOAD/];

our $AUTOLOAD;

sub can {
    if(@_ != 2) {
        local $AUTOLOAD = ref($_[0]) .'::can';
        return $_[0]->AUTOLOAD(@_);
    }

    my($self, $key) = @_;
    return unless( exists $self->{$key} );
    return sub { __get_data($self, $key) };
}

sub AUTOLOAD {
    my $self = shift;
    my $index = shift;
        my $data;

    my $key = $AUTOLOAD;
    $key =~ s/.*:://;
    undef $AUTOLOAD;

    if ($key eq "can" && defined $index && $index != /\d+/) {
        return undef;
    }

    if ($key eq "isa" && defined $index && $index != /\d+/) {
        $index eq ref($self) or
        $index eq "Data::AsObject::Hash" or
        $index eq "UNIVERSAL"
            ? return 1
            : return 0;
    }

    return __get_data($self, $key, $index);
}

sub __get_data {
    my ($self, $key, $index) = @_;
    my $data = exists $self->{$key} ? $self->{$key} : __guess_data($self, $key);
    my $mode = ref($self) =~ /^.*::(\w+)$/ ? $1 : '';

    if ( !$data ) {
        return     if $key eq "DESTROY";

        my $msg = "Attempting to access non-existing hash key $key!";

        carp $msg  if $mode eq 'Loose';
        croak $msg if $mode eq 'Strict';
        return;
    }

    if (
            defined $index
        && $index =~ /\d+/
        && $Data::AsObject::__check_type->($data) eq "ARRAY"
        && exists $data->[$index]
    )
    {
        $data = $data->[$index];
    }

    if ( $Data::AsObject::__check_type->($data) eq "ARRAY" ) {
        bless $data, "Data::AsObject::Array::$mode";
    } elsif ( $Data::AsObject::__check_type->($data) eq "HASH" ) {
        bless $data, "Data::AsObject::Hash::$mode";
    }

    return $data;
}

sub __guess_data {
    my $self = shift;
    my $key_regex = shift;
    my $has_colon_or_dash = $key_regex =~ s/_/[-:]/g;
    my @matches = grep(/$key_regex/, keys %$self) if $has_colon_or_dash;

    if ( @matches == 1 ) {
        return $self->{$matches[0]};
    } elsif ( @matches > 1 ) {
        carp "Attempt to disambiguate hash key $key_regex returns multiple matches!";
        return $self->{$matches[0]};
    }

    return;
}


package Data::AsObject::Hash::Strict;
BEGIN {
  $Data::AsObject::Hash::Strict::VERSION = '0.07';
}
use base 'Data::AsObject::Hash';

package Data::AsObject::Hash::Loose;
BEGIN {
  $Data::AsObject::Hash::Loose::VERSION = '0.07';
}
use base 'Data::AsObject::Hash';

package Data::AsObject::Hash::Silent;
BEGIN {
  $Data::AsObject::Hash::Silent::VERSION = '0.07';
}
use base 'Data::AsObject::Hash';

1;


__END__
=pod

=for :stopwords Peter Shangov AnnoCPAN Arrayrefs arrayrefs hashrefs xml isa

=head1 NAME

Data::AsObject::Hash - Base class for Data::AsObject hashrefs

=head1 VERSION

version 0.07

=head1 SYNOPSIS

See L<Data::AsObject> for more information.

=head1 NAME

Data::AsObject::Hash - Base class for Data::AsObject hashes

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

