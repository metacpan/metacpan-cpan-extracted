package CPANPLUS::Config::BaseEnv;
$CPANPLUS::Config::BaseEnv::VERSION = '0.06';
#ABSTRACT: Set the environment for the CPANPLUS base dir

use strict;
use File::Spec;

sub setup {
  my $conf = shift;
  $conf->set_conf( base => File::Spec->catdir( $ENV{PERL5_CPANPLUS_BASE}, '.cpanplus' ) )
	  if $ENV{PERL5_CPANPLUS_BASE};
  return 1;
}

'YACSmoking';

__END__

=pod

=encoding UTF-8

=head1 NAME

CPANPLUS::Config::BaseEnv - Set the environment for the CPANPLUS base dir

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  export PERL5_CPANPLUS_BASE=/home/moo/perls/conf/perl-5.8.9/

=head1 DESCRIPTION

CPANPLUS::Config::BaseEnv is a L<CPANPLUS::Config> file that allows the CPANPLUS user to
specify where L<CPANPLUS> gets its configuration from.

Setting the environment variable C<PERL5_CPANPLUS_BASE> to a path location, determines
where the C<.cpanplus> directory will be located.

=head1 METHODS

=over

=item C<setup>

Called by L<CPANPLUS::Configure>.

=back

=head1 KUDOS

Contributions and patience from Jos Boumans the L<CPANPLUS> guy!

=head1 SEE ALSO

L<CPANPLUS>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams and Jos Boumans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
