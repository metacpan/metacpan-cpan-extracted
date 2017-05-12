package MyPlugin::XMLSupport;
{
    sub new {
        return bless { }, shift;
    }

    sub requires {
        return 'XML::Parser';
    }
}

1;
