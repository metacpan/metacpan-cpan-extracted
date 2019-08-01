#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Bash qw(format_completion);
use Test::More;

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

subtest "esc_mode default" => sub {
    is(format_completion({words=>['a /:$']}),
       "a\\ /:\\\$\n");
};

subtest "esc_mode none" => sub {
    is(format_completion({words=>['a /:$'], esc_mode=>'none'}),
       "a /:\$\n");
};

subtest "esc_mode shellvar" => sub {
    is(format_completion({words=>['a /:$'], esc_mode=>'shellvar'}),
       "a\\ /\\:\$\n");
};

subtest "as array" => sub {
    is_deeply(format_completion({words=>['a ','b'], as=>'array'}),
              ["a\\ ",'b']);
};

subtest "path_sep /" => sub {
    is(format_completion({words=>['a/'], path_sep=>'/'}),
       "a/\na/\\ \n");
    is(format_completion({words=>['a/', 'b/'], path_sep=>'/'}),
       "a/\nb/\n");
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
