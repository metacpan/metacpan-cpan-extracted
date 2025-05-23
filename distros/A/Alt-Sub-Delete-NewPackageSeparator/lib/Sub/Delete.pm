## no critic: TestingAndDebugging::RequireUseStrict
use 5.008003;

package
    Sub::Delete; # hide from PAUSE indexing

$VERSION = '1.00002';
@EXPORT = delete_sub;

use Exporter 5.57 'import';
use constant point0 => 0+$] eq 5.01;

# This sub must come before any lexical vars.
sub strict_eval($) {
 local %^H if point0;
 local *@;
 use#
  strict 'vars';
 local $SIG{__WARN__} = sub {};
 eval shift
}

my %sigils = qw( SCALAR $  ARRAY @  HASH % );

sub delete_sub {
	my $sub = shift;
	my($stashname, $key) = $sub =~ /(.*::)((?:(?!::).)*)\z/s
		? ($1,$2) : (caller()."::", $sub);
	exists +(my $stash = \%$stashname)->{$key} or return;
	ref $stash->{$key} eq 'SCALAR' and  # perl5.10 constant
		delete $stash->{$key}, return;
	my $globname = "$stashname$key";
	my $glob = *$globname; # autovivify the glob in case future perl
	defined *$glob{CODE} or return;  # versions add new funny stuff
	my $check_importedness
	 = $stashname =~ /^(?:(?!\d)\w*(?:::\w*)*)\z/
	   && $key    =~ /^(?!\d)\w+\z/;
	my %imported_slots;
	my $package;
	if($check_importedness) {
		$package = substr $stashname, 0, -2;
		for (qw "SCALAR ARRAY HASH") {
			defined *$glob{$_} or next;
			$imported_slots{$_} = strict_eval
			  "package $package; 0 && $sigils{$_}$key; 1"
		}
	}
        delete $stash->{$key};
	keys %imported_slots == 1 and exists $imported_slots{SCALAR}
	 and !$imported_slots{SCALAR} and Internals::SvREFCNT $$glob =>== 1
	 and !defined *$glob{IO} and !defined *$glob{FORMAT}
	 and return; # empty glob
	my $newglob = \*$globname;
	local *alias = *$newglob;
	defined *$glob{$_} and (
	 !$check_importedness || $imported_slots{$_}
	  ? *$newglob
	  : *alias
	) = *$glob{$_}
		for qw "SCALAR ARRAY HASH";
	defined *$glob{$_} and *$newglob = *$glob{$_}
		for qw "IO FORMAT";
	return # nothing;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Delete

=head1 NAME

Sub::Delete - Perl module enabling one to delete subroutines

=head1 VERSION

This document describes version 1.000022 of Sub::Delete (from Perl distribution Alt-Sub-Delete-NewPackageSeparator), released on 2023-12-04.

=head1 VERSION

1.00002

=head1 SYNOPSIS

    use Sub::Delete;
    sub foo {}
    delete_sub 'foo';
    eval 'foo();1' or die; # dies

=head1 DESCRIPTION

This module provides one function, C<delete_sub>, that deletes the
subroutine whose name is passed to it. (To load the module without
importing the function, write S<C<use Sub::Delete();>>.)

This does more than simply undefine
the subroutine in the manner of C<undef &foo>, which leaves a stub that
can trigger AUTOLOAD (and, consequently, won't work for deleting methods).
The subroutine is completely obliterated from the
symbol table (though there may be
references to it elsewhere, including in compiled code).

=head1 PREREQUISITES

This module requires L<perl> 5.8.3 or higher.

=head1 LIMITATIONS

If you take a reference to a glob containing a subroutine, and then delete
the subroutine with C<delete_sub>, you will find that the glob you
referenced still has a subroutine in it. This is because C<delete_sub>
removes a glob, replaces it with another, and then copies the contents of
the old glob into the new one, except for the C<CODE> slot. (This is nearly
impossible to fix without breaking constant::lexical.)

=head1 FUNCTIONS

=head2 * delete_sub

=head2 * strict_eval

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Alt-Sub-Delete-NewPackageSeparator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Alt-Sub-Delete-NewPackageSeparator>.

=head1 SEE ALSO

L<perltodo>, which has C<delete &sub> listed as a possible future feature

L<Symbol::Glob> and L<Symbol::Util>, both of which predate this module (but
I only discovered them recently), and which allow one to delete any
arbitrary slot from a glob. Neither of them takes perl 5.10 constants
into account, however. They also both differ from this module, in that a
subroutine referenced in compiled code can no longer be called if deleted
from its glob. The entire glob must be replaced (which this module does).

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2008-10 Father Chrysostomos (sprout at, um, cpan dot org)

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

If you find any bugs, please report them to the author via e-mail.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alt-Sub-Delete-NewPackageSeparator>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
