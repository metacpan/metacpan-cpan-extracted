package App::Prove::Plugin::Metrics;

use strict;
use warnings;

our $VERSION='0.0.2';

sub load {
	my ($class,$opt)=@_;
	$$opt{args}//=[];
	my $app=$$opt{app_prove};
	$app->harness(sprintf('TAP::Harness::Metrics=%s',join(',',@{$$opt{args}})));
	return 1;
}

1;

__END__

=pod

=head1 NAME

App::Prove::Plugin::Metrics - Emit metrics when running prove

=head1 VERSION

Version 0.0.2

=head1 SYNOPSIS

  prove -PMetrics [options] [files or directories]

=head1 DESCRIPTION

This module provides a plugin that emits pass-rate metrics from Perl unit tests executed with the `prove` testing tool.

=head1 CONFIGURATION

=head2 General Options

The plugin can be configured by passing a mode (see below) and a number of key/value options:

  -PMetrics=(mode,options),key,value,...

Supported configuration options and their defaults are:

  prefix,PREFIX
  sep,.
  subdepth,.
  label,0
  allowed,-._/A-Za-z0-9
  rollup,0

A metric name is constructed from:  The prefix, the test filename, the subtest path, the label.  These options control the naming of metrics:

=over 4

=item prefix

The prefix to use when constructing any metric name.  If empty, the prefix will be omitted.

=item sep

The separator character used to join the components of the metric name.

=item subdepth

The maximum number of subtest names to include in the metric name.  If subtests are nested beyond this value, they will be interpreted as results at the configured maximum depth, aggregated with a Boolean AND.

If C<subdepth=0>, no subtest paths will be included in the metric name.  If C<subdepthE<lt>0>, the depth will not be limited.

=item label

The assertion label will be included in the metric name when C<label=1>.

=item allowed

The character class of characters that may appear in the final metric name.  All other characters will be removed.

=item rollup

If C<rollup=1>, the metric value will be the percentage of passing tests at that metric name (0 to 1 inclusive).  When C<rollup=0>, the default, the metric value will be a Boolean pass/fail value (0 or 1).

=back

=head2 File Output

The default output mechanism for test metrics is a plain file.  The plugin can be configured as:

  -PMetrics=file,key,value,...

The following options are available in file-output mode:

=over 4

=item outfile

The output filename.

=item format

Not yet available.

=back

=head2 Module Output

Metrics may be emitted via a separate module:

  -PMetrics=module,name,key,value,...

The module must provide a C<save> function that will be called when metrics are emitted, and may optionally provide a stored configuration in C<configureHarness>, as in this example:

  package CustomMetrics;
  use Data::Dumper;

  sub configureHarness {
    return (
      prefix  =>'ORG.TEST.UNIT',
      subdepth=>2,
      label   =>0,
    );
  }

  sub save {
    my (%metrics)=@_;
    foreach my $name (keys %metrics) {
      print "$metrics{$name} $name\n";
    }
  }

=head1 BUGS

The plugin assumes that C<prove> is running with the standard console output formatter.

=head1 SEE ALSO

L<TAP::Harness::Metrics>

L<TAP::Parser::Metrics>

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
