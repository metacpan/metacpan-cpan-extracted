perlapp --bind manifests/base.xml[file=share\manifests\base.xml,text,mode=666]^
 --bind manifests/all.xml[file=share\manifests\all.xml,text,mode=666]^
 --bind plugins/retrieve.plugins.pm[file=share\plugins\retrieve.plugins.pm,text,mode=777]^
 --add MooX::Options::Role^
 --add App::SFDC::Role::Credentials^
 --lib lib --norunlib --force --exe SFDC.exe script/SFDC.pl
