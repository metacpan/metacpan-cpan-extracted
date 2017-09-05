package Anego::Git;
use strict;
use warnings;
use utf8;
use parent qw/ Exporter /;
use Git::Repository;

use Anego::Logger;

our @EXPORT = qw/ git_log git_cat_file /;

sub git_log {
    Git::Repository->new->run('log', @_);
}

sub git_cat_file {
    Git::Repository->new->run('cat-file', '-p', @_);
}

1;
