package # hide from CPAN
    Catalyst::ActionRole::NotCachableHeaders;
BEGIN {
  $Catalyst::ActionRole::NotCachableHeaders::VERSION = '0.02';
}

use strict;
use Moose::Role;

sub BUILD {
    die "please use Catalyst::ActionRole::NotCacheableHeaders instead"
       ." (typo in package name)";
}

no Moose::Role;
1; # End of Catalyst::ActionRole::NotCachableHeaders



=pod

=encoding utf-8

=head1 NAME

Catalyst::ActionRole::NotCachableHeaders

=head1 VERSION

version 0.02

=for Pod::Coverage   BUILD

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



