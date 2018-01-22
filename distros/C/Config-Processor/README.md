# NAME

Config::Processor - Cascading configuration files processor with additional
features

# SYNOPSIS

    use Config::Processor;

    my $config_processor = Config::Processor->new(
      dirs => [qw( /etc/myapp /home/username/etc/myapp )]
    );

    my $config = $config_processor->load(qw( dirs.yml db.json metrics/* ));

    $config = $config_processor->load(
      qw( dirs.yml db.json redis.yml mongodb.json metrics/* ),

      { myapp => {
          db => {
            connectors => {
              stat_master => {
                host => 'localhost',
                port => '4321',
              },
            },
          },
        },
      },
    );

# DESCRIPTION

Config::Processor is the cascading configuration files processor, which
supports file inclusions, variables interpolation and other manipulations with
configuration tree. Works with YAML and JSON file formats. File format is
determined by the extension. Supports following file extensions: `.yml`,
`.yaml`, `.jsn`, `.json`.

# CONSTRUCTOR

## new( %params )

    my $config_processor = Config::Processor->new(
      dirs       => [qw( /etc/myapp /home/username/etc/myapp )],
      export_env => 1,
    );

    $config_processor = Config::Processor->new;

    $config_processor = Config::Processor->new(
      dirs                  => [qw( /etc/myapp /home/username/etc/myapp )],
      interpolate_variables => 0,
      process_directives    => 0,
    );

- dirs => \\@dirs

    List of directories, in which configuration processor will search files. If
    the parameter not specified, current directory will be used.

- interpolate\_variables => $boolean

    Enables or disables variable interpolation in configurations files.
    Enabled by default.

- process\_directives => $boolean

    Enables or disables directive processing in configurations files.
    Enabled by default.

- export\_env => $boolean

    Enables or disables environment variables exporting to configuration tree.
    If enabled, environment variables can be accessed by the key `ENV` from the
    configuration tree and can be interpolated into other configuration parameters.

    Disabled by default.

# METHODS

## load( @config\_sections )

Attempts to load all configuration sections and returns reference to resulting
configuration tree.

Configuration section can be a relative filename, a filename with wildcard
characters or a hash reference. Filenames with wildcard characters is processed
by `CORE::glob` function and supports the same syntax.

    my $config = $config_processor->load( qw( myapp.yml extras/* ), \%hard_config );

## interpolate\_variables( \[ $boolean \] )

Enables or disables variable interpolation in configurations files.

## process\_directives( \[ $boolean \] )

Enables or disables directive processing in configuration files.

## export\_env( \[ $boolean \] )

Enables or disables environment variables exporting to configuration tree.

# MERGING RULES

Config::Processor merges all configuration sections in one resulting configuration tree by following rules:

    Left value  Right value  Result value

    SCALAR $a   SCALAR $b    SCALAR $b
    SCALAR $a   ARRAY  \@b   ARRAY  \@b
    SCALAR $a   HASH   \%b   HASH   \%b

    ARRAY \@a   SCALAR $b    SCALAR $b
    ARRAY \@a   ARRAY  \@b   ARRAY  \@b
    ARRAY \@a   HASH   \%b   HASH   \%b

    HASH \%a    SCALAR $b    SCALAR $b
    HASH \%a    ARRAY  \@b   ARRAY  \@b
    HASH \%a    HASH   \%b   HASH   recursive_merge( \%a, \%b )

For example, we have two configuration files. `db.yml` at the left side:

    db:
      connectors:
        stat_writer:
          host:     "stat.mydb.com"
          port:     "1234"
          dbname:   "stat"
          username: "stat_writer"
          password: "stat_writer_pass"

And `db_test.yml` at the right side:

    db:
      connectors:
        stat_writer:
          host:     "localhost"
          username: "test"
          password: "test_pass"

After merging of two files we will get:

    db => {
      connectors => {
        stat_writer => {
          host      => "localhost",
          port:     => "1234",
          dbname:   => "stat",
          username: => "test",
          password: => "test_pass",
        },
      },
    },

# INTERPOLATION

Config::Processor can interpolate variables in string values (if you need alias
for complex structures see `var` directive). Variable names can be absolute or
relative. Relative variable names begins with "." (dot). The number of dots
depends on the nesting level of the current configuration parameter relative to
referenced configuration parameter.

    myapp:
      media_formats: [ "images", "audio", "video" ]

      dirs:
        root_dir: "/myapp"
        templates_dir: "${myapp.dirs.root_dir}/templates"
        sessions_dir: "${.root_dir}/sessions"
        media_dirs:
          - "${..root_dir}/media/${myapp.media_formats.0}"
          - "${..root_dir}/media/${myapp.media_formats.1}"
          - "${..root_dir}/media/${myapp.media_formats.2}"

After processing of the file we will get:

    myapp => {
      media_formats => [ "images", "audio", "video" ],

      dirs => {
        root_dir      => "/myapp",
        templates_dir => "/myapp/templates",
        sessions_dir  => "/myapp/sessions",
        media_dirs    => [
          "/myapp/media/images",
          "/myapp/media/audio",
          "/myapp/media/video",
        ],
      },
    },

To escape variable interpolation add one more "$" symbol before variable.

    templates_dir: "$${myapp.dirs.root_dir}/templates"

After processing we will get:

    templates_dir => ${myapp.dirs.root_dir}/templates,

# DIRECTIVES

- var: varname

    Assigns configuration parameter value to another configuration parameter.
    Variable names in the directive can be absolute or relative. Relative variable
    names begins with "." (dot). The number of dots depends on the nesting level of
    the current configuration parameter relative to referenced configuration
    parameter.

        myapp:
          db:
            default_options:
              PrintWarn:  0
              PrintError: 0
              RaiseError: 1

            connectors:
              stat_master:
                host:     "stat-master.mydb.com"
                port:     "1234"
                dbname:   "stat"
                username: "stat_writer"
                password: "stat_writer_pass"
                options: { var: myapp.db.default_options }

              stat_slave:
                host:     "stat-slave.mydb.com"
                port:     "1234"
                dbname:   "stat"
                username: "stat_reader"
                password: "stat_reader_pass"
                options: { var: ...default_options }

- include: filename

    Loads configuration parameters from file or multiple files and assigns it to
    specified configuration parameter. Argument of `include` directive can be
    relative filename or a filename with wildcard characters. If loading multiple
    files, configuration parameters from them will be merged before assignment.

        myapp:
          db:
            generic_options:
              PrintWarn:  0
              PrintError: 0
              RaiseError: 1

            connectors: { include: db_connectors.yml }

          metrics: { include: metrics/* }

- underlay

    Merges specified configuration parameters with parameters located at the same
    context. Configuration parameters from the context overrides parameters from
    the directive. `underlay` directive most usefull in combination with `var`
    and `include` directives.

    For example, you can use this directive to set default values of parameters.

        myapp:
          db:
            connectors:
              default:
                port:   "1234"
                dbname: "stat"
                options:
                  PrintWarn:  0
                  PrintError: 0
                  RaiseError: 1

              stat_master:
                underlay: { var: .default }
                host:     "stat-master.mydb.com"
                username: "stat_writer"
                password: "stat_writer_pass"

              stat_slave:
                underlay: { var: .default }
                host:     "stat-slave.mydb.com"
                username: "stat_reader"
                password: "stat_reader_pass"

    You can move default parameters in separate files.

        myapp:
          db:
            connectors:
              underlay:
                - { include: db_connectors/default.yml }
                - { include: db_connectors/default_test.yml }

              stat_master:
                underlay: { var: .default }
                host:     "stat-master.mydb.com"
                username: "stat_writer"
                password: "stat_writer_pass"

              stat_slave:
                underlay: { var: .default }
                host:     "stat-slave.mydb.com"
                username: "stat_reader"
                password: "stat_reader_pass"

              test:
                underlay: { var: .default_test }
                username: "test"
                password: "test_pass"

- overlay

    Merges specified configuration parameters with parameters located at the same
    context. Configuration parameters from the directive overrides parameters from
    the context. `overlay` directive most usefull in combination with `var` and
    `include` directives.

    For example, you can use `overlay` directive to temporaly overriding regular
    configuration parameters.

        myapp:
          db:
            connectors:
              default:
                port:   "1234"
                dbname: "stat"
                options:
                  PrintWarn:  0
                  PrintError: 0
                  RaiseError: 1

              test:
                host: "localhost"
                port: "4321"

              stat_master:
                underlay: { var: .default }
                host:     "stat-master.mydb.com"
                username: "stat_writer"
                password: "stat_writer_pass"
                overlay:  { var: .test }

              stat_slave:
                underlay: { var: .default }
                host:     "stat-slave.mydb.com"
                username: "stat_reader"
                password: "stat_reader_pass"
                overlay:  { var: .test }

    To disable overriding just assign to `test` connector empty hash.

        test: {}

# AUTHOR

Eugene Ponizovsky, <ponizovsky@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (c) 2016-2018, Eugene Ponizovsky, <ponizovsky@gmail.com>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
