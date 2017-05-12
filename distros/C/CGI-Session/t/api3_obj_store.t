# $Id: api3_obj_store.t,v 1.3 2002/11/22 22:54:41 sherzodr Exp $

use strict;

use Data::Dumper;

use CGI;
use CGI::Session qw/-api3/;

my @mods = qw(Storable FreezeThaw);

my $ser = undef;
for ( @mods ) {
    eval "require $_";
    unless ( $@ ) {
        $ser = $_;
        next;
    }
}

unless ( $ser ) {
    print "1..0"; # Neither Storable nor FreezeThaw avaialble
    exit(0);
}


warn "#Using $ser as object serializer\n";

my $args = "serializer:$ser";
my $dr_args = {Directory=>'t'};

print "1..8\n";

my $cgi = CGI->new;
my $s   = CGI::Session->new($args, undef, $dr_args);


print defined($s) ? "ok\n" : "not ok\n";
print $s->id() ? "ok\n" : "not ok\n";

$cgi->param(name => 'Sherzod');

print $cgi->param('name') ? "ok\n" : "not ok\n";

print $s->param(_CGI => $cgi) ? "ok\n" : "not ok - _CGI=>$cgi\n";

my $sid = $s->id();

$s->flush();

my $s2 = CGI::Session->new($args, $sid, $dr_args);
print defined($s2) ? "ok\n" : "not ok\n";

print $s2->id eq $sid ? "ok\n" : "not ok\n";

my $old_cgi = $s2->param('_CGI');

print ref($old_cgi) ? "ok\n" : "not ok\n";

print $old_cgi->param('name') eq 'Sherzod' ? "ok\n" : "not ok\n";

$s2->delete();




