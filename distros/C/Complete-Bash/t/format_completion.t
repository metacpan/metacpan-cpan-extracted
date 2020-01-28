#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Complete::Bash qw(format_completion);

local $ENV{COMPLETE_BASH_DEFAULT_ESC_MODE};

subtest "accepts array of str" => sub {
    is(format_completion([qw/a b c/]), "a\nb\nc\n");
};

subtest "accepts array of hashref" => sub {
    is(format_completion([
        {word=>'a', description=>'da'},
        {word=>'b', description=>'db'},
        {word=>'c', description=>'dc'},
    ]), "a\nb\nc\n");
};

subtest "opt:esc_mode=default" => sub {
    is(format_completion({words=>['a /:$']}),
       "a\\ /:\$\n");
};

subtest "opt:esc_mode=shellvar" => sub {
    is(format_completion({words=>['a /:$']}, {esc_mode=>'shellvar'}),
       "a\\ /:\\\$\n");
};

subtest "opt:esc_mode=none" => sub {
    is(format_completion({words=>['a /:$']}, {esc_mode=>'none'}),
       "a /:\$\n");
};

subtest "opt:as=array" => sub {
    is_deeply(format_completion({words=>['a ','b']}, {as=>'array'}),
              ["a\\ ",'b']);
};

subtest "path_sep /" => sub {
    is(format_completion({words=>['a/'], path_sep=>'/'}),
       "a/\na/\\ \n");
    is(format_completion({words=>[{word=>'a/'}], path_sep=>'/'}),
       "a/\na/\\ \n");
    is(format_completion({words=>['a/', 'b/'], path_sep=>'/'}),
       "a/\nb/\n");
};

subtest "is_partial" => sub {
    is(format_completion({words=>['a'], is_partial=>1}),
       "a\na\\ \n");
    is(format_completion({words=>[{word=>'a', is_partial=>1}]}),
       "a\na\\ \n");
};

subtest "path_sep ::" => sub {
    is(format_completion({words=>['a/'], path_sep=>'::'}),
       "a/\n");
    is(format_completion({words=>['a::'], path_sep=>'::'}),
       "a::\na::\\ \n");
    is(format_completion({words=>['a::', 'b::'], path_sep=>'::'}),
       "a::\nb::\n");
};

subtest "message" => sub {
    like(format_completion({message=>"foo"}),
         qr/\Afoo *\n \n\z/);
};

DONE_TESTING:
done_testing;
