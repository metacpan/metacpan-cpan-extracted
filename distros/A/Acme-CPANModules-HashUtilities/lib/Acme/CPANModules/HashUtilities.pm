package Acme::CPANModules::HashUtilities;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-01'; # DATE
our $DIST = 'Acme-CPANModules-HashUtilities'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => "Modules that manipulate hashes",
    description => <<'_',

Most of the time, you don't need modules to manipulate hashes; Perl's built-in
facilities suffice. The modules below, however, are sometimes convenient. This
list is organized by task.

## Creating an alias to another variable

<pm:Hash::Util>'s C<hv_store> allows you to store an alias to a variable in a
hash instead of copying the value. This means, if you set a hash value, it will
instead set the value of the aliased variable instead. Copying from Hash::Util's
documentation:

    my $sv = 0;
    hv_store(%hash,$key,$sv) or die "Failed to alias!";
    $hash{$key} = 1;
    print $sv; # prints 1


## Getting internal information

Aside from creating restricted hash, <pm:Hash::Util> also provides routines to
get information about hash internals, e.g. `hash_seed()`, `hash_value()`,
`bucket_info()`, `bucket_stats()`, etc.


## Merging

Merging hashes is usually as simple as:

    my %merged = (%hash1, %hash2, %hash3);

but sometimes you want different merging behavior, particularly in case where
the same key is found in more than one hash. See the various hash merging
modules:

<pm:Hash::Merge>

<pm:Data::ModeMerge>

<pm:Hash::Union>


## Providing default value for non-existing keys

<pm:Hash::WithDefault>


## Restricting keys

Perl through <pm:Hash::Util> (a core module) allows you to restrict what keys
can be set in a hash. This can be used to protect against typos and for simple
validation. (For more complex validation, e.g. allowing patterns of valid keys
and/or rejecting patterns of invalid keys, you can use the tie mechanism.)


## Reversing (inverting)

Reversing a hash (where keys become values and values become keys) can be done
using the builtin's `reverse` (which actually just reverse a list):

    %hash = (a=>1, b=>2);
    %reverse = reverse %hash; # => (2=>"b", 1=>"a")

Since the new keys can contain duplicates, this can "destroy" some old keys:

    %hash = (a=>1, b=>1);
    %reverse = reverse %hash; # => sometimes (1=>"b"), sometimes (1=>"a")

<pm:Hash::MoreUtil>'s `safe_reverse` allows you to specify a coderef that can
decide whether to ignore overwriting, croak, or whatever else.


## Slicing (creating subset)

<pm:Hash::MoreUtils>'s `slice_*` functions.

<pm:Hash::Subset>

<pm:Hash::Util::Pick>


## Tying

The tie mechanism, although relatively slow, allows you to create various kinds
of "magical" hash that does things whenever you get or set keys.


_
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Modules that manipulate hashes

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::HashUtilities - Modules that manipulate hashes

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::HashUtilities (from Perl distribution Acme-CPANModules-HashUtilities), released on 2020-03-01.

=head1 DESCRIPTION

Modules that manipulate hashes.

Most of the time, you don't need modules to manipulate hashes; Perl's built-in
facilities suffice. The modules below, however, are sometimes convenient. This
list is organized by task.

=head2 Creating an alias to another variable

L<Hash::Util>'s C<hv_store> allows you to store an alias to a variable in a
hash instead of copying the value. This means, if you set a hash value, it will
instead set the value of the aliased variable instead. Copying from Hash::Util's
documentation:

 my $sv = 0;
 hv_store(%hash,$key,$sv) or die "Failed to alias!";
 $hash{$key} = 1;
 print $sv; # prints 1

=head2 Getting internal information

Aside from creating restricted hash, L<Hash::Util> also provides routines to
get information about hash internals, e.g. C<hash_seed()>, C<hash_value()>,
C<bucket_info()>, C<bucket_stats()>, etc.

=head2 Merging

Merging hashes is usually as simple as:

 my %merged = (%hash1, %hash2, %hash3);

but sometimes you want different merging behavior, particularly in case where
the same key is found in more than one hash. See the various hash merging
modules:

L<Hash::Merge>

L<Data::ModeMerge>

L<Hash::Union>

=head2 Providing default value for non-existing keys

L<Hash::WithDefault>

=head2 Restricting keys

Perl through L<Hash::Util> (a core module) allows you to restrict what keys
can be set in a hash. This can be used to protect against typos and for simple
validation. (For more complex validation, e.g. allowing patterns of valid keys
and/or rejecting patterns of invalid keys, you can use the tie mechanism.)

=head2 Reversing (inverting)

Reversing a hash (where keys become values and values become keys) can be done
using the builtin's C<reverse> (which actually just reverse a list):

 %hash = (a=>1, b=>2);
 %reverse = reverse %hash; # => (2=>"b", 1=>"a")

Since the new keys can contain duplicates, this can "destroy" some old keys:

 %hash = (a=>1, b=>1);
 %reverse = reverse %hash; # => sometimes (1=>"b"), sometimes (1=>"a")

L<Hash::MoreUtil>'s C<safe_reverse> allows you to specify a coderef that can
decide whether to ignore overwriting, croak, or whatever else.

=head2 Slicing (creating subset)

L<Hash::MoreUtils>'s C<slice_*> functions.

L<Hash::Subset>

L<Hash::Util::Pick>

=head2 Tying

The tie mechanism, although relatively slow, allows you to create various kinds
of "magical" hash that does things whenever you get or set keys.

=head1 INCLUDED MODULES

=over

=item * L<Hash::Util>

=item * L<Hash::Merge>

=item * L<Data::ModeMerge>

=item * L<Hash::Union>

=item * L<Hash::WithDefault>

=item * L<Hash::MoreUtil>

=item * L<Hash::MoreUtils>

=item * L<Hash::Subset>

=item * L<Hash::Util::Pick>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries HashUtilities | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=HashUtilities -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-HashUtilities>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-HashUtilities>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-HashUtilities>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
