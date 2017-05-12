package CPAN::Repository::Perms;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: 06perms

our $VERSION = '0.010';

use Moo;

with qw(
	CPAN::Repository::Role::File
);

use Dist::Data;
use File::Spec::Functions ':ALL';
use IO::File;
use DateTime::Format::RFC3339;
use DateTime::Format::Epoch::Unix;

sub file_parts { 'modules', '06perms.txt' }

our @perm_perms = qw( m f c );

has perms => (
	is => 'rw',
	lazy => 1,
	builder => '_build_perms',
);

sub _build_perms {
	my ( $self ) = @_;
	return {} unless $self->exist;
	my @lines = $self->get_file_lines;
	my %perms;
	for (@lines) {
		chomp($_);
		next if ($_ =~ /[^:]:[ \t]/);
		next if ($_ =~ /^ +/);
		next unless $_;
		my @perm_parts = split(',',$_);
		if (@perm_parts == 3) {
			my $module = shift @perm_parts;
			my $userid = shift @perm_parts;
			my $perm = shift @perm_parts;
			$perms{$module} = {} unless defined $perms{$module};
			warn "already found entry for ".$userid." on ".$module if defined $perms{$module}->{$userid};
			$perms{$module}->{$userid} = $perm;
		}
	}
	return \%perms;
}

has written_by => (
	is => 'ro',
	required => 1,
);

sub perms_linecount {
	my ( $self ) = @_;
	my $i = 0;
	for (keys %{$self->perms}) {
		for my $u (keys %{$self->perms->{$_}}) {
			$i++;
		}
	}
	return $i;
}

sub set_perms {
	my ( $self, $module, $userid, $perm ) = @_;
	die "unknown perm ".$perm unless grep { $_ eq $perm } @perm_perms;
	$self->perms->{$module} = {} unless defined $self->perms->{$module};
	$self->perms->{$module}->{$userid} = $perm;
	return $self;
}

sub get_perms {
	my ( $self, $module ) = @_;
	return defined $self->perms->{$module}
		? $self->perms->{$module}
		: {}
}

sub get_perms_by_userid {
	my ( $self, $userid ) = @_;
	my %perms_by_userid;
	for (keys %{$self->perms}) {
		if (defined $self->perms->{$_}->{$userid}) {
			$perms_by_userid{$_} = $self->perms->{$_}->{$userid};
		}
	}
	return \%perms_by_userid;
}

# File:        06perms.txt
# Description: CSV file of upload permission to the CPAN per namespace
#     best-permission is one of "m" for "modulelist", "f" for
#     "first-come", "c" for "co-maint"
# Columns:     package,userid,best-permission
# Line-Count:  215301
# Written-By:  PAUSE version 1.14
# Date:        Fri, 06 Jul 2012 20:23:21 GMT

sub generate_content {
	my ( $self ) = @_;
	my @file_parts = $self->file_parts;
	my $content = "";
	$content .= $self->generate_header_line('File:',(pop @file_parts));
	$content .= $self->generate_header_line('Description:','Description: CSV file of upload permission to the CPAN per namespace');
	$content .= '    best-permission is one of "m" for "modulelist", "f" for'."\n";
	$content .= '    "first-come", "c" for "co-maint"'."\n";
	$content .= $self->generate_header_line('Columns:','package, userid, best-permission');
	$content .= $self->generate_header_line('Intended-For:','Automated fetch routines, namespace documentation.');
	$content .= $self->generate_header_line('Written-By:',$self->written_by);
	$content .= $self->generate_header_line('Line-Count:',$self->perms_linecount);
	$content .= $self->generate_header_line('Date:',DateTime->now->strftime('%a, %e %b %y %T %Z'));
	$content .= "\n";

    my @perms;
	for (sort { $a cmp $b } keys %{$self->perms}) {
		for my $u (sort { $a cmp $b } keys %{$self->perms->{$_}}) {
			push @perms, join(",",$_,$u,$self->perms->{$_}->{$u});
		}
	}
	$content .= join "\n", @perms;
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

CPAN::Repository::Perms - 06perms

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use CPAN::Repository::Perms;

  my $packages = CPAN::Repository::Perms->new({
    repository_root => $fullpath_to_root,
    written_by => $written_by,
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
