package Aion::Run::RunsRun;
# Печатает список команд Aion::Run на stdout
use common::sense;
use List::Util qw/max/;
use Aion::Format qw/printcolor/;
use Aion::Run::Runner;
use Aion;

with qw/Aion::Run/;

# Маска для фильтра по командам
has mask => (is => "ro", isa => Maybe[Str], arg => 1);

#@run run:runs „List of scripts”
sub list {
	my ($self) = @_;

	my @runs = sort {
		$a->{rubric} eq $b->{rubric}? ($a->{name} cmp $b->{name}): $a->{rubric} cmp $b->{rubric}
	} grep { $_->{name} =~ $self->mask } values %{ Aion::Run::Runner->new->runs };
	
	my $len = max map length $_->{name}, @runs;

	for my $run (@runs) {
		eval "require $run->{pkg}";
		my $FEATURE = $Aion::META{$run->{pkg}}{feature};
		my $ARG = {};
		exists $_->{arg} and $ARG->{$_->{arg}} = $_ for values %$FEATURE;

		my @features = sort { $a->{arg} =~ /^\d+$/ && $b->{arg} =~ /^\d+$/ ? $a->{arg} <=> $b->{arg}: $a->{arg} cmp $b->{arg} } values %$ARG;

		$run->{args} = join " ", map {
			my $argument = $_->{opt}{init_arg} // $_->{name};
			my $x = $_->{arg} =~ /^\d+$/ ? $argument :
				$_->{isa}{name} eq "Bool" ? $_->{arg} : "$_->{arg} $argument";
			
			$_->{required} ? ($_->{isa}{name} eq "ArrayRef" ? "$x..." : $x) :
			    ($_->{isa}{name} eq "ArrayRef" ? "[$x...]" : "[$x]")
	    } @features;
	}
	
	my $len2 = max map length $_->{args}, @runs;
	
	my $rubric;
	for(@runs) {
		printcolor "#yellow%s#r\n", $rubric = $_->{rubric} if $rubric ne $_->{rubric};

		printcolor "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", $_->{name}, $_->{args}, $_->{remark};
	}
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Run::RunsRun - list of scripts with the annotation C<#@run>

=head1 SYNOPSIS

File etc/annotation/run.ann:

	Aion::Run::RunRun#run=run:run „Executes Perl code in the context of the current project”
	Aion::Run::RunsRun#list=run:runs „List of scripts”



	use common::sense;
	use Aion::Format qw/trappout coloring/;
	use Aion::Run::RunsRun;
	
	my $len = 4;
	my $len2 = 6;
	
	my $list = coloring "#yellow%s#r\n", "run";
	$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "run", "code", "„Executes Perl code in the context of the current project”";
	$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "runs", "[mask]", "„List of scripts”";
	
	trappout { Aion::Run::RunsRun->new->list } # => $list

=head1 DESCRIPTION

Prints a list of scripts from the file B<etc/annotation/run.ann> to standard output.

To do this, it loads files to obtain descriptions of the arguments from them.

You can change the file in the C<Aion::Run::Runner#INI> config.

=head1 FEATURES

=head2 mask

Mask for filter by scripts.

	my $len = 4;
	my $len2 = 6;
	
	my $list = coloring "#yellow%s#r\n", "run";
	$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "runs", "[mask]", "„List of scripts”";
	
	trappout { Aion::Run::RunsRun->new(mask => 'runs')->list } # => $list

=head1 SUBROUTINES

=head2 list ()

Lists scripts on C<STDOUT>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:darviarush@mail.ru>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Run::RunsRun module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
