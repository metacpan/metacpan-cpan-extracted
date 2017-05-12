package Business::DPD::Label;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.22');

use parent qw(Class::Accessor::Fast);
use Carp;
use POSIX 'ceil';

# input data
__PACKAGE__->mk_accessors(qw(zip country depot serial service_code address));

# more input data
__PACKAGE__->mk_accessors(qw(weight weight_g shipment_count_this shipment_count_total recipient reference_number order_number));


# calculated values
__PACKAGE__->mk_accessors(qw(_fields_calculated tracking_number checksum_tracking_number tracking_number_without_checksum o_sort d_sort d_depot target_country_code route_code code code_human code_barcode barcode_id));

# internal
__PACKAGE__->mk_accessors(qw(_dpd));


our %SERVICE_TEXT = (
    101     => 'D',
    102     => 'D-HAZ',
    105     => 'D-EXW',
    106     => 'D-DXW-HAZ',
    109     => 'D-COD',
    110     => 'D-COD-HAZ',
    113     => 'D-SWAP',
    136     => 'D',
    154     => 'PARCELetter',
    155     => 'PM2',
    161     => 'PM2-COD',
    179     => 'AM1',
    191     => 'AM1-COD',
    225     => 'AM2',
    137     => 'AM2-COD',
    350     => 'AM0',
);

=head1 NAME

Business::DPD::Label - one DPD label

=head1 SYNOPSIS

    use Business::DPD::Label;
    my $label = Business::DPD::Label->new( $dpd, {
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '50123456%0878',
        service_code    => '101',    
        weight          => '6 kg',
    });
    $label->calc_fields;
    say $label->tracking_number;
    say $label->d_sort;

    use Business::DPD::Label;
    my $label2 = Business::DPD::Label->new( $dpd, {
        address => Business::DPD::Address->new($dpd, {
            name1   => 'Hans Mustermann GmbH',
            street  => 'Musterstr. 12a',
            postal  => '63741',
            city    => 'Aschaffenburg',
            country => 'DE',
            phone   => '06021/112',
        }),
        serial          => '9700001010',
        service_code    => '101',
        shipment_count_this => 1,
        shipment_count_total => 2,
        reference_number => [ 'Testpaket2' ],
        weight_g        => 6000,
    });

=head1 DESCRIPTION

Calculate the data that's needed for a valid addresse label.

=head1 METHODS

=head2 Public Methods

=cut

=head3 new

    my $label = Business::DPD::Label->new( $dpd, {
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',
    });

TODO?: take a Business::DPD::Address as an agrument (instead of zip & country)

=cut

sub new {
    my ($class, $dpd, $opts) = @_;

    if (my $address = $opts->{address}) {
        $opts->{zip} //= $address->postal;
        $opts->{country} //= $address->country;
        $opts->{recipient} //= [ $address->as_array ];
    }
    $opts->{depot} //= ($dpd->originator_address ? $dpd->originator_address->depot : undef);
    if (my $weight_g = $opts->{weight_g}) {
        $opts->{weight} = (ceil($weight_g/10)/100).' kg';
    }

    # check required params
    my @missing;
    foreach (qw(zip country depot serial service_code)) {
        push(@missing, $_) unless $opts->{$_};
    }
    croak "required option ".join(',',map{"'$_'"}@missing)." missing" if @missing;

    # validata some params
    croak "'country' must be uppercase two letter ISO code (eg 'DE')" unless $opts->{country}=~/^[A-Z][A-Z]$/;
    croak "'depot' must be 4 digits (eg '1090')" unless $opts->{depot} =~ /^\d{4}$/;
    croak "'serial' must be 10 digits (eg '5012345678')" unless $opts->{serial} =~ /^\d{10}$/;
    croak "'service_code' must be 4 digits (eg '1090')" unless $opts->{service_code} =~ /^\d{3}$/;

    my $self = bless $opts, $class;
    $self->_dpd($dpd);
    return $self;
}

=head3 calc_fields

    $label->calc_fields;

Calculate all caluclatable fields from the provided data using the DPD database from C<$schema>:

  target_country

=cut

sub calc_fields {
    my $self = shift;

    $self->calc_tracking_number;
    $self->calc_routing;
    $self->calc_target_country_code;
    $self->calc_barcode;
    $self->_fields_calculated(1);
}

=head3 calc_tracking_number

    $label->calc_tracking_number;

