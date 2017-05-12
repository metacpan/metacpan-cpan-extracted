package Business::PhoneBill::Allopass;

use vars qw/$VERSION/;
$VERSION = "1.09";

=head1 NAME

Business::PhoneBill::Allopass - A class for micro-payment system from Allopass

=head1 SYNOPSIS

  use Business::PhoneBill::Allopass;
  
  my $allopass=Business::PhoneBill::Allopass->new($session_file, [$ttl]);
  die "Cann't create class: ".$allopass unless ref $allopass;
  
  # Check access
  if ($allopass->check($document_id, [$RECALL])){
        print "OK\n";
  } else {
        print $allopass->get_last_error;
  }
  
  # No further access for this user
  $allopass->end_session($document_id);
  
=head1 DESCRIPTION

This class provides you an easy api to the allopass.com system. It automatically handles user sessions.

=head1 SEE ALSO

Please consider using Business::PhoneBill::Allopass::Simple if you don't need session management.

See I<http://www.allopass.com/index.php4?ADV=1508058> for more informations on their system and how it basically works.

=cut

use strict;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use CGI::Cookie;

my $baseurl = 'http://www.allopass.com/check/vf.php4';

=head1 METHODS

=over 4

=item B<new> Class constructor. Provides session-based access check.

    $allopass=Billing::Allopass->new($session_file, [$ttl]);

$session_file is the physical location for the session file. The webserver must have write access to it.
If not, this constructor returns a text error message.

$ttl is the number of minutes of inactivity for automatically removing sessions. Default : 60.

You have to test if the returned value is a reference.

=cut

sub new {
    my $class   = shift;
    my $ses_file= shift || return "You must provide writable session file name";
    if (!-e $ses_file) {
        open TEMP, ">$ses_file" or return "Cann't create session file: ".$!; close TEMP;
    }
    my $ttl=shift || 60;
    
    my %arg = @_;
    my $self = {
        os       =>    0,
        ttl      =>    $ttl,
        ses_file =>    $ses_file,
        error    =>    '',
        hhttp    =>    $arg{hhttp} || '',
        code     =>    '',
    };
    $self = bless $self, $class;
    $self;
}

=item B<check> - Checks if a client have access to this document
    
    $ok=$allopass->check($document_id, [$RECALL]);

The RECALL parameter is provided by Allopass.com when it redirects the visitor to your website, after the secret code verification.
Returns 1 if authorization is successfull.
Next accesses to the script will be protected by the session-based system, and you no longer need to provide the $RECALL argument..
    
=cut

sub check {
    my $self=shift;
    my $doc_id=shift || return 0;
    my $code = shift || '';
    my ($res, $ua, $req);
    if ($self->_is_session($doc_id)) {
        return 1;
    } elsif ($code) {
        $ua = LWP::UserAgent->new;
        $ua->agent('Business::PhoneBill::Allopass/'.$VERSION);
        $req = POST $baseurl,
        [
        'CODE'        => $code ,
	'AUTH'        => $doc_id ,
        ];
        $res = $ua->simple_request($req)->as_string;
        if($self->_is_res_ok($res)) {
            $self->_add_session($doc_id, $code);
            $self->_set_error('Allopass Recall OK');
            return 1;
        }
    }
    0;
}

=item B<end_session> - Ends user session for specified document.

    $allopass->end_session($document_id);

=cut

sub end_session {
    shift->_end_session(@_);
}

=item B<get_last_error> - Returns last recorded error

    $allopass->get_last_error();

=cut

sub get_last_error {
    shift->{error};
}

=item B<check_code> - Checks if a client have access to this document
    
    $ok=$allopass->check_code($document_id, $code, [$datas], [$ap_ca]);

=cut

