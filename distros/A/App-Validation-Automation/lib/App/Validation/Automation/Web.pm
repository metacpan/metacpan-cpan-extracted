package App::Validation::Automation::Web;

use Moose;
use Carp;
use WWW::Mechanize;
use HTML::Form::ForceValue;
use English qw( -no_match_vars );
use namespace::autoclean;

=head1 NAME

App::Validation::Automation::Web - Base Class App::Validation::Automation

Stores utilities that perform web based validation

=head1 SYNOPSIS

App::Validation::Automation::Web browses the web urls stored in config or passed as arguments using WWW::Mechanize Logs into the web urls using the credentials stored in attributes.Handles password expiry and authentication failure along with DNS round robin and Load Balancing Functionality check.

=head1 ATTRIBUTES

user_name houses the login name needed to login into the web url.password stores the decrypted password.

=cut 

has 'user_name' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'password' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'site' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'zone' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'web_msg' => (
    is       => 'rw',
    isa      => 'Str',
    clearer  => 'clear_web_msg',
); 

has 'mech_state' => (
    is       => 'rw',
    isa      => 'WWW::Mechanize',
); 

=head1 METHODS

=head2 validate_url

Browses the weblink passed as parameter using WWW::Mechanize.Tries to log into the weblink if user_name and password are defined.Tweak this method or override to fit your requirement.

=cut

sub validate_url {
    my $self    = shift;
    my $url     = shift;
    my $mech    = WWW::Mechanize->new();
    my ( $content,    $return,   $web_server,  $web_server_ip, $web_port,
         $app_server, $user,     $menu_tokens, $auto_tokens,   $site,
         $zone,       $slif_flag,$menu_url,    $req_string, $ret);

    $mech->get($url);
    $self->web_msg( $mech->status ) if (not ($ret = $mech->success));

    if($self->user_name && $self->password) {
        $self->mech_state($mech);
        $ret = $self->_login;
    }

    return $ret;
}

=head1 METHODS

=head2 dnsrr

Tests if DNS Round Robin is working fine or not.Posts the main url max_requests no of times and stores the url redirected.Counts the no of unique redirected urls and reports if they are less than min_unique.

=cut

sub dnsrr {
    my $self         = shift;
    my $url          = shift;
    my $max_requests = shift;
    my $min_unique   = shift;
    my $mech         = WWW::Mechanize->new();
    my $msg          = "Round Robin details:\n";
    my ( @redirect_uris, $unique );

    foreach my $count ( 1..$max_requests ) {
        $mech->get( $url )
                    || confess "Couldn't Fetch $url : ".$mech->error;
        $self->web_msg( $mech->status ) if ( not $mech->success );
        $msg .= $url." Redirected to ".$mech->uri."\n";
        push @redirect_uris,$mech->uri;
    }
    
    $unique = keys %{{ map {$_ => 1} @redirect_uris }};
    if( $unique < $min_unique ) {
        $self->web_msg( $msg );
        return 0;
    }

    return 1;
}

=head2 lb

Tests if Load Balancing is working fine or not.Posts the main url max_requests no of times and logs into the url and scraps server specific info each time and stores in a list.Counts the unique elements in the list to ascertain Load Balancing is in place and transactional load is being divided amongst various servers.

=cut

sub lb {
    my ($self, $url, $max_requests, $min_unique) = @_;
    my $mech         = WWW::Mechanize->new();
    my $msg
        = "Load Balancing details:\nWeb_Server App_Server Alt_App_Server\n";
    my ($unique, @system_info);

    foreach my $count ( 1..$max_requests ) {
        my ( $web_server, $ret, $app_server, $alt_app_server);

        $mech->get( $url )
                  || confess "Couldn't Fetch $url : ".$mech->error;
        $self->web_msg( $mech->status ) if ( not $mech->success );

        if($self->user_name && $self->password) {
            $self->mech_state($mech);
            $ret = $self->_login;
            if( $ret ) {
                push @system_info, join '_',
                    ($web_server, $app_server, $alt_app_server)
                        = ( $mech->content
                            =~ /
                                strWebSrvr\=(.+?)\; .+
                                strAppSrvr\=(.+?)\; .+
                                strKSAppSrvr\=(.+?)\; .+
                              /isx
                          );
            }
            else {
                $self->web_msg( "Missdirected to".$mech->uri );
                return 0;
            }
        }
    }
    $unique = keys %{{ map { $_ => 1} @system_info }};
    if( $unique < $min_unique ) {
        $msg .= join "\n", @system_info;
        $self->web_msg( $msg );
        return 0;
    }
    return 1;
}

