use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
hiratara
hiratara {at} cpan.org
Data::Monad
api
fmap
condvar
condvars
cvs
monad
monads
monadic
monadplus
kleisli
haskell
morphism
dsl
