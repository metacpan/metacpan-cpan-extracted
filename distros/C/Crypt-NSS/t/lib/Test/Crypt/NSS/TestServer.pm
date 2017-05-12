package Test::Crypt::NSS::TestServer;

use strict;
use warnings;

my $pid;
my $port = 4433;;

use Crypt::NSS::Constants qw(:ssl);
use constant DB_PASSWORD => "crypt-nss";

sub import {
    shift;
    my %args = @_;
    
    $port = $args{port} if $args{port};
    
    start_server();    
}

sub start_server {
#    $pid = fork();
#    if ($pid) {
#        print STDERR "In client\n";
#    }
#    else {
        require Crypt::NSS;
        Crypt::NSS->import(config_dir => "db", cipher_suite => "US");

        my $private_cert = Crypt::NSS::PKCS11->find_cert_by_nickname("127.0.0.1", DB_PASSWORD);
        if (!$private_cert) {
            print STDERR "Failed to get private cert\n";
            exit;
        }
        my $private_key = Crypt::NSS::PKCS11->find_key_by_any_cert($private_cert, DB_PASSWORD);
        if (!$private_key) {
            print STDERR "Failed to get private key\n";
            exit;
        }
        
        Crypt::NSS::SSL->config_server_session_cache({});
        
        my $sock = Net::NSS::SSL->create_socket("tcp");
        $sock->set_option(Blocking => 1);
                
        $sock->bind("127.0.0.1", $port);
        $sock->listen();
        $sock->import_into_ssl_layer();

        $sock->configure_as_server($private_cert, $private_key);
        
        my $client = $sock->accept();
        $client->set_option(Blocking => 1);
        $client->set_option(SSL_SECURITY, SSL_OPTION_ENABLE);
        $client->set_option(SSL_HANDSHAKE_AS_SERVER, SSL_OPTION_ENABLE);
        $client->set_option(SSL_REQUEST_CERTIFICATE, SSL_OPTION_DISABLE);
        $client->set_option(SSL_REQUIRE_CERTIFICATE, SSL_OPTION_DISABLE);
        $client->set_pkcs11_pin_arg(DB_PASSWORD);
        

        $client->reset_handshake(1);
        
        my $buff;
        while($client->read($buff) > 0) {
            if ($buff eq "quit") {
                $client->close();
            }
            else {
                $client->write(reverse $buff);
            }
        }
        
        $sock->close();
        
        exit;        
 #   }
}

END {
    if ($pid) {
        waitpid $pid, 0;
    }
}