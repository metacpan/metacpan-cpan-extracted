use strict;
use warnings;
use Test2::V0;
use List::AutoNumbered;

use App::GitFind::cmdline;
my $r = \&App::GitFind::cmdline::_is_valid_rev;

# Miscellaneous OK forms
my $gitrevisions_good = List::AutoNumbered->new(__LINE__);
$gitrevisions_good->load('tag-1-g123ae')->
    ('tag-g123ae')
    ('@')
    ('tag@{3 days ago}')
    ('tag@{2}')
    ('@{1}')
    ('@{-1}')
    ('tag@{3 days ago}')
    ('a' x 40)
    ('0' x 40)
    ('foo@{bar}')
    ('foo@bar')
    ('foo@')
    ('@bar')
    (']')       # `git tag ']'` works!
    (']]')      # We use this as a special case, but it's a rev to git.
;

# The examples from gitrevisions(7)
$gitrevisions_good->load(LSKIP 3, 'dae86e1950b1277e545cee180551750029cfe735')->
    ('dae86e')
    ('v1.7.4.2-679-g3bee7fb')
    ('master')
    ('heads/master')
    ('refs/heads/master')
    ('@')
    ('master@{yesterday}')
    ('HEAD@{5 minutes ago}')
    ('master@{1}')
    ('@{1}')
    ('@{-1}')
    ('master@{upstream}')
    ('@{u}')
    ('master@{push}')
    ('@{push}')
    ('HEAD^')
    ('v1.5.1^0')
    ('HEAD~')
    ('master~3')
    ('v0.99.8^{commit}')
    ('v0.99.8^{}')
    ('HEAD^{/fix nasty bug}')
    (':/fix nasty bug')
    (':/^foo')
    (':/!-foo')
    (':/!!foo')
    ('HEAD:README')
    ('master:./README')
    ('master:foo/../README')    # not in gitrevisions
    (':0:README')
    (':README')
    ('^r1')
    ('r1')
    ('r2')
    ('r1..r2')
    ('r1...r2')
    ('origin..')
    ('origin..HEAD')
    ('origin..@')
    ('..origin')
    ('@..origin')
    ('r1^@')
    ('r1^!')
    ('r1^-')
    ('r1^-1')
    ('r1%1..r2')
    (('aa' x 20) . '^-')
    ('HEAD^2^@')
    ('HEAD^-')
    ('HEAD^-2')
    ('B..C')
    ('B...C')
    ('B^-')
    ('B^..B')
    ('^B^1')
    ('C^@')
    ('C^1')
    ('B^@')
    ('B^1')
    ('B^2')
    ('B^3')
    ('C^!')
    ('^C^@')
    ('^C^!')
;

# Forms from git-rev-parse.  Treat these as revs for our purposes,
# since they pertain primarily to revs rather than to files.
$gitrevisions_good->load(LSKIP 4, '--all')->
    ('--branches')
    ('--branches=foo')
    ('--branches=foo?bar')
    ('--branches=foo*')
    ('--branches=foo[a-z]')
    ('--tags')
    ('--tags=foo')
    ('--tags=foo?bar')
    ('--tags=foo*')
    ('--tags=foo[a-z]')
    ('--remotes')
    ('--remotes=foo')
    ('--remotes=foo?bar')
    ('--remotes=foo*')
    ('--remotes=foo[a-z]')
    ('--glob=foo')
    ('--glob=foo?bar')
    ('--glob=foo*')
    ('--glob=foo[a-z]')
    ('--exclude=foo')
    ('--exclude=foo?bar')
    ('--exclude=foo*')
    ('--exclude=foo[a-z]')
    ('--disambiguate=1234')
    ('--disambiguate=cdef')
    ('--disambiguate=029a')
    ('--since=2001-01-01')
    ('--after=2001-01-01')
    ('--until=2001-01-01')
    ('--before=2001-01-01')
    ('--since=5 minutes ago')
    ('--after=5 minutes ago')
    ('--until=5 minutes ago')
    ('--before=5 minutes ago')
;

# Bad forms from git-revisions
my $gitrevisions_bad = List::AutoNumbered->new(__LINE__);
$gitrevisions_bad->load(':/!oops')->    #invalid char after !
    ('HEAD^, v1.5.1^0')     # Multiple revs - comma not valid here
    ('HEAD~, master~3')     # ditto
    #('HEAD^@^2')   # This is a git semantic error - should the parser care?
;

# Bad forms from git-rev-parse
$gitrevisions_bad->load(LSKIP 4, '--disambiguate')->
    ('--disambiguate')          # no arg
    ('--disambiguate=x')        # Not a hex digit
    ('--disambiguate=12f')      # <4 hex digits
    ('--since')                 # no arg
    ('--until')                 # no arg
    ('--after')                 # no arg
    ('--before')                # no arg
;

# Other bad forms
$gitrevisions_bad->load(LSKIP 3, '')->
    ('~')
    ('foo bar')
    ('?')   # These seem to be bad, but I'm not 100% sure
    ('*')
    ('[')
    ('foo//bar')    # non-normalize => bad
    ('foo\\bar')    # backslash => bad
    ('.')           # Prohibit because ambigious in our use case
;


foreach(@{$gitrevisions_good->arr}) {
    ok($r->($$_[1]), "line $$_[0]: -$$_[1]-");
}

foreach(@{$gitrevisions_bad->arr}) {
    ok(!$r->($$_[1]), "line $$_[0]: -$$_[1]-");
}

# Ones to test manually to suppress odd output
ok(!$r->(undef), "undef");
ok(!$r->("\003"), '^C');
ok(!$r->("\177"), '^?');

done_testing();
