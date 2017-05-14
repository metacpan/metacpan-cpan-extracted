use strict;
use warnings;
package Bing::Translate;
# ABSTRACT: Class for using the functions, provided by the Microsoft Bing Translate API.

# for Wide character in print at
use utf8;
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# for translate
use LWP::UserAgent;
use HTTP::Headers;
use URI::Escape;
# for getToken
use JSON;
use Data::Dumper;
use HTTP::Request::Common qw(POST);

#http://stackoverflow.com/questions/392135/what-exactly-does-perls-bless-do
#http://www.tutorialspoint.com/perl/perl_oo_perl.htm
sub new {
        my $class = shift;
        my $self = {
                'id' => shift,
                'secret' => shift,
        };
        bless $self, $class;
        return $self;
}

sub decodeJSON {
        my $rawJSON = shift;
        my $json = new JSON;
        my $obj = $json->decode($rawJSON);
        #print "The structure of obj: ".Dumper($obj);
        #obj is a hash
        #print "$obj->{'access_token'}\n";
        return $obj->{'access_token'};
}

sub translate {
        #需要給主程式呼叫時, 要建立 $self
        my ($self, $text, $from, $to) = @_;
        $text = uri_escape($text);

        my $apiuri = "http://api.microsofttranslator.com/v2/Http.svc/Translate?"."text=".$text."&from=$from"."&to=$to"."&contentType=text/plain";
        my $agent_name='myagent';
        my $ua = LWP::UserAgent->new($agent_name);
        my $request = HTTP::Request->new(GET=>$apiuri);
        my $authToken = &getToken;
        #$request->header(Accept=>'text/html');
        $request->header(Authorization=>$authToken);

        my $response = $ua->request($request);
        #print $response->as_string, "\n";
        if ($response->is_success) {
                #print $response->decoded_content;
                my $content = $response->decoded_content;
                if ($content =~ />(.*)<\/string>/) {
                        return $1;
                }
        } else {
                return "translate fail";
        }
}

sub getToken {
        #my ($id, $secret) = @_;
        my $self = shift;
        my $id = $self->{'id'};
        my $secret = $self->{'secret'};

        my $ua = LWP::UserAgent->new() or die;
        $ua->ssl_opts (verify_hostname => 0);
        my $url = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13/";
        my $request = POST( $url, [ grant_type => "client_credentials", scope => "http://api.microsofttranslator.com", client_id => "$id", client_secret => "$secret" ] );
#       my $content = $ua->request($request)->as_string() or die;
        my $response = $ua->request($request);
        my $content;
        my $authToken;
        if ($response->is_success) {
                #print $response->decoded_content;
                $content = $response->decoded_content;
                my $accessToken = &decodeJSON($content);
                $authToken = "Bearer" . " " . "$accessToken";
        } else {
                die $response->status_line;
        }
        return $authToken;
}

1;

__END__

=pod

=head1 NAME

Bing::Translate - Class for using the functions, provided by the Microsoft Bing Translate API.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Bing::Translate;

  my $srcText = "胖達人昨起受理退費";
  my $translator = Bing::Translate->new('Your client id', 'Your client secret'); 
  my $result = $translator->translate("$srcText", "zh-CHT", "en");
  print "$result\n";

=head1 DESCRIPTION

This is an implementation of the Microsoft Translator (Bing Translator) API.

=head1 CONSTRUCTORS 

=head2 new($client_id, $client_secret)

This is the constructor.  Options are as follows:

=over 4

=item * Client ID (required)

Your Application client ID on the Windows Azure Marketplace 

=item * Client secret (required)

Your Application client secret on the Windows Azure Marketplace

=back

If you don't know how to do this, you can see : http://blogs.msdn.com/b/translation/p/gettingstarted1.aspx

=head1 METHODS

=head2 translate("source text", "from language code", "to language code")

  my $result = $translator->translate("$srcText", "zh-CHT", "en");

This method reads source text and send to Bing translate server, it process the Access Token  then get the translated result.
The language code reference : http://msdn.microsoft.com/en-us/library/hh456380.aspx

=head1 AUTHOR

Meng-Jie Wang <taiwanwolf.iphone@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Meng-Jie Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
