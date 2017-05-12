use Module::Build;
# See perldoc Module::Build for details of how this works

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub prepare_metadata {
            my $node = shift->SUPER::prepare_metadata(@_);

            delete $node->{provides}{'Catalyst::Response'};

            $node;
        }
    },
);

$class->new(
    module_name => 'Catalyst::Plugin::XSendFile',
    license     => 'perl',
    requires    => {
        'Catalyst'                 => '5.6902',
        'Class::Data::Inheritable' => 0,
        'NEXT'                     => 0,
        'MIME::Types'              => 0,
        'Path::Class'              => 0,
    },
)->create_build_script;
