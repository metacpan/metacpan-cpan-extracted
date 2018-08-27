#!perl -w
# $Id: /src/B-Keywords/trunk/Makefile.PL 189 2006-08-17T14:36:23.798783Z josh  $

use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'          => 'B::Keywords',
  'VERSION_FROM'  => 'lib/B/Keywords.pm',
  'ABSTRACT_FROM' => 'lib/B/Keywords.pm',
  'AUTHOR'        => 'Joshua ben Jore <jjore@cpan.org>',
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
