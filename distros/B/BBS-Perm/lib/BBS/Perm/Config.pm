package BBS::Perm::Config;

use warnings;
use strict;
use Carp;

BEGIN {
    local $@;
    eval { require YAML::Syck; };
    if ($@) {
        require YAML;
        *_LoadFile = *YAML::LoadFile;
        *_DumpFile = *YAML::DumpFile;
    }
    else {
        *_LoadFile = *YAML::Syck::LoadFile;
        *_DumpFile = *YAML::Syck::DumpFile;
    }
}

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, ref $class || $class;
    my %opt = @_;
    if ( $opt{file} ) {
        $self->{file} = $opt{file};
        $self->load( $opt{file} );
    }
    return $self;
}

sub load {
    my $self = shift;
    $self->{config} = _LoadFile(shift);
    $self->_tidy;
}

sub _tidy {
    my $self = shift;
    for my $site ( grep { $_ ne 'global' } keys %{ $self->{config} } ) {
        for ( keys %{ $self->{config}{global} } ) {
            $self->{config}{$site}{$_} = $self->{config}{global}{$_}
              unless defined $self->{config}{$site}{$_};
        }
    }
}

sub sites {
    my $self = shift;
    return grep { $_ ne 'global' } keys %{ $self->{config} };
}

sub setting {
    my ( $self, $site ) = @_;
    return $self->{config}{$site};
}

sub file {
    return shift->{file};
}

1;

__END__

=head1 NAME

BBS::Perm::Config - wrap a BBS::Perm configuration file 

=head1 SYNOPSIS

    use BBS::Perm::Config;
    my $conf = BBS::Perm::Config->new( file => 'config.yml' );
    my $setting = $conf->setting('newsmth');
    my $file = $conf->file;
    my @sites = $conf->sites;

=head1 DESCRIPTION

BBS::Perm::Config is a simple wrapper of the configuration file for BBS::Perm.

BBS::Perm's configuraton file is a normal YAML file. See t/config.yml for the
cunstruct.

=head1 INTERFACE

=over 4

=item new ( file => $file )

create a new BBS::Perm::Config module.

=item load( $file )

load $file, which is a YAML file.


=item setting ( $site )

return corresponding settings for $site;

=item sites

return a list of our site names.

=item file

return config file name

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, sunnavy C<< <sunnavy@gmail.com> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

