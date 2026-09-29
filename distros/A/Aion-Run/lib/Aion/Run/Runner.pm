package Aion::Run::Runner;
use common::sense;

use Aion::Annotation::Reader;

use Aion;

# Список команд
has runs => (is => 'ro?!', isa => HashRef, default => sub {
	my($self) = @_;
	my %run;
	my $reader = Aion::Annotation::Reader->new('run');
	while (<$reader>) {
		if($_->{annotation} !~ /^(\S+?):(\S+)[ \t]+(.+)/am) {
			warn("Annotation error. Use #\@run <rubric>:<name> <remark>\n  $_->{annotation}\n  at $reader->{path} line $.");
		 	next;
		}

		$run{$2} = {
			rubric => $1,
			name   => $2,
			remark => $3,
			pkg    => $_->{pkg},
			sub    => $_->{name},
		};
	}
	\%run;
});

# Запускает команду
sub run {
    my ($self, $name, @args) = @_;

    my $run = $self->runs->{$name} or die "Not found \@run `$name`!";
    my ($pkg, $sub) = @$run{qw/pkg sub/};
    eval "require $pkg" or die;

    $pkg->new_from_args(\@args)->$sub
}

my $singleton = __PACKAGE__->new;
*new = sub {$singleton};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Run::Runner - runs the command described by the C<#@run> annotation

=head1 SYNOPSIS

File etc/annotation/run.ann:

	Aion::Run::RunRun#run,3=run:run „Executes Perl code in the context of the current project”
	Aion::Run::RunsRun#list,5=run:runs „List of scripts”



	use Aion::Format qw/trappout/;
	use Data::Printer colored => 1, caller_info => 0, show_memsize => 0;
	use Aion::Run::Runner;
	use Aion::Run::RunRun;
	
	trappout { Aion::Run::Runner->run("run", "1+2") } # -> do { my $t = 3; p $t, return_value => "dump", caller_info => 0, show_memsize => 0 } . "\n"

=head1 DESCRIPTION

C<Aion::Run::Runner> reads the file B<etc/annotation/run.ann> with a list of scripts, and any script from the list can be executed through its C<run> method.

The path to the file with scripts can be changed using the C<AION_ANNOTATION_INI> config.

Used in the C<act> command.

=head1 FEATURES

=head2 runs

Hash with commands. Loaded from a file.

=head1 SUBROUTINES

=head2 run ($name, @args)

Runs a command with the name C<$name> and the arguments C<@args> from the list B<etc/annotation/run.ann>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:darviarush@mail.ru>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Run::Runner module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
