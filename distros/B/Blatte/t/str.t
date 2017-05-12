use lib './t';
use BlatteTestHarness;

&blatte_test(['ABC', '{\\uc abc}'],
             ['abc', '{\\lc ABC}'],
             ['bc', '{\\substr abcde 1 2}'],
             ['bc', '{\\substr abcde -4 2}'],
             ['yes', '{\\if {\\streq a a} yes no}'],
             ['no', '{\\if {\\streq a b} yes no}']);
