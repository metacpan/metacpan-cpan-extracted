package CPAN::Repository::Packages;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: 02packages

use Moo;

our $VERSION = '0.010';

with qw(
	CPAN::Repository::Role::File
);

use Dist::Data;
use File::Spec::Functions ':ALL';
use IO::File;
use DateTime::Format::RFC3339;
use DateTime::Format::Epoch::Unix;

sub file_parts { 'modules', '02packages.details.txt' }
sub file_parts_stamp { 'modules', '02STAMP' }

has modules => (
	is => 'ro',
	lazy => 1,
	builder => '_build_modules',
);

sub _build_modules {
	my ( $self ) = @_;
	return {} unless $self->exist;
	my @lines = $self->get_file_lines;
	my %modules;
	for (@lines) {
		chomp($_);
		next if ($_ =~ /[^:]:[ \t]/);
		if ($_ =~ m/^([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)$/) {
			# $1 = module
			# $2 = version
			# $3 = path (inside repository)
			$modules{$1} = [ $2, $3 ];
		}
	}
	return \%modules;
}

has authorbase_path_parts => (
	is => 'ro',
	required => 1,
);

has url => (
	is => 'ro',
	required => 1,
);

has written_by => (
	is => 'ro',
	required => 1,
);

sub get_module {
	my ( $self, $module ) = @_;
	return defined $self->modules->{$module}
		? $self->modules->{$module}->[1]
		: ();
}

sub get_module_version {
	my ( $self, $module ) = @_;
	return defined $self->modules->{$module}
		? $self->modules->{$module}->[0]
		: ();
}

sub set_module {
	my ( $self, $module, $version, $path ) = @_;
	return $self->modules->{$module} = [ $version, $path ];
}

sub add_distribution {
	my ( $self, $author_distribution_path ) = @_;
	my $filename = catfile( $self->repository_root, @{$self->authorbase_path_parts}, splitdir( $author_distribution_path ) );
	my $dist = Dist::Data->new( $filename );
	for (keys %{$dist->packages}) {
		$self->set_module($_, $dist->packages->{$_}->{version}, $author_distribution_path);
	}
	return $self;
}

sub stamp_filename {
	my ( $self ) = @_;
	catfile( $self->repository_root, $self->file_parts_stamp );
}

after save => sub {
	my ( $self ) = @_;
	my $stamp = IO::File->new($self->stamp_filename, "w") or die "cant write to ".$self->stamp_filename;
	my $now = DateTime->now;
	print $stamp (DateTime::Format::Epoch::Unix->format_datetime($now).' '.DateTime::Format::RFC3339->new->format_datetime($now)."\n");
	$stamp->close;
};

sub timestamp {
	my ( $self ) = @_;
	my $stamp = IO::File->new($self->stamp_filename, "r") or die "cant read ".$self->stamp_filename;
	my ( $line ) = <$stamp>;
	chomp($line);
	if ($line =~ /^(\d+) /) {
		return DateTime::Format::Epoch::Unix->parse_datetime($1);
	} else {
		die "cant find unix timestamp from ".$self->stamp_filename;
	}
}

sub generate_content {
	my ( $self ) = @_;
	my @file_parts = $self->file_parts;
	my $content = "";
	$content .= $self->generate_header_line('File:',(pop @file_parts));
	$content .= $self->generate_header_line('URL:',$self->url.$self->path_inside_root);
	$content .= $self->generate_header_line('Description:','Package names found in directory $CPAN/authors/id/');
	$content .= $self->generate_header_line('Columns:','package name, version, path');
	$content .= $self->generate_header_line('Intended-For:','Automated fetch routines, namespace documentation.');
	$content .= $self->generate_header_line('Written-By:',$self->written_by);
	$content .= $self->generate_header_line('Line-Count:',scalar keys %{$self->modules});
	$content .= $self->generate_header_line('Last-Updated:',DateTime->now->strftime('%a, %e %b %y %T %Z'));
	$content .= "\n";
	for (sort { $a cmp $b } keys %{$self->modules}) {
		$content .= sprintf("%-60s %-20s %s\n",$_,$self->modules->{$_}->[0] ? $self->modules->{$_}->[0] : 'undef',$self->modules->{$_}->[1]);
	}
	return $content;
}

sub generate_header_line {
	my ( $self, $key, $value ) = @_;
	return sprintf("%-13s %s\n",$key,$value);
}

1;

__END__

=pod

=head1 NAME

CPAN::Repository::Packages - 02packages

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use CPAN::Repository::Packages;

  my $packages = CPAN::Repository::Packages->new({
    repository_root => $fullpath_to_root,
    url => $url,
    written_by => $written_by,
    authorbase_path_parts => ['authors','id'],
  });

=encoding utf8

=head1 SEE ALSO

L<CPAN::Repository>

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-cpan-repository
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-cpan-repository/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<http://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by DuckDuckGo, Inc. L<http://duckduckgo.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
