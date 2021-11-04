#!perl -w

use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'          => 'B::Keywords',
  'VERSION_FROM'  => 'lib/B/Keywords.pm',
  'ABSTRACT_FROM' => 'lib/B/Keywords.pm',
  'AUTHOR'        => 'Reini Urban <rurban@cpan.org>',
  'SIGN'          => 1,
  'PREREQ_PM'	  =>
   {
     'B'                  => 0,
   },
  depend            => { 'README'   => 'lib/B/Keywords.pm' },
  ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
   ('META_MERGE'  =>
    {
      resources =>
      {
        repository  => 'http://github.com/rurban/b-keywords',
        license     => 'http://dev.perl.org/licenses/',
        bugtracker  => {
            web    => 'https://github.com/rurban/b-keywords/issues',
        },
      },
    }
   ) : ()),
  );

package MY;
use Config;

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

release : dist
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags
"
}
