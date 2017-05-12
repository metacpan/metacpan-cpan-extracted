use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::TraitFor::Component::ConfigPerSite',
    VERSION_FROM      => 'lib/Catalyst/TraitFor/Component/ConfigPerSite.pm', # finds $VERSION
    PREREQ_PM         => {
			  Catalyst => 0,
	                  Catalyst::Action::RenderView => 0,
			  Catalyst::Plugin::Static::Simple => 0,
			  Catalyst::Plugin::ConfigLoader => 0,
			  Catalyst::View::TT => 0,
			  Catalyst::Model::DBIC::Schema => 0,
			  Moose => 0,
			  Test::Pod => 0,
			  Test::Pod::Coverage => 0,
			  Test::HTML::Form => 0,
			  Config::General => 0,
        		  DBIx::Class::TimeStamp => '0',
			  DateTime => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Aaron Trevena <teejay@cpan.org>') : ()),
    META_MERGE => {
     resources => {
       repository => 'https://github.com/hashbangperl/Catalyst-TraitFor-Component-ConfigPerSite',
    },
   },
   ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),

);
