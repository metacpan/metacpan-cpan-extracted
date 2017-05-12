package Authen::GoogleAccount;

use warnings;
use strict;

=head1 NAME

Authen::GoogleAccount - Simple Authentication with Google Account

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # step 1
    # redirect to goole to get token
    use CGI;
    use Authen::GoogleAccount;
    my $q = CGI->new;
    my $ga = Authen::GoogleAccount->new;
    
    # set callback url to verify token
    my $next = "http://www.example.com/googleauth.cgi";
    my $uri_to_login = $ga->uri_to_login($next);
    
    print $q->redirect($uri_to_login);
    
    
    
    # step 2
    # user will be redirected to http://www.example.com/googleauth.cgi?token=(token)
    # get token with CGI.pm and give it to verify()
    use CGI;
    use Authen::GoogleAccount;
    
    my $google_base_data_api_key = "fwioe2fqwoajieqawerq123ae...";
    
    my $q = CGI->new;
    my $ga = Authen::GoogleAccount->new(
    	key => $google_base_data_api_key,
    );
    
    my $token = $q->param('token');
    
    $ga->verify($token) or die $ga->errstr;
    print "login succeeded\n";
    print $ga->name, " ", $ga->email, "\n";
    #"email" may be unique.



=head1 FUNCTIONS

=head2 new(key => $google_base_data_api_key)

Creates a new object. Requires Google Base data API Key. L<http://code.google.com/apis/base/signup.html>

=head2 uri_to_login($next)

Creates a URI to login Google Account.

User will be redirected to $next with token after a successful login.

=head2 verify($token)

Verifies given token and returns true when the token is successfully verified.

=head2 name

Returns user name.

=head2 email

Returns user email("anon-~~~~@base.google.com"). It may be unique.

=head2 errstr

Returns error message.

=head2 delete_item

=head2 get_item

=head2 post_item

=head2 upgrade_to_session_token

=head2 revoke_session_token

=head2 init

=head1 AUTHOR

Hogeist, C<< <mahito at cpan.org> >>, L<http://www.ornithopter.jp/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-authen-googleaccount at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-GoogleAccount>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::GoogleAccount

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-GoogleAccount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-GoogleAccount>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-GoogleAccount>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-GoogleAccount>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2007 Hogeist, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
















use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use Data::Dumper;
#use Smart::Comments;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw/session_token base_key enable_session errstr name email/ );


my $insert_xml = << "END_OF_INSERT_XML";
<?xml version='1.0'?>
<entry xmlns='http://www.w3.org/2005/Atom'
  xmlns:g='http://base.google.com/ns/1.0'>
  <category scheme='http://base.google.com/categories/itemtypes' term='Jobs'/>
  <title type='text'>Authen::GoogleAccount Temporary Data</title>
  <content type='xhtml'>It will be deleted automatically.</content>
  <link rel='alternate' type='text/html' href='http://search.cpan.org/dist/Authen-GoogleAccount'/>
  <g:item_type type='text'>Jobs</g:item_type>
  <g:hoge type='text'>hoge hoge</g:hoge>
</entry>
END_OF_INSERT_XML


sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->init(@_);
	return $self;
}

sub init {
	my $self = shift;
	my %fields = @_;
	
	$self->base_key($fields{key});
	$self->enable_session(1);
}

sub uri_to_login {
	my $self = shift;
	my ($next) = @_;
	my $scope = 'http://www.google.com/base/';
	
	return 'https://www.google.com/accounts/AuthSubRequest'
		. '?scope=' . uri_escape($scope)
		. '&session=' . 1
		. '&next=' . uri_escape($next);
}

sub verify {
	my $self = shift;
	my $token = shift;
	my $debug = shift;
	
	
	
	if($self->enable_session){
		if(!$debug){
			$self->upgrade_to_session_token($token) or return 0;
		}
		else{
			$self->session_token($token);
		}
		
		my $item = $self->post_item() or return 0;
		$self->get_item($item) or return 0;
		
		$self->revoke_session_token() if(!$debug);
		
		return 1;
	}
	else{
		#depreciated...
		my $ua = LWP::UserAgent->new();
		my $res = $ua->get(
			'https://www.google.com/accounts/AuthSubTokenInfo',
			'Authorization' => 'AuthSub token="' . $token . '"',
		);
		if ($res->is_success){
			return 1;
		}
		else{
			$self->errstr( $res->message );
			return 0;
		}
	}
}


sub upgrade_to_session_token {
	my $self = shift;
	my $token = shift;
	
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get(
		'https://www.google.com/accounts/AuthSubSessionToken',
		'Content-Type' => 'application/x-www-form-urlencoded',
		'Authorization' => 'AuthSub token="' . $token . '"',
	);
	if ($res->is_success and $res->content =~ /^Token=(.+)$/){
		$self->session_token($1);
		return 1;
	}
	else{
		$self->errstr("failure of getting session token.($token)");
		return 0;
	}
}

sub revoke_session_token {
	my $self = shift;
	
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get(
		'https://www.google.com/accounts/AuthSubRevokeToken',
		'Content-Type' => 'application/x-www-form-urlencoded',
		'Authorization' => 'AuthSub token="' . $self->session_token . '"',
	);
	if ($res->is_success){
		return 1;
	}
	else{
		return 0;
	}
}

sub post_item {
	my $self = shift;
	
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new(
		'POST',
		'http://www.google.com/base/feeds/items/',
	);
	$req->header('Authorization' => 'AuthSub token="' . $self->session_token . '"');
	$req->header('X-Google-Key' => "key=" . $self->base_key);
	$req->header('Content-Type' => "application/atom+xml");
	$req->content($insert_xml);
	
	
	
	my $res = $ua->request($req);
	if ($res->is_success){
		$res->content =~ m{<id>http://www.google.com/base/feeds/items/(\d+)</id>};
		return $1;
	}
	else{
		$self->errstr( $res->message );
		return 0;
	}
}

sub get_item {
	my $self = shift;
	my $item = shift;
	
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get(
		'http://www.google.com/base/feeds/items/' . $item,
		'Authorization' => 'AuthSub token="' . $self->session_token . '"',
		'X-Google-Key' => "key=" . $self->base_key,
		'Content-Type' => "application/atom+xml",
	);
	if ($res->is_success){
		$res->content =~ m{<author><name>(.+?)</name><email>(.+?)</email></author>};
		$self->name($1);
		$self->email($2);
		return 1;
	}
	else{
		$self->errstr( $res->message );
		return 0;
	}

}


sub delete_item {
	my $self = shift;
	my $item = shift;
	
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new(
		'DELETE',
		'http://www.google.com/base/feeds/items/' . $item,
	);
	$req->header('Authorization' => 'AuthSub token="' . $self->session_token . '"');
	$req->header('X-Google-Key' => "key=" . $self->base_key);
	$req->header('Content-Type' => "application/atom+xml");
	
	
	my $res = $ua->request($req);
	if ($res->is_success){
		return 1;
	}
	else{
		$self->errstr( $res->message );
		return 0;
	}

}








1; # End of Authen::GoogleAccount
