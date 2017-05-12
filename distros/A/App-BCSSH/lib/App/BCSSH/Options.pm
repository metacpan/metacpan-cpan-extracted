package App::BCSSH::Options;
use strictures 1;
use Package::Variant
    importing => ['Moo::Role'],
    subs => [ qw(has around before after with) ],
;
use Carp;
use App::BCSSH::Options::Accessor as => 'OptAccessor';
use MooX::CaptainHook qw(on_application);

sub make_variant {
    my ($class, $target_package, %in_config) = @_;

    my $error     = delete $in_config{'-error'}     || $class->default_error;
    my $arg_error = delete $in_config{'-arg_error'} || $class->default_arg_error;

    my $config = $class->default_config;
    for my $opt (keys %in_config) {
        $config->{$opt} = $in_config{$opt}
            if exists $config->{$opt};
    }

    my %arguments;
    on_application {
        my $target = $_;
        Moo::Role->apply_roles_to_object(
            Moo->_accessor_maker_for($target),
            OptAccessor(sub {
                my ($into, $name, $spec) = @_;
                $arguments{$name} = $spec;
            }),
        );
    } $target_package;

    my $parser;
    install _parse => sub {
        my ($class, $args) = @_;
        $parser ||= do {
            require Getopt::Long;
            Getopt::Long::Parser->new(config => [
                'default',
                map {
                    $_ =~ /_pattern$/ ? "$_=$config->{$_}"
                    : $config->{$_}   ? $_
                                      : "no_$_"
                } keys %$config
            ]);
        };

        my %opts;
        my @parse_args = map {
            ("$arguments{$_}" => \($opts{$_}))
        } keys %arguments;
        {
            local @ARGV = @$args;
            local $SIG{__WARN__} = $arg_error;
            $parser->getoptions(@parse_args) or $error->();
            @$args = @ARGV;
        }
        for my $k (keys %opts) {
            delete $opts{$k} if !defined $opts{$k};
        }
        if ($config->{passthrough}) {
            for my $idx (0..$#$args) {
                if ($args->[$idx] eq '--') {
                    splice @$args, $idx, 1;
                    last;
                }
            }
        }
        return \%opts;
    };

    has args => (is => 'ro', default => sub { [] });

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        if (@_ == 1 && ref $_[0]) {
            return $class->$orig(@_);
        }
        my $args = [@_];
        my $opts = $class->_parse($args);
        $opts->{args} = $args;
        return $class->$orig($opts);
    };
}

sub default_config {{
    auto_abbrev         => 0,
    gnu_compat          => 1,
    permute             => 0,
    bundling            => 1,
    bundling_override   => 0,
    ignore_case         => 0,
    ignore_case_always  => 0,
    pass_through        => 1,
    prefix_pattern      => '--|-',
    long_prefix_pattern => '--',
    debug               => 0,
}}

sub default_error {
    sub { die "Bad arguments!\n" }
}

sub default_arg_error {
    sub { warn $_[0] }
}

1;
__END__

=head1 NAME

App::BCSSH::Options - Options parser for command objects

=head1 SYNOPSIS

    package App::BCSSH::Command::mycommand;
    use App::BCSSH::Options;
    with Options permute => 1;

    has myoption => ( is => 'ro', arg_spec => 'myoption' );

    $ bcssh mycommand --myoption

=cut
