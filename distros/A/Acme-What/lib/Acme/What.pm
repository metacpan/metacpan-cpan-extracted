use 5.010;
use strict;
use warnings;

package Acme::What;

BEGIN {
	$Acme::What::AUTHORITY = 'cpan:TOBYINK';
	$Acme::What::VERSION   = '0.005';
}

use Devel::Declare;
use Sub::Util qw/set_subname/;

use base qw/Devel::Declare::Context::Simple/;

sub import
{
	no strict 'refs';
	
	my $caller = caller;
	my $self   = shift;
	my $method = shift // 'WHAT';
	
	my $export = "$caller\::what";
	unless ( exists &$export )
	{
		$self = $self->new unless ref $self;
		Devel::Declare->setup_for(
			$caller,
			{ what => { const => sub { $self->_parser(@_) } } }
		);
		*$export = set_subname($export => sub ($) { $self->_do(@_) });
	}
	
	$^H{(__PACKAGE__)} = $method =~ m{^\+(.+)$}
		? $1
		: sprintf("$caller\::$method");
}

sub unimport
{
	$^H{(__PACKAGE__)} = undef;
}

sub _parser
{
	my $self = shift;
	$self->init(@_);
	$self->skip_declarator;
	$self->skipspace;
	my $linestr = $self->get_linestr;
	
	my $remaining = substr($linestr, $self->offset);
	
	if ($remaining =~ /^(.*?);(.*)$/)
	{
		# Found semicolon
		my $quoted = $self->_quote($1);
		substr($linestr, $self->offset) = "('$quoted');" . $2;
	}
	else
	{
		chomp $remaining;
		my $quoted = $self->_quote($remaining);
		substr($linestr, $self->offset) = "('$quoted');\n";
	}
	
	$self->set_linestr($linestr);
}

sub _quote
{
	my ($self, $str) = @_;
	$str =~ s{([\\\'])}{\\$1}g;
	return $str;
}

sub _do
{
	no strict 'refs';
	my ($self, @args) = @_;
	my @caller = caller(1);
	
	my $meth = $caller[10]{ (__PACKAGE__) };
	
	if (not defined $meth) {
		require Carp;
		Carp::croak("Acme::What disabled");
	}
	
	return $meth->(@args);
}

__PACKAGE__
__END__

=head1 NAME

Acme::What - the f**k?

=head1 SYNOPSIS

 use Acme::What;
 sub WHAT { warn @_ }
 
 what is happening?
 what is the problem?

=head1 WHAT?

Acme::What installs a new C<what> keyword for you.

The C<what> keyword takes the rest of the line of source code on which it
occurs (up to but excluding any semicolon), treats it as a single string
scalar and passes it through to a function called C<WHAT> in the caller
package.

So the example in the SYNOPSIS will warn twice, with the following strings:

  "is happening?"
  "is the problem?"

If you'd rather use a function other than C<WHAT>, then that is OK. Simply
provide the name of an alternative function:

 use Acme::What '_what';
 sub _what { warn @_ }
 
 what is happening?
 what is the problem?

Acme::What is lexically scoped, so you can define different handling for
it in different parts of your code. You can even use:

 no Acme::What;

to disable Acme::What for a scope. (The C<what> keyword is still parsed
within the scope, but when the line is executed, it throws a catchable
error.)

=head1 WHY?

It's in the Acme namespace. There is no why.

=head1 HOW?

Acme::What uses L<Devel::Declare> to work its magic.

=head1 WHITHER?

L<Devel::Declare>, L<Acme::UseStrict>.

=head1 WHO?

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 MAY I?

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 REALLY?

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
