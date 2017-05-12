package App::cpanmigrate::bash;
use strict;
use warnings;

sub script {
    my ($class, $version) = @_;

    return <<"EOS";
echo "@@@@@ Start migration to $version"; sleep 1;

echo "@@@@@ Installing ExtUtils::Installed"; sleep 1;
cpanm ExtUtils::Installed;

echo "@@@@@ Extracting all modules"; sleep 1;
if [[ -e /tmp/modules.list ]]; then rm /tmp/modules.list; fi;
perl -MExtUtils::Installed -E 'say for ExtUtils::Installed->new->modules' > /tmp/modules.list;

echo "@@@@@ Upgrading perlbrew"; sleep 1;
curl -L http://xrl.us/perlbrewinstall | bash;
source ~/perl5/perlbrew/etc/bashrc;

echo "@@@@@ Installing $version"; sleep 1;
perlbrew install "$version" -v &&

echo "@@@@@ Switching new environment"; sleep 1;
perlbrew switch "$version" &&

echo "@@@@@ Installing cpanminus for new environment"; sleep 1;
perlbrew install-cpanm &&

echo "@@@@@ Installing all modules into new environment"; sleep 1;
cpanm < /tmp/modules.list;

echo "@@@@@ Re-running cpanminus to check everything is OK"; sleep 1;
cpanm < /tmp/modules.list;

echo "@@@@@ Done migration!";
perl -V;
EOS
}

1;
__END__
