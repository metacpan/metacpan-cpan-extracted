package App::Followme::ConfiguredObject;

use 5.008005;
use strict;
use warnings;

use Cwd;
our $VERSION = "1.93";

#----------------------------------------------------------------------
# Create object that returns files in a directory tree

sub new {
    my ($pkg, %configuration) = @_;

    my $self = {};
    my $cycle = {};
    initialize($pkg, $self, $cycle, %configuration);

    return $self;
}

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            quick_update => 0,
            top_directory => getcwd(),
            base_directory => getcwd(),
           );
}

#----------------------------------------------------------------------
# Update an object's fields from all the configuration hashes

sub add_configurations {
    my ($self, $pkg, %configuration) = @_;

    foreach my $field ($self->all_fields($configuration{''})) {
        $self->{$field} = $configuration{''}->{$field};
    }

    foreach my $field ($self->all_fields($configuration{$pkg})) {
        $self->{$field} = $configuration{$pkg}->{$field};
    }

    foreach my $field ($self->all_fields(\%configuration)) {
        $self->{$field} = $configuration{$field};
    }

    return;
}

#----------------------------------------------------------------------
# Create subobjects for any parameter ending in _pkg

sub add_subpackages {
    my ($self, %configuration) = @_;

    foreach my $field ($self->all_fields($self)) {
        my $subpkg = $self->{$field};
        next unless $field =~ s/_pkg$//;

        eval "require $subpkg" or die "Module not found: $subpkg\n";

        if ($subpkg->isa('App::Followme::ConfiguredObject')) {
            $self->{$field} = $subpkg->new(%configuration);
        } elsif ($subpkg->can('new')) {
            $self->{$field} = $subpkg->new();
        } else {
            $self->{$field} = $subpkg;
        }
    }

    return;
}

#----------------------------------------------------------------------
# Get the configuration fields that apply to this package

sub all_fields {
    my ($self, $configuration) = @_;

    my @fields = ();
    if (defined $configuration) {
        my $pkg = ref $self;
        my %parameters = $pkg->parameters();

        foreach my $field (keys %$configuration) {
            next if ref $configuration->{$field};
            next unless exists $parameters{$field};

            push(@fields, $field);
        }
    }

    return @fields;
}

#----------------------------------------------------------------------
# Initialize the object by populating its hash

sub initialize {
    my ($pkg, $self, $cycle, %configuration) = @_;
    %configuration = () unless %configuration;
    return if $cycle->{$pkg};

    no strict 'refs';
    initialize($_, $self, $cycle, %configuration) foreach @{"${pkg}::ISA"};
    $cycle->{$pkg} = 1;

    my %parameters = $pkg->parameters();
    while (my ($key, $value) = each(%parameters)) {
        $self->{$key} = $value if length $value;
    }

    $self = bless($self, $pkg);

    $self->add_configurations($pkg, %configuration);
    $self->add_subpackages(%configuration);

    $self->setup(%configuration) if defined &{"${pkg}::setup"};
    return;
}

#----------------------------------------------------------------------
# Set up object fields (stub)

sub setup {
    my ($self, %configuration) = @_;
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::ConfiguredObject - Base class for App::Followme classes

=head1 SYNOPSIS

    use App::Followme::ConfiguredObject;
    my $obj = App::Followme::ConfiguredObjects->new($configuration);

=head1 DESCRIPTION

This class creates a new configured object. All classes in App::Followme are
subclassed from it. The new method creates a new object and initializes the
parameters from the configuration file.

=over 4

=item $obj = ConfiguredObject->new($configuration);

Create a new object from the configuration. The configuration is a reference to
a hash containing fields with the same names as the object parameters. Fields
in the configuration whose name does not match an object parameter are ignored.
If a configuration field ends in "_pkg", its value is assumed to be the name of
a subpackage, which is is created and stored in a field whose name is stripped
of the "_pkg" suffix.

=item %parameters = $self->parameters();

Returns a hash of the default values of the object's parameters.

=item $self->setup(%configuration);

Sets those parameters of the object which are computed when the object is
initialized.

=back

=head1 CONFIGURATION

The following fields in the configuration file are used in this class and every
class based on it:

=over 4

=item base_directory

The directory containing the configuration file that loads the class. The
default value is the current directory.

=item quick_mode

A flag indicating application is run in quick mode.

=item top_directory

The top directory of the website. The default value is the current directory.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
