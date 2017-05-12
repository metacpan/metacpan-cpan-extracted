package CGI::XMLForm::Path;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);

$VERSION = '0.01';

1;
__END__
# This class allows comparison of current paths

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self;
	$self->{_path} = $_[0];
	$self->{_fullpath} = [];
	bless ($self, $class);          # reconsecrate
	if ($self->{_path}) {
		$self->buildSelf($_[1] || new $class);
	}
	return $self;
}

sub buildSelf {
	my $self = shift;
	my $prev = shift;

	if ($self->{_path} =~ s/\*$//) {
		$self->{_repeat} = 1;
	}

#	warn "Building from ", $self->{_path}, "\n";


	my @parts = split('/', $self->{_path});
	my @fullpath;
	$self->{Relative} = 0;

	if ($self->{_path} !~ /^\//) {
		# It's a relative path

		$self->{_relative} = 1;
		@fullpath = @{$prev->{_fullpath}};

		if ($prev->isRelative) {
			# prev was a relative path so remove top item
			pop @fullpath;
		}
		foreach ( @parts ) {
			if ($_ eq "..") {
				pop @fullpath;
			}
			else {
				push @fullpath, $_;
			}
		}
	}
	else {
		# remove crap from beginning (empty because of preceding "/")
		shift @parts;
		@fullpath = @parts;
	}

	if ($fullpath[$#fullpath] =~ /^\@(\w+)$/) {
		pop @fullpath;
		pop @parts;
		$self->{_attrib} = $1;
	}

	$self->{Parts} = \@parts;
	$self->{_fullpath} = \@fullpath;

#	warn "Built: ", $self->FullPath, "\n";

}

sub rebuildSelf {
	my $self = shift;
	$self->buildSelf(new CGI::XMLExt::Path);
}

sub isRelative {
	$_[0]->{_relative};
}

sub isRepeat {
	$_[0]->{_repeat};
}

sub isChildPath {
	my $self = shift;
	my $compare = shift;

	# Now compare each level of the tree, and throw away attributes.
	my @a = @{$self->{_fullpath}};
	my @b = @{$compare->{_fullpath}};

	if (@a >= @b) {
		return 0;
	}
	foreach ($#a..0) {
		$a[$_] =~ s/\[.*\]//;
		$b[$_] =~ s/\[.*\]//;
		return 0 if ($a[$_] ne $b[$_]);
	}
	return 1;
}

sub Attrib {
	$_[0]->{_attrib};
}

sub isEqual {
	my $self = shift;
	my $compare = shift;

	my @a = @{$self->{_fullpath}};
	my @b = @{$compare->{_fullpath}};

#	warn "Comparing: ", $self->FullPath, "\nTo      : ", $compare->FullPath,
#	"\n";
	if (scalar @a != scalar @b) {
		return 0;
	}
	foreach (0..$#a) {
		$a[$_] =~ s/\[.*\]//;
		$b[$_] =~ s/\[.*\]//;
		if ($a[$_] ne $b[$_]) {
			return 0;
		}
	}
#	warn "*** FOUND ***\n";
	return 1;
}

sub Append {
	my $self = shift;
	my $element = shift;
	my %attribs = @_;
	if (%attribs) {
		$element .= "[";

		$element .= join " and ",
					(map "\@$_=\"$attribs{$_}\"", (keys %attribs));
		$element .= "]";
	}
	push @{$self->{_fullpath}}, $element;
	push @{$self->{Parts}}, $element;
	$self->{_path} .= "/". $element;
}

sub Pop {
	my $self = shift;
	pop @{$self->{_fullpath}};
	$self->{_path} =~ s/^(.*)\/.*?$/$1/;
	pop @{$self->{Parts}};
}

sub Path {
	$_[0]->{_path};
}

sub FullPath {
	my $self = shift;
	my $path = "/" . (join "/", @{$self->{_fullpath}});
	$path .= ($self->Attrib ? "/\@" . $self->Attrib : '');
	$path;
}

1;
