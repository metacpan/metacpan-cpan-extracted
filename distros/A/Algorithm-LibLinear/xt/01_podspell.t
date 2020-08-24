use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Koichi SATO
L1
L2
LIBLINEAR
LIBSVM
MERCHANTABILITY
NONINFRINGEMENT
Redistributions
SVC
SVM
SVR
fh
misclassification
multiclass
sublicense
