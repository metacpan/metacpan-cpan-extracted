package Data::Crumbr::Default::Default;
$Data::Crumbr::Default::Default::VERSION = '0.1.1';
# ABSTRACT: "Default" profile for Data::Crumbr::Default

# Default is default... nothing is set here!
sub profile { return {}; }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Crumbr::Default::Default - "Default" profile for Data::Crumbr::Default

=head1 VERSION

version 0.1.1

=head1 DESCRIPTION

Profile for default (exact) encoder

=head1 INTERFACE

=over

=item B<< profile >>

   my $profile = Data::Crumbr::Default::Default->profile();

returns a default profile, i.e. encoder data to be used to instantiate a
Data::Crumbr::Default encoder. See L</Data::Crumbr> for details about
this profile.

=back

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Flavio Poletti <polettix@cpan.org>

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