=head2 change_web_pwd

Change Password at Website level after Password expiration.

=cut

sub change_web_pwd {
    my $self    = shift;
    my $url = shift;
    my ($mon, $random_no, $new_pwd, %month_map, $body, $form);
    %month_map = (
        '1' => 'Jan', '2' => 'Feb', '3' => 'Mar','4' => 'Apr','5' => 'May',
        '6' => 'Jun', '7' => 'Jul', '8' => 'Aug', '9' => 'Sep','10' => 'Oct',
        '10' => 'Oct', '11' => 'Nov', '12' => 'Dec',
    );
    my $mech = $self->mech_state();

    #Compute new password
    ( $mon ) = ( localtime( time ))[4];
    $mon += 1;
    $mon %= 12; #Handles year change
    $random_no = int( rand( $mon )).int( rand( $mon )).int( rand( $mon ));
    $mon = $month_map{($mon + 1)}; #We need to pick the next month
    $new_pwd = $mon.'-'.$random_no;

    #Compare current and new password
    if($self->password =~ /$new_pwd/) {
        $self->web_msg("Pwd Change Failed! : old pwd == new pwd!");
        return 0;
    }

    if(not ($form = $mech->form_with_fields(qw(pw1 pw2)))) {
        $self->web_msg("No form with pw1 & pw2");
        return 0;
    }
    $form->find_input("pw1")->force_value($new_pwd);
    $form->find_input("pw2")->force_value($new_pwd);
    $mech->submit;
    if(not $mech->success) {
        $self->web_msg(
            "Pwd Change Failed! : ".$mech->status." ".$mech->error
        );
        return 0;
    }
    $self->config->{'COMMON.OLD_PASSWORD'} = $self->password;
    $self->password = $new_pwd;
 
    return 1;
}


sub  _login {
    my $self                    = shift;
    my $mech                    = $self->mech_state;
    my ($content, $req_string, $web_server_ip, $web_port, $web_server,
        $app_server, $site, $zone, $slif_flag, $menu_url, $menu_tokens,
        $auto_tokens, $user, $form);

    local $WARNING = 0;
    if(not ($form = $mech->form_with_fields(qw(user password)))) {
        $self->web_msg("No form with user & password");
        return 0;
    }
    $form->find_input("user")->force_value($self->user_name);
    $form->find_input("password")->force_value($self->password);
    $form->find_input("shortsite")->force_value($self->site) if($self->site);
    $form->find_input("zone")->force_value($self->zone) if($self->zone);
    $mech->submit;
    $self->web_msg( $mech->status ) if ( not $mech->success );

    $content = $mech->content;
    if($content =~ /Password\s+has\s+expired/i) {
        $self->web_msg("Password has Expired!");
        $self->mech_state($mech);
        return 0;
    }
    elsif($content =~ /Authentication\s+Failure/i) {
        $self->web_msg("Authentication Failure!");
        return 0;
    }
    elsif($content =~ /launchMenu\((.*)\)\;/) {
        (( $req_string = $1 ) =~ s/^\'(.*)\'$/$1/ );
        ($web_server,$web_server_ip,$web_port,$app_server,$user,$menu_tokens,
        $auto_tokens, $site, $zone, $slif_flag ) = split /','/,$req_string;

        $menu_url
            = "http://$web_server_ip:$web_port/LoginIWS_Servlet/Menu?webserver";
        $menu_url .= "=$web_server&webport=$web_port&appserver=$app_server&user";
        $menu_url .= "$user&menuTokens=$menu_tokens&autoTokens=$auto_tokens&site";
        $menu_url .= "=$site&zone=$zone&SLIflag=$slif_flag&code=x9y8z70D0";

        $mech->get( $menu_url );
        $self->web_msg( $mech->status ) if ( not $mech->success );
        return 1;
    }
    else {
        $self->web_msg( "Missdirected to".$mech->uri );
        return 0;
    }
}

__PACKAGE__->meta->make_immutable;

1;
