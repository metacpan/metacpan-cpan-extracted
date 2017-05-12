package App::Commando::Option;

use strict;
use warnings;

use Moo;

has 'config_key'    => ( is => 'ro' );
has 'description'   => ( is => 'ro' );
has 'long'          => ( is => 'ro' );
has 'short'         => ( is => 'ro' );
has 'spec'          => ( is => 'ro' );

sub BUILDARGS {
    my ($class, $config_key, @info) = @_;

    my $buildargs = {
        config_key  => $config_key,
        long        => '',
        short       => '',
    };

    # Getopt::Long regular expression to match argument specification
    my $spec_re = qr(
        # Either modifiers ...
        [!+]
        |
        # ... or a value/dest/repeat specification
        [=:] [ionfs] [@%]? (?: \{\d*,?\d*\} )?
        |
        # ... or an optional-with-default spec
        : (?: -?\d+ | \+ ) [@%]?
    )x;

    for my $arg (@info) {
        if ($arg =~ /^-/) {
            if ($arg =~ /^--/) {
                $buildargs->{long} = $arg;
            }
            else {
                $buildargs->{short} = $arg;
            }
        }
        elsif ($arg =~ $spec_re) {
            $buildargs->{spec} = $arg;
        }
        else {
            $buildargs->{description} = $arg;
        }
    }

    return $buildargs;
}

sub for_get_options {
    my ($self) = @_;

    return
        join('|',
            grep { /\S/ } # Exclude empty strings
                map { s/^-+//; $_ } # Strip off leading dashes
                    map { $self->$_ } qw( short long )) .
        ($self->spec || '');
}

sub switches {
    my ($self) = @_;

    return [ $self->short, $self->long ];
}

sub formatted_switches {
    my ($self) = @_;

    my $output = join(', ', 
        sprintf("%10s", $self->switches->[0]),
        sprintf("%-13s", $self->switches->[-1]));
    $output =~ s/ , /   /g;
    $output =~ s/,   /    /g;

    return $output;
}

sub as_string {
    my ($self) = @_;
    
    return $self->formatted_switches . '  ' . $self->description;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Commando::Option

=head1 VERSION

version 0.012

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
