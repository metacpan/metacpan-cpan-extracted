use ExtUtils::MakeMaker;
require 5.006;

WriteMakefile
  (
   NAME	           => "B::Debug",
   VERSION_FROM    => "Debug.pm",
   PREREQ_PM => {'B'          => 0,
                 'Test::More' => 0},
   ($] >= 5.005 ?
    ('AUTHOR' => 'Malcolm Beattie <mbeattie@sable.ox.ac.uk>, Reini Urban <rurban@cpan.org>',
     'ABSTRACT' => 'print debug info about ops') : ()),
   ($ExtUtils::MakeMaker::VERSION gt '6.30' ?
    ('LICENSE'                => 'perl', ) : ()),
   (($ExtUtils::MakeMaker::VERSION gt '6.31' and $ExtUtils::MakeMaker::VERSION lt '6.46') ?
    ('EXTRA_META'  => "recommends:\n" .
     "    B::Flags:                      0.04\n"
    ) : ()),
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  => {"recommends" => {
                       "B::Flags" => "0.04"}}
    ) : ()),
   # Part of core perl since 5.005005, but core wants it to be in site since 5.12
   'INSTALLDIRS' => ( $] > 5.005005 && $] < 5.011 ? "perl" : "site" ),
   # install into ARCHLIB
   ($] < 5.011) ? (PM => {
       'Debug.pm' => '$(INST_ARCHLIB)/B/Debug.pm',
   }) : (),
   SIGN => 1,
  );
