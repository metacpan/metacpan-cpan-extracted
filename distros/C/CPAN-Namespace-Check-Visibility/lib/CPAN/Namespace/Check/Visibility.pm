package CPAN::Namespace::Check::Visibility;
use Exporter 'import';
our @EXPORT = qw(is_not_public); # No need to care more than that for pollution

use 5.006;
use strict;
use warnings;

use App::cpm::Resolver::02Packages;
use App::cpm::Resolver::MetaDB;
use App::cpm::Resolver::MetaCPAN;

=head1 NAME

CPAN::Namespace::Check::Visibility - Check if a namespace exists on public CPAN

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Demo CPAN Namespace Check Visibility" src="https://fastapi.metacpan.org/source/CONTRA/CPAN-Namespace-Check-Visibility-0.03/demo.png" style="max-width: 100%">
</div>
</div>

=end html


You can use the C<is_not_public> sub with one or several packages:

    use CPAN::Namespace::Check::Visibility;

    exit is_not_public("Local::Acme");

Or 

    use CPAN::Namespace::Check::Visibility;

    exit is_not_public(@ARGV);

Or prefer the executable:

    cpan-check-visibility Local::Acme

Or from a file:

    cpan-check-visibility `cat private-deps.txt`

Please note: it does not accept C<cpanfile> nor C<cpm.yml> format

=head1 SUBROUTINES/METHODS

=head2 is_not_public

Test indexes for package(s) provided as argument(s).

=cut

sub is_not_public {
    my @packages = @_;
    my $cpan = App::cpm::Resolver::02Packages->new(
        mirror => "https://cpan.org",
        cache => "/tmp",
    );
    my $metadb = App::cpm::Resolver::MetaDB->new();
    my $metacpan = App::cpm::Resolver::MetaCPAN->new(dev => 1);


    my $status = 0;
    for my $package (@packages) {
        chomp $package;
        my $fail = 0;
	#print "🔍 Working on $package...\n";
        my $task = { package => "$package" };
	my @resolvers = ();
        if (not defined $cpan->resolve($task)->{error}) { push @resolvers, "CPAN"; $fail = 1; }
        if (not defined $metadb->resolve($task)->{error}) { push @resolvers, "MetaDB"; $fail = 1; }
        if (not defined $metacpan->resolve($task)->{error}) { push @resolvers, "MetaCPAN"; $fail = 1; }
	
	if ($fail) { print "❌ [$package] resolves in " . join("/", @resolvers) . "\n"; }
	if (not $fail) { print "✅ [$package] does not resolve\n"; } else { $status +=1 }
    }

    return -1 if $status;
    return;
}

=head1 AUTHOR

Thibault Duponchelle, C<< <thibault.duponchelle at gmail.com> >>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Thibault Duponchelle.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of CPAN::Namespace::Check::Visibility
