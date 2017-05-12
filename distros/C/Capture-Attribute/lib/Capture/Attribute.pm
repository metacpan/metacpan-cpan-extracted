package Capture::Attribute;

use 5.010;
use strict;

BEGIN {
	$Capture::Attribute::AUTHORITY = 'cpan:TOBYINK';
	$Capture::Attribute::VERSION   = '0.003';
}

use Attribute::Handlers;
use Capture::Attribute::Return;
use Capture::Tiny qw//;
use Carp qw//;
use Sub::Name qw//;

my @importers;
sub import
{
	my ($class, %args) = @_;
	my $caller =
		   $args{-into}
		|| $args{-package}
		|| caller;
	
	no strict 'refs';
	push @{"$caller\::ISA"}, __PACKAGE__;
	push @importers, $caller unless $args{-keep};
}

my ($make_replacement_coderef, $save_coderef, $saved);
BEGIN
{
	$make_replacement_coderef = sub
	{
		my ($orig, $data) = @_;

		if ($data eq 'STDOUT')
		{
			return sub
			{
				my (@args) = @_;
				my $wa = wantarray;
				my $stdout = Capture::Tiny::capture {
					$wa ? $save_coderef->(1, my @r = $orig->(@args)) :
					defined $wa ? $save_coderef->(0, my $r = $orig->(@args)) :
					do { $orig->(@args); $save_coderef->() } ;
				};
				return $stdout;
			}
		}
		elsif ($data eq 'STDERR')
		{
			return sub
			{
				my (@args) = @_;
				my $wa = wantarray;
				my (undef, $stderr) = Capture::Tiny::capture {
					$wa ? $save_coderef->(1, my @r = $orig->(@args)) :
					defined $wa ? $save_coderef->(0, my $r = $orig->(@args)) :
					do { $orig->(@args); $save_coderef->() } ;
				};
				return $stderr;
			}
		}
		elsif ($data eq 'MERGED')
		{
			return sub
			{
				my (@args) = @_;
				my $wa = wantarray;
				my $merged = Capture::Tiny::capture_merged {
					$wa ? $save_coderef->(1, my @r = $orig->(@args)) :
					defined $wa ? $save_coderef->(0, my $r = $orig->(@args)) :
					do { $orig->(@args); $save_coderef->() } ;
				};
				return $merged;
			}
		}
		elsif ($data eq 'STDERR,STDOUT')
		{
			return sub
			{
				my (@args) = @_;
				my $wa = wantarray;
				my @r = Capture::Tiny::capture {
					$wa ? $save_coderef->(1, my @r = $orig->(@args)) :
					defined $wa ? $save_coderef->(0, my $r = $orig->(@args)) :
					do { $orig->(@args); $save_coderef->() } ;
				};
				return wantarray ? reverse(@r[0..1]) : $r[0];
			}
		}
		elsif ($data eq 'STDOUT,STDERR')
		{
			return sub
			{
				my (@args) = @_;
				my $wa = wantarray;
				return Capture::Tiny::capture {
					$wa ? $save_coderef->(1, my @r = $orig->(@args)) :
					defined $wa ? $save_coderef->(0, my $r = $orig->(@args)) :
					do { $orig->(@args); $save_coderef->() } ;
				};
			}
		}

		return;
	};
	
	$save_coderef = sub
	{
		if (not scalar @_)
		{
			$saved = Capture::Attribute::Return->new(wasarray => undef);
			return;
		}
		
		my $context = shift;
		$saved = Capture::Attribute::Return->new(
			wasarray => $context,
			value    => ($context ? \@_ : $_[0]),
			);
	}
}

INIT # runs AFTER attributes have been handled.
{
	no strict 'refs';
	foreach my $caller (@importers)
	{
		@{"$caller\::ISA"} = grep { $_ ne __PACKAGE__ } @{"$caller\::ISA"};
	}
	no warnings 'once';
	*return = sub { $saved };
}

sub Capture :ATTR(CODE,RAWDATA)
{
	my (
		$package,
		$symbol,
		$referent,
		$attr,
		$data,
		$phase,
		$filename,
		$linenum,
		) = @_;

	$data = uc($data) || (my $default_data = 'STDOUT');

	my $orig = *{$symbol}{CODE};
	my $replacement = $make_replacement_coderef->($orig, $data)
		or Carp::croak "Unrecognised option string: $data";

	{
		no strict 'refs';
		no warnings 'redefine';
		my $subname = sprintf '%s::%s', *{$symbol}{PACKAGE}, *{$symbol}{NAME};
		*{$subname} = Sub::Name::subname($subname, $replacement);
	}
}

__PACKAGE__
__END__

=head1 NAME

Capture::Attribute - s/return/print/g

=head1 SYNOPSIS

 use Capture::Attribute;
 
 sub foobar :Capture {
   print "Hello World\n";
 }
 
 my $result = foobar();
 $result =~ s/World/Planet/;
 print "$result";   # says "Hello Planet"

=head1 DESCRIPTION

