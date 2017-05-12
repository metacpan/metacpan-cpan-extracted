package Acme::PPIx::MetaSyntactic;

use 5.010001;
use Moo;
use namespace::sweep;
no warnings qw( void once uninitialized numeric );

BEGIN {
	$Acme::PPIx::MetaSyntactic::AUTHORITY = 'cpan:TOBYINK';
	$Acme::PPIx::MetaSyntactic::VERSION   = '0.003';
}

use Acme::MetaSyntactic;
use Perl::Critic::Utils qw( is_perl_builtin is_function_call );
use PPI;

use Types::Standard -types;
use Type::Utils;

my $Document      = class_type Document      => { class => "PPI::Document" };
my $MetaSyntactic = class_type MetaSyntactic => { class => "Acme::MetaSyntactic" };
my $TruthTable    = declare TruthTable       => as Map[Str, Bool];

coerce $Document,
	from ScalarRef[Str], q { "PPI::Document"->new($_) },
	from Str,            q { "PPI::Document"->new($_) },
	from FileHandle,     q { do { local $/; my $c = <$_>; "PPI::Document"->new(\$c) } },
	from ArrayRef[Str],  q { do { my $c = join "\n", map { chomp(my $l = $_); $l } @$_; "PPI::Document"->new(\$c) } },
;

coerce $MetaSyntactic,
	from Str,            q { "Acme::MetaSyntactic"->new($_) },
;

coerce $TruthTable,
	from ArrayRef[Str],  q { +{ map +($_, 1), @$_ } },
;

has document => (
	is       => "ro",
	isa      => $Document,
	coerce   => $Document->coercion,
	required => 1,
	trigger  => 1,
);

has theme => (
	is       => "lazy",
	isa      => $MetaSyntactic,
	coerce   => $MetaSyntactic->coercion,
);

has local_subs => (
	is       => "lazy",
	isa      => $TruthTable,
	coerce   => $TruthTable->coercion,
);

has names => (
	is       => "lazy",
	isa      => Map[Str, Str],
);

has already_used => (
	is       => "lazy",
	isa      => $TruthTable,
	coerce   => $TruthTable->coercion,
	init_arg => undef,
);

sub _get_name
{
	my $self = shift;
	my $name = $self->theme->name;
	my $i    = undef;
	my $used = $self->already_used;
	$i++ while $used->{"$name$i"};
	$used->{"$name$i"} = 1;
	return "$name$i";
}

sub _build_theme
{
	my $self = shift;
	return $MetaSyntactic->new("haddock");
}

sub _build_local_subs
{
	my $self = shift;
	my %r;
	
	for my $word (@{ $self->document->find("PPI::Token::Word") || [] })
	{
		$r{$word} = 1 if $word->sprevious_sibling eq "sub";
		$r{$word} = 1 if $word->sprevious_sibling eq "constant" && $word->sprevious_sibling->sprevious_sibling eq "use";
	}
	
	return \%r;
}

sub _build_names
{
	my $self = shift;
	return +{};
}

sub _build_already_used
{
	my $self = shift;
	return +{
		map +($_, 1), values %{ $self->names },
	};
}

sub _trigger_document
{
	my $self = shift;
	$self->_relabel_subs;
	$self->_relabel_variables;
	return;
}

sub _relabel_subs
{
	my $self = shift;
	my $ls   = $self->local_subs;
	my $n    = $self->names;
	
	for my $word (@{ $self->document->find("PPI::Token::Word")||[] })
	{
		next if is_perl_builtin($word);
		
		# Function to preserve original case of variable.
		my $case =
			($word eq uc $word) ? sub { uc $_[0] } :
			($word eq lc $word) ? sub { lc $_[0] } : sub { $_[0] };
		
		if ($word->sprevious_sibling eq "sub" and $ls->{$word})
		{
			$word->set_content($n->{$word} ||= $case->($self->_get_name));
		}
		elsif ($word->sprevious_sibling eq "constant" && $word->sprevious_sibling->sprevious_sibling eq "use" and $ls->{$word})
		{
			$word->set_content($n->{$word} ||= $case->($self->_get_name));
		}
		elsif (is_function_call($word) and $ls->{$word})
		{
			$word->set_content($n->{$word} ||= $case->($self->_get_name));
		}
	}
	
	return;
}

