use strict;
use warnings;
use Test::More;
use t::Util;
use File::Temp qw(tempdir);

use App::envfile;

sub test_requires {
    my $module = shift;
    plan skip_all => "Test requires module '$module' but it's not found"
        unless eval "require $module; 1";
}

my $tmdir = tempdir CLEANUP => 1;
sub write_file {
    my ($filename, $data) = @_;
    my $envfile = "$tmdir/$filename";
    open my $fh, '>', "$envfile" or die $!;
    print $fh $data;
    close $fh;
    return $envfile;
}

my $envf = App::envfile->new;

runtest 'no extension file' => sub {
    my $envfile = write_file('foo', '');
    my $env = $envf->_try_any_config_file($envfile);
    ok !$env;
};

runtest 'not supported extension' => sub {
    my $envfile = write_file('foo.env', '');
    my $env = $envf->_try_any_config_file($envfile);
    ok !$env;
};

runtest 'success (pl)' => sub {
    my $envfile = write_file('foo.pl', '{ foo => "bar" }');
    my $env = $envf->_try_any_config_file($envfile);
    is_deeply $env, { foo => 'bar' };
};

runtest 'success (perl)' => sub {
    my $envfile = write_file('foo.perl', '{ foo => "bar" }');
    my $env = $envf->_try_any_config_file($envfile);
    is_deeply $env, { foo => 'bar' };
};

runtest 'do not returned hashref (pl)' => sub {
    my $envfile = write_file('foo.pl', '[]');
    eval { $envf->_try_any_config_file($envfile) };
    like $@, qr/Should be return HASHREF/;
};

runtest 'file not found (pl)' => sub {
    eval { $envf->_try_any_config_file('foooooooooooooooo.pl') };
    ok $@;
};

runtest 'syntax error (pl)' => sub {
    my $envfile = write_file('foo.pl', '{ foo => "bar"} }');
    eval { $envf->_try_any_config_file($envfile) };
    ok $@;
};

subtest json => sub {
    test_requires('Data::Encoder');
    test_requires('JSON');

    runtest 'success (js)' => sub {
        my $envfile = write_file('foo.js', '{"foo":"bar"}');
        my $env = $envf->_try_any_config_file($envfile);
        is_deeply $env, { foo => 'bar' };
    };

    runtest 'success (json)' => sub {
        my $envfile = write_file('foo.json', '{"foo":"bar"}');
        my $env = $envf->_try_any_config_file($envfile);
        is_deeply $env, { foo => 'bar' };
    };

    runtest 'do not returned hashref (js)' => sub {
        my $envfile = write_file('foo.js', '[]');
        eval { $envf->_try_any_config_file($envfile) };
        like $@, qr/Should be return HASHREF/;
    };

    runtest 'file not found (js)' => sub {
        eval { $envf->_try_any_config_file('foooooooooooooooo.js') };
        ok $@;
    };

    runtest 'syntax error (js)' => sub {
        my $envfile = write_file('foo.js', '{"foo":"bar"} }');
        eval { $envf->_try_any_config_file($envfile) };
        ok $@;
    };
};

subtest yaml => sub {
    test_requires('Data::Encoder');
    test_requires('YAML');

    runtest 'success (yml)' => sub {
        my $envfile = write_file('foo.yml', <<YAML);
foo: bar
YAML
        my $env = $envf->_try_any_config_file($envfile);
        is_deeply $env, { foo => 'bar' };
    };

    runtest 'success (yaml)' => sub {
        my $envfile = write_file('foo.yaml', <<YAML);
foo: bar
YAML
        my $env = $envf->_try_any_config_file($envfile);
        is_deeply $env, { foo => 'bar' };
    };

    runtest 'do not returned hashref (yml)' => sub {
        my $envfile = write_file('foo.yml', <<YAML);
- foo
- bar
YAML
        eval { $envf->_try_any_config_file($envfile) };
        like $@, qr/Should be return HASHREF/;
    };

    runtest 'file not found (yml)' => sub {
        eval { $envf->_try_any_config_file('foooooooooooooooo.yml') };
        ok $@;
    };

    runtest 'syntax error (yml)' => sub {
        my $envfile = write_file('foo.yml', '{"foo":"bar"} }');
        eval { $envf->_try_any_config_file($envfile) };
        ok $@;
    };
};

done_testing;
