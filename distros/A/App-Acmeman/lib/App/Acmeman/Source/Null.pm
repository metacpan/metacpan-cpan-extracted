package App::Acmeman::Source::Null;
use strict;
use warnings;
use parent 'App::Acmeman::Source';

sub new {
        return bless {}, shift;
}

sub scan { 1; }

1;
