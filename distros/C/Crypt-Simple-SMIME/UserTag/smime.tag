UserTag smime Order subject
UserTag smime hasEndTag
UserTag smime addAttr
UserTag smime Interpolate
UserTag smime Routine <<EOR
sub {
    my ($subject, $opt, $body) = @_;
    my $ok = 0;
	
	use Crypt::Simple::SMIME;

    my $cc_num = $CGI::values{mv_credit_card_number};
    my $cc_exp = $CGI::values{mv_credit_card_type};

    my $return_body = $body;
    $return_body =~ s/CREDIT_CARD_NUM/XXXXXXXXXXXXXXXX/;
    
    $body =~ s/CREDIT_CARD_NUM/$cc_num/;

	my $c = new Crypt::Simple::SMIME();

	$c->CertificatePath($Variable->{SMIME_CERT_PATH});

	my $to = $Variable->{ORDERS_TO};
	my $from = $Variable->{ORDERS_TO};

	my $result = $c->SendMail($to,$from,$subject,$body);

	$c->Close();


    if ( ! $result) {

        logError( $c->ErrorMessage() );
    }

    return $return_body;
}
EOR
