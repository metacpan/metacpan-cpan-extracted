package Acme::CPANAuthors::Register;

use strict;
use warnings;

sub import {
  my ($class, %authors) = @_;

  my $caller = caller;
  {
    no strict 'refs';
    no warnings 'redefine';
    *{"$caller\::authors"} = sub { wantarray ? %authors : \%authors };

    (my $category = $caller) =~ s/^Acme::CPANAuthors:://;
    *{"$caller\::category"} = sub { $category };
  }
}

1;

__END__

=head1 NAME

Acme::CPANAuthors::Register

=head1 SYNOPSIS

  package Acme::CPANAuthors::YourGroup
  use strict;
  use warnings;
  our $VERSION = '0.071226';
  use Acme::CPANAuthors::Register (
    ID  => 'Real Name',
  );

  1;

  # then you can get authors list like these.
  # note that ->authors is context sensitive)

  my %hash    = Acme::CPANAuthors::YourGroup->authors;
  my $hashref = Acme::CPANAuthors::YourGroup->authors;

=head1 DESCRIPTION

This is used to register Pause IDs and real names of those who belong to your country/local perl mongers group/your company etc.

=head1 SEE ALSO

L<Acme::CPANAuthors>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
