#   $Id: 03-error.t 57 2014-05-19 19:17:51Z adam $
use strict;
use Test;
use Storable qw(lock_store);

BEGIN { plan tests => 89 };

use Config::Trivial::Storable;
ok(1);

# Prep some empty data
my $duff ='';
my $file = './t/empty.store';
ok(lock_store \$duff, $file);
ok(-e $file);

#
#   Basic Constructor
#
my $config = Config::Trivial::Storable->new();
my @array=();
my %hash = ( file => './t/file.that.is.not.there' );

# Try and write to self (4-7)
ok(! $config->write );
ok($config->get_error(), "Not allowed to write to the calling file.");
ok(! $config->store );
ok($config->get_error(), "Not allowed to store to the calling file.");

# Missing file (8-11)
ok(! $config->set_config_file("./t/file.that.is.not.there"));
ok($config->get_error(), "File error: Cannot find ./t/file.that.is.not.there");

ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: Cannot find ./t/file.that.is.not.there");

# Not a file (12-15)
ok(! $config->set_config_file("./t"));
ok($config->get_error(), "File error: ./t isn't a real file");

%hash = (file => "./t");
ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: ./t isn't a real file");

# Empty filename (16-26)
ok(! $config->set_config_file(''));
ok($config->get_error(), "File error: No file name supplied");
ok(! $config->set_config_file(undef));
ok($config->get_error(), "File error: No file name supplied");
ok(! $config->write(config_file => undef));
ok($config->get_error(), "Not allowed to write to the calling file.");
ok(! $config->store(config_file => undef));
ok($config->get_error(), "Not allowed to store to the calling file.");
$config->{_config_file} = '';
eval { $config->write(config_file => undef) };
ok($@ =~ 'File error: No file name supplied');
$config->{_config_file} = $0;

%hash = (file => undef);
ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: No file name supplied");

# Empty file (27-30)
ok(! $config->set_config_file("./t/empty"));
ok($config->get_error(), "File error: ./t/empty is zero bytes long");

%hash = (file => "./t/empty");
ok(! $config->set_config_file(\%hash));
ok($config->get_error(), "File error: ./t/empty is zero bytes long");

# write to self (31-34)
$config->set_config_file($0);
ok(! $config->write );
ok($config->get_error(), "Not allowed to write to the calling file.");
ok(! $config->store );
ok($config->get_error(), "Not allowed to store to the calling file.");

# duped keys, normal mode (25-37)
ok($config->set_config_file("./t/bad.data"));
ok(my $settings = $config->read());
ok($settings->{test1}, "bar");

# setting not a hash_ref (38-43)
ok(! $config->set_configuration("foo"));
ok($config->get_error(), 'Configuration not a reference');

ok(! $config->set_configuration());
ok($config->get_error(), "No configuration data");

ok(! $config->set_configuration(\@array));
ok($config->get_error(), "Configuration data isn't a hash reference");

# Try and multi_read a single file (44-25)
ok($config->set_config_file("./t/test.data"));
eval { $config->multi_read };
ok($@ =~ "ERROR: Multi_Read is for multiple configuration files");

$settings = undef;

# Try a bad file in the constructor (46)
eval { $config = Config::Trivial::Storable->new(config_file => "foo") };
ok($@ =~ "Unable to read config file foo");

$config = Config::Trivial::Storable->new(strict => "on");

# Try and write to self (47)
eval { $config->write };
ok($@ =~ "Not allowed to write to the calling file.");

# duped keys, strict mode (48-50)
ok($config->set_config_file("./t/bad.data"));
eval { $settings = $config->read(); };
ok(! defined($settings->{test1}));
ok($@ =~ 'ERROR: Duplicate key "test1" found in config file on line 5');

# Missing File, Strict mode (51-52)
eval { $config->set_config_file("./t/file.that.is.not.there"); };
ok($@ =~ "File error: Cannot find ./t/file.that.is.not.there");

%hash = (config => "./t/file.that.is.not.there");
eval { $config->set_config_file(\%hash); };
ok($@ =~ "File error: Cannot find ./t/file.that.is.not.there");

