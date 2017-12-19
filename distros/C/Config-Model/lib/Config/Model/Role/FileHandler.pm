#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Role::FileHandler;
$Config::Model::Role::FileHandler::VERSION = '2.116';
# ABSTRACT: role to read or write configuration files

use strict;
use warnings;
use Carp;
use 5.10.0;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

use Mouse::Role;
requires 'config_dir';

my $logger = get_logger("FileHandler");

# used only for tests
my $__test_home = '';
sub _set_test_home { $__test_home = shift; }

sub get_tuned_config_dir {
    my ($self, %args) = @_;

    my $dir = $args{os_config_dir}{$^O} || $args{config_dir} || $self->config_dir || '';
    if ( $dir =~ /^~/ ) {
        # because of tests, we can't rely on Path::Tiny's tilde processing
        my $home = $__test_home || File::HomeDir->my_home;
        $dir =~ s/^~/$home/;
    }

    $dir .= '/' if $dir and $dir !~ m(/$);

    return $dir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Role::FileHandler - role to read or write configuration files

=head1 VERSION

version 2.116

=head1 SYNOPSIS

=head1 DESCRIPTION

Role used to handle configuration files on the behalf of a backend.

=head1 METHODS

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
