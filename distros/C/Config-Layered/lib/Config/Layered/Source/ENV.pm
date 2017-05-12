package Config::Layered::Source::ENV;
use warnings;
use strict;
use Storable qw( dclone );
use base 'Config::Layered::Source';

sub get_config {
    my ( $self ) = @_;

    my $struct = dclone($self->layered->default);
    my $config = {};
    $self->args->{prefix} ||= "CONFIG";

    for my $key ( keys %{$struct} ) {
        $config->{$key} = $ENV{ $self->args->{prefix} . "_" . uc($key) }
            if exists $ENV{ $self->args->{prefix} . "_" . uc($key) };
    }

    for my $key ( @{$self->args->{params}} ) {
        $config->{$key} = $ENV{ $self->args->{prefix} . "_" . uc($key) }
            if exists $ENV{ $self->args->{prefix} . "_" . uc($key) };
    }

    return $config;
}

1;

=head1 NAME

Config::Layered::Source::ENV - The Environment Variable Source

=head1 DESCRIPTION

The ENV source provides configuration through environment variables.

For each top-level key in the default data structure, it checks for the
environment variable C<CONFIG_$KEY> where $KEY is the name of the key used
in the default data structure.

=head1 EXAMPLE

    my $config = Config::Layered->load_config( 
        default => {
            foo         => "bar",
            blee        => "baz",
            bax         => {
                chicken => "eggs",
            }
        }
    );

With the above configuration, the following keys will be checked:

=over 4

=item * CONFIG_FOO

=item * CONFIG_BLEE

=item * CONFIG_BAX

=back

The following would *NOT* be checked:

=over 4

=item * CONFIG_CHICKEN

=back

Given the above default data structure, a command run as 
C<CONFIG_FOO="Hello World" ./myprogram> would result in a
C<$config> structure like this:


    {
        foo         => "Hello World",
        blee        => "baz",
        bax         => {
            chicken => "eggs",
    }

=head1 SOURCE ARGUMENTS

=over 4

=item * params is an array ref of keys to check Default: Keys of the default
data structure.

=item * prefix is a word prepended to your key that is used to check 
C<$ENV{$prefix . "_" . uc($key) }>.

=back

Example:

    Config::Layered->load_config(
        sources => [ 
            'ENV' => { prefix => "MYAPP", params => [qw( bar blee )] } 
        ],
        default => { debug => 0, verbose => 1 },
    );

The following keys would be checked:

=over 4

=item * MYAPP_BAR

=item * MYAPP_BLEE

=item * MYAPP_DEBUG

=item * MYAPP_VERBOSE

=back

=cut
