use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

ok(1);

# XXX
#~ my $config_template = $validator->make_config_template(verbose => 1);
#~
#~ ok (exists $config_template->{GENERAL}, 'section "GENERAL" exists');
#~ ok (exists $config_template->{GENERAL}->{logfile}, '"logfile" exists');
#~ ok ($config_template->{GENERAL}->{logfile} = 'absolute path to logfile (?-xism:/.*)', 'logifle has correct content');
#~
#~ my $config_template = $validator->make_config_template(entry_point => $schema->{GENERAL}->{members}->{silos});
#~ ok (exists $config_template->{'silo-.+'}, 'entry point "silos" found');
#~ ok ($config_template->{'silo-.+'}->{url} eq 'url of the silo server. Only https:// allowed(?^:https.*)',
#~     'url has correct content');
#~

done_testing;
