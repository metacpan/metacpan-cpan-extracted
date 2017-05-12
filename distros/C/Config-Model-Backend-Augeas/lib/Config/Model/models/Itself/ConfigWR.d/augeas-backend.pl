[
    [
        name => "Itself::ConfigWR",

        'element' => [

            'backend' => {
                choice       => [qw/Augeas/],
                help => {
                    augeas => "Experimental backend with RedHat's Augeas library. See http://augeas.net for details",
                }
            },

            'save' => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/backup newfile/],
                level      => 'hidden',
                description =>
'Specify how to save the configuration file. Either create a newfile (with extension .augnew, and do not overwrite the original file) or move the original file into a backup file (.augsave extension). Configuration files are overwritten by default',
                warp => {
                    follow => '- backend',
                    rules  => [ Augeas => { level => 'normal', } ],
                }
            },

            'set_in' => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- - element',
                level      => 'hidden',
                description =>
'Sometimes, the structure of a file loaded by Augeas starts directly with a list of items. For instance, /etc/hosts structure starts with a list of lines that specify hosts and IP addresses. This parameter specifies an element name in Config::Model root class that will hold the configuration data retrieved by Augeas',
                warp => {
                    follow => '- backend',
                    rules  => [ Augeas => { level => 'normal', } ],
                }
            },
            'sequential_lens' => {
                type  => 'list',
                level => 'hidden',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                },
                warp => {
                    follow => { b                => '- backend' },
                    rules  => [ '$b eq "Augeas"' => { level => 'normal', } ],
                },
                description =>
'List of hash or list Augeas lenses where value are stored in sequential Augeas nodes. See Config::Model::Backend::Augeas for details.',
            },
        ],

    ],

];
