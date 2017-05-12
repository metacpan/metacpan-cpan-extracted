package Business::DPD;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.22');

use parent qw(Class::Accessor::Fast);
use Business::DPD::DBIC;
use Business::DPD::Label;
use Carp;
use Scalar::Util 'weaken';
use DateTime;

__PACKAGE__->mk_accessors(qw(schema schema_class dbi_connect _iso7064_mod37_36_checksum_map originator_address));

=head1 NAME

Business::DPD - handle DPD label generation

=head1 SYNOPSIS

    use Business::DPD;
    my $dpd = Business::DPD->new();
    $dpd->connect_schema;
    my $label = $dpd->generate_label({
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',    
    });
    say $label->tracking_number;
    say $label->d_sort;

    use Business::DPD;
    my $dpd = Business::DPD->new();
    $dpd->connect_schema;
    $dpd->set_originator_address({
        name1   => 'DELICom DPD GmbH',
        street  => 'Wailandtstrasse 1',
        postal  => '63741',
        city    => 'Aschaffenburg',
        country => 'DE',
        phone   => '06021/ 0815',
        fax     => '06021/ 0816',
        email   => 'test.dpd@dpd.com',
        depot   => '0176',
    }));
    my $label = $dpd->generate_label({
        address         => Business::DPD::Address->new($dpd,{ ... });
        serial          => '5012345678',
        service_code    => '101',
    });
    say $label->tracking_number;
    say $label->d_sort;

=head1 DESCRIPTION

Calculate routing information for parcel sending via DPD (http://dpd.com)

Generate labels for parcels (including barcode)

=head1 METHODS

=head2 Public Methods

=cut

=head3 new

    my $dpd = Business::DPD->new();

Perl default, Business::DPD will use the included SQLite DB and 
C<Business::DPD::DBIC::Schema>. If you want to use another DB or 
another schema-class, you can define them via the options 
C<schema_class> and C<dbi_connect>.

    my $dpd = Business::DPD->new({
        schema_class => 'Your::Schema::DPD',
        dbi_connect  => ['dbi:Pg:dbname=yourdb','dbuser','dbpasswd', { } ],
    });

=cut

sub new {
    my ($class, $opts) = @_;

    $opts->{schema_class} ||= 'Business::DPD::DBIC::Schema';
    $opts->{dbi_connect} ||= [ 'dbi:SQLite:dbname=' . Business::DPD::DBIC->path_to_sqlite ];

    my $self = bless $opts, $class;
    return $self;
}

=head3 connect_schema

    $dpd->connect_schema;

Connect to the Schema/DB specified in L<new>.

Stores the DBIx::Class Schema in C<< $dpd->schema >>. 

=cut

sub connect_schema {
    my $self = shift;

    eval "require ".$self->schema_class;
    croak $@ if $@;

    my $schema = $self->schema_class->connect(@{$self->dbi_connect});
    $self->schema($schema);

    unless ($ENV{HARNESS_ACTIVE}) {
        my $expires = $self->routing_meta->expires;
        my $today   = DateTime->now()->strftime('%Y%m%d');
        warn 'your DPD routing database is outdated since '.$expires
            if $expires < $today;
    }
}

=head3 generate_label

    my $label = $dpd->generate_label({
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',    
    });

=cut

sub generate_label {
    my ($self, $data) = @_;

    my $label = Business::DPD::Label->new($self, $data);
}

sub iso7064_mod37_36_checksum {
    my $self = shift;
    my $string = shift;
    my ($map, $chars) = $self->iso7064_mod37_36_checksum_map;
    
    my $m  = 36;
    my $m1 = $m + 1;
    my $p  = $m;

    foreach my $chr ( split( //, uc($string) ) ) {
        if ( defined $map->{$chr} ) {
            $p += $map->{$chr};
            $p -= $m if ( $p > $m );
            $p *= 2;
            $p -= $m1 if ( $p >= $m1 );
        }
        else {
            croak "Cannot find value for $chr";
        }
    }
    $p = $m1 - $p;
    return ( $p == $m ) ? $chars->[0] : $chars->[$p];
}

sub iso7064_mod37_36_checksum_map {
    my $self = shift;
    my @chars = ( 0 .. 9, 'A' .. 'Z', '*' );
    my $map = $self->_iso7064_mod37_36_checksum_map;
    return ($map,\@chars) if $map;

    my $count = 0;
    my %map   = ();
    for (@chars) {
        $map{$_} = $count;
        $count++;
    }
    $self->_iso7064_mod37_36_checksum_map(\%map);
    return (\%map,\@chars);
}

=head3 country_code

    my $country_num = $dpd->country_code('DE');

=cut

sub country_code {
    my ($self, $country) = @_;
    my $c = $self->schema->resultset('DpdCountry')->search({ alpha2 => $country })->first;
    croak 'country "'.$country.'" not found' unless $c;
    return $c->num;
}

=head3 country_alpha2

    my $country = $dpd->country_alpha2(276);

=cut

sub country_alpha2 {
    my ($self, $country_num) = @_;
    my $c = $self->schema->resultset('DpdCountry')->search({ num => $country_num })->first;
    croak 'country "'.$country_num.'" not found' unless $c;
    return $c->alpha2;
}

=head3 routing_meta

    my $routing_version = $dpd->routing_meta->version;

Returns L<Business::DPD::DBIC::Schema::DpdMeta> object.

=cut

sub routing_meta {
    my ($self) = @_;
    my $meta = $self->schema->resultset('DpdMeta')->search({})->single;
    croak 'no meta!' unless $meta;
    return $meta;
}

sub set_originator_address {
    my ($self, $options) = @_;
    $self->originator_address(Business::DPD::Address->new(
        $self,
        $options,
    ));

    # prevent circular reference
    weaken($self->originator_address->{_dpd});
}

1;

__END__

=head1 TO GENERATE DPD ROUTE DATABASE

    cd Business-DPD
    mkdir route-db
    cd route-db
    wget https://www.dpdportal.sk/download/routing_tables/rlatest_rev_dpdshipper_legacy.zip
    unzip rlatest_rev_dpdshipper_legacy.zip
    cd ..
    rm -f lib/Business/DPD/dpd.sqlite
    perl -Ilib helper/generate_sqlite_db.pl
    perl -Ilib helper/import_dpd_data.pl route-db/
    perl Build.PL
    perl Build test
    sudo perl Build install

=head1 AUTHOR

Thomas Klausner C<< domm AT cpan.org >>

Jozef Kutej C<< jozef@kutej.net >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
