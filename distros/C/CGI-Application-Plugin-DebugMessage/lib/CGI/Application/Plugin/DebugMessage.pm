package CGI::Application::Plugin::DebugMessage;

use 5.006;
use strict;
use warnings;

use CGI::Application 3.21;
use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
	debug
	debug_ocode
);
our $VERSION = '0.01';
my $prefix = "CAP_DeubgMessage";

sub import {
	my $caller = scalar(caller);
	$caller->add_callback('postrun', 'CGI::Application::Plugin::DebugMessage::log2footer');
	goto &Exporter::import;
}

sub debug {
	my $self = shift;
	my @added = @_;
	if (@added) {
		my $footer = $self->param("${prefix}_footer") || [];
		my $caller = bless([caller(0)], "${prefix}::Caller");
		@added = map { [$caller, $_] } @added;
		push(@{$footer}, @added);
		$self->param("${prefix}_footer" => $footer)
	}
}

sub debug_ocode {
	my $self  = shift;
	my $code  = shift;
	$self->param("${prefix}_code" => $code) if (UNIVERSAL::can($self, 'param'));
}

sub log2footer {
	my $self   = shift;
	my $ref    = shift;
	my $footer = $self->param("${prefix}_footer") ? $self->param("${prefix}_footer") : [];
	return unless ($footer and ref($footer) eq 'ARRAY' and @{$footer});
	my $html = "<hr />\n" . $self->dump_html() . "<p>Debug Messages:</p>\n<ol>\n";
	foreach my $message (@{$footer}) {
		my $string = '';
		my $caller = undef;
		($caller, $message) = @{$message} if (ref($message) eq 'ARRAY' and @{$message} and ref($message->[0]) eq "${prefix}::Caller");
		$caller = sprintf("[%s(%s)] ", $caller->[0], $caller->[2]) if ($caller);
		# HTML escape and dump (if necessary)
		if (ref($message)) {
			$string = CGI::Application::Plugin::DebugMessage::dump_pretty($self, $message);
			$string = CGI->pre($string);
		} else {
			$string = CGI->escapeHTML($message);
		}
		$string = CGI::Application::Plugin::DebugMessage::convert_code($self, $string) if ($self->param("${prefix}_code"));
		$html .= CGI->li($caller . $string) . "\n";
	}
	$html .= "</ol>\n";
	$$ref =~ s/(<\/html>|$)/$html$1/i;
}

sub dump_pretty {
	my $self = shift;
	eval '
		use Data::Dumper;
		local $Data::Dumper::Indent = 1;
		local $Data::Dumper::Sortkeys = 1;
		local $Data::Dumper::Terse = 1;
	';
	return join(", ", @_) if ($@);
	return unless (@_);
	my $dump = Dumper(@_);
	return $dump;
}

sub convert_code {
	my $self  = shift;
	my $str   = shift;
	my $ref   = ref($str) ? $str : \$str;
	my $class = ref($self) ? ref($self) : $self;
	my $ocode = $self->param("${prefix}_code");
	return $str unless (length($str));
	return $str unless ($ocode);
	# Use Jcode
	eval "use Jcode";
	return $str if ($@);
	# Guess input code
	my ($icode, $match) = Jcode::getcode($$ref);
	$icode = 'euc' if ($icode eq undef and $match > 0);
	if ($icode eq 'euc') {
		my $re_sjis = '[\201-\237\340-\374][\100-\176\200-\374]|[\241-\337]|[\x00-\x7F]';
		my $re_euc  = '[\241-\376][\241-\376]|\216[\241-\337]|\217[\241-\376][\241-\376]|[\x00-\x7F]';
		$icode = 'sjis' if ($$ref !~ /^(?:$re_euc)*$/o and $str =~ /^(?:$re_sjis)*$/o);
	}
	# Convert
	$$ref = Jcode::jcode($ref, $icode)->$ocode if ($icode ne $ocode);
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::DebugMessage - show the debug message

=head1 SYNOPSIS

  -- in your CGI::Application module --
  package Your::App;
  use base qw(CGI::Application);
  use CGI::Application::Plugin::DebugMessage;

  -- in your cgi --
  use Your::App;
  $_ = Your::App->new;
  $_->debug('debug message');       # add debug message as string
  $_->debug([data1, data2, data3]); # add debug message as array ref
  $_->run;                          # debug messages are put before </html>

=head1 DESCRIPTION

CGI::Application::Plugin::DebugMessage is debug utility for CGI::Application.
You can see any debug messages in your html footer, as Sledge::Plugin::DebugScreen does.

=head1 METHODS

=head2 debug

    $a->debug('USER' => $user);

set the debug message. Debug message can be any reference, it will be dumped with Data::Dumper.

=head2 debug_ocode

    $a->debug_ocode('euc');

set code for outputting. When set, debug message is converted with Jcode.

=head1 SEE ALSO

L<CGI::Application>, L<Sledge::Plugin::DebugScreen>

=head1 AUTHOR

Makio Tsukamoto, E<lt>tsukamoto@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Makio Tsukamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
