
=pod

The tester must supply their own PayPal sandbox seller authentication
(either using certificates or 3-token auth), as well as the buyer
sandbox account (email address).

Should we set env variables, prompt for them, or have them in a conf
file? Prompt for them, but we should allow for an input file as an env
variable:

  WPP_TEST=auth.txt prove -lvr t

=cut

sub do_args {
    unless ( $ENV{WPP_TEST} && -f $ENV{WPP_TEST} ) {
        die
            "See the TESTING section in `perldoc Business::PayPal::API documentation`\n";
        exit;
    }

    my %args = ();
    open FILE, "<", $ENV{WPP_TEST}
        or die "Could not open $ENV{WPP_TEST}: $!\n";

    my @variables = qw( Username Password Signature Subject timeout
        CertFile KeyFile PKCS12File PKCS12Password
        BuyerEmail SellerEmail
    );

    my %patterns = ();
    @patterns{ map { qr/^$_\b/i } @variables } = @variables;

    while (<FILE>) {
        chomp;

    MATCH: for my $pat ( keys %patterns ) {
            next unless $_ =~ $pat;
            ( my $value = $_ ) =~ s/$pat\s*=\s*(.+)/$1/;
            $args{ $patterns{$pat} } = $value;
            delete $patterns{$pat};
            last MATCH;
        }
    }

    close FILE;

    ## leave this!
    $args{sandbox} = 1;

    return %args;
}

1;