Calulates the tracking number and stores it in C<tracking_number>. C<tracking_number> consists of 

   DDDDXXLLLLLLLLP
      | |     |  |
      | |     |  +-> iso7064_mod37_36_checksum      L
      | |     +----> serial                         12345678
      | +----------> first two positions of serial  50
      +------------> depot                          1090

We additionally store the checksum in C<checksum_tracking_number> and the C<tracking_number_without_checksum>

=cut

sub calc_tracking_number {
    my $self = shift;

    my $base = $self->depot . $self->serial;
    my $checksum = $self->_dpd->iso7064_mod37_36_checksum($base);
    $self->checksum_tracking_number($checksum);
    $self->tracking_number($base . $checksum);
    $self->tracking_number_without_checksum($base);
}
    
=head3 calc_routing

    $label->calc_routing;
    $label->o_sort

Calculates the following fields:

  o_sort d_sort d_depot barcode_id
  
=cut

sub calc_routing {
    my $self = shift;
    my $schema = $self->_dpd->schema;

    my $zip = $self->_zip_for_calc;
    my $route_rs = $schema->resultset('DpdRoute')->search({
        'me.dest_country'=>$self->country,
        'me.begin_postcode' => { '<=' => $zip },
        'me.end_postcode' => { '>=' => $zip },
    },
    {
        order_by=>'me.begin_postcode DESC',
        rows=>1,
    } );

    if ($self->service_code eq '101') {
        $route_rs = $route_rs->search({service_code=>''});
    }
    else {
        $route_rs = $route_rs->search({service_code=> { 'LIKE' => '%'.$self->service_code.'%' } });
    }

    croak "No route found!" if $route_rs->count == 0;
    
    my $route=$route_rs->first;

    $self->o_sort($route->o_sort);
    $self->d_sort($route->d_sort);
    $self->d_depot($route->d_depot);
    $self->barcode_id($route->barcode_id);

    # TODO: route_code = beförderungsweg

}

=head3 calc_target_country_code

    $label->calc_target_country_code;

Store the numeric country code from the alpha2 target country (i.e.: 'DE' -> 276)
into C<target_country_code>

=cut

sub calc_target_country_code {
    my $self = shift;
    $self->target_country_code($self->_dpd->country_code($self->country));
}


=head3 service_text

 $label->service_text

Returns the service text for the given service code

=cut

sub service_text {
    my ($self, $code) = @_;
    
    $code //= $self->service_code;
    return $SERVICE_TEXT{$code}
        if defined $SERVICE_TEXT{$code};
    
    return;  
}
    



=head3 calc_barcode

    $label->calc_barcode;

Generate the various parts of the barcode, which are:

=over

=item * code 

PPPPPPPTTTTTTTTTTTTTTSSSCCC

=item * code_human

PPPPPPPTTTTTTTTTTTTTTSSSCCCP

=item * code_barcode

IPPPPPPPTTTTTTTTTTTTTTSSSCCC

=back

And here's the explanation of those strange letter:

    IPPPPPPPTTTTTTTTTTTTTTSSSCCCP
    |   |          |       |  | |
    |   |          |       |  | +-> iso7064_mod37_36_checksum         Z
    |   |          |       |  +---> target_country_code               276
    |   |          |       +------> service_code                      101
    |   |          +--------------> tracking_number_without_checksum  01905002345615
    |   +-------------------------> zip (zero padded)                 0012555
    +-----------------------------> barcode_id                        %                   

=cut

sub calc_barcode {
    my $self = shift;

    my $cleartext = sprintf("%07s",$self->_zip_for_calc) .  $self->tracking_number_without_checksum . $self->service_code . $self->target_country_code;
    my $checksum = $self->_dpd->iso7064_mod37_36_checksum($cleartext);

    $self->code($cleartext);
    $self->code_human($cleartext . $checksum);
    $self->code_barcode(chr($self->barcode_id) . $cleartext);
}

# clean-up zip code for route calculation (most countries has just numbers, GB has also letters)
sub _zip_for_calc {
    my $self = shift;
    my $zip = uc($self->zip);
    $zip =~ s/[^0-9a-zA-Z]//g;
    return $zip;
}

=head1 TODO

* weiters:

kennzeichnung (kleingewicht, Express)
Servicetext
Servicecode

=cut

=head1 needed methods

* one object for one address
* required fields
** target country
** target zipcode
** laufende nummer
** depot number
** service code
* semi-required
** address data
* optional
** referenznummer
** auftragsnummer
** gewicht
** n of m
** template

=cut


1;

__END__

=head1 AUTHOR

RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
