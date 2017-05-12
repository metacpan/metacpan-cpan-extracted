use strict;
use warnings;
use CAF_MB_Installer;
use Digest::MD5 ();
use File::Spec ();
use File::Basename ();

my $builder = CAF_MB_Installer->new(
    module_name         => 'CGI::Application::Framework',
    license             => 'perl',
    dist_author         => 'Richard Dice <rdice@pobox.com>',
    dist_version_from   => 'lib/CGI/Application/Framework.pm',
    get_options => {
         'skip-examples'  => {                 },
         'help'           => {                 },
         'root'           => { type    => '=s' },
         'framework-root' => { type    => '=s' },
         'examples-path'  => { type    => '=s' },
         'examples-url'   => { type    => '=s' },
         'cgi-bin-path'   => { type    => '=s' },
         'cgi-bin-url'    => { type    => '=s' },
         'projects'       => { type    => '=s' },
         'sessions'       => { type    => '=s' },
         'logs'           => { type    => '=s' },
         'sqlite'         => { type    => '=s' },
         'sql'            => { type    => '=s' },
         'webuser'        => { type    => '=s' },
         'webgroup'       => { type    => '=s' },
    },
    requires => {
        'Test::More'                                => 0,
        'DB_File'                                   => 0,
        'Digest::MD5'                               => 0,
        'Data::Dumper'                              => 0,
        'Time::HiRes'                               => 0,
        'Date::Manip'                               => 0,
        'Time::Format'                              => 0,
        'DBI'                                       => 0,
        'DBD::SQLite'                               => 1.09,
        'Class::DBI'                                => 0,
        'Class::DBI::Loader'                        => 0.22,
        'Class::DBI::SQLite'                        => 0,
        'Class::DBI::AbstractSearch'                => 0,
        'Apache::Session'                           => 0,
        'Apache::SessionX'                          => 0,
        'URI'                                       => 0,
        'CGI'                                       => 0,
        'CGI::Carp'                                 => 0,
        'CGI::Enurl'                                => 0,
        'HTML::Template'                            => 0,
        'Config::General'                           => 2.28,
        'CGI::Application'                          => 4.0,
        'CGI::Application::Plugin::ValidateRM'      => 0,
        'Log::Dispatch'                             => 0,
        'Log::Dispatch::Config'                     => 0,
        'Regexp::Common'                            => 0,
        'Text::CSV_XS'                              => 0,
        'IPC::Shareable'                            => 0,
        'CGI::Application::Plugin::Config::Context' => 0,
        'CGI::Application::Plugin::AnyTemplate'     => 0.11,
        'CGI::Application::Plugin::LogDispatch'     => 0,
        'Module::Build'                             => 0.2602,
        'Module::Load'                              => 0,
    },
    meta_add            => {
        no_index       => {
            dir => [ qw/
                 caf_cgi
                 caf_config
                 caf_htdoc
                 caf_image
                 caf_project
                 caf_server
                 caf_sql
                 misc
                 t
            /]
        }
    },
    add_to_cleanup      => [ 'CGI-Application-Framework-*' ],
    create_makefile_pl  => 'passthrough',
);

###################################################################
# Print help if requested
###################################################################

if ($builder->args('help')) {
    print <<EOF;

This is the installer for CGI::Application::Framework

You can specify arguments on the command line, or you can
answer the questions interactively.

Options:
    --root           # e.g. /var/www/myhost
    --framework-root # e.g. /var/www/myhost/framework
    --examples-path  # e.g. /var/www/myhost/framework/htdocs/caf-examples
    --examples-url   # e.g. /caf-examples
    --cgi-bin-path   # e.g. /var/www/myhost/framework/cgi-bin
    --cgi-bin-url    # e.g. /cgi-bin
    --projects       # e.g. /var/www/myhost/framework/projects
    --sessions       # e.g. /var/www/myhost/framework/projects/sessions
    --logs           # e.g. /var/www/myhost/framework/projects/logs
    --sqlite         # e.g. /var/www/myhost/framework/projects/sqlite
    --sql            # e.g. /var/www/myhost/framework/projects/sql
    --user           # e.g. jsmith
    --group          # e.g. jsmith
    --webuser        # e.g. nobody
    --webgroup       # e.g. nobody

If you choose not to install the examples, then none of
the above settings will be used.  To skip installing the
examples, use:

    --skip-examples  # don't install the examples

EOF
    exit 255;
}


###################################################################
# Decide whether or not to install the examples
###################################################################

my $install_examples = ! $builder->args('skip-examples');

