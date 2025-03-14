#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Role::FileHandler 2.155;

# ABSTRACT: role to read or write configuration files

use strict;
use warnings;
use Carp;
use 5.10.0;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);
use Path::Tiny;

use Mouse::Role;

use Config::Model::TypeConstraints;

my $logger = get_logger("FileHandler");

# used only for tests
sub _set_test_home {
    Config::Model::TypeConstraints::_set_test_home(shift) ;
    return;
}

# Configuration directory where to read and write files. This value
# does not override the configuration directory specified in the model
# data passed to read and write functions.
has config_dir => ( is => 'ro', isa => 'Config::Model::TypeContraints::Path', required => 0 );

sub get_tuned_config_dir {
    my ($self, %args) = @_;

    my $dir = $args{os_config_dir}{$^O} || $args{config_dir} || $self->config_dir || '';
    if ( $dir =~ /^~/ ) {
        # because of tests, we can't rely on Path::Tiny's tilde processing
        # TODO: should this be my_config ? May be once this is done:
        # https://github.com/perl5-utils/File-HomeDir/pull/5/files
        # beware of compat and migration issues
        my $home =  &Config::Model::TypeConstraints::_get_test_home || File::HomeDir->my_home;
        $dir =~ s/^~/$home/;
    }

    return $args{root} ? $args{root}->child($dir)
        : $dir ?  path($dir)
        :         path ('.');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Role::FileHandler - role to read or write configuration files

=head1 VERSION

version 2.155

=head1 SYNOPSIS

=head1 DESCRIPTION

Role used to handle configuration files on the behalf of a backend.

=head1 METHODS

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
