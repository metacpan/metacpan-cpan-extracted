#	$Id: 03-error.t 51 2014-05-21 19:14:11Z adam $
use strict;
use Test;

BEGIN { plan tests => 58 };

use Config::Trivial;
ok(1);

#
#	Basic Constructor
#
my $config = Config::Trivial->new;
my @array=();
my %hash = (file => "./t/file.that.is.not.there");

# Try and write to self (2-3)
ok(! $config->write );
ok($config->get_error(), "Not allowed to write to the calling file.");

# Missing file (4-7)
ok(! $config->set_config_file("./t/file.that.is.not.there")); 
ok($config->get_error(), "File error: Cannot find ./t/file.that.is.not.there");

ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: Cannot find ./t/file.that.is.not.there");

# Not a file (8-11)
ok(! $config->set_config_file("./t"));
ok($config->get_error(), "File error: ./t isn't a real file");

%hash = (file => "./t");
ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: ./t isn't a real file");

# Empty filename (12-19)
ok(! $config->set_config_file(''));
ok($config->get_error(), "File error: No file name supplied");
ok(! $config->set_config_file(undef));
ok($config->get_error(), "File error: No file name supplied");
ok(! $config->write(config_file => undef));
ok($config->get_error(), "Not allowed to write to the calling file.");
$config->{_config_file} = '';
eval { $config->write(config_file => undef) };
ok($@ =~ 'File error: No file name supplied');
$config->{_config_file} = $0;

%hash = (file => undef);
ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: No file name supplied");

# Empty file (20-23)
ok(! $config->set_config_file("./t/empty"));
ok($config->get_error(), "File error: ./t/empty is zero bytes long");

%hash = (file => "./t/empty");
ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: ./t/empty is zero bytes long");

# write to self (24-25)
$config->set_config_file($0);
ok(! $config->write );
ok($config->get_error(), "Not allowed to write to the calling file.");

# duped keys, normal mode (22-24)
ok($config->set_config_file("./t/bad.data"));
ok(my $settings = $config->read());
ok($settings->{test1}, "bar");

# setting not a hash_ref (25-26)
ok(! $config->set_configuration("foo"));
ok($config->get_error(), 'Configuration not a reference');

ok(! $config->set_configuration());
ok($config->get_error(), "No configuration data");

ok(! $config->set_configuration(\@array));
ok($config->get_error(), "Configuration data isn't a hash reference");

# Try and multi_read a single file (27-28)
ok($config->set_config_file("./t/test.data"));
eval { $config->multi_read };
ok($@ =~ "ERROR: Multi_Read is for multiple configuration files");

$settings = undef;

# Try a bad file in the constructor (29-30)
eval { $config = Config::Trivial->new(config_file => "foo") };
ok($@ =~ "Unable to read config file foo");

$config = Config::Trivial->new(strict => "on");

# Try and write to self (31)
eval { $config->write };
ok($@ =~ "Not allowed to write to the calling file.");

# duped keys, strict mode (32-34)
ok($config->set_config_file("./t/bad.data"));
eval { $settings = $config->read(); };
ok(! defined($settings->{test1}));
ok($@ =~ 'ERROR: Duplicate key "test1" found in config file on line 5');

# Missing File, Strict mode (35-36)
eval { $config->set_config_file("./t/file.that.is.not.there"); };
ok($@ =~ "File error: Cannot find ./t/file.that.is.not.there");

%hash = (config => "./t/file.that.is.not.there");
eval { $config->set_config_file(\%hash); };
ok($@ =~ "File error: Cannot find ./t/file.that.is.not.there");

# Wrong ref types   (37-38)
eval { $config->set_config_file(\@array); };
ok($@ =~ "ERROR: Can only deal with a hash references");

eval { $config->set_configuration(\@array); };
ok($@ =~ "Configuration data isn't a hash reference");

# Try and read a multi file in a standard read (38-39)
%hash = (config => "./t/test.data");
ok($config->set_config_file(\%hash));
eval { $config->read };
ok($@ =~ "ERROR: Read can only deal with a single file");

# Empty file, Strict mode (40-41)
eval { $config->set_config_file("./t/empty"); };
ok($@ =~ "File error: ./t/empty is zero bytes long");

%hash = (config => "./t/empty");
eval { $config->set_config_file(\%hash); };
ok($@ =~ "File error: ./t/empty is zero bytes long");

# write to self, Strict mode (42)
$config->set_config_file($0);
eval { $config->write };
ok($@ =~ "Not allowed to write to the calling file.");

# setting not a hash_ref, Strict mode (43-45)
eval { $config->set_configuration("foo"); };
ok($@ =~ "Configuration not a reference");
eval { $config->set_configuration(\@array); };
ok($@ =~ "Configuration data isn't a hash reference");

#   Bad data
$settings = {'bad key' => "data"};
eval { $config->write(
    config_file => "./t/badly_formed.data",
    configuration => $settings)
};
ok($@ =~ 'ERROR: Setting key "bad key" contains an illegal space');
ok(-e "./t/badly_formed.data");
ok(unlink("./t/badly_formed.data"),1);

# No settings to write
my $second = -s './t/second.data';
$config =  Config::Trivial->new();
$config->{_configuration} = undef;
eval { $config->write(
    config_file => "./t/second.data",
    configuration => undef)
};
ok($@ =~ 'ERROR: No settings hash to write.');
ok(-s './t/second.data', $second);

exit;

__END__
