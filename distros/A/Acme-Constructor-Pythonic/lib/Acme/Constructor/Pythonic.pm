use 5.006;
use strict;
use warnings;

use Exporter::Tiny ();

package Acme::Constructor::Pythonic;

BEGIN {
	$Acme::Constructor::Pythonic::AUTHORITY = 'cpan:TOBYINK';
	$Acme::Constructor::Pythonic::VERSION   = '0.002';
	@Acme::Constructor::Pythonic::ISA       = qw( Exporter::Tiny );
}

sub import
{
	my $me      = shift;
	my $globals = ref($_[0]) eq 'HASH' ? shift() : {};
	
	unless (ref($globals->{into}))
	{
		my @caller = caller;
		$globals->{into_file} = $caller[1] unless exists $globals->{into_file};
		$globals->{into_line} = $caller[2] unless exists $globals->{into_line};
	}
	
	unshift @_, $me, $globals;
	goto \&Exporter::Tiny::import;
}

my %_CACHE;
sub _exporter_expand_sub
{
	my $me = shift;
	my ($name, $args, $globals) = @_;
	
	# We want to be invisible to Carp
	$Carp::Internal{$me} = 1;
	
	# Process incoming arguments, providing sensible defaults.
	my $module = $name;
	my $class  = defined($args->{class})       ? $args->{class}       : $name;
	my $ctor   = defined($args->{constructor}) ? $args->{constructor} : 'new';
	my $alias  = defined($args->{alias})       ? $args->{alias}       : $name;
	my $req    = exists($args->{no_require})   ? !$args->{no_require} : !$globals->{no_require};
	
	# Doesn't really make sense to include a package name
	# as part of the alias. We were just lazy in initializing
	# the default above.
	$alias = $1 if $alias =~ /::(\w+)\z/;
	
	# We really only need Module::Runtime if $req is on.
	# $req is on by default, but in imagined case where
	# the caller has been diligent enough to no_require
	# every import, we can do them a favour and not
	# needlessly load Module::Runtime into memory.
	if ($req) { require Module::Runtime }
	
	# Compile a custom coderef instead of closing
	# over variables.
	my $code = join("\n",
		sprintf('package %s;', $me),
		defined($globals->{into_line}) && defined($globals->{into_file})
			? sprintf('#line %d "%s"', @$globals{qw(into_line into_file)})
			: (),
		sprintf('sub {'),
		$req
			? sprintf('Module::Runtime::use_module(qq[%s]);', quotemeta($module))
			: (),
		sprintf('qq[%s]->%s(@_);', quotemeta($class), $ctor),
		sprintf('}'),
	);
	
	# Orcish maneuver
	# This is not done for reasons of efficiency, but
	# rather because if we're exporting the exact same
	# sub twice, we want it to have the same refaddr.
	# This reduces the chances of 'redefine' warnings,
	# and conflicts (if our subs have been imported into
	# roles).
	my $coderef = ($_CACHE{"$class\034$ctor\034$req"} ||= eval($code))
		or die("Something went horribly wrong!\n$code\n\n");
	
	return ($alias => $coderef);
}

1;

__END__

=head1 NAME

Acme::Constructor::Pythonic - import Python-style constructor functions

=head1 SYNOPSIS

    use Acme::Constructor::Pythonic qw(
        LWP::UserAgent
        JSON
        HTTP::Request
    );
    
    my $json = JSON();
    my $ua   = UserAgent();
    my $req  = Request( GET => 'http://www.example.com/foo.json' );
    
    my $data = $json->decode( $ua->request($req)->content )

=head1 DESCRIPTION

In Python you import classes like this:

    import BankAccount from banking

And you instantiate them with something looking like a function call:

    acct = BankAccount(9.99)

This module allows Python-like object instantiation in Perl. The example in
the SYNOPSIS creates three functions C<UserAgent>, C<JSON> and <Request> each
of which just pass through their arguments to the real object constructors.

=head2 Options

Each argument to the Acme::Constructor::Pythonic is a Perl module name and
may be followed by a hashref of options:

    use Acme::Constructor::Pythonic
        'A::Module',
        'Another::Module' => \%some_options,
        'Yes::Another::Module',
    ;

=over

=item *

B<class>

The class to call the constructor on. This is normally the same as the module
name, and that's the default assumption, so there's no usually much point in
providing it.

=item *

B<constructor>

The method name for the constructor. The default is C<new> which is usually
correct.

=item *

B<alias>

The name of the function you want created for you. The default is the last
component of the module name, which is often sensible.

=item *

B<no_require>

Acme::Constructor::Python will automatically load the module specified. Not
straight away; it waits until you actually perform an instantiation. If you
don't want Acme::Constructor::Python to load the module, then set this option
to true.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Constructor-Pythonic>.

=head1 SEE ALSO

L<aliased>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

(Though it was SSCAFFIDI's idea.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

