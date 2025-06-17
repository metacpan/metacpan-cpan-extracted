use utf8;
package CPAN::Testers::Schema::Base;
our $VERSION = '0.028';
# ABSTRACT: Base module for importing standard modules, features, and subs

#pod =head1 SYNOPSIS
#pod
#pod     # lib/CPAN/Testers/Schema/MyModule.pm
#pod     package CPAN::Testers::Schema::MyModule;
#pod     use CPAN::Testers::Schema::Base;
#pod
#pod     # t/mytest.t
#pod     use CPAN::Testers::Schema::Base 'Test';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module collectively imports all the required features and modules
#pod into your module. This module should be used by all modules in the
#pod L<CPAN::Testers::Schema> distribution. This module should not be used by
#pod modules in other distributions.
#pod
#pod This module imports L<strict>, L<warnings>, and L<the sub signatures
#pod feature|perlsub/Signatures>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Import::Base>
#pod
#pod =cut

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    'strict', 'warnings',
    feature => [qw( :5.24 signatures )],
    '>-warnings' => [qw( experimental::signatures )],
);

our %IMPORT_BUNDLES = (
    Result => [
        'DBIx::Class::Candy',
    ],
    ResultSet => [
        'DBIx::Class::Candy::ResultSet',
    ],
    Test => [
        'Test::More', 'Test::Lib',
        'Local::Schema' => [qw( prepare_temp_schema )],
    ],
    Test2 => [
        'Test2::V0', 'Test::Lib',
        'Local::Schema' => [qw( prepare_temp_schema )],
    ],
);

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Base - Base module for importing standard modules, features, and subs

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    # lib/CPAN/Testers/Schema/MyModule.pm
    package CPAN::Testers::Schema::MyModule;
    use CPAN::Testers::Schema::Base;

    # t/mytest.t
    use CPAN::Testers::Schema::Base 'Test';

=head1 DESCRIPTION

This module collectively imports all the required features and modules
into your module. This module should be used by all modules in the
L<CPAN::Testers::Schema> distribution. This module should not be used by
modules in other distributions.

This module imports L<strict>, L<warnings>, and L<the sub signatures
feature|perlsub/Signatures>.

=head1 SEE ALSO

L<Import::Base>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
