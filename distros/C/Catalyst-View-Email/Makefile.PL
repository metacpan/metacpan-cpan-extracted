use inc::Module::Install 0.91;
test_requires 'Test::Requires';

name 'Catalyst-View-Email';
all_from 'lib/Catalyst/View/Email.pm';
author 'J. Shirley <jshirley@gmail.com>';
license 'perl';
version_from 'lib/Catalyst/View/Email.pm';
test_requires 'Test::More';

requires 'MIME::Base64'          => '3.08';
requires 'Authen::SASL'          => '2.13';
requires 'Catalyst'              => '5.7';
requires 'Moose'                 => '0.93';
requires 'parent'                => '0.223';
requires 'Email::Sender::Simple' => '0.100110';
requires 'Email::MIME'           => '1.859';
requires 'Email::MIME::Creator'  => '1.455';
requires 'Test::More'            => '0.88';
requires 'Module::Runtime'       => '0.014';
#requires 'Catalyst::View::TT'    => '0.31';
#requires 'Catalyst::View::Mason' => '0.18';

# Rebuild README for maintainers
if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/View/Email.pm > README");
}

realclean_files 'README';

resources 'IRC'     => 'irc://irc.perl.org/#catalyst';
resources 'license' => 'http://dev.perl.org/licenses/';
resources 'repository' =>
  'http://github.com/dhoss/catalyst-view-email';
resources 'Mailing_list' =>
  'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst';
resources 'bugtracker' => 
  'https://github.com/dhoss/catalyst-view-email/issues';

auto_provides;
auto_install;
WriteAll;
