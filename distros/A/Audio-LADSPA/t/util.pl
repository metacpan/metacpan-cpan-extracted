sub sdk_installed {
    grep { $_ eq "Audio::LADSPA::Library::delay" } Audio::LADSPA->libraries();
}

1;

