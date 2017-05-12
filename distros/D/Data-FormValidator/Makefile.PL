use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Data::FormValidator',
  VERSION_FROM  => 'lib/Data/FormValidator.pm',
  ABSTRACT_FROM => 'lib/Data/FormValidator.pm',
  AUTHOR        => 'David Farrell <dfarrell@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM     => {
    # In 5.6, t/upload* was failing.
    # rjbs says "It relies on CGI relying on 5.008 glob stringification behavior"
    'perl'            => '5.008',
    'Image::Size'     => 0,
    'Test::More'      => 0,
    'Date::Calc'      => 5.0,
    'File::MMagic'    => 1.17,
    'MIME::Types'     => 1.005,
    'Regexp::Common'  => 0.03, # when ::whitespace was added
    'Scalar::Util'    => 0,
    'Email::Valid'    => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url  => 'https://github.com/dnmfarrell/Data-FormValidator',
          web  => 'https://github.com/dnmfarrell/Data-FormValidator',
        },
      },
      # this is a cuckoo package in Data::FormValidator::Results
      no_index => {
        package => ['Data::FormValidator::Constraints::RegexpCommon'],
      }})
   : ()
  ),
);
