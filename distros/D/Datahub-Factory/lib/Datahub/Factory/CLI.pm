package Datahub::Factory::CLI;

use Datahub::Factory::Sane;

our $VERSION = '1.74';

use Datahub::Factory;
use Log::Any::Adapter;
use Log::Log4perl;
use DateTime;
use Term::ANSIColor qw(:constants);
use namespace::clean;

use parent qw(App::Cmd);

sub default_command {'commands'}

sub plugin_search_path {'Datahub::Factory::Command'}

sub global_opt_spec {
    return (
        ['log_level|L:i', "Log level (1 - 3) with 3 the chattiest."]
    );
}

sub default_log4perl_config {
    my $level    = shift // 'DEBUG';
    my $appender = shift // 'STDERR';


    my $date = DateTime->now()->dmy();
    my $import_log_header = sprintf('DATAHUB FACTORY IMPORT LOG FOR %s', DateTime->now()->datetime());

    my $config = <<EOF;
log4perl.rootLogger=$level,$appender
log4perl.category.datahub=$level,$appender

log4perl.appender.STDOUT=Log::Log4perl::Appender::Screen
log4perl.appender.STDOUT.stderr=0
log4perl.appender.STDOUT.utf8=1

log4perl.appender.STDOUT.layout=PatternLayout
log4perl.appender.STDOUT.layout.ConversionPattern=%d [%P] - %p %l %M time=%r : %m%n

log4perl.appender.STDERR=Log::Log4perl::Appender::Screen
log4perl.appender.STDERR.stderr=1
log4perl.appender.STDERR.utf8=1

log4perl.appender.STDERR.layout=PatternLayout
log4perl.appender.STDERR.layout.ConversionPattern=%d [%P] - %l : %m%n

EOF
    return \$config;
}

sub setup_logging {
    my %LEVELS = (1 => 'WARN', 2 => 'INFO', 3 => 'DEBUG');
    my $logging = shift;
    my $level  = $LEVELS{$logging};
    my $load_from = "<none>";

    try {
        my $log4perl_pkg = Datahub::Factory::Util::require_package('Log::Log4perl');
        my $logany_adapter = Datahub::Factory::Util::require_package('Log::Any::Adapter::Log4perl');

        my $config = Datahub::Factory->config->{log4perl};

        if (defined ($config)) {
            if ($config =~ /^\S+$/) {
                Log::Log4perl::init($config);
                $load_from = "file: $config";
            }
            else {
                Log::Log4perl::init(\$config);
                $load_from = "string: <defined in datahubfactory.yml>";
            }
        }
        else {
            Log::Log4perl::init(default_log4perl_config($level, 'STDERR'));
            $load_from = "string: <defined in : " . __PACKAGE__ . ">";
        }
 
        Log::Any::Adapter->set('Log4perl');

    } catch {
        print STDERR <<EOF;

Oops! Debugging tools not available on this platform.

Try to install Log::Log4perl and Log::Any::Adapter::Log4perl.

Hint: cpan Log::Log4perl Log::Any::Adapter::Log4perl
EOF

        exit(2);
    };

    Datahub::Factory->log->warn(
        "Logger activated - level $level - config loaded from $load_from"
    );
}

sub run {
    my ($class) = @_;
    my ($global_opts, $argv)
         = $class->_process_args([@ARGV],
         $class->_global_option_processing_params);

    if (exists $global_opts->{'log_level'}) {
        setup_logging($global_opts->{'log_level'} // 1);
    }

    my $self = ref $class ? $class : $class->new;
    $self->set_global_options($global_opts);

    my ($cmd, $opt, @args) = $self->prepare_command(@$argv);

    # ...and then run it
    try {
        $self->execute_command($cmd, $opt, @args);
    }
    catch {
        local $Term::ANSIColor::AUTORESET = 1;
        print RED "Oops! $_";
        goto ERROR;
    };

    return 1;

ERROR:
    return undef;
}

1;

__END__

=head1 NAME

Datahub::Factory::CLI - The App::Cmd class for the Datahub::Factory application

=head1 SEE ALSO

L<factory>

=cut

