package Aion::Run::RunRun;
use common::sense;

use Aion::Format qw/p/;

use Aion;

with qw/Aion::Run/;

# Аргумент команд
has code => (is => "ro+", isa => Str, arg => 1);

# Выполняет код perl-а в контексте текущего проекта
#@run run:run „Executes Perl code in the context of the current project”
sub run {
	my ($self) = @_;

	my $x = eval $self->code;
	die if $@;

	p $x, output => 'stdout', caller_info => 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Run::RunRun - executes Perl code and prints the result to STDOUT

=head1 SYNOPSIS

	use Aion::Format qw/trappout np/;
	use Aion::Run::RunRun;
	
	trappout { Aion::Run::RunRun->new(code => "1+2")->run } # -> np(3, caller_info => 0) . "\n"

=head1 DESCRIPTION

This class executes the perl code C<$ run [code](https://metacpan.org/pod/code)> and prints the result to STDOUT.

=head1 FEATURES

=head2 code

Code to execute.

=head1 SUBROUTINES

=head2 run ()

Executes perl code in the context of the current project.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:darviarush@mail.ru>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Run::RunRun module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