sub _relabel_variables
{
	my $self = shift;
	my $ls   = $self->local_subs;
	my $n    = $self->names;
	
	my $VariableFinder = sub {
		$_[1]->isa("PPI::Token::Symbol") or $_[1]->isa("PPI::Token::ArrayIndex");
	};
	
	for my $word (@{ $self->document->find($VariableFinder) || [] })
	{
		next if $word->isa("PPI::Token::Magic");
		
		# Function to preserve original case of variable.
		my $case =
			($word eq uc $word) ? sub { uc $_[0] } :
			($word eq lc $word) ? sub { lc $_[0] } : sub { $_[0] };
		
		# Separate sigil from the rest of the variable name.
		(my $sigil = "$word") =~ s/(\w.*)$//g;
		my $rest = $1;
		
		if ($word->isa("PPI::Token::Symbol"))
		{
			$n->{$word->symbol} ||= $case->($self->_get_name);
			$word->set_content($sigil . $n->{$word->symbol});
		}
		elsif ($word->isa("PPI::Token::ArrayIndex"))  # like $#foo
		{
			$n->{"\@$rest"} ||= $case->($self->_get_name);
			$word->set_content($sigil . $n->{"\@$rest"});
		}
	}
	
	for my $qq (@{ $self->document->find("PPI::Token::Quote") || [] })
	{
		# A string that "co-incidentally" happens to have the name as a locally
		# defined sub. This might be a __PACKAGE__->can("foo"), so change it!
		# 
		if ($ls->{$qq->string})
		{
			my $txt = "$qq";
			$txt =~ s/${\quotemeta($qq->string)}/$n->{$qq->string}/eg;
			$qq->set_content($txt);
		}
		
		# An interpolated string. We'll do our best to find any variables
		# within it and rename them, but PPI doesn't really look inside
		# interpolated strings (yet?).
		# 
		elsif ($qq->isa("PPI::Token::Quote::Double") or $qq->isa("PPI::Token::Quote::Interpolate"))
		{
			my $txt = "$qq";
			$txt =~ s/([\$\@]\w+)/$n->{$1}?substr($1,0,1).$n->{$1}:$1/eg;
			$qq->set_content($txt);
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::PPIx::MetaSyntactic - rename functions and variables in a PPI::Document using Acme::MetaSyntactic

=head1 SYNOPSIS

 my $acme = "Acme::PPIx::MetaSyntactic"->new(document => \<<'END');
 use v5.010;
 use constant PLACE => "World";
 
 sub join_spaces {
    return join " ", @_;
 }
 
 my @greetings = qw(Hello);
 
 say join_spaces($greetings[0], PLACE);
 END
 
 say $acme->document;

Example output:

 use v5.010;
 use constant VULTURE => "World";
 
 sub fraud {
    return join " ", @_;
 }
 
 my @gang_of_thieves = qw(Hello);
 
 say fraud($gang_of_thieves[0], VULTURE);

=head1 DESCRIPTION

This module uses L<PPI> to parse some Perl source code, find all the
variables and function names defined in it, and reassign them random names
using L<Acme::MetaSyntactic>.

=head2 Constructor

This module is object-oriented, though there's really very little reason
for it to be.

=over

=item C<< new(%attributes) >>

Moose-style constructor.

=back

=head2 Attributes

All attributes are read-only.

=over

=item C<< document >>

The L<PPI::Document> that will be munged.

Can be coerced from a C<< Str >> (filename), C<< ScalarRef[Str] >> (string
of Perl source), C<< ArrayRef[Str] >> (lines of Perl source) or
C<< FileHandle >>.

Required.

Once the C<document> attribute has been set, a trigger automatically runs
the relabelling.

=item C<< theme >>

The L<Acme::MetaSyntactic> object that will be used to obtain new names.
If your source code is more than a couple of lines; choose one that provides
a large selection of names.

Can be coerced from C<< Str >> (theme name).

Defaults to the C<< "haddock" >> theme.

=item C<< local_subs >>

HashRef where the keys are the names of subs which are considered locally
defined (i.e. not Perl built-ins, and not imported) and thus available for
relabelling. Values are expected to all be C<< "1" >>.

Can be coerced from C<< ArrayRef[Str] >>.

Defaults to a list built by scanning the C<document> with PPI.

=item C<< names >>

HashRef mapping old names to new names. This will be populated by the
relabelling process, but you may supply some initial values. 

Defaults to empty hashref.

=item C<< already_used >>

HashRef keeping track of names already used in remapping, to avoid renaming
two variables the same thing.

Defaults to a hashref populated from C<names>.

This attribute cannot be provided to the constructor.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-PPIx-MetaSyntactic>.

=head1 SEE ALSO

L<PPI>, L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::RefactorCode>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
