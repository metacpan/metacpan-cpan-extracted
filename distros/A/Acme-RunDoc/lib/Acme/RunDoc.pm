package Acme::RunDoc;

use strict;
use autodie;

BEGIN {
	$Acme::RunDoc::AUTHORITY = 'cpan:TOBYINK';
	$Acme::RunDoc::VERSION   = '0.002';
}

# 'undef' is Text::Extract::Word's default filter, and probably the only
# one that makes sense.
use constant FILTER => undef;

use Carp qw//;
use Data::Dumper qw//;
use File::Spec;
use IO::File;
use Text::Extract::Word;
use Module::Runtime qw//;

sub do
{
	my ($class, $file) = _args(@_);
	my $text = Text::Extract::Word->new($file)->get_body(FILTER)
		or CORE::do { $! = 'cannot read file'; return undef };
	return CORE::eval($text);
}

sub require_file
{
	my ($class, $file) = _args(@_);
	my $fh = IO::File->new($file, 'r')
		or Carp::croak("Could not require file $file: $!");
	$class->do($fh) or Carp::croak("Could not require file $file: $@");
}

sub require
{
	my ($class, $module) = _args(@_);
	(my $filename = Module::Runtime::module_notional_filename($module))
		=~ s{ \.pm $ }{ '.docm' }ex;
	my ($file) = 
		grep { -e $_ }
		map { File::Spec->catfile($_, $filename) }
		@INC;
	Carp::croak("Could not find $filename in \@INC: ".join q{ }, @INC)
		unless defined $file;
	$class->require_file($file);
}

sub use
{
	my ($class, $module, @args) = _args(@_);
	$class->require($module);
	
	{
		my $import = $module->can('import');
		@_ = ($module, @args);
		goto $import if $import;
	}
}

sub import
{
	my ($class, @args) = _args(@_);
	my $caller = scalar caller;
	local $Data::Dumper::Indent = 0;
	while (@args)
	{
		my $module = shift @args;
		my $args   = ref $args[0] ? shift @args : undef;
		my $eval = sprintf(
			"{ package %s; my \@args = %s; Acme::RunDoc->use('%s', \@args); }",
			$caller,
			ref $args eq 'HASH'
				? sprintf('do { my %s; %%$VAR1 }', Data::Dumper::Dumper($args))
				: ref $args
				? sprintf('do { my %s; @$VAR1 }',  Data::Dumper::Dumper($args))
				: '()',
			$module,
			);
		eval "$eval; 1" or Carp::croak($@);
	}
}

sub _args
{
	my (@args) = @_;
	return @args if $args[0] eq __PACKAGE__;
	return @args if UNIVERSAL::can($args[0] => 'isa')
	             && $args[0]->isa(__PACKAGE__);
	unshift @args, __PACKAGE__;
	return @args;
}

__FILE__
__END__

=head1 NAME

Acme::RunDoc - executes a Microsoft Word document as if it were Perl code

=head1 SYNOPSIS

 Acme::RunDoc->do("helloworld.doc"); 

=head1 DESCRIPTION

It is recieved wisdom that word processors are better than text editors.
After all, you can style your documents with different fonts and colours;
you can take advantage of the built-in spell check; and your ugly single
and double quote characters get auto-replaced with "smart" curly versions.

This module allows you to run Perl documents edited in Microsoft Word
(and other word processors capable of saving in the ".doc" format) as
normal Perl code. You can write scripts and run them like this:

  perl -Microsoft::Word helloworld.doc

or call them from other files using:

  Acme::RunDoc->do("helloworld.doc");

You can write Perl modules using Microsoft Word too. (Just take care to
rename ".doc" to ".docm".) To "require" them:

  Acme::RunDoc->require_file("Hello/World.docm");
  Acme::RunDoc->require("Hello::World");

Acme::RunDoc searches C<< @INC >> just like you'd expect.

You can even "use" modules written in Microsoft Word:

  BEGIN {
    require Acme::RunDoc;
    Acme::RunDoc->use("Hello::World", "greet");
  }

There's a handy shortcut for that too:

  use Acme::RunDoc "Hello::World" => ["greet"];

=head2 C<< do($file) >>

This module provides a class method C<do> which works in an analagous method
to Perl's built-in C<< do $file >> function. In other words, it reads the
contents of the file, and executes it (via C<eval>).

Unlike Perl's built-in, it expects the Perl code to be in Microsoft Word's
"doc" format. Headers, footers, footnotes and annotations are ignored.
"Smart quotes" should be treated as their normal ASCII equivalents.

It may take a file name or an open file handle. (The filehandle needs to be
seekable - see L<IO::Seekable> and L<IO::File>.)

=head2 C<< require_file($file) >>

This class method is analagous to Perl's built-in C<< require $file >>
function. Performs a C<do> on the given filename, but croaks if the file
returns false at the end.

=head2 C<< require($module) >>

This class method is analagous to Perl's built-in C<< require Module >>
function.

Unlike Perl's built-in, it expects Module::Foo to correspond to the file
"Module/Foo.docm".

=head2 C<< use($module) >>

This class method is analagous to Perl's built-in C<< use Module >> function.

Unlike Perl's built-in, this is not automatically executed at compile time.
You'll need to wrap it in a C<< BEGIN { ... } >> block for that to happen.

Unlike Perl's built-in, there is no method for skipping the module's C<import>
method. If you don't want to run C<import>, then just C<require> the module.

=head2 C<< import($module1, \@args1, ...) >>

A handy shortcut for:

 BEGIN {
   require Acme::RunDoc;
   Acme::RunDoc->use($module1, @args1);
   Acme::RunDoc->use($module2, %args2);
   Acme::RunDoc->use($module3);
 }

is:

 use Acme::RunDoc
     $module1  => \@args1,
     $module2  => \%args2,
     $module3  => undef;

(See the sections on C<use>, C<import> and C<require> in L<perlfunc> if any
of that confuses you.)

=head1 SEE ALSO

L<icrosoft::Word>, L<Text::Extract::Word>.

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

