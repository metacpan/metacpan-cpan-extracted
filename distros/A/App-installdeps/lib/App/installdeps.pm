package App::installdeps;

use strict;
use warnings;

# ABSTRACT: A tiny script to install dependent modules
our $VERSION = 'v0.0.3'; # VERSION

use Getopt::Std;
use Getopt::Config::FromPod;
use Pod::Usage;

use Module::ExtractUse;
use File::Find;
use version 0.77;

sub _exists
{
	my $module = shift;
	unless($module =~ /\.pm$/) {
		$module =~ s@::@/@g;
		$module .= '.pm';
	}
	for my $prefix (@INC) {
		my $path = "$prefix/$module";
		return $path if -e $path;
	}
	return;
}

sub _process
{
	local (@ARGV) = @_;

	my %opts;
	getopts(Getopt::Config::FromPod->string, \%opts);
	pod2usage(-verbose => 2) if exists $opts{h};
	pod2usage(-msg => 'At least one argument MUST be specified', -verbose => 0, -exitval => 1) if ! @ARGV;
	$opts{i} ||= 'cpanm';

	my $p = Module::ExtractUse->new;

	while(my $arg = shift @ARGV) {
		if(-f $arg) { $p->extract_use($arg); }
		elsif(-d $arg) {
			find({ no_chdir => 1, wanted => sub {
				$p->extract_use($_) if -f $_;
			}}, $arg);
		} else {
			warn "can't recognize argument: $arg";
		}
	}
	my @target;
	my %checked;
	my @candidate = keys %{exists $opts{r} ? $p->used_out_of_eval || {}: $p->used || {}};
	while(my $candidate = shift @candidate) {
		next if version::is_lax($candidate);
		my $path;
		$path = _exists($candidate) if ! exists $opts{u} || exists $opts{R};
		next if exists $opts{x} && $candidate =~ /$opts{x}/;
		next if ! exists $opts{X} && $candidate =~ /\$/;
		next if exists $checked{$candidate};
		$checked{$candidate} = 1;
		if(defined $path && exists $opts{R}) {
			my $pp = Module::ExtractUse->new;
			$pp->extract_use($path);
			push @candidate, grep { ! exists $checked{$_} } keys %{exists $opts{r} ? $pp->used_out_of_eval || {} : $pp->used || {}};
		}
		next if ! exists $opts{u} && defined $path;
		push @target, $candidate;
	}
	return (\%opts, \@target);
}

sub run
{
	shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
	my ($opts, $target) = _process(@_);

	if($opts->{n}) {
		print join(' ', @$target), "\n";
	} else {
		print $opts->{i},' ',join(' ', @$target), "\n";
		system $opts->{i},@$target;
	}
}

1;

__END__

=pod

=head1 NAME

App::installdeps - A tiny script to install dependent modules

=head1 VERSION

version v0.0.3

=head1 SYNOPSIS

  App::installdeps->run(@ARGV);

=head1 DESCRIPTION

This is an implementation module for a tiny script to install dependent modules.
If you upload your scripts or modules to PAUSE, you can install dependent modules by cpanm/cpan/cpanp.
However, it is almost impossible and meaningless to upload all your daily-use scripts.

This script scans source to detect dependent modules and install them.

=head1 METHODS

=head2 C<run(@arg)>

Process arguments. Typically, C<@ARGV> is passed. For argument details, see L<installdeps>.

=head1 SEE ALSO

=over 4

=item *

L<installdeps>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
