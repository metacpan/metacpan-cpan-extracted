package Config::Layered::Source::ConfigAny;
use warnings;
use strict;
use Config::Any;
use base 'Config::Layered::Source';

sub get_config {
    my ( $self ) = @_;

    my $file = $self->args->{file};
    $file = $self->layered->{file} unless $file;

    return {} unless defined $file;

    my $config = Config::Any->load_stems( { 
        stems => [ $file ],
        use_ext => 1, 
    });
        
    return $config->[0]->{ (keys %{$config->[0]})[0] }
        if @{$config} == 1;

    return {}; # If we couldn't load a config file.
}

1;

=head1 NAME

Config::Layered::Source::ConfigAny - The Configuration File Source

=head1 DESCRIPTION

The ConfigAny source provices access to running ConfigAny on a given
file stem.

=head1 EXAMPLE

    my $config = Config::Layered->load_config( 
        sources => [ 'ConfigAny' => { file => "/etc/myapp" } ],
        default => {
            foo         => "bar",
            blee        => "baz",
            bax         => {
                chicken => "eggs",
            }
        }
    );


Provided a file C</etc/myapp> with the following content:

    foo: this
    bax:
        chicken: no-eggs
        pork:    chops

The following data structure in C<$config> would be the result:

    {
        foo         => "this",
        blee        => "baz",
        bax         => {
            chicken => "no-eggs",
            pork    => "chops",
    }
    
=head1 SOURCE ARGUMENTS

=over 4

=item * file is a string which will be passed to Config::Any as a
file stem.

=back

=head1 GLOBAL ARGUMENTS

=over 4

=item * file is a string which will be passed to Config::Any as a
file stem -- file as a source argument will take precedence.

=back

=cut
