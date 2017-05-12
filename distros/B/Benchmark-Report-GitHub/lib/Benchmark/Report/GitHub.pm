use 5.006;
use strict;
use warnings;

package Benchmark::Report::GitHub;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

my @attributes = qw/ travis_repo_slug gh_name gh_email gh_token /;

sub new {
	my $class = shift;
	my $self  = bless +{ @_ }, $class;
	defined($self->{$_}) || die("missing required attribute: $_")
		for @attributes;
	return $self;
}

sub new_from_env {
	my $class = shift;
	
	my $missing = 0;
	for my $var (qw/ TRAVIS_REPO_SLUG GH_NAME GH_EMAIL GH_TOKEN /) {
		next if defined $ENV{$var};
		warn "missing: $var\n";
		$missing++;
	}
	die "correct environment variables are not set; bailing out"
		if $missing;
	
	$class->new(map +( $_ => $ENV{uc($_)} ), @attributes);
}

sub add_benchmark {
	my $self = shift;
	@_ == 3 or die("too many or too few arguments");
	push @{ $self->{benchmarks} ||= [] }, @_;
	return $self;
}

sub publish {
	my $self = shift;
	my %args = @_;
	
	my ($owner, $project) = split "/", $self->{travis_repo_slug};
	
	my @benchmarks = @{$self->{benchmarks}}
		or die "did you forget something?";
	
	system("rm -fr $project.wiki");
	system("git clone https://github.com/$owner/$project.wiki.git");
	
	my $perl = $args{perl_version} || $ENV{TRAVIS_PERL_VERSION} || $];
	my ($build_num, $build_id, $job_num, $job_id) = map {
		$args{$_} || $ENV{ "TRAVIS_" . uc($_) } || 'unknown'
	} qw( build_number build_id job_number job_id );
	
	my $page    = $args{page}       || "Benchmark_$job_id";
	my $title   = $args{page_title} || "Travis Job $job_num";
	my $idxpage = $args{index_page} || "Benchmarks";
	
	require Benchmark;
	require Cwd;
	require File::Path;
	
	RESULTS: {
		open my $fh, ">", "$project.wiki/$page.md";
		print $fh "# $title\n\n";
		print $fh "[Build log](https://travis-ci.org/$owner/$project/jobs/$job_id).\n\n";
		my $old = select($fh);
		while (@benchmarks) {
			my ($name, $times, $cases) = splice(@benchmarks, 0, 3);
			print "## $name\n\n";
			print "```\n";
			Benchmark::cmpthese($times, $cases);
			print "```\n\n";
		}
		select($old);
		close $fh;
	}
	
	INDEX: {
		open my $idx, ">>", "$project.wiki/$idxpage.md";
		print $idx "* [$title]($page)\n";
		close $idx;
	}
	
	UPLOAD: {
		my $orig = Cwd::cwd();
		chdir "$project.wiki";
		system("git config user.name '$ENV{GH_NAME}'");
		system("git config user.email '$ENV{GH_EMAIL}'");
		system("git config credential.helper 'store --file=.git/credentials'");
		open my $cred, '>', '.git/credentials';
		print $cred "https://$ENV{GH_TOKEN}:\@github.com\n";
		close $cred;
		system("git add .");
		system("git commit -a -m 'benchmarks for $job_num'");
		system("git push --all");
		system("rm '.git/credentials'");
		chdir($orig);
		File::Path::remove_tree("$project.wiki");
	}
	
	return "https://github.com/$owner/$project/wiki/$page";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Benchmark::Report::GitHub - submit a benchmark report from Travis-CI to GitHub wiki

=head1 SYNOPSIS

Let's call this C<< t/benchmarking.pl >>.

   #!/usr/bin/env perl
   use strict;
   use warnings;
   use Benchmark::Report::GitHub;
   
   my $gh = Benchmark::Report::GitHub->new_from_env;
   
   $gh->add_benchmark(
      "Simple benchmark", -1, {
         implementation1 => sub { ... },
         implementation2 => sub { ... },
      },
   );
   
   $gh->add_benchmark(
      "Some other benchmark", -1, {
         implementation1 => sub { ... },
         implementation2 => sub { ... },
         implementation3 => sub { ... },
      },
   );
   
   print $gh->publish, "\n";

And in your C<< .travis.yml >>:

   env:
     global:
       - GH_NAME=username
       - GH_EMAIL=your@email.address
       - secure: "..."   # GH_TOKEN
   after_success: perl -Ilib t/benchmarking.pl

=head1 DESCRIPTION

After a successful Travis build, this module will C<< git pull >>
your project's GitHub wiki, run some benchmarks and output them as
markdown, and then C<< git push >> the wiki contents back to GitHub.

=head2 Constructors

=over

=item C<< new(%attributes) >>

=item C<< new_from_env >>

=back

=head2 Attributes

=over

=item C<< travis_repo_slug >>

(e.g. C<< "tobyink/p5-type-tiny" >>)

=item C<< gh_name >>

=item C<< gh_email >>

=item C<< gh_token >>

=back

=head2 Methods

=over

=item C<< add_benchmark($name, $times, \%implementations) >>

=item C<< publish(%options) >>

The supported options (all of which will be picked up from the
environment, or a sane default provided if omitted) are:

=over

=item C<perl_version>

=item C<build_number>

=item C<build_id>

=item C<job_number>

=item C<job_id>

=item C<page>

=item C<index_page>

=item C<page_title>

=back

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Benchmark-Report-GitHub>.

=head1 SEE ALSO

L<Benchmark>,
L<http://travis-ci.org/>,
L<http://github.com/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

