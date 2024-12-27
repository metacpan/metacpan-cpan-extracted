package App::Codit::Macro;

=head1 NAME

App::Codit::Macro - Little applets for line to line text tasks.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION =  0.14;
use Tk;

=head1 SYNOPSIS

 my $macro = $app->mdi->macroInit($docname, 'macroname', ['Some method', $obj]);
 $macro->start;

=head1 DESCRIPTION

B<App::Codit::Macro> creates a task that calls the callback on a line to line basis.
It comes in handy for scanning and or modifying a document.

The callback receives the document textmanagers object and the line number as parameters.

The extension CoditMDI uses it for showing tabs and spaces, removing trailing spaces and fix indentation.

=head1 METHODS

=over 4

=cut

sub new {
	my ($class, $mdi, $name, $doc, $call) = @_;
	my $self = {
		CALL => $mdi->CreateCallback(@$call),
		DOC => $doc,
		COUNTREF => undef,
		INTERVAL => 1,
		LAST => undef,
		LINE => 1,
		MDI => $mdi,
		NAME => $name,
		REMAIN => 0,
		WIDG => $mdi->docGet($doc),
	};
	bless $self, $class;
	return $self
}

=item B<busy>

Returns true when the macro is running.

=cut

sub busy {
	my $self = shift;
	return $self->dem->jobExists($self->jobname)
}

sub call {	return $_[0]->{CALL} }

sub countref {
	my $self = shift;
	$self->{COUNTREF} = shift if @_;
	return $self->{COUNTREF}
}

sub cycle {
	my $self = shift;
	my $line = $self->line;
	$self->call->execute($self->widg, $line);
	$line ++;
	if ($line > $self->lastline) {
		$self->stop;
	} else {
		$self->line($line);
	}
	my $c = $self->countref;
	$$c ++
}

sub dem {
	my $self = shift;
	return $self->mdi->extGet('Daemons');
}

sub doc {	return $_[0]->{DOC} }

=item B<interval>I<(?$cycles?)>

Default value 1. It specifies the interval duration for the Daemons extension.

=cut

sub interval {
	my $self = shift;
	$self->{INTERVAL} = shift if @_;
	return $self->{INTERVAL}
}

sub jobname {
	my $self = shift;
	return $self->doc . $self->name;
}

=item B<last>I<(?$line?)>

Default value undef. Specifies the last line to be handled.
If you leave it unset the last line will be the last line of the document.

=cut

sub last {
	my $self = shift;
	$self->{LAST} = shift if @_;
	return $self->{LAST}
}

sub lastline {
	my $self = shift;
	my $last = $self->last;
	return $last if defined $last;
	my $widg = $self->widg;
	return $widg->linenumber('end - 1c');
}

=item B<line>I<(?$line?)>

Holds the line number that will be processed in the next cycle.
Default value before the call to start is 1.

=cut

sub line {
	my $self = shift;
	$self->{LINE} = shift if @_;
	return $self->{LINE}
}

sub mdi {	return $_[0]->{MDI} }

sub name {	return $_[0]->{NAME} }

=item B<start>

Starts the macro.

=cut

sub start {
	my $self = shift;
	return if $self->busy;
	$self->dem->jobAdd($self->jobname, $self->interval, 'cycle', $self);

	my $mdi = $self->mdi;

	my $count = 0;
	$self->countref(\$count);

	my $last = $self->last;
	unless (defined $last) {
		my $w = $mdi->docGet($self->doc);
		$last = $w->linenumber('end - 1c');
	}

	my $size = $last - $self->line;
	$mdi->progressAdd($self->jobname, $self->name, $size, \$count);
}

=item B<stop>

Stops the macro. It is called after the last line is processed. However, you
may call it to interrupt the macro.

=cut

sub stop {
	my $self = shift;
	return unless $self->busy;
	$self->dem->jobRemove($self->jobname);
	my $mdi = $self->mdi;
	$mdi->macroRemove($self->doc, $self->name) unless $self->remain;
	$mdi->progressRemove($self->jobname);
}

=item B<remain>I<(?$flag?)>

Default value false. If you set it the macro will not be removed
from memory after it finishes.

=cut

sub remain {
	my $self = shift;
	$self->{REMAIN} = shift if @_;
	return $self->{REMAIN}
}

sub widg {	return $_[0]->{WIDG} }

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::BaseClasses::Callback>

=item L<Tk::AppWindow::Ext::Daemons>

=item L<App::Codit::Exit::CoditMDI>

=back

=cut

