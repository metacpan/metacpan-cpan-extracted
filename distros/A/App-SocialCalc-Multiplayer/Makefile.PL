use 5.008001;
use strict;
use FindBin '$Bin';
use inc::Module::Install;

if (-e "$Bin/../socialcalc.css" and -d "$Bin/../cpan" and $Bin =~ /cpan$/) {
    mkdir 'socialcalc' unless -d 'socialcalc';
    system("rsync -av --delete --exclude cpan ../* socialcalc");
}

name            'App-SocialCalc-Multiplayer';
author          '唐鳳 <cpan@audreyt.org>';
license         'CPAL';
repository      'http://github.com/audreyt/socialcalc';
all_from        'Multiplayer.pm';
readme_from     'Multiplayer.pm';
requires        'Fliggy';
requires        'File::ShareDir';

# These are requirements to PocketIO.pm
requires        'Protocol::WebSocket';
requires        'JSON';
requires        'Try::Tiny';

install_share   'socialcalc';
install_script  'socialcalc-multiplayer.pl';

WriteAll;

1;
