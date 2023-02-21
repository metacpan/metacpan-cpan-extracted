=encoding utf-8

=head1 NAME

App::Greple::tee - module to replace matched text by the external command result

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple's B<-Mtee> module sends matched text part to the specified
command, and replace them by the command result.

External command is specified as following arguments after the module
option ending with C<-->.  For example, next command call command
C<tr> command with C<a-z A-Z> arguments for the matched word in the
data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command effectively convert all matched words from lower-case to
upper-case.  Actually this example is not useful because B<greple> can
do the same thing more effectively with B<--cm> option.

By default, the command is executed only once and all data is sent to
the same command.  Data are mapped line by line, so the number of
lines of input and output data must be identical.

Using B<--discrete> option, individual command is called for each
matched part.  You can notice the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

In this case, lines of input and output data can be differ.

=head1 OPTIONS

=over 7

=item B<--discrete>

Invoke new command for every matched part.

=back

=head1 EXAMPLE

First of all, use the B<teip> command for anything that can be done
with it.

Next command will find some indented part in LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
=begin comment

      c) accompany any non-standard executables with their corresponding Standard
         Version executables, giving the non-standard executables non-standard
         names, and clearly documenting the differences in manual pages (or
         equivalent), together with instructions on where to get the Standard
         Version.
    
      d) make other distribution arrangements with the Copyright Holder.

=end comment

You can reformat this part by using B<tee> module with B<ansifold>
command:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    
=begin comment

      c) accompany any non-standard
         executables with their
         corresponding Standard Version
         executables, giving the non-
         standard executables non-standard
         names, and clearly documenting the
         differences in manual pages (or
         equivalent), together with
         instructions on where to get the
         Standard Version.
    
      d) make other distribution
         arrangements with the Copyright
         Holder.

=end comment

=head1 SEE ALSO

=over 7

=item L<https://github.com/greymd/teip>

This module is inspired by the command named B<teip>.  Unlike B<teip>
command, this module does not have a performace advantage.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "0.01";

use v5.14;
use warnings;
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use App::cdif::Command;
use Data::Dumper;

my($mod, $argv);

our $command;
our $blockmatch;
our $discrete;

my @converted;

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } 0 .. $#{$argv})) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv;
    }
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    $exec->command($command)->setstdin($data)->update->data;
}

sub map_lines {
    my @wonl = grep { $_[$_] !~ /\n\z/ } 0 .. $#_;
    my @from = @_;
    $from[$_] =~ s/\z/\n/ for @wonl;
    my @lines = map { int tr/\n/\n/ } @from;
    my $from = join '', @from;
    my $to = call $from;
    my @out = $to =~ /.*\n/g;
    if (@out < sum @lines) {
	die "Unexpected response from command:\n\n$to\n";
    }
    my @to = map { join '', splice @out, 0, $_ } @lines;
    $to[$_] =~ s/\n\z// for @wonl;
    return @to;
}

sub postgrep {
    my $grep = shift;
    @converted = my @block = ();
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback} ]
	      } $grep->result
	    ] ];
    }
    $discrete and return;

    my @result = $grep->result;
    for my $r (@result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }
    @converted = map_lines(@block) if @block;
}

sub callback {
    if ($discrete) {
	call { @_ }->{match};
    }
    else {
	shift @converted // die;
    }
}

1;

__DATA__

builtin --blockmatch $blockmatch
builtin --discrete!  $discrete

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip
