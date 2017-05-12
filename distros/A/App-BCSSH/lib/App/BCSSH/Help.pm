package App::BCSSH::Help;
use Moo::Role;
use App::BCSSH::Util qw(command_to_package package_to_command);

has opt_help       => (is => 'ro', arg_spec => 'help');
has opt_help_short => (is => 'ro', arg_spec => 'h');

around run => sub {
    my $orig = shift;
    my $self = shift;
    if ($self->opt_help_short) {
        my $package = ref $self;
        require App::BCSSH;
        require App::BCSSH::Pod;
        my $parsed = App::BCSSH::Pod->parse($package);
        my ($abstract, $synopsis, $options) = @{$parsed}{qw(abstract synopsis options)};
        my $command = package_to_command($package);
        printf "bcssh %0.6f\n", $App::BCSSH::VERSION;
        print "bcssh $command";
        print " - $abstract"
            if $abstract;
        print "\n";
        print "\nSynopsis:\n$synopsis\n"
            if $synopsis;

        if ($options && %$options) {
            print "\nOptions:\n";
            for my $option (sort keys %$options) {
                my $short = $options->{$option};
                $short =~ s/\..*/./;
                printf "%15s : %s\n", $option, $short;
            }
        }
        return 1;
    }
    elsif ($self->opt_help) {
        my $package = ref $self;
        require App::BCSSH::Command::help;
        return App::BCSSH::Command::help->new->help_for_package($package);
    }
    return $self->$orig(@_);
};

1;
__END__

=head1 NAME

App::BCSSH::Help - Role to provide -h and --help options

=head1 SYNOPSIS

    package App::BCSSH::Command::mycommand;
    use App::BCSSH::Options;
    with Options;
    with 'App::BCSSH::Help';

    $ bcssh mycommand --help

=cut
