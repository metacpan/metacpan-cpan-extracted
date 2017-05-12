# ABSTRACT: Can turn an OpenAPI to App::Spec file
use strict;
use warnings;
package API::CLI::App::Spec;

our $VERSION = '0.001'; # VERSION

use YAML::XS qw/ LoadFile /;

use base 'App::Spec';

use Moo;

has openapi => ( is => 'ro' );

sub from_openapi {
    my ($class, %args) = @_;

    my $file = delete $args{file};
    my $openapi = LoadFile($file);

    my $spec = $class->openapi2appspec(
        openapi => $openapi,
        %args,
    );

    my $appspec = $class->read($spec);

    return $appspec;
}

sub openapi2appspec {
    my ($class, %args) = @_;

    my $openapi = $args{openapi};
    my $name = $args{name};
    my $classname = $args{class};
    my $spec;

    my $paths = $openapi->{paths};
    my $subcommands = $spec->{subcommands} = {};

    for my $path (sort keys %$paths) {
        my $methods = $paths->{ $path };
        $path =~ s{(?:\{(\w+)\})}{:$1}g;
        for my $method (sort keys %$methods) {

            my $config = $methods->{ $method };
            $spec->{name} = $name;
            $spec->{class} = $classname;
            $spec->{title} //= $openapi->{info}->{title};
            $spec->{summary} = $openapi->{info}->{description};

            my @parameters;
            my @options;
            if (my $params = $config->{parameters}) {
                for my $p (@$params) {
                    my $appspec_param = $class->param2appspec($p);
                    if ($p->{in} eq 'path') {
                        push @parameters, $appspec_param;
                    }
                    elsif ($p->{in} eq 'query') {
                        push @options, $appspec_param;
                    }
                }
            }

            my $apicall = $subcommands->{ uc $method } ||= {
                op => 'apicall',
                summary => "\U$method\E call",
                subcommands => {},
            };
            my $desc = $config->{description};
            $desc =~ s/\n.*//s;
            if (length $desc > 30) {
                $desc = substr($desc, 0, 50) . '...';
            }
            my $subcmd = $apicall->{subcommands}->{ $path } ||= {
                summary => $desc,
                parameters => \@parameters,
                options => \@options,
            };

        }
    }

    $spec->{openapi} = $openapi;

    my $options = $spec->{options} ||= [];
    push @$options, {
        name => "data-file",
        type => "file",
        summary => "File with data for POST/PUT/PATCH/DELETE requests",
    };
    push @$options, {
        name => "debug",
        type => "flag",
        summary => "debug",
        aliases => ['d'],
    };
    push @$options, {
        name => "verbose",
        type => "flag",
        summary => "verbose",
        aliases => ['v'],
    };
    $spec->{apppec}->{version} = '0.001';

    return $spec;
}

sub param2appspec {
    my ($self, $p) = @_;
    my $type = $p->{type};
    my $required = $p->{required};
    my $item = {
        name => $p->{name},
        type => $type,
        required => $required,
        summary => $p->{description},
        $p->{enum} ? (enum => $p->{enum}) : (),
    };
    if ($p->{in} eq 'path') {
    }
    elsif ($p->{in} eq 'query') {
        $item->{name} = "q-" . $item->{name};
    }
    return $item;
}

1;

__END__

=pod

=head1 NAME

API::CLI::App::Spec - Can turn an OpenAPI to App::Spec file

=head1 METHODS

=over 4

=item from_openapi

    my $spec = API::CLI::App::Spec->from_openapi(
        openapi => $openapi,
        name => "myclient",
        class => "My::API::CLI", # default API::CLI
    );

Returns a L<App::Spec> object from an OpenAPI structure.

=item openapi2appspec

    my $hashref = API::CLI::App::Spec->openapi2appspec(
        openapi => $openapi,
        name => $name,
        class => $class,
    );

Returns a hashref representing L<App::Spec> data

=item param2appspec

    my $appspec_param = $class->param2appspec($p);

Returns a Parameter for L<App::Spec> from an OpenAPI parameter.

=item openapi

Attribute which stores the OpenAPI structure.

=back

=cut
