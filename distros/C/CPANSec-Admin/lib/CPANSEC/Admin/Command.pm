use v5.38;
use feature 'class';
use builtin qw( true false );
no warnings qw(
    experimental::class
    experimental::builtin
    experimental::for_list
);
use Module::Load ();
use Getopt::Long ();

class CPANSEC::Admin::Command {
    field %dispatcher;
    field $config :param = {};
    field $verbosity = 1;

    method dispatcher { %dispatcher }
    method config     { $config     }

    method load ($name) {
        my $pkg = 'CPANSEC::Admin::Command::' . $name;
        Module::Load::load($pkg);
        my $obj = $pkg->new;
        $dispatcher{ $obj->name } = $obj;
    }

    method run (@args) {
        my $quiet;
        my $show_version;
        my $getopt = Getopt::Long::Parser->new( config => ['pass_through'] );
        $getopt->getoptionsfromarray(\@args, 'quiet' => \$quiet, 'version' => \$show_version );
        if ($show_version) {
            say "cpansec-admin $CPANSEC::Admin::VERSION ($0)";
            return true;
        }
        my ($cmd_name, @cmd_args) = @args;
        return false unless defined $cmd_name && exists $dispatcher{$cmd_name};
        $verbosity = 0 if $quiet;
        $dispatcher{$cmd_name}->command($self, @cmd_args);
        return true;
    }

    method get_options ($args, $opts) {
        my (%parsed, %defaults, %output);
        %defaults = (%$config);
        foreach my ($k, $v) (%$opts) {
            my $parsed_k = $k =~ s/\-/_/gr;
            $parsed_k =~ s/\=.\z//;
            $parsed{$k} = \$output{$parsed_k};
            $defaults{$parsed_k} = $opts->{$k} if $opts->{$k};
        }
        Getopt::Long::Parser->new->getoptionsfromarray($args, %parsed);

        foreach my $k (keys %defaults) {
            if (!defined $output{$k}) {
                my $default_value = $defaults{$k};
                foreach my $to_replace ($default_value =~ /\{(.+?)\}/g) {
                    my $replacement = $output{$to_replace} // $defaults{$to_replace};
                    if ($replacement) {
                        $default_value =~ s/\{$to_replace\}/$replacement/ge;
                    }
                }
                $output{$k} = $default_value;
            }
        }
        return %output;
    }

    method info ($msg) { say '[+] ' . $msg if $verbosity > 0 }
}
