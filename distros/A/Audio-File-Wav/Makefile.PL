use inc::Module::Install;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Audio/File/Wav.pm > README' );
}

# Define metadata
name                'Audio-File-Wav';
all_from            'lib/Audio/File/Wav.pm';

# Specific dependencies
requires 'Audio::File';
requires 'Audio::Wav';

WriteAll;
