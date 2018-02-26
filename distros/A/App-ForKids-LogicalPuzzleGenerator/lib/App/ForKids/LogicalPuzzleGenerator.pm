package App::ForKids::LogicalPuzzleGenerator;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;
use App::ForKids::LogicalPuzzleGenerator::Variable::Name;
use App::ForKids::LogicalPuzzleGenerator::Variable::Color;
use App::ForKids::LogicalPuzzleGenerator::Variable::Animal;
use App::ForKids::LogicalPuzzleGenerator::Variable::Fruit;
use App::ForKids::LogicalPuzzleGenerator::Variable::Race;
use App::ForKids::LogicalPuzzleGenerator::Variable::Profession;
use App::ForKids::LogicalPuzzleGenerator::Fact::True;
use App::ForKids::LogicalPuzzleGenerator::Fact::NotTrue;
use Capture::Tiny ':all';
use AI::Prolog;

=head1 NAME

App::ForKids::LogicalPuzzleGenerator - The great new App::ForKids::LogicalPuzzleGenerator!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

The module generates a logical puzzle. The field "story" contains a text describing the puzzle (multiple sessions)
while the field "solution" contains the data describing the solution.

    use App::ForKids::LogicalPuzzleGenerator;

    my $x = App::ForKids::LogicalPuzzleGenerator->new(range=>3, amount_of_facts_per_session => 4);
    
    print $$x{intro_story};
    
    print $$x{story};
    
    print $$x{solution_story};

=head1 SUBROUTINES/METHODS

=head2 new

It requires "range" (a value 2..4). Optionally one can pass amount_of_facts_per_session (the default equals 3)
and debug.

=cut

sub new {
	my $class = shift;
	my $this = { @_ };
	bless $this, $class;
	
	croak "missing range" unless defined $$this{range};
	croak "invalid range" if $$this{range}<2 or $$this{range}>4;	
	
	$$this{amount_of_variables} = $$this{range};
	$$this{amount_of_values} = $$this{range};
	$$this{amount_of_facts_per_session} = 3 unless defined $$this{amount_of_facts_per_session};
	
	croak "invalid amount_of_facts_per_session" if $$this{amount_of_facts_per_session} < 1;

	$this->generate_a_solution();
	$this->create_variables();
	$this->generate_facts();
	$this->generate_story();
	$this->generate_solution_story();
	$this->generate_intro_story();
	
	return $this;
}

=head2 generate_facts
=cut

sub generate_facts
{
	my $this = shift;
	for my $i (0..$$this{amount_of_variables}-1)
	{
		for my $j ($i+1..$$this{amount_of_variables}-1)
		{
			for my $r (@{$$this{solution}})
			{
				push @{$$this{facts}}, 
					App::ForKids::LogicalPuzzleGenerator::Fact::True->new( 
						first => $i, 
						second => $j, 
						a => $$r{$i}, 
						b => $$r{$j}, 
						known => 0
					);

				for my $na (0..$$this{amount_of_values}-1)
				{
					for my $nb (0..$$this{amount_of_values}-1)
					{
						if (($$r{$i} == $na && $$r{$j} != $nb) || ($$r{$i} != $na && $$r{$j} == $nb))
						{
							push @{$$this{facts}}, 
								App::ForKids::LogicalPuzzleGenerator::Fact::NotTrue->new( 
								first => $i, 
								second => $j, 
								a => $na, 
								b => $nb, 
								known => 0
								);
						}
					}
				}
			}
		}
	}
}

=head2 generate_prolog_for_categories
=cut

