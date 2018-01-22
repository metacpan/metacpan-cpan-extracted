use utf8;
package CPAN::Testers::API::Base;
our $VERSION = '0.023';
# ABSTRACT: Base module for importing standard modules, features, and subs

#pod =head1 SYNOPSIS
#pod
#pod     # lib/CPAN/Testers/API/MyModule.pm
#pod     package CPAN::Testers::API::MyModule;
#pod     use CPAN::Testers::API::Base;
#pod
#pod     # t/mytest.t
#pod     use CPAN::Testers::API::Base 'Test';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module collectively imports all the required features and modules
#pod into your module. This module should be used by all modules in the
#pod L<CPAN::Testers::API> distribution. This module should not be used by
#pod modules in other distributions.
#pod
#pod This module imports L<strict>, L<warnings>, and L<the sub signatures
#pod feature|perlsub/Signatures>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Import::Base>
#pod
#pod =back
#pod
#pod =cut

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    'strict', 'warnings',
    feature => [qw( :5.24 signatures refaliasing )],
    '-warnings' => [qw( experimental::signatures experimental::refaliasing )],
);

our %IMPORT_BUNDLES = (
    Test => [
        'Test::More', 'Test::Lib', 'Test::Mojo',
        'Local::Schema' => [qw( prepare_temp_schema )],
        'Local::App' => [qw( prepare_test_app )],
    ],
);

1;

__END__

=pod

=head1 NAME

CPAN::Testers::API::Base - Base module for importing standard modules, features, and subs

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    # lib/CPAN/Testers/API/MyModule.pm
    package CPAN::Testers::API::MyModule;
    use CPAN::Testers::API::Base;

    # t/mytest.t
    use CPAN::Testers::API::Base 'Test';

=head1 DESCRIPTION

This module collectively imports all the required features and modules
into your module. This module should be used by all modules in the
L<CPAN::Testers::API> distribution. This module should not be used by
modules in other distributions.

This module imports L<strict>, L<warnings>, and L<the sub signatures
feature|perlsub/Signatures>.

=head1 SEE ALSO

=over

=item L<Import::Base>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
