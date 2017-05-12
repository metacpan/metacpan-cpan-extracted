package Managers::buildConfig;
use strict;
use warnings;
use File::Path;
use File::Spec;
use Cwd qw/abs_path cwd/;

use Ambrosia::Context;
use Ambrosia::Meta;
class sealed
{
    extends => [qw/Ambrosia::BaseManager/],
};

our $VERSION = 0.010;

sub readln()
{
    chomp(my $c = <STDIN>);
    $c =~ s/^(\s+)|(\s+)$//sg;
    return $c;
}

sub isRootDir
{
    my ($volume, $dir, $name) = File::Spec->splitpath(shift);
    return File::Spec->rootdir() eq $dir;
}
sub prepare
{
    my $self = shift;

    ### enter name of project ###
    my $projectName = '';
    print 'Enter the name of project: ';
    $projectName = readln() or die 'Project must be named!';

    ### enter title of project ###
    my $projectTitle = '';
    print "Enter the title of project [$projectName]:";
    $projectTitle = readln() || $projectName;

    ### enter charset of project ###
    my $charset = '';
    print "Enter the charset of project for output results [utf-8]:";
    $charset = readln() || 'utf-8';

    ### enter path for root directory of project ###
    my $rootPath;
    while(1)
    {
        $rootPath = cwd();
        print "Enter the path for root directory of project [$rootPath]: ";
        $rootPath = readln() || abs_path($rootPath);

        unless ($rootPath && !isRootDir($rootPath))
        {
            print "Error: bad directory '$rootPath'. Try agane.\n";
            next;
        }

        last if -d $rootPath;
        print "Error: no sach directory $rootPath\n";

        print "Create path $rootPath [nY]: ";
        my $YN = readln();
        if ( !$YN || lc($YN) eq 'y' )
        {
            my $err = [];
            mkpath($rootPath, {mode => oct(755), error => \$err});
            if ( scalar @$err )
            {
                print 'Error: ' . join "\n", (map { my $h = $_; map { $h->{$_} } keys %$h; } grep {$_} @$err), '';
                next;
            }
            last;
        }
    };

    ### enter domain ###
    chomp(my $httpServerName = `hostname`);
    print "Enter the domain for web server [$httpServerName]:";
    $httpServerName = readln() || $httpServerName;

    ### enter port ###
    my $httpPort;
    print "Enter the port for web server [8042]:";
    $httpPort = readln() || 8042;

    ### enter paths for INC ##
    my @perlLibPath = ();
    while(1)
    {
        print "Enter the path for perl's lib [empty for done]: ";
        if ( my $path = readln() )
        {
            unless ($path && !isRootDir($path) && -d $path)
            {
                print "Error: the path '$path' not found or permission denied\n";
                next;
            }
            push @perlLibPath, $path;
            next;
        }
        last;
    }

    my $DojoToolkitPath;
#    print 'Enter the path to dojo toolkit or empty for download it from http://dojotoolkit.org:';
    print 'Enter the path to dojo toolkit:';
    unless ( $DojoToolkitPath = readln() )
    {
        print <<'MSG';

    You must download dojo toolkit version 1.7.2
    from http://download.dojotoolkit.org/release-1.7.2/dojo-release-1.7.2.tar.gz
    and unzip this file in any directory.
    And then enter path to this directory in the configuration file.

MSG
        #print 'Do you wont download dojo tookit? [Yn]';
        #my $yn = readln();
        #if ( !$yn || lc($yn) eq 'y' )
        #{
        #    downloadLib();
        #}
        #else
        #{
        #    
        #}
    }

    ######### PARAMS FOR DB #########
    ### enter engine name ###
    my $dbEngineName;
    while(1)
    {
        $dbEngineName = '';
        ### enter title of project ###
        print "Choose the database [m(MySQL)|p(PostgresQL)]: m";
        $dbEngineName = {
                m => 'mysql',
                p => 'pg',
            }->{readln() || 'm'} and last;
        print "Enter character 'm'(default) if your project used MySQL or character 'p' for PostgresQL\n";
    }

    ### enter schema ###
    my $dbSchema;
    print "Enter the schema of database [$projectName]:";
    $dbSchema = readln() || $projectName;

    ### enter schema ###
    my $dbHost;
    print "Enter the host location of database [localhost]:";
    $dbHost = readln() || 'localhost';

    ### enter schema ###
    my $dbPort = {
            mysql => 3306,
            pg    => 5432
        }->{$dbEngineName} || '';
    print "Enter the port for connection to database or enter 's' for use UNIX socket [$dbPort]:";
    $dbPort = readln() || $dbPort;
    $dbPort = '' if 's' eq lc($dbPort);

    ### enter user ###
    my $dbUser;
    print "Enter the username of database [root]:";
    $dbUser = readln() || 'root';

    ### enter password ###
    my $dbPassword;
    print "Enter user's password []:";
    $dbPassword = readln() || '';

    ### enter password ###
    my $dbCharset = lc($charset);
    $dbCharset =~ s/[^a-z0-9]//sg;
    print "Enter the charset of database [$dbCharset]:";
    $dbCharset = readln() || $dbCharset;

    ### enter password ###
    my $dbEngineParams = "database=$dbSchema;host=$dbHost" . ($dbPort ? ";port=$dbPort" : '');
    print "Enter the settings for connecting to the database as a string [$dbEngineParams]:";
    $dbEngineParams = readln() || 'undef';

    ### write config to file ###
    if ( open(my $fh, '>', $projectName . '.conf') )
    {
        my $template = join '', <Managers::buildConfig::DATA>;
        print $fh proces_template($template,
            NAME    => $projectName,
            TITLE   => $projectTitle,
            ROOT    => $rootPath,
            CHARSET => $charset,
            SHARE_DIR => Context->repository->get('SHARE_DIR'),
            PERL_LIB_PATH => "@perlLibPath",
            DOJO_TOOLKIT_PATH => $DojoToolkitPath,

            HTTP_SERVER_NAME  => $httpServerName,
            HTTP_PORT => $httpPort,

            DB_ENGINE   => $dbEngineName,
            DB_SCHEMA => $dbSchema,
            DB_HOST => $dbHost,
            DB_PORT => ($dbPort ? "port          => $dbPort," : ''),
            DB_USER => $dbUser,
            DB_PASSWORD => $dbPassword,
            DB_ENGINE_PARAMS => ($dbEngineParams ? "engine_params => $dbEngineParams," : ''),
            DB_CHARSET => $dbCharset,
        );
        close $fh;
    }

    my $message = <<MESSAGE;

#######################################################################
#
#   Config file "${projectName}.conf" has been created successfully.
#
#   Now you can additionally edit ${projectName}.conf and run:
#   ambrosia -c ${projectName}.conf -a db2xml
#
#######################################################################

MESSAGE
    Context->repository->set( Message => $message );
}