Sometimes you write a function that needs to build a long string via a
convoluted series of conditional statements, loops and so on. I tend to
end up defining a variable C<< $return >> at the top of the code,
concatenating bits to it as required, and then return it at the end. For
example:

 sub count_to_10 {
   my $return = "Listen to me count!\n";
   foreach (1..10) {
     $return .= "$_\n";
     $return .= "Half-way there!\n" if $_==5;
   }
   $return .= "All done!\n";
   return $return;
 }
 
 Mail::Message->new(
   To      => 'teacher@example.com',
   From    => 'student@example.com',
   Subject => 'I can count!',
   data    => count_to_ten(),
   )->send;

Capture::Attribute simplifies this pattern by capturing all output to
STDOUT, so you can use STDOUT as a place to capture each part of the
string.

 sub count_to_10 :Capture {
   say "Listen to me count!";
   foreach (1..10) {
     say $_;
     say "Half-way there!" if $_==5;
   }
   say "All done!";
 }
 
 Mail::Message->new(
   To      => 'teacher@example.com',
   From    => 'student@example.com',
   Subject => 'I can count!',
   data    => count_to_ten(),
   )->send;

Doesn't that look nicer?

Within a sub marked with the ":Capture" attribute, all data that would be
printed is captured instead. When the sub is finished, the return value is
ignored and the captured text is returned instead.

The C<return> keyword still works just fine for its control flow purpose
inside a captured sub. The return value just doesn't get returned.

=head2 How does it work?

When you C<< use Capture::Attribute >>, then at BEGIN time (see 
L<perlmod>) your package will be automatically made into an subclass
of Capture::Attribute.

At CHECK time (again L<perlmod>), Capture::Attribute will then use
L<Attribute::Handlers> to wrap each sub marked with the ":Capture"
attribute with a sub that captures its output via L<Capture::Tiny>,
and returns the output.

At INIT time (again L<perlmod>), Capture::Attribute then removes
itself from your package's C<< @ISA >>, thus your package is no longer
a subclass of Capture::Attribute. (It would be nice if the
subclassing could be avoided altogether, but alas this seems to be
the way Attribute::Handlers works.)

=head2 The ":Capture" Attribute

There are actually various options you can use on the ":Capture"
attribute. They are mostly useless.

=head3 C<< :Capture(STDOUT) >>

This is the default. Captures STDOUT.

=head3 C<< :Capture(STDERR) >>

Captures STDERR instead of STDOUT.

=head3 C<< :Capture(MERGED) >>

Captures both STDOUT and STDERR, merged into one. Because of
buffering, lines from different handles may interleave differently
than expected.

=head3 C<< :Capture(STDOUT,STDERR) >>

Capture both STDOUT and STDERR. In scalar context, returns STDOUT.
In List context returns both.

 sub foo :Capture(STDOUT,STDERR) {
   print "World\n";
   warn "Hello\n";
 }
 my ($hello, $world) = map { chomp;$_ } foo();

=head3 C<< :Capture(STDERR,STDOUT) >>

Capture both STDOUT and STDERR. In scalar context, returns STDERR.
In List context returns both.

=head1 CAVEATS

=head2 Subclassing

As mentioned above, Capture::Attribute B<temporarily> installs itself
as a superclass of your class. If your class has subs named any of
the following, they may override the Capture::Attribute versions,
and bad stuff may happen.

=over

=item * C<ATTR>

=item * C<Capture>

=item * C<MODIFY_CODE_ATTRIBUTES>

=item * any sub matching the expresssion C<< /^_ATTR_CODE_/ >>

=back

=head2 Accessing the real return value

 sub quux :Capture
 {
   print "foo";
   return "bar";
 }
 
 say quux();                             # says "foo"
 say Capture::Attribute->return->value;  # says "bar"

The C<< Capture::Attribute->return >> class method gives you the
B<real> return value from the most recently captured sub. This is
a L<Capture::Attribute::Return> object.

However, this section is listed under CAVEATS for a good reason. The
fact that a sub happens to use the ":Capture" attribute should be
considered private to it. The caller shouldn't consider there to be
any difference between:

 sub foo :Capture { print "foo" }

and

 sub foo { return "foo" }

If the caller of the captured sub goes on to inspect
C<< Capture::Attribute->return >>, then this assumes an implementation
detail of the captured sub, which breaks encapsulation.

=head2 Adding a ":Capture" attribute to somebody else's function

So you want to do something like:

 add_attribute(\&Some::Module::function, ':Capture(STDOUT)');

Here's how:

 # Declare a generic wrapper
 sub CAP :Capture { (shift)->(@_) }
 
 # Wrap Some::Module::function in our wrapper.
 my $orig = \&Some::Module::function;
 local *Some::Module::function = sub { CAP($orig, @_) };

Though you are probably better off investigating L<Capture::Tiny>.

=head2 Call stack

Capture::Attribute adds two extra frames to the call stack, and
L<Capture::Tiny> adds (it seems) two more again. So any code that
you capture will see them quite clearly in the call stack if they
decide to look. They'll show up in stack traces, etc.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Capture-Attribute>.

=head1 SEE ALSO

L<Capture::Tiny>, "Subroutine Attributes" in L<perlsub>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

