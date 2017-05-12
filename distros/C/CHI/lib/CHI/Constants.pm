package CHI::Constants;
$CHI::Constants::VERSION = '0.60';
use strict;
use warnings;
use base qw(Exporter);

my @all_constants = do {
    no strict 'refs';
    grep { exists &$_ } keys %{ __PACKAGE__ . '::' };
};
our @EXPORT_OK = (@all_constants);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant CHI_Meta_Namespace => '_CHI_METACACHE';
use constant CHI_Max_Time       => 0xffffffff;

1;

__END__

=pod

=head1 NAME

CHI::Constants - Internal constants

=head1 VERSION

version 0.60

=head1 DESCRIPTION

These are constants for internal CHI use.

=head1 SEE ALSO

L<CHI|CHI>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
