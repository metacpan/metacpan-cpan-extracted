#!/usr/bin/env perl

use strict;
use warnings;

package My::Namespace;
sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

package My::Namespace::Class;
use base 'My::Namespace';

package Other::Namespace;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

package Other::Namespace::Class;
use base 'Other::Namespace';

package Good::Namespace::Class;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub salute {
    return "I'm a good class!";
}

package main;


use strict;
use warnings;

use File::Spec;
use Data::Dumper;

use Dancer qw/:syntax/;

my $blacklist = [qw/My::Namespace
                    Other::Namespace/];

set engines => { template_flute => { autodetect  => { disable => $blacklist } } };
set template => 'template_flute';
set views => 't/views';
set log => 'debug';

get '/' => sub {
    session salute => "Hello session";
    my %values = (
                  first => My::Namespace::Class->new(salute => "Object 1"),
                  second => Other::Namespace::Class->new(salute => "Object 2"),
                  third  => Good::Namespace::Class->new(),
                 );
    template objects => \%values;
};

use Test::More tests => 3, import => ['!pass'];

use Dancer::Test;

my $resp = dancer_response GET => '/';

my $expected = <<'HTML';
<body>
<span class="firstobj">Object 1</span>
<span class="secondobj">Object 2</span>
<span class="thirdobj">I'm a good class!</span>
<span class="sessionobj">Hello session</span><
/body>
HTML

$expected =~ s/\n//sg;

response_status_is $resp, 200, "GET / is found";
response_content_like $resp, qr{\Q$expected\E}, "GET / ok";
is_deeply read_logs, [], "Empty logs, all good";
