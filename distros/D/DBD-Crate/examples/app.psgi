#===================================
# a plack example to run Crate db 
# with basic authintication
#===================================
use strict;
use warnings;
use HTTP::Tiny;
use MIME::Base64;
use Data::Dumper;
use Plack::Request;

# Settings ========================================
my $username = "xxx";
my $password = "xxx";
my $host = "http://127.0.0.1:4200";
#==================================================

my $http = HTTP::Tiny->new( keep_alive => 1 );

my $app = sub {
    my $env = shift;
    my $auth = $env->{HTTP_AUTHORIZATION};
    if ($auth && $auth =~ /^Basic (.*)$/i) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":"), 2;
        $pass = '' unless defined $pass;
        if ($user eq $username && $pass eq $password){
            my $req = Plack::Request->new($env);
            my $content = $req->content;
            
            my $ret = $http->request($req->method, $host . $req->path, {
                content => $content,
            });

            return [$ret->{status}, [], [$ret->{content}]];
        } else {
            return [401, [], ["Unauthorized"]];
        }
    } else {
        return [401, [], ["Authorization Required"]];
    }
};
