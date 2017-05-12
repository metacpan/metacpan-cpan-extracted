package Business::PhoneBill::Allopass::Simple;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = "1.01";

use HTTP::Request::Common qw(GET POST);
use LWP::UserAgent;

my $baseurl = 'http://www.allopass.com/check/vf.php4';
my $error   = '';

use Exporter;
@EXPORT=qw('allopass_check');

=head1 NAME

Billing::Allopass::Simple - A simple function for micropayment system from Allopass

=head1 SYNOPSIS

    use Business::PhoneBill::Allopass::Simple;
  
    if (allopass_check($document_id, $RECALL)){
        print "OK\n";
    } else {
        print get_last_allopass_error;
    }
  
=head1 DESCRIPTION

This module provides a simple API to the Allopass.com micropayment system.
This alternative to Business::PhoneBill::Allopass justs performs access code checks.

See I<http://www.allopass.com/index.php4?ADV=1508058> for more informations on their system and how it basically works.

=head1 FUNCTIONS

=over 4

=item B<allopass_check> - Checks if a code has been recently validated for this document.

    allopass_check($document_id, $code);

You must perform this check within 2 minutes after the code is entered.

=cut

sub allopass_check {
    my ($doc_id, $code, $r) = @_;
    my ($res, $ua, $req);
    $ua = LWP::UserAgent->new;
    $ua->agent('Business::PhoneBill::Allopass::Simple/'.$VERSION);
    $req = POST $baseurl,
        [
        'CODE'      => $code ,
	'to'        => $doc_id ,
        ];
    $res = $ua->simple_request($req)->as_string;
    return _is_res_ok($res);
}

=item B<get_last_allopass_error> - Returns last status string

    print get_last_allopass_error();

=cut

sub get_last_allopass_error {
    shift->{error};
}

sub _is_res_ok {
    my $res=shift;
    my($h, $c, $a)=split(/\n\n/, $res); chomp $c;
    if($res && $res!~/NOK/ && $res!~/ERR/ && $res!~/error/i && $c=~/OK/) {
        _set_error('Allopass Recall OK');
        return 0;
    }
    if ($c =~/NOK/) {
        return _set_error("Allopass.com says : This code is invalid")
    } elsif ($c =~/ERR/) {
        return _set_error("Allopass.com says : Invalid document id")
    } else {
        $res=~s/[\r\n]/ /g;
        return _set_error("Invalid Allopass.com response code : $res")
    }
    1;
}
sub _set_error {
    $error=shift;
}

=back

=head1 AUTHOR

Bernard Nauwelaerts <bpn#it-development%be>

=head1 LICENSE

GPL.  Enjoy !
See COPYING for further informations on the GPL.

=cut

1;
