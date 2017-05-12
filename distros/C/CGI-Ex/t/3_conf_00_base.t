# -*- Mode: Perl; -*-

=head1 NAME

3_conf_00_base.t - Test for the basic functionality of CGI::Ex::Conf

=cut

use strict;
use Test::More tests => 8;
use POSIX qw(tmpnam);

my $file = tmpnam;
END { unlink $file };

use_ok('CGI::Ex::Conf');

my $obj = CGI::Ex::Conf->new;
ok($obj);

### TODO - re-enable more fileside tests

if (eval { require JSON }) {
    ok(eval { CGI::Ex::Conf::conf_write($file, {foo => "bar"}, {file_type => 'json'}) }, "Could JSON write") || diag($@);
    my $ref = eval { CGI::Ex::Conf::conf_read($file, {file_type => 'json'}) };
    is(eval { $ref->{'foo'} }, 'bar', "Could JSON read");
} else {
    SKIP: {
        skip("Can't test read/write of json", 2);
    };
}

if (eval { require YAML }) {
    ok(eval { CGI::Ex::Conf::conf_write($file, {foo => "bar2"}, {file_type => 'yaml'}) }, "Could YAML write") || diag($@);
    my $ref = eval { CGI::Ex::Conf::conf_read($file, {file_type => 'yaml'}) };
    is(eval { $ref->{'foo'} }, 'bar2', "Could YAML read");
} else {
    SKIP: {
        skip("Can't test read/write of yaml", 2);
    };
}

if (eval { require Data::Dumper }) {
    ok(eval { CGI::Ex::Conf::conf_write($file, {foo => "bar2"}, {file_type => 'pl'}) }, "Could Perl write") || diag($@);
    my $ref = eval { CGI::Ex::Conf::conf_read($file, {file_type => 'pl'}) };
    is(eval { $ref->{'foo'} }, 'bar2', "Could perl read");
} else {
    SKIP: {
        skip("Can't test read/write of pl", 2);
    };
}
