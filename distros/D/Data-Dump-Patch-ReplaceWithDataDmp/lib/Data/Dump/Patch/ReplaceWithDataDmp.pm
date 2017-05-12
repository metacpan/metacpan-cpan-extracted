package Data::Dump::Patch::ReplaceWithDataDmp;

our $DATE = '2015-11-05'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
no warnings;
#use Log::Any '$log';

use Module::Patch 0.12 qw();
use Data::Dmp;
use base qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'replace',
                sub_name => 'dump',
                code => sub {
                    if (defined wantarray) { dmp(@_) } else { dd(@_) }
                },
            },
        ],
    };
}

1;
# ABSTRACT: Replace Data::Dump's dump() with Data::Dmp's version

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::Patch::ReplaceWithDataDmp - Replace Data::Dump's dump() with Data::Dmp's version

=head1 VERSION

This document describes version 0.01 of Data::Dump::Patch::ReplaceWithDataDmp (from Perl distribution Data-Dump-Patch-ReplaceWithDataDmp), released on 2015-11-05.

=head1 SYNOPSIS

 use Data::Dump::Patch::ReplaceWithDataDmp;

=head1 DESCRIPTION

This patch module is for testing. It will replace L<Data::Dump>'s C<dump()>
routine with one that uses L<Data::Dmp>, so any other code that uses Data::Dump
will dump using Data::Dmp instead.

=for Pod::Coverage ^(patch_data)$

=head1 SEE ALSO

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Patch-ReplaceWithDataDmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-Patch-ReplaceWithDataDmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Patch-ReplaceWithDataDmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