# not cancelled on the command line so ask the user
if ($install_examples) {
    # if the user has specified --root=/some/path
    # then assume they want the examples installed
    # otherwise ask them
    if (!$builder->args('root')) {
        $install_examples = $builder->y_n("Install examples? ", 'yes');
    }
}

$builder->notes('install-examples', $install_examples);

if ($install_examples) {


    my (
         $root,
         $framework_root,
         $examples_path,
         $examples_url,
         $cgi_bin_path,
         $cgi_bin_url,
         $user,
         $group,
         $webuser,
         $webgroup,
    );

    # This loop allows us to repeat all the questions if the user
    # decides they have made a mistake

    while (1) {

        ###################################################################
        # Ask for user's input on where to install the web files
        ###################################################################

        # Root Directory varies by platform
        # Win32 support is totally untested!

        my @root_dirs = (
           '/var/www/caf',
           '/usr/local/caf',
        );

        if ($^O =~ /Win32/) {
            @root_dirs = (
                'C:/Program Files/CAF',
            );
        }

        if ($ENV{'HOME'}) {
           push @root_dirs, "$ENV{'HOME'}/caf";
        }

        $root = $builder->multiple_choice(
            question_name => 'root',
            preamble      => qq{
                Root Installation Directory
                ---------------------------
                This should probably be in the directory of a virtual host that you've set up on
                your local web server.  It could also be in your home directory.

                Where do you want the root of the installation to be?
            },
            choices       => \@root_dirs,
            default       => $root_dirs[0],
            pre_defined   => $builder->args('root'),  # skip question if already defined
        );

        $framework_root = $builder->multiple_choice(
            question_name => 'framwork-root',
            preamble      => qq{
                Framework Root
                --------------
                This should be within the virtual host ($root),
                but NOT within the publicly visible web root.  In this directory
                will go all of your web application's projects, sessions logs, etc.

                Where do you want the framework root to be?
            },
            choices       => File::Spec->catdir($root, 'framework'),
            default       => File::Spec->catdir($root, 'framework'),
            pre_defined   => $builder->args('framework-root'),  # skip question if already defined
        );

        my $default_examples_path = File::Spec->catdir($root, 'htdocs', 'caf-examples');

        $examples_path = $builder->multiple_choice(
            question_name => 'examples-path',
            preamble      => qq{
                Web Examples (HTML + CSS)
                -------------------------
                This is the location (in your public webroot) where the
                example files (html, images, css files, etc.) will be
                installed.  We need both the filesystem path and the
                URL by which they can be publicly accessed.

                If you specify a location that is already within your
                web server's public web space, then you should not have
                to any additional webserver configuration.

                On the other hand, if you choose a location that
                is outside of your public web space you will need to configure
                your web server to make this location public.  For instance,
                if you are using Apache, you will need to add the following lines
                to httpd.conf:

                     Alias  /caf  $default_examples_path/htdocs/caf-examples/

                Where do you want the example files to be installed (path)?
            },
            choices       => $default_examples_path,
            default       => $default_examples_path,
            pre_defined   => $builder->args('examples-path'),  # skip question if already defined
        );

        # Make a guess at the examples url by taking the last element
        # of $examples_path
        my ($volume, @path) = File::Spec->splitpath($examples_path);
        my $default_examples_url = '/' . pop @path;

        $examples_url = $builder->multiple_choice(
            question_name => 'examples-url',
            preamble      => qq{
                What is the URL to the example files?
            },
            choices       => $default_examples_url,
            default       => $default_examples_url,
            pre_defined   => $builder->args('examples-url'),  # skip question if already defined
        );

        my $default_cgi_bin_path = File::Spec->catdir($root, 'cgi-bin' );

        $cgi_bin_path = $builder->multiple_choice(
            question_name => 'cgi-bin-path',
            preamble      => qq{
                cgi-bin path
                ------------
                This is the location where the app.cgi script will be
                installed.  The location you choose should be configured in
                your web server as a location in which CGI scripts can be run.

                We need both the filesystem path and the URL by which this location
                can be publicly accessed.

                If you specify a location that is already within your web
                server's existing cgi-bin directory, then you should not
                have to any additional webserver configuration.

                On the other hand, if you choose a location that is outside
                of your public cgi-bin directory, you will need to configure
                your web server to make this location public and capable of
                running CGI scripts.  For instance, if you are using Apache,
                you will need to add the following lines to httpd.conf:

                     ScriptAlias  /caf-cgi  $default_cgi_bin_path

                Where do you want the cgi-bin files to be installed (path)?

            },
            choices       => $default_cgi_bin_path,
            default       => $default_cgi_bin_path,
            pre_defined   => $builder->args('cgi-bin-path'),  # skip question if already defined
        );

        # Make a guess at the cgi-bin url by taking the last element
        # of $cgi_bin_path
        ($volume, @path) = File::Spec->splitpath($cgi_bin_path);
        my $default_cgi_bin_url = '/' . pop @path;

        $cgi_bin_url = $builder->multiple_choice(
            question_name => 'cgi-bin-url',
            preamble      => qq{
                What is the URL to the cgi-bin directory?
            },
            choices       => $default_cgi_bin_url,
            default       => $default_cgi_bin_url,
            pre_defined   => $builder->args('cgi-bin-url'),  # skip question if already defined
        );

        $user     = 'nobody';
        $group    = 'nobody';
        $webuser  = 'nobody';
        $webgroup = 'nobody';

        if ($^O !~ /Win32/) {

            my $default_user  = getpwuid($<);
            my $default_group = getgrgid($();

            my @users  = ($default_user, qw(www-data web www nobody));
            my @groups = ($default_group, qw(www-data web www nobody));

            $user = $builder->multiple_choice(
                question_name => 'user',
                preamble      => qq{
                    Examples User
                    -------------
                    What user do you want the installed example files
                    to be owned by?

                },
                prompt        => 'Examples user (pick a number or enter a username)',
                choices       => \@users,
                default       => $users[0],
                pre_defined   => $builder->args('user'),  # skip question if already defined
            );

            # Add the selected user to the list of groups
            # if it also happens to be a valid group name
            if (! grep { /$user/ } @users) {
                if (getgrnam($user)) {
                    push @groups, $user;
                }
            }

            $group = $builder->multiple_choice(
                question_name => 'group',
                preamble      => qq{
                    Examples Group
                    --------------
                },
                choices       => \@groups,
                default       => $groups[0],
                prompt        => 'Examples group (pick a number or enter a group name)',
                pre_defined   => $builder->args('group'),  # skip question if already defined
            );


            my @web_users  = qw(www-data web www nobody);
            my @web_groups = qw(www-data web www nobody);

            $webuser = $builder->multiple_choice(
                question_name => 'webuser',
                preamble      => qq{
                    Web Server User
                    ---------------
                    This is the system user that Apache runs under.
                    Certain files have to be writeable by this user.

                },
                prompt        => 'Web server user (pick a number or enter a username)',
                choices       => \@web_users,
                default       => $web_users[0],
                pre_defined   => $builder->args('webuser'),  # skip question if already defined
            );

            if (! grep { /$webuser/ } @web_users) {
                unshift @web_groups, $webuser;
            }

            $webgroup = $builder->multiple_choice(
                question_name => 'webgroup',
                preamble      => qq{
                    Web Server Group
                    ----------------
                },
                choices       => \@web_groups,
                default       => $webuser,
                prompt        => 'Web server group (pick a number or enter a group name)',
                pre_defined   => $builder->args('webgroup'),  # skip question if already defined
            );
        }

        print <<EOF;

This is your current configuration:

Root directory:    $root
Framework root:    $framework_root
Examples path:     $examples_path
Examples URL:      $examples_url
cgi-bin path:      $cgi_bin_path
cgi-bin URL:       $cgi_bin_url
Examples user:     $user
Examples group:    $group
Web server user:   $webuser
Web server group:  $webgroup

If you are using Apache and if the path to the Examples or the path to
the cgi-bin directory is outside of your existing webroot, you will need
to add the following configuration to your httpd.conf:

    Alias       $examples_url $examples_path
    ScriptAlias $cgi_bin_url $cgi_bin_path

NOTE: if you installed into your home directory, there is a good chance that
the web server will not be able to read the files there.

EOF

# warn about home directory

        if ($builder->args('root')) {  # don't ask for confirmation if the user passed
            last;                      # values on the command line
        }
        last if $builder->y_n("Is this configuration correct? ", 'yes');
    }


    ###################################################################
    # From the user's input, prepare the paths and store
    # them in $builder->notes
    ###################################################################

    my $url_caf_examples     = $examples_url;
    my $url_cgi_bin          = $cgi_bin_url;
    my $md5_salt             = Digest::MD5::md5_hex($$, time, rand(42));  # is this even remotely random?

    my $web_server_user      = $webuser;
    my $web_server_group     = $webgroup;
    my $examples_user        = $user;
    my $examples_group       = $group;

    my $caf_projects_dir     = $builder->args('projects') || "$framework_root/projects";
    my $caf_sessions_dir     = $builder->args('sessions') || "$framework_root/sessions";
    my $caf_sqlite_dir       = $builder->args('sqlite')   || "$framework_root/sqlite";
    my $caf_sqlite_file      = "$framework_root/sqlite/sqlite_db.sqlite";
    my $caf_logs_dir         = $builder->args('logs')     || "$framework_root/logs";
    my $caf_sql_dir          = $builder->args('sql')      || "$framework_root/sql";

    my $caf_examples_htdocs  = $examples_path;
    my $caf_examples_images  = File::Spec->catdir($caf_examples_htdocs, 'images');
    my $caf_examples_cgi_bin = $cgi_bin_path;

    # Look up web server user

    my $web_server_user_num  = -1;
    my $web_server_group_num = -1;
    my $examples_user_num    = 0;
    my $examples_group_num   = 0;

    if ($^O !~ /Win32/) {  # skip on Win32
       $web_server_user_num  = getpwnam($web_server_user);
       $web_server_group_num = getgrnam($web_server_group);

       $examples_user_num    = getpwnam($examples_user);
       $examples_group_num   = getgrnam($examples_group);
    }

    # Make relative versions of the paths - relative to the directory
    # containing the cgi script
    # Relative versions of the paths go in app.cgi and the framework.conf
    # files.
    #
    # They probably won't work with mod_perl, since the apache process
    # won't be chdir'd to the cgi-bin directory


    my $rel_caf_sessions_dir = File::Spec->abs2rel($caf_sessions_dir, $caf_examples_cgi_bin);
    my $rel_caf_sqlite_dir   = File::Spec->abs2rel($caf_sqlite_dir,   $caf_examples_cgi_bin);
    my $rel_caf_sqlite_file  = File::Spec->abs2rel($caf_sqlite_file,  $caf_examples_cgi_bin);
    my $rel_caf_logs_dir     = File::Spec->abs2rel($caf_logs_dir,     $caf_examples_cgi_bin);
    my $rel_caf_projects_dir = File::Spec->abs2rel($caf_projects_dir, $caf_examples_cgi_bin);

    $builder->notes('path_root'                =>    $root);
    $builder->notes('path_framework_root'      =>    $framework_root);

    $builder->notes('path_projects_dir'        =>    $caf_projects_dir);
    $builder->notes('relpath_projects_dir'     =>    $rel_caf_projects_dir);

    $builder->notes('url_caf_logo'             =>    "$url_caf_examples/images/caf_logo_t.png");
    $builder->notes('url_barfiller'            =>    "$url_caf_examples/images/barfiller.jpg");
    $builder->notes('url_app_cgi'              =>    "$url_cgi_bin/app.cgi");
    $builder->notes('url_example_css'          =>    "$url_caf_examples/example.css");
    $builder->notes('md5_salt'                 =>    "$md5_salt");

    $builder->notes('path_sql_dir'             =>     $caf_sql_dir);

    $builder->notes('path_session_dir'         =>    $caf_sessions_dir);
    $builder->notes('relpath_session_dir'      =>    $rel_caf_sessions_dir);

    $builder->notes('path_session_locks'       =>    "$caf_sessions_dir/locks");
    $builder->notes('relpath_session_locks'    =>    "$rel_caf_sessions_dir/locks");

    $builder->notes('path_session_database'    =>    "$caf_sessions_dir/database");
    $builder->notes('relpath_session_database' =>    "$rel_caf_sessions_dir/database");

    $builder->notes('path_weblog'              =>    $caf_logs_dir);
    $builder->notes('relpath_weblog'           =>    $rel_caf_logs_dir);

    $builder->notes('file_sqlite_db'           =>    $caf_sqlite_file);
    $builder->notes('relfile_sqlite_db'        =>    $rel_caf_sqlite_file);
    $builder->notes('path_sqlite'              =>    $caf_sqlite_dir);
    $builder->notes('relpath_sqlite'           =>    $rel_caf_sqlite_dir);

    $builder->notes('path_examples_htdocs'     =>    $caf_examples_htdocs);
    $builder->notes('path_examples_images'     =>    $caf_examples_images);
    $builder->notes('path_examples_cgi_bin'    =>    $caf_examples_cgi_bin);

    $builder->notes('web_server_user'          =>    $web_server_user);
    $builder->notes('web_server_group'         =>    $web_server_group);

    $builder->notes('web_server_user_num'      =>    $web_server_user_num);
    $builder->notes('web_server_group_num'     =>    $web_server_group_num);

    $builder->notes('examples_user'            =>    $examples_user);
    $builder->notes('examples_group'           =>    $examples_group);

    $builder->notes('examples_user_num'        =>    $examples_user_num);
    $builder->notes('examples_group_num'       =>    $examples_group_num);


    ###################################################################
    # Initialize the $builder and create the install script
    ###################################################################

    $builder->caf_add_examples_build_elements;
}

$builder->create_build_script;





