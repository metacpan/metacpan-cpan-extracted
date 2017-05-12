package Catmandu::Fix::Datahub;

use strict;
use 5.008_005;
our $VERSION = '0.03';

1;
__END__

=encoding utf-8

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-Fix-Datahub"><img src="https://travis-ci.org/thedatahub/Catmandu-Fix-Datahub.svg?branch=master"></a>

Catmandu::Fix::Datahub - Utility functions and generic fixes developed for the Datahub project

=head1 SYNOPSIS

L<Catmandu::Fix::Datahub::Util>:

  use Catmandu::Fix::Datahub::Util;

L<Catmandu::Fix::Bind::each>:

  do each(path: demo, var: d)
    
    copy_field(d.key, var.$append)
  
  end

=head1 DESCRIPTION

=head2 L<Catmandu::Fix::Datahub::Util>

Utility functions for use in Catmandu fixes.

=over 4

=item C<declare_source($fixer, $var, $declared_var)>

=item C<walk($fixer, $path, $key, $h)>

=back

=head2 L<Catmandu::Fix::Bind::each>

A bind to iterate over a hash.

=head1 AUTHOR

Pieter De Praetere E<lt>pieter@packed.beE<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>

=cut
