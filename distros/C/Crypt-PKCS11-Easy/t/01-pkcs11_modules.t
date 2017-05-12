use lib 't/lib';
use Path::Tiny;
use Test::Roo;
use Test::Fatal;

with 'CommonTest';

test module_dirs => sub {
    my $self = shift;

    my $mod = 'Crypt::PKCS11::Easy';
    require_ok $mod;

    like(
        exception {
            $mod->new(module => 'nosuchmodule', module_dirs => 'test')
        },
        qr/did not pass type constraint "ArrayRef"/,
        'module_dirs must be an arrayref',
    );

    like(
        exception {
            $mod->new(module => 'nosuchmodule', module_dirs => ['test'])
        },
        qr/No valid module paths found/,
        'No valid module dirs were passed',
    );

    # this is an empty file, so can never be loaded
    like(
        exception {
            $mod->new(
                module      => 'fakemodule',
                module_dirs => ['test', 't/lib'])
        },
        qr/^Failed to load PKCS11 module \[.+\/t\/lib\/fakemodule.so\]: CKR_FUNCTION_FAILED/,
        'Attempted to load module from full path',
    );
};

test module => sub {
    my $self = shift;

    my $mod = 'Crypt::PKCS11::Easy';
    require_ok $mod;

    like(
        exception { $mod->new },
        qr/Missing required arguments: module/,
        'Died without module',
    );

    # this is an empty file, so can never be loaded
    like(
        exception { $mod->new(module => 't/lib/fakemodule.so') },
        qr/^Failed to load PKCS11 module \[.+\/t\/lib\/fakemodule.so\]: CKR_FUNCTION_FAILED/,
        'Attempted to load module from full path',
    );

    like(
        exception {
            Crypt::PKCS11::Easy->new(
                module      => 'nosuchmodule',
                module_dirs => ['/tmp'])
        },
        qr/Unable to find .+nosuchmodule/,
        'Died with an invalid module',
    );

  SKIP: {
        skip 'softhsm2 is not available', 1 unless $self->has_softhsm2;

        # this will load but fail to initialize without valid config
        local $ENV{SOFTHSM2_CONF} = undef;
        like(
            exception { $mod->new(module => 'libsofthsm2') },
            qr/^Failed to initialize PKCS11 module \[.+libsofthsm2.so\]: CKR_GENERAL_ERROR/,
            'Attempted to load a module from name only',
        );
    }
};

run_me;
done_testing;
