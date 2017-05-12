#!perl
use strict;
use warnings;

do
{
    package Mr::Mastodon::Farm;
    our $birds = 'fall';
    my $window = 'ledge';
};

my $pre_lexical = 'alpha';
our $pre_global = 'sheep';
our $pre_global_safe = 'sheep';

sub sandwich
{
    my $other_lexical = 'short skirt';
    our $other_global = 'long jacket';
}

sub marine
{
    my $inner_lexical = 'parking';
    our $inner_global = 'to';
    my $pre_global = 'shadow stabbing';

    die 'coping with scoping? or scoping the coping?';
}

my $post_lexical = 'beta';
our $post_global = 'go';

sandwich();
marine();

my $postcall_lexical = 'lot';
our $postcall_global = 'heaven';

