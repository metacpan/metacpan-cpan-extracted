package Cog::Base;
use Mo;

# System singleton object pointers.
my $app;
my $config;
my $maker;
my $runner;
my $webapp;
my $json;

# The config reference must be initialized at startup.
$Cog::Base::initialize = sub {
    $app ||= $_[0];
    $config ||= $_[1];
};

# The accessors to common singleton objects are kept in single file
# scoped lexicals, so that every Cog::Base subclass can access them
# without needing to store them in their objects. This keeps things
# clean and fast, and avoids needless circular refs.
my $singleton = sub {
    my ($type) = @_;
    my $method = lc($type) . "_class";
    my $class = $app->$method
        or die "Can't determine class for '$type'";
    unless (UNIVERSAL::isa($class, 'Cog::Base')) {
        eval "require $class; 1" or die $@;
    }
    return $class->new();
};

sub app    { $app }
sub config { $config }
sub maker  { $maker  || ($maker  = $singleton->('Maker')) }
sub runner { $runner || ($runner = $singleton->('Runner')) }
sub webapp { $webapp || ($webapp = $singleton->('WebApp')) }

# Cog plugins need to know their distribution name. This name is used to
# locate shared files using File::ShareDir and other methods.
#
# This method will figure out the correct dist name most of the time.
# Otherwise the class can hardcode it like this:
#
# package Foo::Bar;
# use constant DISTNAME => 'Foo-X';
sub DISTNAME {
    my $class = shift;
    my $module = $class;
    while (1) {
        no strict 'refs';
        last if ${"${module}::VERSION"};
        eval "require $module";
        last if ${"${module}::VERSION"};
        $module =~ s/(.*)::.*/$1/
            or die "Can't determine DISTNAME for $class";
    }
    my $dist = $module;
    $dist =~ s/::/-/g;
    return $dist;
}

# Access to a set up JSON object
sub json {
    $json ||= do {
        require JSON;
        my $j = JSON->new;
        $j->allow_blessed;
        $j->convert_blessed;
        $j;
    };
    return $json;
}

1;
