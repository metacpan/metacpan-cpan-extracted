package ACME::Error::SHOUT;

use strict;
no  strict 'refs';

use vars qw[$VERSION];
$VERSION = '0.02';

*warn_handler = *die_handler = sub {
  my @error = @_;
  $error[$_] =~ s/.$/!/g for 0 .. $#error;
  return map uc, @error;
};

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

ACME::Error::SHOUT - ACME::Error Backend to Scream Errors

=head1 SYNOPSIS

  use ACME::Error SHOUT;

=head1 DESCRIPTION

This backend converts your errors to screams.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2002 Casey R. West <casey@geeknest.com>.  All
rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1).

=cut
