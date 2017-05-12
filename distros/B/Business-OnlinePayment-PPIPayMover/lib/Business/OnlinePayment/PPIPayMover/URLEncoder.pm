package Business::OnlinePayment::PPIPayMover::URLEncoder;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Encode);

1;

sub Encode {
    #my $self = shift;
    my $value = shift;

    $value =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    return $value;
}
