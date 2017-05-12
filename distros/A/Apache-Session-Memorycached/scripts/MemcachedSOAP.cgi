#!/usr/bin/perl -w
# Filename: MemcachedSOAP.cgi
# MemcachedSOAPClass Web Service 
#  This program is a piece of lemonldap web sss framework  
# 
#  Modify the line with your memcached ip address
#  copy this file in cgi-bin directory AND changes right (x)  in order to run it
use MemcachedSOAPClass;

use SOAP::Transport::HTTP;
$machine = 'ip.ip.ip.ip:11211';
SOAP::Transport::HTTP::CGI
  ->dispatch_to('MemcachedSOAPClass')
  ->handle;
