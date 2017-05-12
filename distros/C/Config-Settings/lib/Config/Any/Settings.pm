package Config::Any::Settings;

use Config::Any::Base;
use base qw/Config::Any::Base/;

use Config::Settings;

use strict;
use warnings;

sub extensions { qw/settings/ }

sub load {
  my ($class,$file) = @_;

  my $parser = Config::Settings->new;

  return $parser->parse_file ($file);
}

1;

__END__

=pod

=head1 NAME

Config::Any::Settings - Config::Any glue for Config::Settings

=head1 SYNOPSIS

  See Config::Any for examples

=head1 SEE ALSO

=over 4

=item L<Config::Any>

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>berle@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

