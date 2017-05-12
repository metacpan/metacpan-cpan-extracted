package Ambrosia::DataProvider;
use strict;
use warnings;
use Carp qw/croak/;

use Ambrosia::Assert;
require Ambrosia::core::ClassFactory;

use Ambrosia::Meta;

class sealed {
    extends => [qw/Exporter/],
    private => [qw/_list/],
};

our $VERSION = 0.010;

our @EXPORT = qw/storage/;

our %PROCESS_MAP = ();
our %STORAGE = ();

sub import
{
    my $pkg = shift;
    my %prm = @_;
    assign($prm{assign}) if $prm{assign};

    __PACKAGE__->export_to_level(1, @EXPORT);
}

sub assign
{
    $PROCESS_MAP{$$} = shift;
}

sub new : Private
{
    return shift->SUPER::new(@_);
}

sub instance
{
    my $package = shift;
    my $key = shift;

    unless ( $STORAGE{$key} )
    {
        my %params = @_ == 1 ? %{$_[0]} : @_;
        my %list = ();

        foreach my $driverType ( keys %params )
        {
            foreach my $p ( ref $params{$driverType} eq 'ARRAY' ? @{$params{$driverType}} : $params{$driverType} )
            {
                my %h = %$p;
                my ($source_name, $engine_name) = @h{qw/source_name engine_name/};
                delete @h{qw/source_name engine_name/};
                $p->{type} = $driverType;
                $list{$driverType}->{$source_name}
                    = Ambrosia::core::ClassFactory::create_object(
                        'Ambrosia::DataProvider::' . $driverType . '::' . $engine_name, \%h);
            }
        }
        $STORAGE{$key} = $package->new(_list => \%list);
    }

    return $STORAGE{$key};
}

sub storage
{
    my $key = shift || $PROCESS_MAP{$$};
    assert {$key} 'First access to Ambrosia::DataProvider without assign to storage.';
    return __PACKAGE__->instance($key);
}

sub destroy
{
    %STORAGE = ();
}

sub add_source
{
    my $self = shift;

    my %params = @_ == 1 ? %{$_[0]} : @_;

    my %list = ();
    foreach my $driverType ( keys %params )
    {
        foreach my $p ( ref $params{$driverType} eq 'ARRAY' ? @{$params{$driverType}} : $params{$driverType} )
        {
            my %h = %$p;
            my ($source_name, $engine_name) = @h{qw/source_name engine_name/};
            delete @h{qw/source_name engine_name/};
            $list{$driverType}->{$source_name}
                = Ambrosia::core::ClassFactory::create_object(
                    'Ambrosia::DataProvider::' . $driverType . '::' . $engine_name, \%h);
        }
    }
    $self->_list->{$_} = $list{$_} foreach ( keys %list);
}

sub driver #(driverType, sourceName)
{
    assert {$_[0] && $_[1] && $_[2]} "bad usage: driver(@_)";
    shift()->_list->{+shift}->{+shift};
}

sub foreach
{
    my $self = shift;
    my $function = shift;
    foreach my $type ( keys %{$self->_list} )
    {
        foreach my $name ( keys %{$self->_list->{$type}} )
        {
            if ( ref $function )
            {
                $function->($self->_list->{$type}->{$name}, $type, $name, @_);
            }
            else
            {
                if ( $self->_list->{$type}->{$name}->can($function) )
                {
                    $self->_list->{$type}->{$name}->$function(@_);
                }
                else
                {
                    croak("Unknown method $function in driver $name of type $type");
                }
            }
        }
    }
}

1;

__END__

=head1 NAME

Ambrosia::DataProvider - a container for data sources. (Singleton)

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::DataProvider;
    my $confDS = {
        DBI => [
            {
                engine_name   => 'DB::mysql',
                source_name  => 'Employee',
                engine_params => 'database=EmployeeDB;host=localhost;',
                user         => 'test',
                password     => 'test',
                additional_params => { AutoCommit => 0, RaiseError => 1, LongTruncOk => 1 },
                additional_action => sub { my $dbh = shift; $dbh->do('SET NAMES utf8')},
            },
            #........
        ],
        IO => [
            {
                engine_name => 'IO::CGI',
                source_name => 'cgi',
                engine_params => {
                    header_params => {
                            '-Pragma' => 'no-cache',
                            '-Cache_Control' => 'no-cache, must-revalidate, no-store'
                        }
                    }
            }
        ],
        
    };

    instance Ambrosia::Storage(application_name => $confDS);
    Ambrosia::DataProvider::assign 'application_name';


=head1 DESCRIPTION

Ambrosia::DataProvider is a container for data sources. (Singleton)

For more information see:

=over

=item L<Ambrosia::DataProvider::DBIDriver>

=item L<Ambrosia::DataProvider::IODriver>

=item L<Ambrosia::DataProvider::ResourceDriver>

=back

=head1 SUBROUTINES/METHODS

=head2 instance

Static subrutine.
Creates a singleton container.

    instance('storage_name' => $config_data)

    Structure of config data:

    config = {
        DRIVER_TYPE => [
                engine_name   => 'ENGINE_FOR_DRIVER_TYPE',
                source_name  => 'UNIQ_NAME_FOR_SOURCE_DATA',
                engine_params => 'PARAMS_FOR_ENGINE',
                %ANY_ADDITIONAL_PARAMS_FOR_DRIVER_TYPE
        ]
    }

=head2 assign

Static subrutine.
Assigns a current process to a named data source from container.
    assign('storage_name')

=head2 storage

Static subrutine.
Returns container assigned to current process.
    storage()
    storage('storage_name')

=head2 add_source

Method.
Adds or changes a data source into container.
    storage()->add_source($config_data)

=head2 driver

Method.
Returns a driver from container by driver type and source name.
    storage()->driver($driverType, $sourceName)

=cut

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Ambrosia::core::ClassFactory>
L<Ambrosia::Assert>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
