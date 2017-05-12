ifndef USERTAG_UPS_QUERY
Variable USERTAG_UPS_QUERY     1
Message Loading [ups-query] usertag (compatiblity layer over [business-shipping])...

UserTag  ups-query  Order  mode origin zip weight country
UserTag  ups-query  addAttr
UserTag  ups-query  Routine <<EOR

=head1 NAME

[ups-query] - Interchange usertag for compatiblity (a layer over [business-shipping]).

=cut

sub 
{
    my( $mode, $origin, $zip, $weight, $country, $opt) = @_;
    my %opt = %$opt;
    return $Tag->business_shipping(
        mode       => 'UPS_Offline',
        service    => $mode,
        weight     => $weight,
        to_zip     => $zip,
        to_country => $country,
        %opt,
    );
}

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=cut

EOR
endif
