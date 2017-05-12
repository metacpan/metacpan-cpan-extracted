use inc::Module::Install;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/Upload/Audio/File.pm > README' );
}

# Define metadata
name                'Catalyst-Plugin-Upload-Audio-File';
all_from            'lib/Catalyst/Plugin/Upload/Audio/File.pm';

# Specific dependencies
requires 'Catalyst';
requires 'Audio::File';

WriteAll;