sub generate_prolog_for_categories
{
	my $this = shift;
	my $program .= "% categories:\n";
	for my $i (0..$#{$$this{variable}})
	{
		for my $value (@{$$this{variable}[$i]{selected_values}})
		{
			my $z = ref($$this{variable}[$i]);
			$z =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
			$program .= "is_value_${z}('$value').\n";
		}
	}
	return $program;
}

=head2 generate_prolog_for_facts
=cut

sub generate_prolog_for_facts
{
	my $this = shift;
	my $known_facts_ref = shift;
	my $program = "";

	for my $i (0..$$this{amount_of_variables}-2)
	{
		my $z1 = ref($$this{variable}[$i]);
		$z1 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		for my $j ($i+1..$$this{amount_of_variables}-1)
		{
			my $z2 = ref($$this{variable}[$j]);
			$z2 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
			$program .= "forbidden_";
			$program .= "${z1}_";
			$program .= "${z2}(fake, fake).\n";
		}
	}


	for my $f (grep { $$_{value} == 1 } @$known_facts_ref)
	{
		$program .= "forbidden_";
		my $z1 = ref($$this{variable}[$$f{first}]);
		$z1 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		$program .= "${z1}_";
		my $z2 = ref($$this{variable}[$$f{second}]);
		$z2 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		$program .= "${z2}('$$this{variable}[$$f{first}]{selected_values}[$$f{a}]', '$$this{variable}[$$f{second}]{selected_values}[$$f{b}]'):-!,fail.\n";
	}

	for my $f (grep { $$_{value} == 0 } @$known_facts_ref)
	{
		$program .= "forbidden_";
		my $z1 = ref($$this{variable}[$$f{first}]);
		$z1 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		$program .= "${z1}_";
		my $z2 = ref($$this{variable}[$$f{second}]);
		$z2 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		$program .= "${z2}('$$this{variable}[$$f{first}]{selected_values}[$$f{a}]', '$$this{variable}[$$f{second}]{selected_values}[$$f{b}]').\n";
	}
	return join("", map { "$_\n" } reverse sort 
		{ 
			$a =~ /^(\w+)/; my $t1 = $1;
			$b =~ /^(\w+)/; my $t2 = $1;

			if ($t1 ne $t2)
			{
				return $t1 cmp $t2;
			}
			return $a =~ /fail/ <=> $b =~ /fail/;
		} split/\n/, $program);
}

=head2 generate_prolog_for_possible_solutions
=cut


sub generate_prolog_for_possible_solutions
{
	my $this = shift;
	my $program .= "possible_solution(".join(",", map { "Z$_" } 0..$#{$$this{variable}})."):-";
	$program .= join(",", map {
		my $z = ref($$this{variable}[$_]);
		$z =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		"is_value_${z}(Z${_})"
		} 0..$#{$$this{variable}});

	for my $i (0..$$this{amount_of_variables}-2)
	{
		my $z1 = ref($$this{variable}[$i]);
		$z1 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
		for my $j ($i+1..$$this{amount_of_variables}-1)
		{
			my $z2 = ref($$this{variable}[$j]);
			$z2 =~ s/App::ForKids::LogicalPuzzleGenerator::Variable:://;
			$program .= ", ";
			$program .= "not(forbidden_${z1}_${z2}(Z${i}, Z${j}))";
		}
	}
	$program .= ".\n\n";
	return $program;
}

=head2 generate_prolog_for_printing_possible_solutions

=cut


sub generate_prolog_for_printing_possible_solutions
{
	my $this = shift;
	
	my $program .= "print_all_possible_solutions :-\n";
	$program .= "	possible_solution(".join(",", map { "Z_0_$_" } 0..$#{$$this{variable}})."),\n";
	$program .= "	eq(Z_0_0, '$$this{variable}[0]{selected_values}[0]'),\n";

	for my $i (1..$$this{amount_of_variables}-1)
	{
		$program .= "	possible_solution(".join(",", map { "Z_${i}_${_}" } 0..$#{$$this{variable}})."),\n";

		$program .= "	eq(Z_${i}_0,'$$this{variable}[0]{selected_values}[$i]'),\n";

		for my $j (0..$i-1)
		{
			$program .= "	".join(",", map { "not(eq(Z_${j}_${_},Z_${i}_${_}))" } 0..$#{$$this{variable}}).",\n";
		}
	}

	for my $i (0..$$this{amount_of_variables}-1)
	{
		$program .= "	write([ ".join(",", map { "Z_${i}_${_}" } 0..$#{$$this{variable}}) ."]),\n";
	}
	$program .= "	nl, fail.\n";
	$program .= "print_all_possible_solutions.\n";

	return $program;
}


=head2 generate_program

=cut

sub generate_program
{
	my $this = shift;
	my $program = "";
	$program .= $this->generate_prolog_for_categories();
	my @known_facts = grep { $$_{known} } @{$$this{facts}};
	$program .= $this->generate_prolog_for_facts(\@known_facts);
	$program .= $this->generate_prolog_for_possible_solutions();
	$program .= $this->generate_prolog_for_printing_possible_solutions();

	for my $r (@{$$this{solution}})
	{
		$program .= "% ".join(",", map { $$this{variable}[$_]{selected_values}[$$r{$_}] } sort keys %$r)."\n";
	}
	
	return $program;
}


=head2 get_result

=cut

sub get_result
{
	my $this = shift;
	my $line = shift;
	my $code = $this->generate_program();
	
	my $p = AI::Prolog->new($code);
	
	my $c;
	
	if ($$this{debug})
	{
		$c = tee_stdout {
			$p->query("print_all_possible_solutions");
			$p->results();
		};
	}
	else
	{
		$c = capture_stdout {
			$p->query("print_all_possible_solutions");
			$p->results();
		};
	}

	my %h = ();
	for my $k (split(/\n/,$c))
	{
		$h{$k} = 1;
	}
	
	print scalar(keys %h), "\n" if $$this{debug};
	return sort keys %h;
}

=head2 add_positive_fact_with_name_to_the_story

=cut


sub add_positive_fact_with_name_to_the_story
{
	my ($this, $current_wizard, $f) = @_;

	my $story = "";
	if ($$f{a} == $current_wizard)
	{
		$story .= $$this{variable}[$$f{second}]->get_description_I($$this{variable}[$$f{second}]{selected_values}[$$f{b}])." ";
	}
	else
	{
		$story .= $$this{variable}[$$f{second}]->get_description_X(
				$$this{variable}[$$f{first}]{selected_values}[$$f{a}],
				$$this{variable}[$$f{second}]{selected_values}[$$f{b}]
				)." ";	
	}
	return $story;
}

=head2 add_positive_fact_without_name_to_the_story

=cut

sub add_positive_fact_without_name_to_the_story
{
	my ($this, $current_wizard, $f) = @_;
	my $story = "";
	
	$story .= $$this{variable}[$$f{first}]->get_description_the_one_who($$this{variable}[$$f{first}]{selected_values}[$$f{a}])." ".
		$$this{variable}[$$f{second}]->get_description_he_likes($$this{variable}[$$f{second}]{selected_values}[$$f{b}])." ";

	return $story;
}


=head2 add_negative_fact_with_name_to_the_story

=cut

sub add_negative_fact_with_name_to_the_story
{
	my ($this, $current_wizard, $f) = @_;

	my $story = "";

	if ($$f{a} == $current_wizard)
	{
		$story .= $$this{variable}[$$f{second}]->get_description_I_dont($$this{variable}[$$f{second}]{selected_values}[$$f{b}])." ";
	}
	else
	{
		$story .= $$this{variable}[$$f{second}]->get_description_X_does_not(
			$$this{variable}[$$f{first}]{selected_values}[$$f{a}],
			$$this{variable}[$$f{second}]{selected_values}[$$f{b}]
			)." ";
	}

	return $story;
}

=head2 add_negative_fact_without_name_to_the_story
=cut

sub add_negative_fact_without_name_to_the_story
{
	my ($this, $current_wizard, $f) = @_;
	my $story = "";
	
	$story .= $$this{variable}[$$f{first}]->get_description_the_one_who($$this{variable}[$$f{first}]{selected_values}[$$f{a}])." ".
		$$this{variable}[$$f{second}]->get_description_he_does_not($$this{variable}[$$f{second}]{selected_values}[$$f{b}])." ";
	
	return $story;
}



=head2 add_negative_fact_to_the_story
=cut


sub add_negative_fact_to_the_story
{
	my ($this, $current_wizard, $f) = @_;

	my $story = "";

	if ($$f{first} == 0)
	{
		$story .= $this->add_negative_fact_with_name_to_the_story($current_wizard, $f);
	}
	else
	{
		$story .= $this->add_negative_fact_without_name_to_the_story($current_wizard, $f);
	}

	return $story;
}


=head2 add_fact_to_the_story
=cut


sub add_fact_to_the_story
{
	my ($this, $current_wizard, $f) = @_;

	my $story = "";
	if ($$f{value})
	{
		$story .= $this->add_positive_fact_to_the_story($current_wizard, $f);
	}
	else
	{
		$story .= $this->add_negative_fact_to_the_story($current_wizard, $f);
	}
	return $story;
}

=head2 get_subsequent_fact

=cut

sub get_subsequent_fact
{
	my ($this, $amount_of_results_ref, $amount_of_results_with_this_fact_ref) = @_;

	my $f;
	my @unknown_facts = grep { !$$_{known} } @{$$this{facts}};
	if (@unknown_facts)
	{
		while (1)
		{
			my @result_without_this_fact = $this->get_result(__LINE__);
			$f = $unknown_facts[int(rand()*@unknown_facts)];
			$$f{known} = 1;
			my @result_with_this_fact = $this->get_result(__LINE__);

			if (@result_without_this_fact > @result_with_this_fact)
			{
				$$amount_of_results_with_this_fact_ref = scalar(@result_with_this_fact);
				$$amount_of_results_ref = scalar(@result_with_this_fact);
				$$f{number} = $$this{counter}++;
				last;
			}
			else
			{
				$$f{known} = 0;
				next;
			}
		}
	}

	return $f;
}



=head2 get_session_with

=cut

sub get_session_with
{
	my $this = shift;
	my $current_wizard = shift;
	my $amount_of_results_ref = shift;
	my $story = "";
	my $introduction;

	for my $i (0..$$this{amount_of_facts_per_session}-1)
	{
		my $amount_of_results_with_this_fact = undef;		
		my $f = $this->get_subsequent_fact($amount_of_results_ref, \$amount_of_results_with_this_fact);

		push @{$$this{sessions}[-1]{facts}}, $f;

		if (!$f)
		{
			$$amount_of_results_ref = 1;
			last;
		}

		if (!$introduction)
		{
			$story .= "- ".sprintf("My name is %s.", 
				$$this{variable}[0]{selected_values}[$current_wizard])." ";
			$introduction = 1;
		}

		$story .= $this->add_fact_to_the_story($current_wizard, $f);

		$$f{known} = 1;

		if (defined($amount_of_results_with_this_fact) && $amount_of_results_with_this_fact == 1)
		{
			return $story;
		}
	}

	return $story;
}


=head2 get_all_sessions

=cut


sub get_all_sessions
{
	my $this = shift;
	my $recent_wizard = undef;
	my $story;
	my $amount_of_results = undef;

	while (1)
	{
		my $current_wizard = undef;

		while (1)
		{
			$current_wizard = int(rand()*($$this{amount_of_variables}));
			last if !defined($recent_wizard) || $current_wizard != $recent_wizard;
		}

		push @{$$this{sessions}}, 
			{ wizard => $current_wizard, amount_of_results => $amount_of_results, facts => [] };

		$story .= $this->get_session_with($current_wizard, \$amount_of_results)."\n";

		$story .= "\n";
		$recent_wizard = $current_wizard;

		if (defined($amount_of_results) && $amount_of_results == 1)
		{
			last;
		}
	}
	return $story;
}

=head2 generate_story
=cut


sub generate_story
{
	my $this = shift;
	my $amount = $$this{amount_of_variables};

	my $story = "";

	$$this{sessions} = [];

	$story .= $this->get_all_sessions();

	$$this{story} = $story;
}


=head2 generate_solution_story
=cut

sub generate_solution_story
{
	my $this = shift;

	my $solution_story = "";

	for my $r (@{$$this{solution}})
	{
		$solution_story .= join(" ", 
			map { $$this{variable}[$_]->get_description_X($$this{variable}[0]{selected_values}[$$r{0}],
				$$this{variable}[$_]{selected_values}[$$r{$_}]) } grep { $_ > 0 } sort keys %$r)."\n";
	}

	$$this{solution_story} = $solution_story;
}

=head2 generate_intro_story

=cut
sub generate_intro_story
{
	my $this = shift;
	my $amount = $$this{amount_of_variables};
	
	my $intro_story = "";
	
	my @names = @{$$this{variable}[0]{selected_values}};
	
	$intro_story .= join(",", @names[0..$#names-1])." and ".$names[-1]." live here.\n";
	
	for my $v (1..$amount-1)
	{
		$intro_story .= $$this{variable}[$v]->get_description()." (".join(",",@{$$this{variable}[$v]{selected_values}}).").\n";
	}
	
	$$this{intro_story} = $intro_story;
}


=head2 create_variables
=cut

sub create_variables
{
	my $this = shift;
	$$this{variable} = [ App::ForKids::LogicalPuzzleGenerator::Variable::Name->new(amount_of_values => $$this{amount_of_values}) ];

	for my $i (1..$$this{amount_of_variables}-1)
	{
		while (1)
		{
			my $z = $this->get_new_variable();

			if (!grep { ref($_) eq ref($z) } @{$$this{variable}})
			{
				push @{$$this{variable}}, $z;
				last;
			}
		}
	}
}


=head2 get_new_variable

=cut


sub get_new_variable
{
	my $this = shift;
	my $r = int(rand()*5);

	if ($r == 0)
	{
		return App::ForKids::LogicalPuzzleGenerator::Variable::Animal->new(amount_of_values => $$this{amount_of_values});
	}
	elsif ($r == 1)
	{
		return App::ForKids::LogicalPuzzleGenerator::Variable::Fruit->new(amount_of_values => $$this{amount_of_values});
	}
	elsif ($r == 2)
	{
		return App::ForKids::LogicalPuzzleGenerator::Variable::Color->new(amount_of_values => $$this{amount_of_values});
	}
	elsif ($r == 3)
	{
		return App::ForKids::LogicalPuzzleGenerator::Variable::Race->new(amount_of_values => $$this{amount_of_values});
	}
	elsif ($r == 4)
	{
		return App::ForKids::LogicalPuzzleGenerator::Variable::Profession->new(amount_of_values => $$this{amount_of_values});
	}
}

=head2 get_variable_number_i_has_appropriate_value

=cut


sub get_variable_number_i_has_appropriate_value
{
	my ($this, $i, $record) = @_;

	for my $r (@{$$this{solution}})
	{
		if ($$r{$i} == $$record{$i})
		{
			return 0;
		}
	}
	return 1;
}

=head2 generate_a_solution

=cut

sub generate_a_solution
{
	my $this = shift;
	for my $i (0..$$this{amount_of_variables}-1)
	{
		my $record = { 0 => $i };
		for my $j (1..$$this{amount_of_variables}-1)
		{
			while (1)
			{
				my $p = int(rand()*$$this{amount_of_values});
				$$record{$j} = $p;
				last if $this->get_variable_number_i_has_appropriate_value($j, $record);
			}
		}
		push @{$$this{solution}}, $record;
	}
}


=head1 AUTHOR

Pawel Biernacki, C<< <pawel.f.biernacki at gmail> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-forkids-logicalpuzzlegenerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ForKids-LogicalPuzzleGenerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ForKids::LogicalPuzzleGenerator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ForKids-LogicalPuzzleGenerator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ForKids-LogicalPuzzleGenerator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ForKids-LogicalPuzzleGenerator>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ForKids-LogicalPuzzleGenerator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pawel Biernacki.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::ForKids::LogicalPuzzleGenerator