# Wrong ref types   (53-54)
eval { $config->set_config_file(\@array); };
ok($@ =~ "ERROR: Can only deal with a hash references");

eval { $config->set_configuration(\@array); };
ok($@ =~ "Configuration data isn't a hash reference");

# Try and read a multi file in a standard read (55-56)
%hash = (config => "./t/test.data");
ok($config->set_config_file(\%hash));
eval { $config->read };
ok($@ =~ "ERROR: Read can only deal with a single file");

# Empty file, Strict mode (57-58)
eval { $config->set_config_file("./t/empty"); };
ok($@ =~ "File error: ./t/empty is zero bytes long");

%hash = (config => "./t/empty");
eval { $config->set_config_file(\%hash); };
ok($@ =~ "File error: ./t/empty is zero bytes long");

# write to self, Strict mode (59-61)
$config->set_config_file($0);
eval { $config->write };
ok($@ =~ "Not allowed to write to the calling file.");
eval { $config->store };
ok($@ =~ "Not allowed to store to the calling file.");

eval { $config->retrieve };
ok($@ =~ "Can't retrieve store from the calling file.");

# setting not a hash_ref, Strict mode (62-63)
eval { $config->set_configuration("foo"); };
ok($@ =~ "Configuration not a reference");
eval { $config->set_configuration(\@array); };
ok($@ =~ "Configuration data isn't a hash reference");

# Try and read the wrong kind of files (64)
$config->set_config_file("./t/test.data");
eval { $config->retrieve };
ok($@ =~ "ERROR: File is not a perl storable");

#   Bad data (65-67)
$settings = {'bad key' => "data"};
eval { $config->write(
    config_file => "./t/badly_formed.data",
    configuration => $settings)
};
ok($@ =~ 'ERROR: Setting key "bad key" contains an illegal space');
ok(-e "./t/badly_formed.data");
ok(unlink("./t/badly_formed.data"),1);

# No settings to write (68-69)
my $second = -s './t/second.data';
$config =  Config::Trivial::Storable->new();
$config->{_configuration} = undef;
eval { $config->write(
    config_file => "./t/second.data",
    configuration => undef)
};
ok($@ =~ 'ERROR: No settings hash to write.');
ok(-s './t/second.data', $second);


# 70-73
$config =  Config::Trivial::Storable->new();
ok ($config->read);
my $error = $config->get_error();
if ( $] > 5.019 ) {
	ok ( ! $error );
}
else {
	ok ($error =~ 'File error: Cannot find \(eval');
}
ok (! $config->retrieve);
ok ($config->get_error() =~ "Can't retrieve store from the calling file.");

$config->{_storable_file} = '';
$config->{_self} = '';
$config->{_config_file} = '';
ok (! $config->retrieve);
ok ($config->get_error() =~ 'File error: No file name supplied');

$config->{_storable_file} = '';
$config->{_self} = '1';
$config->{_config_file} = '';
ok (! $config->retrieve);
ok ($config->get_error() =~ 'File error: No file name supplied');

print STDERR "\nWarnings on console expected...\n";
$config->{_storable_file} = '';
$config->{_self} = '1';
delete $config->{_config_file};
ok (! $config->retrieve);
ok ($config->get_error() =~ 'File error: No file name supplied');

$config =  Config::Trivial::Storable->new();
$config->set_storable_file($file);
ok (! $config->retrieve('foo'));
ok ($config->get_error(), "Retrieved object isn't a HASH reference.");

$config =  Config::Trivial::Storable->new();
$config->{_configuration} = '';
ok (! $config->store(config_file => './t/duff-file.store'));
ok ($config->get_error(), "Configuration object isn't a HASH reference.");
ok (! -e './t/duff-file.store');

$config->{_configuration} = 'foo';
ok (! $config->store(config_file => './t/duff-file.store'));
ok ($config->get_error(), "Configuration object isn't a HASH reference.");
ok (! -e './t/duff-file.store');



# Clean up 74-75
ok(unlink($file, 1));
ok(! -e $file);

exit;

__END__
