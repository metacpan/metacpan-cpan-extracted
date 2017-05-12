#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use CGI::JSONRPC::Session;

CGI::JSONRPC::Session->handler;

exit;

{
    package Count;
    use CGI::JSONRPC::Session::Obj;
    use base qw(CGI::JSONRPC::Session::Obj);
   
    sub increment {
      my $self = shift;
      $self->{count} = 1 unless $self->{count};
      return $self->{count}++;
    }

    # we never serialize keys with leading underdash 
    sub notincrement {
      my $self = shift;
      $self->{_count} = 1 unless $self->{_count};
      return $self->{_count}++;
    }
    
    sub jsonrpc_javascript {
        return <<"EOT";
Create_Class("Count", "JSONRPC");

Count.prototype.increment = function () {
    this.Call_Server(this.show_count, "increment");
}

Count.prototype.show_count = function (count) {
    alert("count is " + count);
}

Count.prototype.notincrement = function () {
    this.Call_Server(this.show_count, "notincrement");
}

Count.prototype.show_count = function (count) {
    alert("count is " + count);
}

EOT
    }
    
    # non session aware class for backwards compat testing
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



};





