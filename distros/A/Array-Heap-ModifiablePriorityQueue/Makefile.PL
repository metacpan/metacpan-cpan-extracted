use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Array::Heap::ModifiablePriorityQueue',
    VERSION_FROM => 'lib/Array/Heap/ModifiablePriorityQueue.pm', # finds \$VERSION
    AUTHOR       => 'Bob Mathews (bobmathews@alumni.calpoly.edu)',
    ABSTRACT     => 'Modifiable priority queue using Array::Heap',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Array::Heap' => 3.0,
                    },
    (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl_5') : ()),
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/bobmath/ModifiablePriorityQueue.git',
                 web  => 'https://github.com/bobmath/ModifiablePriorityQueue',
             },
         }}) : ()),
);
