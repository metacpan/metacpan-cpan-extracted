package Config::Layered::Source::Getopt;
use warnings;
use strict;
use Storable qw( dclone );
use Getopt::Long;
use Scalar::Util qw( looks_like_number );
use base 'Config::Layered::Source';

sub get_config {
    my ( $self ) = @_;
    my @want;

    my $struct = dclone($self->layered->default);

    for my $key ( keys %{$struct} ) {
        if ( ref $struct->{$key} eq 'ARRAY' ) {
            push @want, "$key=s@";
        } elsif ( ref $struct->{$key} eq 'HASH' ) {
            push @want, "$key=s%"
        } elsif ( _is_bool($struct->{$key}) ) {
            push @want, "$key!";
        } else {
            push @want, "$key=s";
        }
    }

    my %config;
    GetOptions( \%config, @want );
    return { %config };
}

sub _is_bool {
    my ( $any ) = @_;
    return 0 unless looks_like_number($any);
    return 1 if $any == 1;
    return 1 if $any == 0;
    return 0;
}

1;

=head1 NAME

Config::Layered::Source::Getopt - The Command Line Source

=head1 DESCRIPTION

The Getopt source provides access to Getopt::Long and will configure
it based on the default data structure.

The configuration of the Getopt::Long options is done in the following
way:

=over 4

=item * If the default value of a key is 0 or 1, it is treated as
a boolean, and the C<key!> directive is used.  This will enable C<--no*> 
options to work as expected.

=item * If the value is a hash reference, the C<key%> directive is used,
and options are configured as C<--key name=value>.  New hash keys will
be added, previously used hash keys (i.e. default configuration, previously
run sources) will be replaced.

=item * If the value if an array reference, the C<key@> directive is used,
and options are configured as C<--key value --key value>.  An array entered
by this source will replace a previously entered array (i.e. default
configuration, previous run sources).

=item * All other situations will result in a simple string, C<key=s>.

=head1 EXAMPLE

    my $config = Config::Layered->load_config( 
        sources => [ 'ConfigAny' => { file => "/etc/myapp" } ],
        default => {
            foo         => "bar",
            blee        => 1,
            size        => 20,
            bax         => { chicken => "eggs", }
            baz         => [ wq( foo bar blee ) ]
        }
    );

The above data structure would create the following Getopt::Long 
configuration:

    Getopts( \%config,
        "foo=s",
        "blee!",
        "size",
        "bax%",
        "baz@",
    );
    
=head1 SOURCE ARGUMENTS

=over 4

=item * None

=back

=cut
