use warnings;
use strict;

use Benchmark;
use CGI::Struct ();
use CGI::Struct::XS ();

# simple params, typical for user interface
my %poor_inp = (
    'action' => 'list',
    'order'  => 'name',
    'page'   => 5,
    'limit'  => 10,
);

# complex params, typical for admin interface
my %rich_inp = (
    'action' => 'update',
    'p.sys.name' => 'dsfdsfdsf',
    'p.sys.slug' => 'sfsdfs',
    'p.sys.client_id' => 'sdfdsgfdsg',
    'p.urls[]' => ['a', 'b', 'c'],
    'p.zeroes' => "a\0b\0c",
    'p.media[0].id' => 1,
    'p.media[0].name' => 'asdasd',
    'p.media[0].type' => 'img',
    'p.media[1].id' => 1,
    'p.media[1].name' => 'asdasd',
    'p.media[1].type' => 'img',
    'p.media[2].id' => 1,
    'p.media[2].name' => 'asdasd',
    'p.media[2].type' => 'img',
);

print "Rich input, dclone => 0\n";
timethese(100000, {
    pp => sub { my @errs; CGI::Struct::build_cgi_struct(\%rich_inp, \@errs, { dclone => 0, nullsplit => 1 }); },
    xs => sub { my @errs; CGI::Struct::XS::build_cgi_struct(\%rich_inp, \@errs, { dclone => 0, nullsplit => 1 }); },
});

print "Rich input, dclone => 1\n";
timethese(100000, {
    pp => sub { my @errs; CGI::Struct::build_cgi_struct(\%rich_inp, \@errs, { dclone => 1, nullsplit => 1 }); },
    xs => sub { my @errs; CGI::Struct::XS::build_cgi_struct(\%rich_inp, \@errs, { dclone => 1, nullsplit => 1 }); },
});

print "Poor input, dclone => 0\n";
timethese(400000, {
    pp => sub { my @errs; CGI::Struct::build_cgi_struct(\%poor_inp, \@errs, { dclone => 0, nullsplit => 0 }); },
    xs => sub { my @errs; CGI::Struct::XS::build_cgi_struct(\%poor_inp, \@errs, { dclone => 0, nullsplit => 0 }); },
});

print "Poor input, dclone => 1\n";
timethese(400000, {
    pp => sub { my @errs; CGI::Struct::build_cgi_struct(\%poor_inp, \@errs, { dclone => 1, nullsplit => 0 }); },
    xs => sub { my @errs; CGI::Struct::XS::build_cgi_struct(\%poor_inp, \@errs, { dclone => 1, nullsplit => 0 }); },
});
