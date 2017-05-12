package Bio::Tools::Run::QCons::Types;
{
  $Bio::Tools::Run::QCons::Types::VERSION = '0.112881';
}

# ABSTRACT: Type library for Bio::Tools::Run::QCons

use strict;
use warnings;

use Mouse::Util::TypeConstraints;
use namespace::autoclean;

use IPC::Cmd qw(can_run);

subtype 'Executable'
    => as 'Str',
    => where { _exists_executable($_) },
    => message { "Can't find $_ in your PATH or not an executable" };

sub _exists_executable {
    my $candidate = shift;

    return 1 if -x $candidate;

    return scalar can_run($candidate);
}

no Mouse::Util::TypeConstraints;

__END__
=pod

=head1 NAME

Bio::Tools::Run::QCons::Types - Type library for Bio::Tools::Run::QCons

=head1 VERSION

version 0.112881

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