sub proces_template
{
    my $template = shift;
    my %data = @_;

    foreach my $name ( keys %data )
    {
        my $value = $data{$name} || '';
        $template =~ s/##$name##/$value/sg;
    }
    $template =~ s/##(.*?)##//sg;
    return $template;
}

#sub downloadLib
#{
#    my $req = HTTP::Request->new(GET => 'http://download.dojotoolkit.org/release-1.7.2/dojo-release-1.7.2.tar.gz');
#}

1;

__DATA__
use strict;
use warnings;

my $ROOT = '##ROOT##';

return
{
    #Application name
    ID => '##NAME##',
    #Application label (title)
    Label => '##TITLE##',

    #Template charset
    Charset => '##CHARSET##',

    #The path to templates of Ambrosia Builder
    TemplatePath  => '##SHARE_DIR##',

    #Now only so. Don't edit this.
    TemplateStyle => { jsframework => 'dojo', htmltemplate => 'xslt' },
    #You must load Dojo Toolkit 1.7.2 from http://download.dojotoolkit.org/release-1.7.2/dojo-release-1.7.2.tar.gz
    #and extract it into this directory
    DojoToolkitPath => '##DOJO_TOOLKIT_PATH##',

    #parameters for project
    ServerName => '##HTTP_SERVER_NAME##',
    ServerPort => ##HTTP_PORT##,

    #The path to the directory where the project will be deployed
    ProjectPath  => $ROOT . '/##NAME##',

    #The path to additional libraries in Perl
    PerlLibPath   => '##PERL_LIB_PATH##',

    ROOT  => $ROOT,
    DEBUG => 1,

    #The path to logfile.
    logger_path => $ROOT . '/app_log',

################################################################################
    data_source => {
        DBI => [
            {
                engine_name   => '##DB_ENGINE##',
                source_name   => '##NAME##',
                catalog       => undef,#optional
                schema        => '##DB_SCHEMA##',
                host          => '##DB_HOST##',#optional
                ##DB_PORT##
                user          => '##DB_USER##',
                password      => '##DB_PASSWORD##',
                ##DB_ENGINE_PARAMS##
                additional_params => { AutoCommit => 0, RaiseError => 1, LongTruncOk => 1 },
                additional_action => sub { my $dbh = shift; $dbh->do('SET NAMES ##DB_CHARSET##')},
            },
        ]
    },

    data_source_info => {
        DBI => { ##NAME## => {charset => '##DB_CHARSET##'} }
    },
};


