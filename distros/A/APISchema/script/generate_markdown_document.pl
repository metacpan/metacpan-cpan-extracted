#!/usr/bin/env perl
use strict;
use warnings;
use Encode qw(encode_utf8);

BEGIN {
    # cpan
    use Path::Class qw(file);
    my $Root = file(__FILE__)->dir->parent->resolve->absolute;
    unshift @INC, $Root->subdir('lib').q();
}

# lib
use APISchema::DSL;
use APISchema::Generator::Markdown;

unless ($ARGV[0]) {
    print <<EOM;
Usage: $0 <file>
Options:
  <file>    API definition file.
EOM
    exit;
}

my $schema = APISchema::DSL::process {
    include $ARGV[0];
};

my $generator = APISchema::Generator::Markdown->new;
print encode_utf8 $generator->format_schema($schema);
