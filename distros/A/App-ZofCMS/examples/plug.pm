package App::ZofCMS::Plugin::Example;

use strict;
use warnings;
use base 'App::ZofCMS::Plugin::Base';

# VERSION

sub _key { 'plug_example' }
sub _defaults { qw/foo bar baz beer/ }
sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;
    $template->{t}{time} = localtime;
}