sub check_code {
    my $self=shift;
    my ($docid, $code, $datas, $ap_ca) = @_;
    if ($self->_is_session($docid)) {
        return 1;
    } elsif ($code) {
        my ($site_id, $doc_id, $r)=split(/\//, $docid);
        my ($res, $ua, $req);
        my $baseurl = 'http://www.allopass.com/check/index.php4';
        $ua = LWP::UserAgent->new;
        $ua->agent('Business::PhoneBill::Allopass/'.$VERSION);
        $req = POST $baseurl,
            [
            'SITE_ID'    => $site_id ,
            'DOC_ID'     => $doc_id ,
            'CODE0'      => $code ,
            'DATAS'      => $datas ,
            'AP_CA'      => $ap_ca
            ];
        $res = $ua->simple_request($req)->as_string;
        if ($res=~/Set-Cookie: AP_CHECK/) {
            $self->_set_error('Allopass Check Code OK');
            my $r = $self->_add_session($docid, $code);
            if ($r) {
                $self->_set_error($r);
                return 0;
            }
            return 1;
        }
    }
    0;
}

=back

=head1 PROPERTIES

=over 4

=item B<ttl> - Session time to live property.

    $ttl=$allopass->ttl([$ttl]);

Session expiration time, in minutes.

=cut

sub ttl {
    my $self=shift;
    my $val =shift;
    $self->{ttl}=$val if $val;
    $self->{ttl};
}

=item B<os> - Operating system property.

    $allopass->os(1);
    
You need to set it to 1 only if your OS doesn't support flock (windoze ???).

=cut

sub os {
    my $self=shift;
    my $val =shift;
    $self->{os}=1 if $val;
    $self->{os};
}

### PRIVATE FUNCTIONS ==========================================================
sub _is_session {
    my $self   = shift;
    my $doc_id = shift;

    my $ok=0;
    my %cookies = fetch CGI::Cookie;
    my $docid=$doc_id; $docid=~s/\//\./g;

    if (!$doc_id) {
        $self->_set_error("No Document ID");
        return 0 
    }
    if (!$cookies{$docid}){
        $self->_set_error("No Session Cookie");
        return 0 
    }
    return 0 if !ref $cookies{$docid};
    return 0 if !defined $cookies{$docid}->value;
    
    my $code = $cookies{$docid}->value || $self->{code};
    
    my $a=time;
    $self->_set_error("Error opening ".$self->{ses_file}." for read");
    open (TEMP, $self->{ses_file}) or return 0;
        if ($self->{os} == 0) {flock (TEMP, 2);}
        my @index = <TEMP>;
        if ($self->{os} == 0) {flock (TEMP, 8);}
    close (TEMP);
    $self->_set_error("Error opening ".$self->{ses_file}." for write");
    open (OUTPUT, ">".$self->{ses_file}) or return 0;
        $self->_set_error('No session match found');
        if ($self->{os} == 0) {flock (TEMP, 2);}
        for (my $i = 0; $i < @index; $i++) {
            chomp $index[$i];
            next unless ($index[$i]);
            my ($docid, $pass, $IP, $heure, @autres) = split (/\|/, $index[$i]);
            next if ($a > ($heure + $self->{ttl} * 60));
            if ($doc_id eq $docid && $code eq $pass){
                print OUTPUT "$docid|$pass|$IP|" . $a . "||\n";
                $self->_set_error('Session found');
                $ok=1;
            } else {
                print OUTPUT "$docid|$pass|$IP|$heure||\n";
            }
        }
        if ($self->{os} == 0) {flock (TEMP, 8);}
    close (OUTPUT);
    $ok;
}
sub _add_session {
    my $self = shift;
    my $doc_id = shift;
    my $code = shift;
    $self->{code}=$code;
    foreach($doc_id, $code){
        s/[\r\n]//g;
        s/\|/&#124;/g;
    }
    my $a=time;
    open (TEMP, $self->{ses_file}) or return("Error opening ".$self->{ses_file}." for read : ".$!);
        if ($self->{os} == 0) {flock (TEMP, 2);}
        my @index = <TEMP>;
        if ($self->{os} == 0) {flock (TEMP, 8);}
    close (TEMP);
    open (OUTPUT, ">".$self->{ses_file}) or return("Error opening ".$self->{ses_file}." for write : ".$!);
        if ($self->{os} == 0) {flock (OUTPUT, 2);}
        for (my $i = 0; $i < @index; $i++) {
            chomp $index[$i];
            next unless ($index[$i]);
            my ($docid, $pass, $IP, $heure, @autres) = split (/\|/, $index[$i]);
            next if ($a > ($heure + $self->{ttl} * 60));
            next if $docid eq $doc_id && $pass eq $code;
            print OUTPUT "$docid|$pass|$IP|$heure||\n";
        }
        print OUTPUT "$doc_id|$code|$ENV{REMOTE_ADDR}|" . $a . "||\n";
        if ($self->{os} == 0) {flock (OUTPUT, 8);}
    close (OUTPUT);
    $doc_id=~s/\//\./g;
    my $cookie = new CGI::Cookie(-name=>$doc_id, -value=> $code );
    if (ref $self->{hhttp}) {
       $self->{hhttp}->add_cookie("Set-Cookie: ".$cookie->as_string);
    } else {
        print "Set-Cookie: ",$cookie->as_string,"\n";
    }
    0;
}
sub _end_session {
    my $self=shift;
    my $doc_id = shift;
    
    my %cookies = fetch CGI::Cookie;
    my $docid=$doc_id; $docid=~s/\//\./g;

    my $code = $self->{code};
    unless ($code) {
        return("Unable to remove session : Undefined sid") if !ref $cookies{$docid};
        return("Unable to remove session : Undefined sid") if !defined $cookies{$docid};
        return("Unable to remove session : Undefined sid") if !defined $cookies{$docid}->value;
        $code = $cookies{$docid}->value if defined $cookies{$docid}->value;
    }
    
    # warn "Code :".$code;
    
    my $a=time;
    open (TEMP, $self->{ses_file}) or return("Error opening ".$self->{ses_file}." for read : ".$!);
        if ($self->{os} == 0) {flock (TEMP, 2);}
        my @index = <TEMP>;
        if ($self->{os} == 0) {flock (TEMP, 8);}
    close (TEMP);
    open (OUTPUT, ">".$self->{ses_file}) or return("Error opening ".$self->{ses_file}." for write : ".$!);
        if ($self->{os} == 0) {flock (TEMP, 2);}
        for (my $i = 0; $i < @index; $i++) {
            chomp $index[$i];
            next unless ($index[$i]);
            my ($ldocid, $pass, $IP, $heure, @autres) = split (/\|/, $index[$i]);
            next if ($a > ($heure + $self->{ttl} * 60));
            next if $pass eq $code;
            print OUTPUT "$docid|$pass|$IP|$heure|$code|\n";
        }
        if ($self->{os} == 0) {flock (TEMP, 8);}
    close (OUTPUT);
    $doc_id=~s/\//\./g;
    my $cookie = new CGI::Cookie(-name=>$docid, -value=> '-' );
    if (ref $self->{hhttp}) {
       $self->{hhttp}->add_cookie("Set-Cookie: ".$cookie->as_string);
    } else {
        print "Set-Cookie: ",$cookie->as_string,"\n";
    }
    0;
}
sub _is_res_ok {
    my $self=shift;
    my $res=shift;
    my($h, $c, $a)=split(/\n\n/, $res); chomp $c;
    if($res && $res!~/NOK/ && $res!~/ERR/ && $res!~/error/i && $c=~/OK/) {
        $self->_set_error('Allopass Recall OK');
        return 1;
    }
    if ($c =~/NOK/) {
        $self->_set_error("Allopass.com says : This code is invalid")
    } elsif ($c =~/ERR/) {
        $self->_set_error("Allopass.com says : Invalid document id")
    } else {
        $res=~s/[\r\n]/ /g;
        $self->_set_error("Invalid Allopass.com response code : $res")
    }
    0;
}
sub _get_new_uid {
    my $id;
    $id=crypt(rand(99999999999),'fi');
    $id=crypt(rand(99999999999),'l2').$id;
    $id=crypt(rand(99999999999),'la').$id;
    $id=~s/[\|\/\\]/\-/g;
    $id;
}
sub _set_error {
    my $self=shift;
    $self->{error}=shift;
}

=back

=head1 Other documentation

Jetez un oeil sur I<http://www.it-development.be/software/PERL/Business-PhoneBill-Allopass/> pour la documentation en français.


=head1 AUTHOR

Bernard Nauwelaerts <bpn#it-development%be>

=head1 LICENSE

GPL.  Enjoy! See COPYING for further informations on the GPL.

=cut

1;
