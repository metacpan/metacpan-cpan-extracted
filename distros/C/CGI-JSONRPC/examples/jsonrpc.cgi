#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use CGI::JSONRPC;

CGI::JSONRPC->handler;

exit;

{
    package Hello;
        
    sub jsonrpc_new {
        my($class, $id) = @_;
        return bless { id => $id }, $class;
    }
        
    sub who_am_i {
        return $ENV{REMOTE_ADDR};
    }
        
    sub jsonrpc_javascript {
        return <<"EOT";
Create_Class("Hello", "JSONRPC");

Hello.prototype.who_am_i = function () {
    this.Call_Server(this.who_i_am, "who_am_i");
}

Hello.prototype.who_i_am = function (ip) {
    alert("Your IP is " + ip);
}
EOT
    }

    use LWP::UserAgent;
    package LWP::UserAgent;
        
    sub jsonrpc_new {
        my $class = shift;
        return $class->new(@_);
    }
        
    sub jsonrpc_javascript {
        return <<"EOT";
Create_Class("LWP.UserAgent", "JSONRPC");
LWP.UserAgent.prototype.get_page = function (url) {
    LWPer.Call_Server(this.write_page, "get", url);
};
LWP.UserAgent.prototype.write_page = function (result) {
    if(result._content) {
        this.frames[0].document.write(result._content);
    } else {
        this.frames[0].document.write("No content, result: " + result._rc);
    }
    this.frames[0].document.close();
};
EOT
    }
}
