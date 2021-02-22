package Authen::NZRealMe::ServiceProvider::CertFactory;
$Authen::NZRealMe::ServiceProvider::CertFactory::VERSION = '1.21';
use warnings;
use strict;

my $term = undef;

my @fields = (

    env => <<EOF,
Which environment do you wish to generate certficates for?  Please answer
either 'ITE' or 'PROD'.
EOF

    org => <<EOF,
Enter your organisation name (e.g.: "Department of Innovation" - without the
quotes).
EOF

    org_unit => <<EOF,
You may optionally include an organisational unit name (e.g.: "Innovation
Labs") - leave  this field blank if you don't need it.
EOF

    subject_suffix => <<EOF,
A certificate subject will be generated for you using the domain name,
organisation name and optional organisational unit name you supplied.  If
you want additional details in the subject, you can supply the here.  Prefix
each fieldname with a forward slash (e.g.: /L=Wellington/ST=Wellington/C=NZ ).
EOF

    domain => <<EOF,

Enter the domain name for your agency.  You might choose to include an
application prefix (e.g.: facetube.innovation.govt.nz) if your applications
will have separate RealMe integrations but just the domain name is usually
sufficient (e.g.: innovation.govt.nz).
EOF

);


sub generate_certs {
    my($class, $conf_dir, %args) = @_;

    %args = $class->_prompt_for_parameters(\%args) or exit 1;
    _check_args(\%args);
    $args{conf_dir} = $conf_dir;

    die "'$conf_dir' is not a directory\n" unless -d "$conf_dir/.";

    $args{domain} =~ s/^(www|secure)[.]//;

    my $key_file = "$conf_dir/sp-sign-key.pem";
    _generate_private_key($key_file);
    _generate_certificate('sig', $key_file, \%args);

    $key_file = "$conf_dir/sp-ssl-key.pem";
    _generate_private_key($key_file);
    _generate_certificate('ssl', $key_file, \%args);

    if(not $args{self_signed}) {
        print "\nSuccessfully generated two certificate signing requests.\n"
            . "You can dump the CSR contents to confirm with:\n\n"
            . "  openssl req -in sp-sign.csr -text\n"
            . "  openssl req -in sp-ssl.csr -text\n\n"
            . "Once you have the certificates signed, save them as\n"
            . "sp-sign-crt.pem and sp-ssl-crt.pem\n";
    }
    else {
        print "\nSuccessfully generated two self-signed certificates.\n";
    }
}


sub _prompt_for_parameters {
    my $class = shift;
    my $args  = shift // { };

    $term = Authen::NZRealMe->class_for('term_readline')->init_readline();
    if($term->Attribs and $term->Attribs->can('ornaments')) {
        $term->Attribs->ornaments(0);
    }
    else {
        warn "Consider installing Term::ReadLine::Gnu for better terminal handling.\n";
    }

    print <<EOF;
This tool will allow you to generate CSRs (Certificate Signing Requests)
for your ITE or Production integration.  You will be asked a short list
of questions.

EOF

    _prompt_yes_no('Do you wish to continue with this process? (y/n) ', 'y')
        or return;

    TRY: while(1) {
        for(my $i = 0; $i <= $#fields; $i += 2) {
            my $key    = $fields[$i];
            my $prompt = $fields[$i + 1];

            print "\n$prompt\n";
            my $field_ok = 0;
            my $value = $args->{$key};
            do {
                $value = $term->readline("$key> ", $value);
                my $method = "_validate_$key";
                $field_ok = $class->can($method) ? $class->$method($value) : 1;
            } until $field_ok;
            $args->{$key} = $value;
        }

        my $output = $args->{self_signed}
                   ? 'self-signed certificates'
                   : 'CSRs';
        print "\nReady to generate $output with the parameters:\n"
            . "  Environment:         $args->{env}\n"
            . "  Organisation:        $args->{org}\n"
            . "  Organisational Unit: $args->{org_unit}\n"
            . "  Subject Suffix:      $args->{subject_suffix}\n"
            . "  Domain:              $args->{domain}\n\n";

        last TRY if _prompt_yes_no("Do you wish to generate $output now? (y/n) ", '');
        redo TRY if _prompt_yes_no('Do you wish to try again? (y/n) ', '');
        exit 1;
    }

    return %$args;
}


sub _prompt_yes_no {
    my($prompt, $default) = @_;

    while(1) {
        my $resp = $term->readline($prompt, $default);

        next unless defined $resp;
        return 1 if $resp =~ /^(y|yes)$/i;
        return 0 if $resp =~ /^(n|no)$/i;
    }
}


sub _generate_private_key {
    my($key_path) = @_;

    system('openssl', 'genrsa', '-out', $key_path, '2048') == 0
        or exit 1;
}


sub _generate_certificate {
    my($type, $key_path, $args) = @_;

    my $conf_dir = $args->{conf_dir};
    my($name, $out_base);
    if($type eq 'sig') {
        $name     = "$args->{env}.sa.saml.sig.$args->{domain}";
        $out_base = "$conf_dir/sp-sign";
    }
    else {
        $name     = "$args->{env}.sa.mutual.ssl.$args->{domain}";
        $out_base = "$conf_dir/sp-ssl";
    }

    my $subject = "/CN=${name}/O=$args->{org}";
    if($args->{org_unit}  and  $args->{org_unit} =~ /\S/) {
        $subject .= "/OU=$args->{org_unit}";
    }
    if($args->{subject_suffix}  and  $args->{subject_suffix} =~ /\S/) {
        $subject .= $args->{subject_suffix};
    }
    my @command = (
        'openssl', 'req', '-new', '-key', $key_path,
        '-subj', $subject,
        '-days', '1095',
    );

    if(not $args->{self_signed}) {
        push @command, '-out', "${out_base}.csr";
    }
    else {
        push @command, '-out', "${out_base}-crt.pem",
            '-x509', '-set_serial', _gen_serial();
    }

    system(@command) == 0 or exit 1;
}


sub _gen_serial {
    my @h = qw(0 1 2 3 4 5 6 7 8 9 a b c d e f);

    return '0x' . join '', $h[rand(8)], map { $h[rand(16)] } (1..15);
}


sub _check_args {
    my($args) = @_;

    die "Need organisation name to generate certs\n" unless $args->{org};
    die "Need domain name to generate certs\n"       unless $args->{domain};

    die "Need environment (MTS/ITE/PROD) to generate certs\n"
        unless $args->{env};

    $args->{env} = lc($args->{env});
    die "Environment must be 'MTS', 'ITE' or 'PROD'\n"
        unless $args->{env} =~ /^(mts|ite|prod)$/;

    warn
        "WARNING: It should not be necessary to generate certificates for MTS.\n"
      . "         You should just use the certificate and key files from the\n"
      . "         MTS integration pack.\n\n"
      . "         Proceeding with certificate generation as requested.\n\n"
        if $args->{env} eq 'mts';
}


sub _validate_env {
    my($class, $value) = @_;

    return 1 if $value =~ /^(ite|prod)$/i;

    print "Environment must be 'ITE' or 'Prod'\n";
    return;
}


sub _validate_org {
    my($class, $value) = @_;

    if($value =~ m{\A[a-z0-9(),./ -]+\z}i) {
        return 1;
    }
    elsif($value !~ m{\S}i) {
        print "Organisation name must not be blank\n";
    }
    else {
        print "Organisation name should be plain text without special characters\n";
    }
    return;
}


sub _validate_org_unit {
    my($class, $value) = @_;

    if($value =~ m{\A[a-z0-9(),./ -]*\z}i) { 
        return 1;
    }
    else {
        print "Organisational unit should be plain text without special characters\n";
    }
    return;
}


sub _validate_subject_suffix {
    my($class, $value) = @_;

    if($value =~ m{\A(/[A-Z]+=[a-zA-Z0-9(),. -]+)*\z}i) {
        return 1;
    }
    else {
        print "Organisational unit should be plain text without special characters\n";
    }
    return;
}


1;


__END__

=head1 NAME

Authen::NZRealMe::ServiceProvider::CertFactory - generate certificates or CSRs

=head1 DESCRIPTION

This class is used for generating the certificates used for signing SAML
AuthnRequest messages and for mutual SSL encryption of messages sent over the
backchannel.

For both production and ITE environments, CSRs will be generated for signing by
a certification authority (CA).  (Historically self-signed certificates were
used in ITE).


=head1 METHODS

=head2 generate_certs

Called by the C<< nzrealme make-certs >> command to run an interactive Q&A
session to generate either self-signed certificates or Certificate Signing
Requests (CSRs).


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


