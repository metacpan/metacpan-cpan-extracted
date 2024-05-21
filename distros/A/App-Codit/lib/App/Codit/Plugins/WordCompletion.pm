package App::Codit::Plugins::WordCompletion;

=head1 NAME

App::Codit::Plugins::WordCompletion - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.03;

use Carp;

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

=head1 DESCRIPTION

Make your life easy with word completion.

Not yet implemented

=cut

my @deliminators = (
	'.',	'(', ')',	':',	'!',	'+',	',',	'-',	'<',	'=',	'>',	'%',	'&',	'*', '"', '\'',
	'/',	';',	'?',	'[',	']',	'^',	'{',	'|',	'}',	'~',	'\\', '$', '@', '#', '`'
);
my $reg = '';
for (@deliminators) {
	$reg = $reg . quotemeta($_) . '|';
}
$reg = $reg . '\s';
$reg = qr/$reg/;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_,);
	return undef unless defined $self;
	$self->{DOCPOOL} = {};
	$self->interval(10);
	$self->{ACTIVEDELAY} = 300;
	$self->cmdHookBefore('deferred_open', 'docOpen', $self);
	$self->cmdHookAfter('modified', 'activate', $self);
	$self->cmdHookAfter('doc_close', 'docClose', $self);

	return $self;
}

sub _pool {
	return $_[0]->{DOCPOOL}
}

sub activeDelay {
	my $self = shift;
	$self->{ACTIVEDELAY} = shift if @_;
	return $self->{ACTIVEDELAY}
}


sub activate {
	my $self = shift;
	my ($name) = @_;
	$name = $self->extGet('CoditMDI')->docSelected unless defined $name;
	my $id = $self->{'active_id'};
	$self->afterCancel($id) if defined $id;
	return @_ unless (defined $name) and $name;
	$self->{'active_id'} = $self->after($self->activeDelay, ['postChoices', $self, $name]);
	return @_;
}

sub docClose {
	my $self = shift;
	my ($name) = @_;
	$self->jobEnd($name) if $self->jobExists($name);
	delete $self->_pool->{$name};
	return @_;
}

sub docExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return exists $self->_pool->{$name}
}

sub docList {
	my $self = shift;
	my $p = $self->_pool;
	return keys %$p
}

sub docOpen {
	my $self = shift;
	my ($name) = @_;
#	print "starting job scan\n";
	return @_ unless defined $name;
#	return @_ if $self->docExists($name);
	$self->_pool->{$name} = {
		line => 1,
		data => {},
	};
	$self->jobStart($name, 'scan', $self, $name) unless $self->jobExists($name);
	return @_;
}

sub getChoices {
	my ($self, $name, $word) = @_;
	my $data = $self->_pool->{$name}->{'data'};
	my @choices = ();
#	print "Word: $word\n";
	for (sort keys %$data) {
		my $test = $_;
#		print "Test: $test\n";
		next if length($test) < length($word);
		push @choices, $test if lc(substr($test, 0, length($word))) eq lc($word);
	}
	return @choices
}

sub postChoices {
#	print "postChoices\n";
	my ($self, $name) = @_;
	$self->jobStart($name, 'scan', $self, $name) unless $self->jobExists($name);
	my $doc = $self->mdi->docGet($name)->CWidg;
	my $ins = $doc->index('insert');
	my $line = $doc->get("$ins linestart", $ins);
#	print "line $line\n";
	if (($line =~ /([a-z0-9_]+)$/i) and (length($1) > 3)) {
		my @choices = $self->getChoices($name, $1);
		if (@choices) {
		}
		for (@choices) { print "$_\n" }
	}
}

sub scan {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
#	print "scanning $name\n";
	
	my $doc = $self->mdi->docGet($name)->CWidg;
	my $end = $doc->linenumber('end - 1c');
	my $count = 0;
	my $line = $self->_pool->{$name}->{'line'};
	my $data = $self->_pool->{$name}->{'data'};
	while ($count < 100) {
		if ($line > $end) {
			$self->_pool->{$name}->{'line'} = 1;
			$self->jobEnd($name);
#			for (sort keys %$data) { print "$_\n" }
			return
		}
#		print "$line\n";
		my $content = $doc->get("$line.0", "$line.0 lineend");
		while ($content ne '') {
			if ($content =~ s/^([a-z0-9_]+)//i) {
				my $word = $1;
				if (length($word) > 3) {
#					print "Found '$word'\n";
					$data->{$word} = 1;
				}
			} else {
				$content =~ s/^.//;
			}
		}

		$line++;
		$count ++;
	}
	$self->_pool->{$name}->{'line'} = $line;
}


sub Unload {
	my $self = shift;
	$self->cmdUnhookBefore('deferred_open', 'docOpen', $self);
	$self->cmdUnhookAfter('modified', 'activate', $self);
	$self->cmdUnhookAfter('doc_close', 'docClose', $self);
	# TODO Change this after new version of Tk::AppWindow
	#return $self->SUPER::Unload;
	$self->SUPER::Unload;
	return 1
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=back

=cut


1;


