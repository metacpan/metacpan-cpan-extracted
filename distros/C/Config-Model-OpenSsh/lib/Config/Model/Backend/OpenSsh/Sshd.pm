#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh::Sshd v2.7.9.1;

use Mouse ;
extends "Config::Model::Backend::Any" ;

with (
    'Config::Model::Backend::OpenSsh::Role::Reader',
    'Config::Model::Backend::OpenSsh::Role::Writer',
);

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

# now the write part
sub write {
    my $self = shift;
    $self->ssh_write(@_) ;
}

sub _write_line {
    return sprintf("%-20s %s\n",@_) ;
}


no Mouse;

1;

# ABSTRACT: Backend for sshd configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh::Sshd - Backend for sshd configuration files

=head1 VERSION

version v2.7.9.1

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This class provides a backend to read and write sshd client configuration files.

This class is a plugin for L<Config::Model::BackendMgr>.

=head1 SEE ALSO

L<cme>, L<Config::Model>,

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2019 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
